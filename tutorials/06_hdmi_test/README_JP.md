# HDMI Pattern Generator with AXI4-Lite Control

EBAZ4205 (Zynq-7010) 向けの AXI4-Lite バスから制御可能な HDMI テストパターンジェネレータです。
PS (Processing System) から AXI バス経由でタイミングプリセットとテストパターンを動的に切り替えることができます。

## 機能概要

- **AXI4-Lite スレーブインターフェース** による PS からのレジスタ制御
- **3 種類のタイミングプリセット** を動的に切り替え可能
  - VGA 640x480 @60Hz (ピクセルクロック 25.179 MHz)
  - 480p 720x480 @60Hz (ピクセルクロック 27.000 MHz)
  - 720p 1280x720 @60Hz (ピクセルクロック 74.250 MHz)
- **10 種類のテストパターン** を動的に切り替え可能
  - 0: カラーバー (8 本の垂直バー)
  - 1: チェッカーボード (32x32 ピクセル格子)
  - 2: 水平グラデーション
  - 3: クロスハッチ (64px グリッド)
  - 4: ボーダー (1px 白枠)
  - 5: RGB フルフィールド (フレームごとに R/G/B/W 切替)
  - 6: 垂直グラデーション
  - 7: 移動バー (アニメーション)
  - 8: SMPTE カラーバー (75% + PLUGE)
  - 9: ゾーンプレート (同心円)
- **MMCM DRP (Dynamic Reconfiguration Port)** によるランタイムクロック切替
- **VSync 同期レジスタ更新** によるティアリング防止
- **クロックドメインクロッシング** に対応した安全なレジスタ転送 (ダブルFF同期化)
- **Digilent rgb2dvi IP** (外部 SerialClk モード) による TMDS/HDMI 信号生成

## ターゲットボード

| 項目 | 仕様 |
| --- | --- |
| ボード | EBAZ4205 |
| FPGA | Xilinx Zynq-7010 (XC7Z010) |
| システムクロック | 100 MHz (PS FCLK_CLK1) |
| リセット | Active Low (PS FCLK_RESET1_N) |
| HDMI 出力 | TMDS 差動ペア (DATA x3 + CLK x1) |

## ディレクトリ構成

```text
hdmi_axi_src/
├── vivado/
│   ├── src/                     # RTL ソースコード
│   │   ├── README.md
│   │   ├── constraints/
│   │   │   └── pattern_hdmi_axi.xdc    # ピン制約 / クロック制約
│   │   ├── ip/
│   │   │   ├── rgb2dvi/             # Digilent rgb2dvi IP (VHDL)
│   │   │   │   └── src/
│   │   │   │       ├── rgb2dvi.vhd
│   │   │   │       ├── ClockGen.vhd
│   │   │   │       ├── DVI_Constants.vhd
│   │   │   │       ├── OutputSERDES.vhd
│   │   │   │       ├── SyncAsync.vhd
│   │   │   │       ├── SyncAsyncReset.vhd
│   │   │   │       └── TMDS_Encoder.vhd
│   │   │   └── mmcm_drp/            # Xilinx mmcm_drp DRP コントローラ
│   │   │       ├── mmcm_drp.v
│   │   │       └── mmcm_pll_drp_func_7s_mmcm.vh
│   │   └── rtl/
│   │       ├── pattern_hdmi_axi.v   # トップモジュール
│   │       ├── axi_hdmi_ctrl.v      # AXI4-Lite レジスタブロック
│   │       ├── pattern_multi.v      # テストパターン生成
│   │       ├── syncgen_multi.v      # 同期信号生成
│   │       ├── pckgen_triple.v      # トリプルピクセルクロック生成
│   │       └── pckgen_dual.v        # (旧版: 参考用)
│   └── drp/                     # DRP 関連ファイル
└── vitis_src/                   # Vitis ソフトウェアソース
    ├── hdmi_axi.h
    ├── hdmi_axi.c
    ├── main.c
    └── README.txt
```

