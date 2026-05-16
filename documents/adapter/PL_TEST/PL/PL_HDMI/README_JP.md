# EBAZ4205 PL_HDMI プロジェクト

## 概要

EBAZ4205（Zynq-7010 搭載ボード）の PL（Programmable Logic）側を使用して、HDMI/DVI 出力を実現するプロジェクトです。
カラーバーテストパターンを生成し、TMDS 差動信号として HDMI コネクタへ出力します。

---

## プロジェクト構成

```
PL_HDMI/
├── PL_HDMI/                        # Vivado プロジェクトディレクトリ
│   ├── PL_HDMI.xpr                 # Vivado プロジェクトファイル
│   └── PL_HDMI.srcs/
│       ├── constrs_1/new/
│       │   └── TOP.xdc             # 物理ピン制約ファイル
│       └── sources_1/
│           ├── new/
│           │   ├── TOP.v           # トップモジュール（Verilog）
│           │   └── color_bar.v     # カラーバーテストパターン生成モジュール
│           └── ip/
│               ├── clk_wiz_0/      # Clocking Wizard IP（MMCM ベース）
│               └── rgb2dvi_0/      # RGB to DVI 変換 IP（Digilent 製）
└── rgb2dvi/                        # Digilent rgb2dvi IP ソース
    └── src/
        ├── rgb2dvi.vhd             # RGB→DVI トップ（VHDL）
        ├── TMDS_Encoder.vhd        # TMDS エンコーダ
        ├── OutputSERDES.vhd        # OSERDESE2 シリアライザ
        ├── ClockGen.vhd            # クロック生成（MMCM/PLL）
        ├── DVI_Constants.vhd       # DVI 制御トークン定数
        ├── SyncAsync.vhd           # 非同期→同期ブリッジ
        └── SyncAsyncReset.vhd      # リセットブリッジ
```

---

## モジュール構成図

```
clk(50MHz, N18)
    │
    ▼
┌─────────────┐   clk_40m(40MHz)   ┌──────────────┐   HS/VS/DE   ┌───────────────┐
│  clk_wiz_0  │──────────────────▶│  color_bar   │─────────────▶│               │
│  (MMCM)     │                    │ (カラーバー) │              │  rgb2dvi_0    │──▶ TMDS_DATA_p/n[2:0]
│             │   clk_200m(200MHz) │              │   R/G/B[7:0] │  (DVI 出力)   │──▶ TMDS_CLK_p/n
└─────────────┘──────────────────▶└──────────────┘─────────────▶└───────────────┘
```

---

## 信号一覧（TOP モジュール）

| 信号名          | 方向   | 説明                          |
| --------------- | ------ | ----------------------------- |
| `clk`           | 入力   | ボードクロック 50 MHz (N18)   |
| `TMDS_DATA_p[2:0]` | 出力 | TMDS データ差動 正側          |
| `TMDS_DATA_n[2:0]` | 出力 | TMDS データ差動 負側          |
| `TMDS_CLK_p`    | 出力   | TMDS クロック差動 正側 (F19)  |
| `TMDS_CLK_n`    | 出力   | TMDS クロック差動 負側        |

---

## Clocking Wizard 設定詳細

### 概要

`clk_wiz_0` は Xilinx の **MMCME2_ADV** プリミティブを使用したクロック生成 IP です。
50 MHz の入力クロックから、映像処理に必要な 2 系統のクロックを生成します。

### MMCM パラメータ

| パラメータ          | 値       | 説明                                 |
| ------------------- | -------- | ------------------------------------ |
| `DIVCLK_DIVIDE`     | 1        | 入力分周なし                         |
| `CLKFBOUT_MULT_F`   | 20.0     | VCO 逓倍数 → VCO = 50×20 = **1000 MHz** |
| `CLKOUT0_DIVIDE_F`  | 25.0     | clk_out1 分周 → 1000/25 = **40 MHz** |
| `CLKOUT1_DIVIDE`    | 5        | clk_out2 分周 → 1000/5 = **200 MHz** |
| `CLKIN1_PERIOD`     | 20.000 ns | 入力クロック周期（50 MHz）            |
| `COMPENSATION`      | ZHOLD    | ゼロホールド補償（入出力スキュー最小化） |
| `BANDWIDTH`         | OPTIMIZED | ジッタ最適化モード                   |

### クロック出力

