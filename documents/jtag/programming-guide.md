# FT2232D EEPROMプログラミングガイド

## 概要

FT2232DをXilinx JTAGプログラマーとして動作させるには、EEPROMに特定の設定を書き込む必要があります。このガイドでは、複数の方法を詳しく説明します。

## 動作確認済み手順（Vivado 2024.2 + FT2232D）

FT2232DでVivado Hardware Managerを使用するには、
openFPGALoaderをXVCサーバーとして起動しVivadoをクライアントとして接続する。

> **bcdDeviceは0x0500（FT2232D標準値）のまま使用する。**
> 0x0700に変更するとVivadoのcs_serverがデバイスを掴んでXVCサーバーと競合する。

### ステップ1: EEPROMのbcdDeviceを0x0500に設定

新品またはすでに0x0500ならスキップ。0x0700になっている場合は以下を実行：

```bash
sudo rmmod ftdi_sio

cat > ~/reset_bcddevice.py << 'EOF'
import usb.core, struct

dev = usb.core.find(idVendor=0x0403, idProduct=0x6010)
dev.ctrl_transfer(0x40, 0x91, 0x0500, 3, b'')

n = 128
words = [struct.unpack('<H', bytes(dev.ctrl_transfer(0xC0, 0x90, 0, i, 2)))[0] for i in range(n)]
cksum = 0xAAAA
for w in words[:-1]:
    cksum ^= w
    cksum = ((cksum << 1) | (cksum >> 15)) & 0xFFFF
dev.ctrl_transfer(0x40, 0x91, cksum, n - 1, b'')
print(f"bcdDevice -> 0x0500, checksum: 0x{cksum:04X}")
EOF

sudo python3 ~/reset_bcddevice.py
# USBを抜き差し
```

### ステップ2: XVCサーバーを起動（ターミナル1）

```bash
sudo rmmod ftdi_sio
openFPGALoader -c ft2232 --xvc
# INFO: To connect to this xvcServer instance, use: TCP:hostname:3721
```

このターミナルは起動したままにする。

### ステップ3: VivadoをXVCクライアントとして接続（ターミナル2）

```bash
vivado -mode tcl
```

```tcl
open_hw_manager
connect_hw_server -url localhost:3121
open_hw_target -xvc_url localhost:3721
open_hw_target -xvc_url localhost:3721
refresh_hw_target
get_hw_devices
# arm_dap_0 xc7z010_1
```

> `open_hw_target -xvc_url localhost:3721` は2回実行する（1回目で接続確立、2回目で完了）。

### 重要な注意事項

- Vivado使用前は必ず`sudo rmmod ftdi_sio`を実行すること。
- 永続化には`/etc/modprobe.d/blacklist-ftdi.conf`にblacklist設定を追加すること。

#### ftdi_sioの永続的な無効化（再起動後も有効）

```bash
echo "blacklist ftdi_sio" | sudo tee /etc/modprobe.d/blacklist-ftdi.conf
sudo update-initramfs -u
```

設定後は再起動することで、以降`sudo rmmod ftdi_sio`は不要になる。

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
vivado -mode batch \
  -source $XILINX_VIVADO/scripts/program_ftdi/program_ftdi.tcl \
  -tclargs FT2232H AB0XXXXX
```

> **注意**: スクリプトは `<ftdi_part> <serial_number>` の位置引数を取ります。
> シリアル番号は5〜13文字である必要があります。

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
```

> **注意**: `channel_a_type`, `channel_a_driver`, `channel_b_type`, `channel_b_driver` オプションは
> libftdi 0.x系（v0.17以下）では非対応です。これらを含めると書き込みエラーになります。
> libftdi 1.x系では使用可能です。

#### EEPROMに書き込み

```bash
# EEPROMを消去
sudo ftdi_eeprom --erase-eeprom ft2232_xilinx.conf

# 新しい設定を書き込み
sudo ftdi_eeprom --flash-eeprom ft2232_xilinx.conf

# 確認
sudo ftdi_eeprom --read-eeprom ft2232_xilinx.conf
```

#### トラブルシューティング: ftdi_eeprom v0.17でEEPROM書き込みが反映されない

**症状**: `FTDI write eeprom: 0`（成功）なのに、USB再接続後も`iManufacturer`/`iProduct`/`iSerial`が空のまま

**原因**: `ftdi_eeprom v0.17`（旧libftdi 0.x系）は、一度消去されたEEPROMへの書き込み時にチェックサム計算が
正しく行われない既知の問題があります。デバイスはチェックサム不正のEEPROMを無視してデフォルト値にフォールバックします。

**対処法**: pyftdiを使用してください。

```bash
# pyftdiをインストール
sudo pip3 install pyftdi

# ftdi_sioカーネルモジュールをアンロード（デバイスを解放）
sudo rmmod ftdi_sio
```

以下のスクリプトを作成して実行します（`program_eeprom.py`）：

```python
from pyftdi.eeprom import FtdiEeprom

eeprom = FtdiEeprom()
eeprom.open('ftdi://ftdi:2232/1')
eeprom.set_manufacturer_name('Xilinx')
eeprom.set_product_name('Platform Cable USB II')
eeprom.set_serial_number('FT000001')
eeprom.commit(dry_run=False)
print("Done. Please replug the device.")
```

```bash
# PetaLinux環境などsysrootのpyftdiを使う場合はPYTHONPATHを指定
sudo PYTHONPATH=/path/to/sysroot/usr/lib/python3.x/site-packages python3 program_eeprom.py

# システムpython3のpyftdiを使う場合
sudo python3 program_eeprom.py
```

USBを再接続後、以下で確認：