## モジュール階層

```text
pattern_hdmi_axi (トップ)
├── axi_hdmi_ctrl            AXI4-Lite レジスタ制御 + CDC + リコンフィグ要求生成
├── pattern_multi            テストパターン生成
│   └── syncgen_multi        同期信号生成 (H/V カウンタ, HSYNC, VSYNC)
│       └── pckgen_triple    ピクセルクロック + 5x クロック生成 (MMCM DRP)
└── rgb2dvi                  RGB → TMDS/HDMI 変換 (外部 SerialClk モード)
```

## AXI4-Lite レジスタマップ

ベースアドレスは Vivado Block Design での割り当てに依存します。

### 0x00: Control Register (R/W)

| ビット | フィールド | 説明 |
| --- | --- | --- |
| [1:0] | `timing_sel` | タイミングプリセット選択: 0 = VGA 640x480, 1 = 480p 720x480, 2 = 720p 1280x720 |
| [5:2] | `pattern_sel` | テストパターン選択 (0..9) |
| [31:6] | - | 予約 (読出し時 0) |

`timing_sel` に新しい値を書き込むと、自動的に MMCM DRP リコンフィグが開始されます。
リコンフィグ中は Status Register の `reconfig_busy` が 1 になり、完了後 0 に戻ります。

### 0x04: Status Register (R)

| ビット | フィールド | 説明 |
| --- | --- | --- |
| [0] | `locked` | MMCM ロック状態: 1 = ロック済み |
| [1] | `reconfig_busy` | MMCM リコンフィグ中: 1 = 実行中 |
| [31:2] | - | 予約 (読出し時 0) |

## タイミングプリセット詳細

### VGA 640x480 @60Hz (`timing_sel = 0`)

| パラメータ | 値 |
| --- | --- |
| ピクセルクロック | 25.179 MHz (目標 25.175 MHz, 誤差 +0.02%) |
| 5x SerialClk | 125.893 MHz |
| MMCM 設定 | DIVCLK=2, M=17.625, VCO=881.25 MHz |
| 水平トータル | 800 ピクセル |
| 水平アクティブ | 640 ピクセル |
| 水平フロントポーチ | 16 ピクセル |
| 水平同期幅 | 96 ピクセル |
| 水平バックポーチ | 48 ピクセル |
| 垂直トータル | 525 ライン |
| 垂直アクティブ | 480 ライン |
| 垂直フロントポーチ | 10 ライン |
| 垂直同期幅 | 2 ライン |
| 垂直バックポーチ | 33 ライン |
| H/V 同期極性 | Active Low |

### 480p 720x480 @60Hz (`timing_sel = 1`)

| パラメータ | 値 |
| --- | --- |
| ピクセルクロック | 27.000 MHz (目標 27.0 MHz, 誤差 0%) |
| 5x SerialClk | 135.000 MHz |
| MMCM 設定 | DIVCLK=5, M=47.250, VCO=945.0 MHz |
| 水平トータル | 858 ピクセル |
| 水平アクティブ | 720 ピクセル |
| 水平フロントポーチ | 16 ピクセル |
| 水平同期幅 | 62 ピクセル |
| 水平バックポーチ | 60 ピクセル |
| 垂直トータル | 525 ライン |
| 垂直アクティブ | 480 ライン |
| 垂直フロントポーチ | 9 ライン |
| 垂直同期幅 | 6 ライン |
| 垂直バックポーチ | 30 ライン |
| H/V 同期極性 | Active Low |

### 720p 1280x720 @60Hz (`timing_sel = 2`)