| 出力ポート  | 周波数    | デューティ比 | ジッタ       | 用途                        |
| ----------- | --------- | ------------ | ------------ | --------------------------- |
| `clk_out1`  | **40 MHz**  | 50%          | 204.383 ps   | ピクセルクロック（color_bar / rgb2dvi_0 PixelClk） |
| `clk_out2`  | **200 MHz** | 50%          | 142.107 ps   | シリアルクロック（rgb2dvi_0 SerialClk = PixelClk × 5） |

### クロックバッファ構成

```
MMCME2_ADV
├── CLKOUT0 ──▶ BUFG ──▶ clk_out1 (40 MHz, PixelClk)
├── CLKOUT1 ──▶ BUFG ──▶ clk_out2 (200 MHz, SerialClk)
└── CLKFBOUT ──▶ BUFG ──▶ CLKFBIN (フィードバックループ)
```

---

## テストパターン（color_bar）のタイミング生成

### 選択解像度

`color_bar.v` は複数の解像度をマクロ定義で切り替え可能な設計になっています。
現在は **`VIDEO_800_600`** が有効です（`color_bar.v` 34行目）。

```verilog
`define VIDEO_800_600
```

### 対応解像度一覧

| マクロ定義          | 解像度       | ピクセルクロック | H_TOTAL | V_TOTAL |
| ------------------- | ------------ | --------------- | ------- | ------- |
| `VIDEO_480_272`     | 480×272      | ~9 MHz          | 525     | 286     |
| `VIDEO_640_480`     | 640×480      | 25.175 MHz      | 800     | 525     |
| `VIDEO_800_480`     | 800×480      | 33 MHz          | 1056    | 505     |
| `VIDEO_800_600`     | **800×600**  | **40 MHz** ✓    | 1056    | 628     |
| `VIDEO_1024_768`    | 1024×768     | 65 MHz          | 1344    | 806     |
| `VIDEO_1280_720`    | 1280×720     | 74.25 MHz       | 1650    | 750     |
| `VIDEO_1920_1080`   | 1920×1080    | 148.5 MHz       | 2200    | 1125    |

### 800×600 タイミングパラメータ

#### 水平タイミング

| パラメータ | 値（ピクセル） | 説明            |
| ---------- | -------------- | --------------- |
| `H_FP`     | 40             | フロントポーチ  |
| `H_SYNC`   | 128            | 水平同期パルス  |
| `H_BP`     | 88             | バックポーチ    |
| `H_ACTIVE` | 800            | 有効映像期間    |
| `H_TOTAL`  | 1056           | 1ライン合計     |
| `HS_POL`   | 正極性 (1)     | 同期極性        |

#### 垂直タイミング

| パラメータ | 値（ライン） | 説明            |
| ---------- | ------------ | --------------- |
| `V_FP`     | 1            | フロントポーチ  |
| `V_SYNC`   | 4            | 垂直同期パルス  |
| `V_BP`     | 23           | バックポーチ    |
| `V_ACTIVE` | 600          | 有効映像期間    |
| `V_TOTAL`  | 628          | 1フレーム合計   |
| `VS_POL`   | 正極性 (1)   | 同期極性        |

> フレームレート ≈ 40,000,000 ÷ (1056 × 628) ≈ **60.3 Hz**

### タイミング生成ロジック

```
h_cnt (0 〜 H_TOTAL-1)
│
├─ h_cnt == H_FP - 1          → HS アサート開始
├─ h_cnt == H_FP + H_SYNC - 1 → HS ネゲート
├─ h_cnt == H_FP + H_SYNC + H_BP - 1 → h_active = 1（映像開始）
└─ h_cnt == H_TOTAL - 1       → h_active = 0、h_cnt リセット

v_cnt は h_cnt == H_FP - 1 のタイミングでインクリメント
│
├─ v_cnt == V_FP - 1          → VS アサート開始
├─ v_cnt == V_FP + V_SYNC - 1 → VS ネゲート
├─ v_cnt == V_FP + V_SYNC + V_BP - 1 → v_active = 1
└─ v_cnt == V_TOTAL - 1       → v_active = 0、v_cnt リセット