```bash
sudo lsusb -v -d 0403:6010 | grep -A 3 "iManufacturer\|iProduct\|iSerial"
# 期待される出力:
# iManufacturer           1 Xilinx
# iProduct                2 Platform Cable USB II
# iSerial                 3 FT000001
```

**永続化**: 毎回`rmmod`しなくて済むようにftdi_sioをブラックリストに追加：

```bash
echo 'blacklist ftdi_sio' | sudo tee /etc/modprobe.d/ftdi-blacklist.conf
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", MODE="0666"' | sudo tee /etc/udev/rules.d/99-ftdi.rules
sudo udevadm control --reload-rules
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
sudo lsusb -v -d 0403:6010 | grep -A 3 "iManufacturer\|iProduct\|iSerial"

# 期待される出力:
# iManufacturer           1 Xilinx
# iProduct                2 Platform Cable USB II
# iSerial                 3 FT000001
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

## FT2232DとVivado 2024.2の使い方

### 互換性の概要

Vivado 2024.2のcs_serverはDigilentプロトコルでJTAGを制御するため、
FT2232D標準MPSSEとは直接通信できない。
ただし、**XVC（Xilinx Virtual Cable）経由**でVivado Hardware Managerを
完全に使用することが可能（動作確認済み）。

| 用途 | 方法 | 状態 |
| --- | --- | --- |
| FPGAビットストリーム書き込み | openFPGALoader直接 | ✅ 動作確認済み |
| Vivado Hardware Manager（ILA/VIO） | openFPGALoader XVC経由 | ✅ 動作確認済み |
| Vivado hw_server直接接続 | cs_server（Digilentプロトコル） | ❌ FT2232D非対応 |

### インストール

```bash
sudo apt install openfpgaloader
```

### 方法A: FPGAビットストリームの書き込み（openFPGALoader直接）

Vivadoを使わずに直接FPGAへ書き込む最もシンプルな方法。

```bash
sudo rmmod ftdi_sio

# JTAGチェーン確認
openFPGALoader --detect
```

正常時の出力（EBAZ4205 Zynq xc7z010）：

```text
No cable or board specified: using direct ft2232 interface
Jtag frequency : requested 6.00MHz   -> real 6.00MHz
index 0:
    idcode   0x4ba00477
    type     ARM cortex A9
    irlength 4
index 1:
    idcode 0x3722093
    manufacturer xilinx
    family zynq
    model  xc7z010
    irlength 6
```

```bash
# SRAMへの書き込み（揮発性）
openFPGALoader -c ft2232 your_design.bit

# フラッシュへの書き込み（不揮発性）
openFPGALoader -c ft2232 --write-flash your_design.bit
```

### 方法B: Vivado Hardware Manager経由（XVC）

ILA・VIOデバッグなど、Vivado Hardware Managerの全機能を使いたい場合。
openFPGALoaderをXVCサーバーとして起動し、Vivadoをクライアントとして接続する。

#### 前提: EEPROMの設定

cs_serverがFT2232Dを自動検出して競合するのを防ぐため、
bcdDeviceを0x0500（FT2232D標準値）に設定する。

```bash
sudo rmmod ftdi_sio
sudo python3 reset_bcddevice.py
# USBを抜き差しして再接続
```

#### ステップ1: XVCサーバーを起動（ターミナル1）

```bash
sudo rmmod ftdi_sio
openFPGALoader -c ft2232 --xvc
```

起動時の出力例：

```text
Jtag frequency : requested 6.00MHz   -> real 6.00MHz
INFO: To connect to this xvcServer instance, use: TCP:hostname:3721
Press <enter> to quit
```

ポートは**3721**。このターミナルは起動したままにする。

#### ステップ2: VivadoをXVCクライアントとして接続（ターミナル2）

```bash
vivado -mode tcl
```

```tcl
open_hw_manager
connect_hw_server -url localhost:3121
open_hw_target -xvc_url localhost:3721
open_hw_target -xvc_url localhost:3721
refresh_hw_target
get_hw_devices
```

成功時の出力：

```text
arm_dap_0 xc7z010_1
```

> **注意**: `open_hw_target -xvc_url localhost:3721` は**2回実行する**。
> 1回目で接続が確立され、2回目で正常に完了する。

### ftdi_sioの永続的な無効化

毎回`sudo rmmod ftdi_sio`を実行するのが面倒な場合：

```bash
echo "blacklist ftdi_sio" | sudo tee /etc/modprobe.d/blacklist-ftdi.conf
sudo update-initramfs -u
```

## まとめ

### EEPROMプログラミングの方法優先順位

1. **方法5 (推奨)**: `program_eeprom_full.py`（pyftdi + usb.coreによる一括設定）
2. **方法3**: カスタムPythonスクリプト（pyftdiのみ、Xilinx fwidなし）
3. **方法4**: 公開EEPROMダンプ（動作確認済みの設定）
4. **方法1**: Vivadoの`program_ftdi`スクリプト（FT2232Hのみ対応、FT2232D不可）
5. **方法2**: FT_PROG（非推奨、Xilinx設定を破壊）

### 用途別ツール選択

| 用途 | 推奨ツール | コマンド例 |
| --- | --- | --- |
| FPGA書き込み | openFPGALoader | `openFPGALoader -c ft2232 design.bit` |
| Vivado ILA/VIOデバッグ | openFPGALoader XVC | `openFPGALoader -c ft2232 --xvc` |
| ARM PSデバッグ | openFPGALoader XVC + Vivado | XVC経由でarm_dap_0を使用 |

必ず事前にEEPROMをバックアップし、慎重に作業を進めてください。