| パラメータ | 値 |
| --- | --- |
| ピクセルクロック | 74.250 MHz (目標 74.25 MHz, 誤差 0%) |
| 5x SerialClk | 371.250 MHz |
| MMCM 設定 | DIVCLK=5, M=37.125, VCO=742.5 MHz |
| 水平トータル | 1650 ピクセル |
| 水平アクティブ | 1280 ピクセル |
| 水平フロントポーチ | 110 ピクセル |
| 水平同期幅 | 40 ピクセル |
| 水平バックポーチ | 220 ピクセル |
| 垂直トータル | 750 ライン |
| 垂直アクティブ | 720 ライン |
| 垂直フロントポーチ | 5 ライン |
| 垂直同期幅 | 5 ライン |
| 垂直バックポーチ | 20 ライン |
| H/V 同期極性 | Active High (CEA-861) |

## クロック構成

`pckgen_triple` モジュールは Xilinx の `mmcm_drp` コントローラ (Clocking Wizard IP 由来) を利用し、
MMCME2_ADV の DRP (Dynamic Reconfiguration Port) 経由でランタイムにクロック周波数を切り替えます。
1 個の MMCM から PCK (1x) と SerialClk (5x) を同時生成します。

```text
SYSCLK (100 MHz)
  └─ MMCME2_ADV (mmcm_drp がDRPシーケンスを制御)
       ├─ CLKOUT0 → BUFG → PCK (ピクセルクロック)
       └─ CLKOUT1 → BUFG → SerialClk (5x, rgb2dvi SERDES 用)

モード切替シーケンス:
  1. AXI レジスタに新 timing_sel を書込み
  2. axi_hdmi_ctrl が変更を検出し reconfig_req パルスを発行
  3. pckgen_triple: パラメータを mmcm_drp S2 ポートにセット → LOAD + SEN
  4. mmcm_drp FSM: MMCM リセット → DRP で Read-Modify-Write → リセット解除
  5. MMCM がロック → SRDY → reconfig_done パルス → 映像出力再開
```

### MMCM DRP パラメータ一覧

| モード | DIVCLK | MULT_F | VCO (MHz) | CLKOUT0_DIV (PCK) | CLKOUT1_DIV (5x) | PCK (MHz) |
| --- | --- | --- | --- | --- | --- | --- |
| VGA | 2 | 17.625 | 881.25 | 35 | 7 | 25.179 |
| 480p | 5 | 47.250 | 945.00 | 35 | 7 | 27.000 |
| 720p | 5 | 37.125 | 742.50 | 10 | 2 | 74.250 |

rgb2dvi IP は `kGenerateSerialClk = FALSE` (外部クロックモード) で使用し、
内部 MMCM を無効化しています。これにより XC7Z010 の MMCM 2 個のうち 1 個のみを使用し、
リソースに余裕を持たせています。

## クロックドメインクロッシング (CDC)

AXI バスクロック (`S_AXI_ACLK`) とピクセルクロック (`PCK`) は非同期です。
安全なデータ転送のため、以下の 2 段階の同期化を行います。

1. **ダブルフリップフロップ同期化**: `timing_sel_reg` / `pattern_sel_reg` を PCK ドメインで 2 段 FF で受ける
2. **VSync 境界ラッチ**: VSync の立ち上がりエッジ (新フレーム開始) でのみ値を更新し、フレーム途中の変更によるティアリングを防止

`reconfig_req` / `reconfig_done` 信号は SYSCLK (100 MHz) ドメインで動作し、
pckgen_triple 内部の DRP FSM も SYSCLK で駆動されるため CDC は不要です。

## ピン割り当て

| 信号 | FPGA ピン | I/O 規格 |
| --- | --- | --- |
| HDMI_CLK_P | F19 | TMDS_33 |
| HDMI_CLK_N | F20 | TMDS_33 |
| HDMI_P[0] | D19 | TMDS_33 |
| HDMI_N[0] | D20 | TMDS_33 |
| HDMI_P[1] | C20 | TMDS_33 |
| HDMI_N[1] | B20 | TMDS_33 |
| HDMI_P[2] | B19 | TMDS_33 |
| HDMI_N[2] | A20 | TMDS_33 |
| UART_0_rxd | H16 | LVCMOS33 |
| UART_0_txd | H17 | LVCMOS33 |

