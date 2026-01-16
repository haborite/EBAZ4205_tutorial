# HDMI AXI制御プロジェクト

[English](README.md) | 日本語

EBAZ4205ボード用のAXI4-Lite制御HDMIパターンジェネレータです。

## 機能

- **2つのタイミングプリセット**: VGA 640x480@60Hz / 480p 720x480@60Hz
- **3種類のテストパターン**: カラーバー / チェッカーボード / グラデーション
- **AXI4-Lite制御**: PSからのレジスタベース設定
- **VSync同期更新**: ティアリングのないパターン/タイミング切替
- **デュアルMMCMアーキテクチャ**: グリッチフリーなピクセルクロック切替

## プロジェクト構成

```
06_hdmi_test/
├── hdmi_axi_src/           # 独立したプロジェクト作成用ソースファイル
│   ├── rtl/                # RTLモジュール
│   │   ├── pckgen_dual.v
│   │   ├── syncgen_multi.v
│   │   ├── pattern_multi.v
│   │   ├── axi_hdmi_ctrl.v
│   │   └── pattern_hdmi_axi.v
│   ├── ip/                 # IPソース
│   │   └── rgb2dvi/        # rgb2dvi IP (VHDL)
│   └── constraints/        # 制約ファイル
│       └── pattern_hdmi_axi.xdc
├── create_vivado_project.tcl  # 自動プロジェクト作成スクリプト
├── create_bd.tcl           # Block Design作成スクリプト
├── README.md               # 英語版
└── README_JP.md            # このファイル（日本語版）
```

## ハードウェアアーキテクチャ

### RTLモジュール

- `pattern_hdmi_axi.v` - トップレベルAXIラッパー
- `axi_hdmi_ctrl.v` - クロックドメイン間同期機能付きAXI4-Liteレジスタブロック
- `pattern_multi.v` - マルチパターンテスト信号生成器
- `syncgen_multi.v` - マルチプリセット同期信号生成器
- `pckgen_dual.v` - デュアルMMCMピクセルクロック生成器

### Block Design

- Zynq PS (processing_system7)
- AXI Interconnect
- pattern_hdmi_axi (カスタムRTL)

## レジスタマップ

ベースアドレス: `0x43C00000` (AXI4-Lite, 4KB範囲)

### レジスタ一覧

| オフセット | 名前 | アクセス | 説明 |
|-----------|------|---------|------|
| 0x00 | CTRL | R/W | 制御レジスタ (timing_sel, pattern_sel) |
| 0x04 | STATUS | R | ステータスレジスタ (MMCMロック状態) |
| 0x08-0xFFF | - | - | 予約 |

### 制御レジスタ (0x00) - R/W

| ビット | フィールド | アクセス | リセット値 | 説明 |
|-------|----------|---------|----------|------|
| 0 | timing_sel | R/W | 0 | タイミングプリセット選択<br>0 = VGA 640x480@60Hz (25.175 MHz)<br>1 = 480p 720x480@60Hz (27 MHz) |
| 2:1 | pattern_sel | R/W | 00 | テストパターン選択<br>00 = カラーバー (8色)<br>01 = チェッカーボード (32x32ピクセル)<br>10 = グラデーション (水平方向)<br>11 = 予約 |
| 31:3 | 予約 | R | 0 | 予約、読み出し時は0 |

**注意:**
- レジスタ更新はピクセルクロックドメインに同期されます
- 変更は次のVSync境界で反映されます（ティアリングフリー切替）
- 有効な出力には両方のMMCMがロックされている必要があります

### ステータスレジスタ (0x04) - 読み出し専用

| ビット | フィールド | アクセス | リセット値 | 説明 |
|-------|----------|---------|----------|------|
| 0 | locked | R | 0 | MMCMロック状態<br>0 = ロックされていない（有効な出力なし）<br>1 = 両方のMMCMがロック（有効な出力あり） |
| 31:1 | 予約 | R | 0 | 予約、読み出し時は0 |

**注意:**
- 電源投入後またはリセット後にこのレジスタを確認してください
- 正常動作にはVGAと480p両方のMMCMがロックされている必要があります
- ロック時間は通常リセット解除後10ms未満です

### レジスタアクセス例

```c
// 制御レジスタ読み出し
uint32_t ctrl = CTRL_REG;
uint8_t timing = ctrl & 0x01;
uint8_t pattern = (ctrl >> 1) & 0x03;

// 制御レジスタ書き込み (VGA, チェッカーボード)
CTRL_REG = (1 << 1) | (0 << 0);  // pattern_sel=1, timing_sel=0

// MMCMロック状態確認
while (!(STATUS_REG & 0x01)) {
    // MMCMのロックを待つ
}

// アトミック更新（推奨）
uint32_t new_ctrl = (pattern_sel << 1) | timing_sel;
CTRL_REG = new_ctrl;
```

## 使用方法

### ソフトウェア制御 (C言語)