DE（Data Enable）= h_active & v_active（1クロック遅延出力）
```

> `hs`・`vs`・`de` はすべて **1クロック遅延**して出力されるため、RGB データとの位相整合が取れています。

### カラーバーパターン

H 方向を 8 分割し、各帯域に以下の色を割り当てます。

| 区間（active_x）        | 色         | R    | G    | B    |
| ----------------------- | ---------- | ---- | ---- | ---- |
| 0 〜 H_ACTIVE/8 × 1 - 1 | 白         | 0xFF | 0xFF | 0xFF |
| H_ACTIVE/8 × 1 〜 ×2 -1 | 黄         | 0xFF | 0xFF | 0x00 |
| H_ACTIVE/8 × 2 〜 ×3 -1 | シアン     | 0x00 | 0xFF | 0xFF |
| H_ACTIVE/8 × 3 〜 ×4 -1 | 緑         | 0x00 | 0xFF | 0x00 |
| H_ACTIVE/8 × 4 〜 ×5 -1 | マゼンタ   | 0xFF | 0x00 | 0xFF |
| H_ACTIVE/8 × 5 〜 ×6 -1 | 赤         | 0xFF | 0x00 | 0x00 |
| H_ACTIVE/8 × 6 〜 ×7 -1 | 青         | 0x00 | 0x00 | 0xFF |
| H_ACTIVE/8 × 7 〜 末尾  | 黒         | 0x00 | 0x00 | 0x00 |

ブランキング期間中は RGB すべて 0x00 になります。

---

## RGB→DVI 変換（rgb2dvi_0）

Digilent 製のオープンソース IP（rgb2dvi v1.4）を使用しています。

### 構成

```
rgb2dvi_0
├── TMDS_Encoder × 3     : DVI 1.0 規格の 8b/10b 類似エンコード（各チャネル）
│     - Stage1: 遷移最小化（XOR / XNOR 選択）
│     - Stage2: DC バランス制御（カウンタベース）
│     - Stage3: 登録出力
├── OutputSERDES × 3     : OSERDESE2 マスタ/スレーブカスケード（10:1 DDR シリアライズ）
│     - OBUFDS            : TMDS_33 差動出力バッファ
└── ClockSerializer      : クロックチャネル（"1111100000" パターン固定出力）
```

### チャネル割り当て

| チャネル | 信号          | データソース               |
| -------- | ------------- | -------------------------- |
| Ch0 (青) | `TMDS_DATA_p/n[0]` | Blue[7:0]、HSync、VSync |
| Ch1 (緑) | `TMDS_DATA_p/n[1]` | Green[7:0]              |
| Ch2 (赤) | `TMDS_DATA_p/n[2]` | Red[7:0]                |
| CLK      | `TMDS_CLK_p/n`     | クロックパターン固定      |

### クロック設定（外部供給モード）

本プロジェクトでは `kGenerateSerialClk = false` 相当の設定で、
`clk_wiz_0` から供給された 40 MHz および 200 MHz クロックを直接使用します。
（`rgb2dvi_0` 内の `ClockGen` は使用しません）

---

## ピン制約（TOP.xdc）

| 信号           | パッケージピン | I/O 規格  |
| -------------- | -------------- | --------- |
| `clk`          | N18            | LVCMOS33  |
| `TMDS_CLK_p`   | F19            | TMDS_33※  |
| `TMDS_DATA_p[0]` | D19          | TMDS_33※  |
| `TMDS_DATA_p[1]` | C20          | TMDS_33※  |
| `TMDS_DATA_p[2]` | B19          | TMDS_33※  |

※ TMDS 差動ペアの N 側は Vivado が自動的に隣接ピンに割り当てます。

---

## ツール・ターゲットデバイス

| 項目         | 内容                              |
| ------------ | --------------------------------- |
| FPGA         | Xilinx Zynq-7010 (xc7z010)        |
| ボード       | EBAZ4205                          |
| EDA ツール   | Vivado (Xilinx Vivado Design Suite) |
| 作成日       | 2022/06/10                        |
| rgb2dvi IP   | Digilent rgb2dvi v1.4 (BSD-3-Clause) |

---

## ビルド手順

1. Vivado で `PL_HDMI/PL_HDMI.xpr` を開く
2. **Generate Bitstream** を実行
3. **Open Hardware Manager** → ボードに接続
4. ビットストリームを書き込む

---

## 解像度の変更方法

`color_bar.v` の先頭マクロ定義を変更し、`clk_wiz_0` のクロック設定をあわせて変更します。

```verilog
// 例: 1280×720 に変更する場合
// `define VIDEO_800_600  ← 削除またはコメントアウト
`define VIDEO_1280_720
```