## PS からの制御例 (C 言語)

```c
#include "xil_io.h"

#define HDMI_CTRL_BASE  0x43C00000  // Vivado での割り当てアドレスに変更すること

// Control Register
#define CTRL_REG        (HDMI_CTRL_BASE + 0x00)
// Status Register
#define STAT_REG        (HDMI_CTRL_BASE + 0x04)

// タイミング選択 (bits [1:0])
#define TIMING_VGA      0  // 640x480
#define TIMING_480P     1  // 720x480
#define TIMING_720P     2  // 1280x720

// パターン選択 (bits [5:2])
#define PATTERN_BARS       (0 << 2)
#define PATTERN_CHECKER    (1 << 2)
#define PATTERN_HGRAD      (2 << 2)
#define PATTERN_CROSSHATCH (3 << 2)
#define PATTERN_BORDER     (4 << 2)
#define PATTERN_RGB_FIELD  (5 << 2)
#define PATTERN_VGRAD      (6 << 2)
#define PATTERN_WALKING    (7 << 2)
#define PATTERN_SMPTE      (8 << 2)
#define PATTERN_ZONE       (9 << 2)

void hdmi_set_mode(uint32_t timing, uint32_t pattern) {
    Xil_Out32(CTRL_REG, timing | pattern);
}

int hdmi_is_locked(void) {
    return Xil_In32(STAT_REG) & 0x1;
}

int hdmi_is_reconfig_busy(void) {
    return (Xil_In32(STAT_REG) >> 1) & 0x1;
}

// 使用例: 720p カラーバー
hdmi_set_mode(TIMING_720P, PATTERN_BARS);
while (hdmi_is_reconfig_busy());  // MMCM リコンフィグ完了待ち
while (!hdmi_is_locked());         // MMCM ロック待ち
```

## ビルド方法

1. Vivado で Zynq Block Design を作成し、PS を配置
2. `pattern_hdmi_axi` を AXI4-Lite ペリフェラルとして Block Design に追加
3. `ip/rgb2dvi/src/` 以下の VHDL ソースと `ip/mmcm_drp/` 以下の Verilog ソースをプロジェクトに追加
4. `constraints/pattern_hdmi_axi.xdc` を制約ファイルとして追加
5. PS の FCLK_CLK1 を 100 MHz に設定し、CLK ポートに接続
6. PS の FCLK_RESET1_N を RST ポートに接続
7. AXI Interconnect 経由で PS の M_AXI_GP0 を本 IP の S_AXI に接続
8. Synthesis → Implementation → Bitstream 生成

## 設計上の注意事項

- `rgb2dvi` の `vid_pData` ポートは `{R, B, G}` の順で接続されている (RGB ではない)
- リセット信号 `RST` は PS から Active Low で供給され、内部で反転して Active High として使用
- `timing_sel` の切替は MMCM DRP リコンフィグを伴い、切替中は映像出力が一時停止する (数十 us)
- `rgb2dvi` IP は外部 SerialClk モード (`kGenerateSerialClk = FALSE`) で動作し、内部 MMCM は未使用
- 720p の H/V 同期極性は Active High (CEA-861 準拠)、VGA/480p は Active Low
- `pckgen_triple.v` の DRP パラメータは Vivado Clocking Wizard (Dynamic Reconfiguration 有効) で生成した値を使用
- `ip/mmcm_drp/` は Clocking Wizard が生成する `mmcm_pll_drp` モジュールとヘッダファイル。DRP レジスタ値の計算と Read-Modify-Write シーケンスを担当
- `pckgen_dual.v` は旧版として残存。新設計では使用されない

## ライセンス

- `ip/rgb2dvi/`: Digilent rgb2dvi IP — Digilent のライセンスに従います
- その他の RTL ソース: プロジェクト固有