```c
#include <stdint.h>

#define HDMI_CTRL_BASE  0x43C00000
#define CTRL_REG        (*(volatile uint32_t*)(HDMI_CTRL_BASE + 0x00))
#define STATUS_REG      (*(volatile uint32_t*)(HDMI_CTRL_BASE + 0x04))

// VGA 640x480, カラーバー
CTRL_REG = 0x00;

// VGA 640x480, チェッカーボード
CTRL_REG = 0x02;

// VGA 640x480, グラデーション
CTRL_REG = 0x04;

// 480p 720x480, カラーバー
CTRL_REG = 0x01;

// 480p 720x480, チェッカーボード
CTRL_REG = 0x03;

// 480p 720x480, グラデーション
CTRL_REG = 0x05;

// MMCMロック状態確認
if (STATUS_REG & 0x01) {
    // MMCMがロックされています
}
```

### Python制御 (/dev/mem経由)

```python
import mmap
import struct

HDMI_BASE = 0x43C00000
PAGE_SIZE = 4096

with open('/dev/mem', 'r+b') as f:
    mem = mmap.mmap(f.fileno(), PAGE_SIZE, offset=HDMI_BASE)
    
    # VGA, カラーバー
    mem[0:4] = struct.pack('<I', 0x00)
    
    # 480p, チェッカーボード
    mem[0:4] = struct.pack('<I', 0x03)
    
    # ステータス読み出し
    status = struct.unpack('<I', mem[4:8])[0]
    print(f"MMCM locked: {status & 0x01}")
```

## Vivadoセットアップ

### クイックスタート: 自動プロジェクト作成

提供されているTclスクリプトを実行して完全なVivadoプロジェクトを作成します:

```bash
cd tutorials/06_hdmi_test
vivado -mode batch -source create_vivado_project.tcl
```

またはVivado Tclコンソールで:
```tcl
cd tutorials/06_hdmi_test
source create_vivado_project.tcl
```

このスクリプトは以下を実行します:
- 新規Vivadoプロジェクト作成 (`vivado_project/hdmi_axi_project.xpr`)
- 全RTLファイル追加 (pckgen_dual, syncgen_multi, pattern_multi, axi_hdmi_ctrl, pattern_hdmi_axi)
- rgb2dvi IPソース追加
- Zynq PSとAXI接続を含むBlock Design作成
- 制約ファイル追加
- AXIアドレス割当 (0x43C00000)
- HDLラッパー作成

スクリプト完了後、Vivado GUIでプロジェクトを開き、合成/実装を進めてください。

### 手動セットアップ (代替方法)

手動セットアップを希望する場合:

#### 1. RTLファイル追加

以下のファイルをVivadoプロジェクトに追加:
- `pckgen_dual.v`
- `syncgen_multi.v`
- `pattern_multi.v`
- `axi_hdmi_ctrl.v`
- `pattern_hdmi_axi.v`
- rgb2dviソース (VHDLファイル)

#### 2. Block Design作成

Block Design作成スクリプトを実行:
```tcl
source create_bd.tcl
```

または手動で:
1. 新規Block Design作成
2. Zynq PS IP追加
3. `pattern_hdmi_axi`をモジュール参照として追加
4. PS M_AXI_GP0をAXI Interconnect経由でpattern_hdmi_axi S_AXIに接続
5. アドレス割当: 0x43C00000, 範囲 4K
6. 外部ポート作成: CLK, RST, HDMI_CLK_N/P, HDMI_N/P

#### 3. 制約追加

提供されている`pattern_hdmi_axi.xdc`制約ファイルを使用します。

#### 4. ビットストリーム生成

1. Block Design生成
2. HDLラッパー作成
3. 合成実行
4. 実装実行
5. ビットストリーム生成

## タイミング詳細

### VGA 640x480@60Hz
- ピクセルクロック: 25.175 MHz
- H: 640 + 16 (front) + 96 (sync) + 48 (back) = 800 total
- V: 480 + 10 (front) + 2 (sync) + 33 (back) = 525 total

### 480p 720x480@60Hz
- ピクセルクロック: 27.000 MHz
- H: 720 + 16 (front) + 62 (sync) + 60 (back) = 858 total
- V: 480 + 9 (front) + 6 (sync) + 30 (back) = 525 total

## パターン説明

### カラーバー (pattern_sel=0)
8本の垂直バー: 白、黄、シアン、緑、マゼンタ、赤、青、黒

### チェッカーボード (pattern_sel=1)
32x32ピクセルの白黒市松模様

### グラデーション (pattern_sel=2)
黒から白への水平方向グレースケールグラデーション

## 注意事項

- レジスタ更新はティアリング防止のためVSyncに同期されます
- 有効な出力には両方のMMCMがロックされている必要があります
- ピクセルクロック切替はグリッチフリー動作のためBUFGMUXを使用します
- rgb2dvi IPは25-30 MHzピクセルクロック範囲をサポート（両プリセットが適合）

## トラブルシューティング

**画面出力がない**
- STATUS_REG経由でMMCMロック状態を確認
- HDMIケーブル接続を確認
- CLK入力 (33.333 MHz) を確認

**切替時のティアリング/アーティファクト**
- モード切替中は正常（1-2フレーム）
- 持続する場合はVSync信号の整合性を確認

**色が正しくない**
- rgb2dvi IP設定を確認
- HDMI_N/Pピン割当を確認