### マクロ定義と対応解像度一覧

| マクロ定義 | 解像度 | HS_POL | VS_POL | 状態 |
| --- | --- | --- | --- | --- |
| `VIDEO_480_272` | 480×272 | 負極性 | 負極性 | |
| `VIDEO_640_480` | 640×480 | 負極性 | 負極性 | |
| `VIDEO_800_480` | 800×480 | 負極性 | 負極性 | |
| `VIDEO_800_600` | 800×600 | 正極性 | 正極性 | **現在有効** |
| `VIDEO_1024_768` | 1024×768 | 負極性 | 負極性 | |
| `VIDEO_1280_720` | 1280×720 | 正極性 | 正極性 | |
| `VIDEO_1920_1080` | 1920×1080 | 正極性 | 正極性 | |

### 解像度別 Clocking Wizard（MMCM）設定

#### 入力クロック 50 MHz の場合

| マクロ定義 | PixelClk | SerialClk | MULT_F | DIVCLK | DIVIDE_F (out1) | DIVIDE (out2) | VCO |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `VIDEO_480_272` | ~9 MHz | ~45 MHz | 18.0 | 2 | 50.0 | 10 | 450 MHz ⚠️ |
| `VIDEO_640_480` | 25.175 MHz | 125.875 MHz | 25.175 | 1 | 50.0 | 10 | ~1259 MHz ⚠️ |
| `VIDEO_800_480` | 33 MHz | 165 MHz | 33.0 | 1 | 50.0 | 10 | 1650 MHz ❌ |
| `VIDEO_800_600` | 40 MHz | 200 MHz | 20.0 | 1 | 25.0 | 5 | 1000 MHz ✅ |
| `VIDEO_1024_768` | 65 MHz | 325 MHz | 26.0 | 1 | 20.0 | 4 | 1300 MHz ⚠️ |
| `VIDEO_1280_720` | 74.25 MHz | 371.25 MHz | 29.700 | 2 | 10.0 | 2 | 742.5 MHz ✅ |
| `VIDEO_1920_1080` | 148.5 MHz | 742.5 MHz | 29.700 | 2 | 5.0 | 1 | 742.5 MHz ✅ |

#### 入力クロック 33.33 MHz の場合

> VCO = 33.33 MHz × MULT_F / DIVCLK

| マクロ定義 | PixelClk | SerialClk | MULT_F | DIVCLK | DIVIDE_F (out1) | DIVIDE (out2) | VCO |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `VIDEO_480_272` | ~9 MHz | ~45 MHz | 18.0 | 1 | 66.6 | 13.3 | 600 MHz ⚠️ |
| `VIDEO_640_480` | 25.175 MHz | 125.875 MHz | 18.900 | 1 | 25.0 | 5 | 629.9 MHz ✅ |
| `VIDEO_800_480` | 33 MHz | 165 MHz | 24.750 | 1 | 25.0 | 5 | 824.8 MHz ✅ |
| `VIDEO_800_600` | 40 MHz | 200 MHz | 24.000 | 1 | 20.0 | 4 | 800.0 MHz ✅ |
| `VIDEO_1024_768` | 65 MHz | 325 MHz | 29.250 | 1 | 15.0 | 3 | 975.0 MHz ✅ |
| `VIDEO_1280_720` | 74.25 MHz | 371.25 MHz | 22.275 | 1 | 10.0 | 2 | 742.5 MHz ✅ |
| `VIDEO_1920_1080` | 148.5 MHz | 742.5 MHz | 22.275 | 1 | 5.0 | 1 | 742.5 MHz ✅ |

> `VIDEO_480_272` の DIVIDE_F=66.6 / DIVIDE=13.3 は整数でないため、Vivado GUI で目標周波数を入力して近似値を自動計算させることを推奨します。

**VCO 判定凡例：** ✅ 範囲内（600〜1200 MHz）／ ⚠️ 要調整／ ❌ 範囲超過

