# FT2232DボードでXilinx JTAGプログラマーを作成する方法

## 概要

秋月電子の「FT2232D USBシリアル2ch変換モジュールキット」（[商品番号: 116897](https://akizukidenshi.com/catalog/g/g116897/)）を使用して、Xilinx（AMD）FPGA用のJTAGプログラマーを作成できます。

> **重要: Vivado 2024.2 ではFT2232DをDigilentケーブルとして完全認識できません。**
>
> cs_server（Digilentドライバ）がFT2232H前提のプロトコルでJTAGを制御するため、
> FT2232DではJTAGスキャンが失敗します。Vivado Hardware Managerを使用する場合は
> openFPGALoaderのXVCサーバーを経由するか、FT2232H/純正Digilentケーブルをご利用ください。
> 詳細な手順は `programming-guide.md` の「FT2232DとVivado 2024.2の使い方」を参照してください。

## 必要な部品

### メインボード
- FT2232D USBシリアル2ch変換モジュールキット EEPROM実装済（秋月電子: 116897）
  - 価格: 約2,000円
  - FT2232DチップとEEPROMが実装済み

## 対応デバイス

### FTDI側
- **公式サポート**: FT232H, FT2232H, FT4232H
- **FT2232D**: 互換性がある可能性が高い（要検証）

### Xilinx側
- Spartan, Artix, Kintex, Virtex シリーズFPGA
- Zynq, Zynq UltraScale+ MPSoC
- Versal シリーズ

## ハードウェア接続

### ピン配置（FT2232D Channel A）

FT2232DのチャネルAのADBUS0-7を使用します：

| FTDIピン | 信号名 | 方向 | 接続先 | 説明 |
|---------|--------|------|--------|------|
| ADBUS0 | TCK | 出力 | FPGA TCK | JTAGクロック |
| ADBUS1 | TDI | 出力 | FPGA TDI | JTAGデータ入力 |
| ADBUS2 | TDO | 入力 | FPGA TDO | JTAGデータ出力 |
| ADBUS3 | TMS | 出力 | FPGA TMS | JTAGモード選択 |
| ADBUS4 | VCCO_ON | 入力 | ターゲット電源 | ターゲット検出（High=電源ON） |
| ADBUS5 | OE_B | 出力 | レベル変換OE | 出力イネーブル（オプション） |
| ADBUS6 | POR_B | 出力 | Zynq PS_POR_B | パワーオンリセット（MPSoC用） |
| ADBUS7 | SRST_B | 出力 | Zynq PS_SRST_B | システムリセット（Zynq用） |

### 最小構成（Spartan/Artix等の純粋なFPGA）

基本的なJTAG接続のみで動作します：

```
FT2232D          レベル変換           FPGA
ADBUS0 (TCK) -----> [3.3V->VCCO] ----> TCK
ADBUS1 (TDI) -----> [3.3V->VCCO] ----> TDI
ADBUS2 (TDO) <----- [VCCO->3.3V] <---- TDO
ADBUS3 (TMS) -----> [3.3V->VCCO] ----> TMS
ADBUS4 -------------------------------- VCCO (電源検出)
```

**注意**: FT2232DのI/Oは3.3V固定です。FPGAのJTAGバンクが1.8Vなど異なる電圧の場合、必ずレベル変換ICを使用してください。

### Zynq用の拡張構成

ZynqやVersal MPSoCの場合、リセット信号も必要です：

```
FT2232D                              Zynq
ADBUS6 (POR_B) -----> [オープンコレクタ] ----> PS_POR_B
ADBUS7 (SRST_B) ----> [オープンコレクタ] ----> PS_SRST_B
```

### EBAZ4205ボード固有の情報

#### JTAG電圧レベル: 3.3V

EBAZ4205ボードのJTAGポート（J8）は **3.3V (LVCMOS33)** です。

**根拠**:
- EBAZ4205はXilinx Zynq XC7Z010 (xc7z010clg400-1) を搭載
- FPGAバンクの電圧は3.3Vに設定されている
- MIOバンク（UART、SD、JTAGを含む）も3.3V
- コミュニティのVivadoボードファイルでLVCMOS33として定義されている

**FT2232Dとの接続**:
- FT2232DのI/O電圧（3.3V）とEBAZ4205のJTAG電圧（3.3V）は一致
- **直接接続は可能ですが、レベル変換ICの使用を推奨**
  - 理由: 異なる電源供給のため、電源ノイズや電位差による問題を回避
  - 推奨IC: SN74AVC4T245, 74AVC4T3144

**確認方法**:
1. J8コネクタのVCCピンの電圧をテスターで測定（3.3Vであることを確認）
2. 回路図でMIOバンクの電源（VCCO_MIO）を確認
3. XC7Z010のデータシートでMIOバンクの仕様を参照

**接続例（EBAZ4205専用）**:

```
FT2232D      SN74AVC4T245      EBAZ4205 (J8)
           VCCA=3.3V VCCB=3.3V
ADBUS0 ----> A1 ----> B1 -----> TCK
ADBUS1 ----> A2 ----> B2 -----> TDI
ADBUS2 <---- A3 <---- B3 <----- TDO
ADBUS3 ----> A4 ----> B4 -----> TMS
ADBUS5 ----> OE (Low=Enable)
3.3V ------> VCCA     VCCB <--- J8 VCC (3.3V)
GND -------> GND <------------- J8 GND
```

**注意事項**:
- J8コネクタはデフォルトで実装されていません（自分ではんだ付けが必要）
- J8のピン配置は標準的な2.54mmピッチ
- EBAZ4205の電源が入っていることを確認してからJTAGを接続

## EEPROMプログラミング

FT2232DをXilinx JTAGプログラマーとして認識させるには、EEPROMに特別な設定を書き込む必要があります。

### 方法1: Vivadoの`program_ftdi`スクリプトを使用（推奨）

Xilinx Vivadoに含まれる公式スクリプトを使用します：

```bash
# Vivadoのスクリプトディレクトリに移動
cd $XILINX_VIVADO/scripts/program_ftdi

# EEPROMをプログラム
./program_ftdi -write -ftdi=ft2232h -serial=<シリアル番号> \
  -vendor="Custom" -board="EBAZ4205 JTAG" -desc="Xilinx JTAG Cable"
```

**パラメータ説明**:
- `-ftdi`: FTDIチップのタイプ（ft2232h, ft4232h, ft232h）
- `-serial`: FTDIデバイスのシリアル番号
- `-vendor`: ベンダー名（Xilinx独自データ領域に保存）
- `-board`: ボード名（hw_server接続文字列に表示）
- `-desc`: USB製品記述文字列

**注意**: 
- USB Manufacturerは常に"Xilinx"に設定されます
- Vivado 2024.1ではこのスクリプトに問題がある可能性があります

### 方法2: カスタムプログラミング（上級者向け）

FTDI D2XX APIを使用して直接EEPROMをプログラムします。

#### EEPROMユーザー領域のフォーマット

```
オフセット  内容
0x00-0x03  シグネチャ（リトルエンディアン）
           FT232H: 0x584A0002
           FT2232H: 0x584A0003
           FT4232H: 0x584A0004
0x04-      Vendor String (UTF-8, NULL終端)
           Board/Product String (UTF-8, NULL終端)
```

#### 例: FT2232Hの設定

ベンダー"Acme"、製品"JTAG"の場合：

```
04 00 4A 58 41 63 6D 65 00 4A 54 41 47 00
^^^^^^^^^^ ^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^
シグネチャ  Vendor="Acme"    Product="JTAG"
```

### 方法3: EEPROMダンプを使用

公開されているDigilent JTAG互換のEEPROMダンプを使用：

- [FTDI EEPROMダンプリポジトリ](https://github.com/dragonlock2/ftdi_dumps)
- [rikka0w0のGist](https://gist.github.com/rikka0w0/24b58b54473227502fa0334bbe75c3c1)

FT_PROGやftdi_eepromツールを使用してダンプファイルを書き込みます。

**警告**: FT_PROGはXilinx固有の設定を破壊する可能性があります。

## 回路図の例

### 基本的な回路（Spartan/Artix FPGA用）

```
USB                FT2232D              レベル変換          FPGA (3.3V/1.8V)
  |                                     SN74AVC4T3144
  +--- [USB Type-B] --- FT2232D
                         |
                         +-- ADBUS0 -----> A1 ----> B1 ----> TCK
                         +-- ADBUS1 -----> A2 ----> B2 ----> TDI  
                         +-- ADBUS2 <----- A3 <---- B3 <---- TDO
                         +-- ADBUS3 -----> A4 ----> B4 ----> TMS
                         +-- ADBUS4 ------------------------> VCCO
                         |
                         +-- BDBUS0-7 (Channel B: 別用途で使用可能)
```

### 完全な回路（Zynq MPSoC用）

Channel AをJTAG専用、Channel Bをシリアル通信に使用できます：

```
FT2232D Channel A (JTAG)           Zynq MPSoC
  ADBUS0-3 --> [レベル変換] --> JTAG (TCK/TDI/TDO/TMS)
  ADBUS4 -----------------------> VCCO_MIO (電源検出)
  ADBUS5 -----------------------> レベル変換OE
  ADBUS6 --> [NC7WZ07] ---------> PS_POR_B
  ADBUS7 --> [NC7WZ07] ---------> PS_SRST_B

FT2232D Channel B (UART)
  BDBUS0 (TX) ------------------> UART RX
  BDBUS1 (RX) <------------------- UART TX
```

## 使用方法

### 1. ハードウェアの準備

1. FT2232Dモジュールを組み立て
2. レベル変換回路を実装（必要に応じて）
3. FPGAボードに接続

### 2. EEPROMのプログラミング

```bash
# デバイスのシリアル番号を確認
lsusb -v | grep -i "ftdi\|serial"

# Vivadoのprogram_ftdiスクリプトで設定
program_ftdi -write -ftdi=ft2232h -serial=XXXXXX
```

### 3. Vivadoでの認識確認

```bash
# Hardware Managerを起動
vivado -mode tcl

# ハードウェアサーバーを開く
open_hw_manager
connect_hw_server

# ターゲットを検出
open_hw_target

# FPGAが検出されれば成功
get_hw_devices
```

### 4. プログラミング

Vivado Hardware Managerから通常のJTAGケーブルと同様に使用できます：

- ビットストリームのダウンロード
- デバッグ（ILA、VIO等）
- フラッシュメモリのプログラミング

## トラブルシューティング

### デバイスが認識されない

**症状**: Vivadoがケーブルを検出しない

**対処法**:
1. EEPROMが正しくプログラムされているか確認
2. USB Manufacturerが"Xilinx"になっているか確認
3. FTDIドライバが正しくインストールされているか確認
4. デバイスマネージャー（Windows）またはlsusb（Linux）で確認

### ターゲットFPGAが検出されない

**症状**: ケーブルは認識されるがFPGAが検出されない

**対処法**:
1. VCCO_ON（ADBUS4）が正しく接続されているか確認
2. レベル変換の電圧が正しいか確認
3. JTAG信号の接続を確認（TCK, TDI, TDO, TMS）
4. FPGAの電源が入っているか確認

### プログラミングエラー

**症状**: プログラミング中にエラーが発生

**対処法**:
1. JTAGクロック速度を下げる
2. ケーブルの長さを短くする
3. グラウンド接続を確認
4. レベル変換回路の電源を確認

## 参考資料

### 公式ドキュメント
- [FT2232Dデータシート](https://akizukidenshi.com/goodsaffix/FT2232D.pdf)
- Xilinx UG908: Vivado Hardware Manager User Guide
- FTDI AN_108: Command Processor for MPSSE and MCU Host Bus Emulation Modes

### コミュニティリソース
- [FT2232 to Digilent JTAG for Xilinx FPGAs](https://gist.github.com/rikka0w0/24b58b54473227502fa0334bbe75c3c1)
- [FTDI JTAG Programmer GitHub](https://github.com/anthony-bernaert/ftdi-jtag-programmer)
- [Xilinx JTAG Support on FTDI](https://etherealwake.com/2024/06/xilinx-ftdi-jtag/)
- [FTDI EEPROMダンプコレクション](https://github.com/dragonlock2/ftdi_dumps)

### 関連ツール
- [FTDI D2XX Drivers](https://ftdichip.com/drivers/d2xx-drivers/)
- [OpenOCD](https://openocd.org/) - オープンソースJTAGツール
- [xc3sprog](https://github.com/matrix-io/xc3sprog) - Xilinx FPGA用プログラマー

## 注意事項

### 法的考慮事項

このドキュメントは教育および個人使用を目的としています。商用製品でDigilent JTAGをエミュレートする場合は、適切なライセンス契約が必要になる可能性があります。

### 技術的制限

- FT2232DはFT2232Hより低速（MPSSE最大6MHz vs 30MHz）
- Channel Bは同時にJTAGとして使用できません
- 一部の高度な機能（高速クロック等）は使用できない可能性があります

## まとめ

FT2232Dボードを使用することで、約2,000円で実用的なXilinx JTAGプログラマーを作成できます。公式のPlatform Cable USB IIやDigilent JTAG-HS2と比べて大幅にコストを削減できます。

EBAZ4205ボードの開発において、このカスタムJTAGプログラマーは非常に有用です。
