# FT2232D EEPROMプログラミングガイド

## 概要

FT2232DをXilinx JTAGプログラマーとして動作させるには、EEPROMに特定の設定を書き込む必要があります。このガイドでは、複数の方法を詳しく説明します。

## 前提条件

### ソフトウェア
- Xilinx Vivado（2020.1以降推奨）
- FTDIドライバ（D2XXまたはVCP）
- Python 3.x（方法3を使用する場合）

### ハードウェア
- FT2232Dモジュール（EEPROM実装済み）
- USBケーブル
- PC（Windows/Linux/macOS）

## 方法1: Vivadoの`program_ftdi`スクリプト（推奨）

### 手順

#### 1. デバイスのシリアル番号を確認

**Linux/macOS:**
```bash
# lsusbコマンドで確認
lsusb -v | grep -A 10 "FTDI"

# または
dmesg | grep FTDI
```

**Windows:**
```powershell
# デバイスマネージャーを開く
devmgmt.msc

# "ポート (COMとLPT)"または"ユニバーサル シリアル バス デバイス"を展開
# FT2232Dデバイスのプロパティからシリアル番号を確認
```

出力例：
```
Serial Number: AB0XXXXX
```

#### 2. Vivado環境を設定

**Linux/macOS:**
```bash
# Vivadoの環境変数を設定
source /tools/Xilinx/Vivado/2023.2/settings64.sh

# program_ftdiスクリプトの場所に移動
cd $XILINX_VIVADO/scripts/program_ftdi
```

**Windows:**
```batch
REM Vivadoの環境変数を設定
call C:\Xilinx\Vivado\2023.2\settings64.bat

REM program_ftdiスクリプトの場所に移動
cd %XILINX_VIVADO%\scripts\program_ftdi
```

#### 3. EEPROMをプログラム

```bash
# 基本的な使用法（FT2232H互換モード）
./program_ftdi -write -ftdi=ft2232h -serial=AB0XXXXX

# カスタム設定を含む詳細な使用法
./program_ftdi -write \
  -ftdi=ft2232h \
  -serial=AB0XXXXX \
  -vendor="Custom" \
  -board="EBAZ4205 JTAG Programmer" \
  -desc="Xilinx Platform Cable USB II"
```

#### 4. 確認

```bash
# 書き込み後、デバイスを再接続

# Vivadoで確認
vivado -mode tcl
open_hw_manager
connect_hw_server
get_hw_targets
```

正常に設定されていれば、デバイスがXilinx JTAGケーブルとして認識されます。

### パラメータ詳細

| パラメータ | 説明 | 例 |
|-----------|------|-----|
| `-write` | EEPROMに書き込みモード | 必須 |
| `-ftdi` | FTDIチップタイプ | `ft232h`, `ft2232h`, `ft4232h` |
| `-serial` | デバイスシリアル番号 | `AB0XXXXX` |
| `-vendor` | ベンダー名（Xilinx独自領域） | `"Digilent"`, `"Custom"` |
| `-board` | ボード名（hw_serverに表示） | `"Platform Cable USB II"` |
| `-desc` | USB製品記述文字列 | `"Xilinx JTAG Cable"` |

### トラブルシューティング

#### エラー: "Unable to find FTDI device"

**原因**: デバイスが見つからない、またはドライバの問題

**対処法**:
```bash
# Linux: デバイスの確認
lsusb | grep FTDI

# Linux: 権限の確認
sudo chmod 666 /dev/bus/usb/XXX/YYY

# または、udevルールを追加
sudo nano /etc/udev/rules.d/99-ftdi.rules
# 以下を追加:
# SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", MODE="0666"
sudo udevadm control --reload-rules
```

#### エラー: "EEPROM write failed"

**原因**: EEPROM書き込み保護、または不良EEPROM

**対処法**:
1. EEPROMの書き込み保護ピンを確認
2. 別のUSBポートで試す
3. EEPROMが正しく実装されているか確認

#### Vivado 2024.1での問題

Vivado 2024.1では`program_ftdi`スクリプトに互換性の問題がある可能性があります。

**対処法**: Vivado 2023.2以前を使用するか、方法2または3を試してください。

## 方法2: FT_PROGツール（Windows）

### 注意事項

**警告**: FT_PROGはXilinx固有の設定を破壊します。この方法は推奨されません。