> **注意:**
>
> - 解像度変更時は Vivado で `clk_wiz_0` IP を開き直し、出力周波数を設定して **Generate Output Products** を再実行してください。
> - `VIDEO_800_480`（50 MHz 入力時）は VCO が 1200 MHz を超えるため、`DIVCLK_DIVIDE=2` に変更して調整が必要です（例: MULT_F=26.4, DIVCLK=2, VCO=660 MHz）。
> - `VIDEO_480_272`（50 MHz 入力時）は VCO が 600 MHz を下回るため `CLKFBOUT_MULT_F` を大きく取るか、SerialClk を `BUFG` 経由で供給する構成に変更が必要です。
> - 実際の Vivado GUI では目標周波数を MHz 単位で入力すれば `MULT_F` / `DIVIDE_F` は自動計算されます。

---

## rgb2dvi のソース直接組み込み

### 概要

`rgb2dvi_0` IP を使わず、`rgb2dvi/src/` 以下の VHDL ソースをプロジェクトに直接追加することができます。
ソース管理のポータビリティが高まり、Vivado バージョン依存を減らせます。

### 追加するファイル

Vivado の **Add Sources** で以下を全て追加します。

| ファイル | 役割 |
| --- | --- |
| `rgb2dvi.vhd` | RGB→DVI トップエンティティ |
| `TMDS_Encoder.vhd` | DVI 1.0 TMDS エンコーダ（3 チャネル分） |
| `OutputSERDES.vhd` | OSERDESE2 マスタ/スレーブカスケードシリアライザ |
| `ClockGen.vhd` | 内蔵クロック生成（MMCM/PLL）※本プロジェクトでは不使用 |
| `DVI_Constants.vhd` | DVI 制御トークン定数パッケージ |
| `SyncAsync.vhd` | 非同期→同期ブリッジ |
| `SyncAsyncReset.vhd` | リセットブリッジ |

### TOP.v のインスタンス書き換え

`rgb2dvi_0`（IP ラッパー）から `rgb2dvi`（VHDL entity）に書き換えます。

```verilog
rgb2dvi #(
    .kGenerateSerialClk(1'b0),
    .kClkPrimitive("PLL"),
    .kClkRange(1),
    .kRstActiveHigh(1'b0)
) u1 (
    .aRst(1'b0),
    .aRst_n(1'b1),
    .SerialClk(clk_200m),
    .PixelClk(clk_40m),
    .TMDS_Clk_p(TMDS_CLK_p),
    .TMDS_Clk_n(TMDS_CLK_n),
    .TMDS_Data_p(TMDS_DATA_p),
    .TMDS_Data_n(TMDS_DATA_n),
    .vid_pData({R,G,B}),
    .vid_pHSync(VGA_HS),
    .vid_pVSync(VGA_VS),
    .vid_pVDE(VGA_DE)
);
```

その後、Vivado の Sources ペインから `rgb2dvi_0` IP を **Remove File from Project** で削除します。

---

## rgb2dvi 内蔵 MMCM の無効化

### 設定パラメータ

`kGenerateSerialClk = false` が内蔵 MMCM を無効化するパラメータです。
本プロジェクトの `rgb2dvi_0.xci` にてすでに `false` に設定されています。

### `kGenerateSerialClk` による動作の違い

| 設定 | 内蔵 ClockGen | SerialClk ポート | 備考 |
| --- | --- | --- | --- |
| `false`（本プロジェクト） | **インスタンス化なし** | 外部供給必須 | `clk_wiz_0` の 200 MHz を使用 |
| `true` | MMCM/PLL を内部生成 | 未接続でよい | PixelClk から ×5 を内部生成 |

`kGenerateSerialClk = false` のとき、`rgb2dvi.vhd` 内では以下の分岐が選択されます。

```vhdl
ClockGenExternal: if not kGenerateSerialClk generate
   PixelClkIO <= PixelClk;
   SerialClkIO <= SerialClk;
   aRstLck <= aRst_int;
end generate ClockGenExternal;
```

`ClockGen` エンティティは完全に合成対象から除外され、MMCM/PLL リソースを消費しません。

### IP 化 vs ソース直接組み込みの比較

| 項目 | IP（現状） | ソース直接組み込み |
| --- | --- | --- |
| パラメータ変更 | Vivado GUI で変更 | VHDL/Verilog 直接編集 |
| P/N スワップ対応 | GUI チェックボックス | `kD0Swap` 等を generic で指定 |
| バージョン管理 | `.xci` ファイル依存 | ソースファイルのみで完結 |
| ポータビリティ | Vivado バージョン依存あり | **高い** |
| Out-of-Context 合成 | 自動 | 無効（プロジェクト全体で合成） |