FT_PROGを使用する場合は、事前にEEPROMをバックアップし、Xilinx固有のユーザーデータ領域を手動で復元する必要があります。

### 手順（参考のみ）

1. [FTDI FT_PROG](https://ftdichip.com/utilities/#ft_prog)をダウンロード
2. FT_PROGを起動
3. デバイスをスキャン
4. テンプレートから設定を読み込み
5. 必要な変更を適用
6. EEPROMにプログラム

**この方法は推奨されません。** 方法1または3を使用してください。

## 方法3: カスタムPythonスクリプト（上級者向け）

### 必要なライブラリ

```bash
pip install pyftdi
```

### サンプルスクリプト: xilinx_jtag_program.py

```python
#!/usr/bin/env python3
"""
FT2232D EEPROM Programming for Xilinx JTAG
このスクリプトはFT2232DのEEPROMをXilinx JTAG互換に設定します
"""

from pyftdi.ftdi import Ftdi
from pyftdi.eeprom import FtdiEeprom
import struct

def program_xilinx_jtag(serial_number, vendor="Custom", board="EBAZ4205 JTAG"):
    """
    FT2232DのEEPROMをXilinx JTAG用にプログラム
    
    Args:
        serial_number: FTDIデバイスのシリアル番号
        vendor: ベンダー名
        board: ボード/製品名
    """
    
    # FTDIデバイスを開く
    ftdi = Ftdi()
    ftdi.open_from_url(f'ftdi://ftdi:2232:{serial_number}/1')
    
    # EEPROMオブジェクトを作成
    eeprom = FtdiEeprom()
    eeprom.connect(ftdi)
    
    # 既存の設定を読み込み
    eeprom.load_config(ftdi.usb_dev)
    
    # 基本設定
    eeprom.set_manufacturer_name("Xilinx")
    eeprom.set_product_name("Xilinx Platform Cable USB II")
    eeprom.set_serial_number(serial_number)
    
    # Port A: MPSSEモード（JTAG用）
    eeprom.set_channel_type(0, 'FIFO')
    
    # Port B: UARTモード（シリアル通信用、オプション）
    eeprom.set_channel_type(1, 'UART')
    
    # USB設定
    eeprom.set_property('max_power', 500)  # 500mA
    eeprom.set_property('self_powered', False)
    eeprom.set_property('remote_wakeup', True)
    
    # Channel A: VCPドライバを無効化
    eeprom.set_property('channel_a_driver', 'D2XX')
    
    # Xilinx固有のユーザーデータを追加
    user_data = create_xilinx_user_data(vendor, board)
    eeprom.set_user_data(user_data)
    
    # EEPROMに書き込み
    print(f"Programming EEPROM for device {serial_number}...")
    eeprom.commit(dry_run=False)
    print("Programming complete!")
    print("Please disconnect and reconnect the device.")
    
    ftdi.close()

def create_xilinx_user_data(vendor, board):
    """
    Xilinx固有のユーザーデータ領域を作成
    
    Format:
        0x00-0x03: シグネチャ (0x584A0003 for FT2232H)
        0x04-    : Vendor String (UTF-8, NULL terminated)
                 : Board String (UTF-8, NULL terminated)
    """
    # FT2232Hのシグネチャ
    signature = struct.pack('<I', 0x584A0003)
    
    # ベンダー名とボード名（NULL終端）
    vendor_bytes = vendor.encode('utf-8') + b'\x00'
    board_bytes = board.encode('utf-8') + b'\x00'
    
    # 結合
    user_data = signature + vendor_bytes + board_bytes
    
    return user_data

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python3 xilinx_jtag_program.py <serial_number> [vendor] [board]")
        print("Example: python3 xilinx_jtag_program.py AB0XXXXX Custom \"EBAZ4205 JTAG\"")
        sys.exit(1)
    
    serial = sys.argv[1]
    vendor = sys.argv[2] if len(sys.argv) > 2 else "Custom"
    board = sys.argv[3] if len(sys.argv) > 3 else "EBAZ4205 JTAG"
    
    program_xilinx_jtag(serial, vendor, board)
```

### 使用方法

```bash
# スクリプトに実行権限を付与
chmod +x xilinx_jtag_program.py

# 実行
python3 xilinx_jtag_program.py AB0XXXXX "Custom" "EBAZ4205 JTAG"
```

### 注意事項

- このスクリプトは教育目的です
- EEPROMの書き込みは慎重に行ってください
- 必ず事前にバックアップを取ってください

## 方法4: 公開EEPROMダンプを使用

### ダンプファイルの入手

```bash
# GitHubからEEPROMダンプをクローン
git clone https://github.com/dragonlock2/ftdi_dumps.git
cd ftdi_dumps

# または、rikka0w0のGistからダウンロード
wget https://gist.github.com/rikka0w0/24b58b54473227502fa0334bbe75c3c1/raw/ft2232_digilent_jtag.bin
```

### ftdi_eepromツールを使用（Linux）

#### インストール

```bash
# Debian/Ubuntu
sudo apt-get install ftdi-eeprom

# または、ソースからビルド
git clone git://developer.intra2net.com/libftdi
cd libftdi
mkdir build && cd build
cmake ..
make
sudo make install
```

#### 設定ファイル作成: ft2232_xilinx.conf

```ini
vendor_id=0x0403
product_id=0x6010

manufacturer="Xilinx"
product="Platform Cable USB II"
serial="FT000001"

self_powered=false
max_power=500

# Channel A: MPSSE for JTAG
channel_a_type="FIFO"
channel_a_driver="D2XX"

# Channel B: UART
channel_b_type="UART"
channel_b_driver="VCP"

# User data (Xilinx specific)
# This needs to be set manually in hex
```

#### EEPROMに書き込み

```bash
# EEPROMを消去
sudo ftdi_eeprom --erase-eeprom ft2232_xilinx.conf

# 新しい設定を書き込み
sudo ftdi_eeprom --flash-eeprom ft2232_xilinx.conf

# 確認
sudo ftdi_eeprom --read-eeprom ft2232_xilinx.conf
```

### バイナリダンプを直接書き込み（上級者向け）

FTDIのD2XX APIを使用して、バイナリダンプを直接EEPROMに書き込むこともできます。詳細は[FTDI AN_121](https://ftdichip.com/wp-content/uploads/2020/08/AN_121_D2XX_EEPROM_Programming.pdf)を参照してください。

## EEPROMの確認

### Vivadoで確認

```tcl
# Vivado Tclシェル
vivado -mode tcl

# Hardware Managerを開く
open_hw_manager
connect_hw_server -url localhost:3121

# 接続可能なターゲットを表示
get_hw_targets

# 期待される出力例:
# localhost:3121/xilinx_tcf/Digilent/210308XXXXXX
```

### lsusbで確認（Linux）

```bash
lsusb -v -d 0403:6010 | grep -A 5 "iManufacturer\|iProduct"

# 期待される出力:
# iManufacturer           1 Xilinx
# iProduct                2 Platform Cable USB II
```

### FTDIツールで確認

```bash
# ftdi_eepromで読み出し
sudo ftdi_eeprom --read-eeprom output.conf
cat output.conf

# Pythonスクリプトで確認
python3 -c "
from pyftdi.ftdi import Ftdi
ftdi = Ftdi()
ftdi.open_from_url('ftdi://ftdi:2232/1')
print(ftdi.device_version)
ftdi.close()
"
```

## バックアップとリストア

### EEPROMのバックアップ

プログラミング前に必ずバックアップを取ってください：

```bash
# ftdi_eepromでバックアップ
sudo ftdi_eeprom --read-eeprom backup.conf

# または、Pythonスクリプト
python3 -c "
from pyftdi.ftdi import Ftdi
from pyftdi.eeprom import FtdiEeprom
ftdi = Ftdi()
ftdi.open_from_url('ftdi://ftdi:2232/1')
eeprom = FtdiEeprom()
eeprom.connect(ftdi)
with open('backup.bin', 'wb') as f:
    f.write(eeprom.data)
ftdi.close()
"
```

### リストア

```bash
# ftdi_eepromでリストア
sudo ftdi_eeprom --flash-eeprom backup.conf
```

## まとめ

推奨される方法の優先順位：

1. **方法1**: Vivadoの`program_ftdi`スクリプト（最も簡単で安全）
2. **方法3**: カスタムPythonスクリプト（柔軟性が高い）
3. **方法4**: 公開EEPROMダンプ（動作確認済みの設定）
4. **方法2**: FT_PROG（非推奨、Xilinx設定を破壊）

必ず事前にEEPROMをバックアップし、慎重に作業を進めてください。
