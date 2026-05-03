# FT2232D JTAGプログラミング & デバッグガイド

## 概要

FT2232Dを使ってEBAZ4205などのXilinxデバイスへJTAG接続する際の実践手順をまとめる。
FT2232DはVivado付属のDigilentケーブル互換モードと完全には互換性がなく、
**openFPGALoaderをXVCサーバーとして使用**するか、openOCDなどオープンツールを利用する。

> **重要**: Vivado 2024.2のcs_serverはFT2232H前提の高速モードを要求するため、
> FT2232Dを直接Digilentケーブルとして使用するとJTAGスキャンに失敗する。
> bcdDeviceは0x0500（本来の値）のままにし、XVCやopenOCDからアクセスする。

## 互換性の概要

| 用途 | 方法 | 状態 |
| --- | --- | --- |
| FPGAビットストリーム書き込み | openFPGALoader直接 | ✅ 動作確認済み |
| Vivado Hardware Manager（ILA/VIO） | openFPGALoader XVC経由 | ✅ 動作確認済み |
| Vitis / XSCT (Classic含む) | openFPGALoader XVC経由 | ✅ 動作確認済み |
| openOCDによるPS/PL制御 | openOCD + FT2232D | ✅ 動作確認済み |
| Vivado hw_server直接接続 | cs_server（Digilentプロトコル） | ❌ FT2232D非対応 |

## 事前準備

### EEPROMのbcdDeviceを0x0500に維持

0x0700 (FT2232H) に書き換えた場合は元へ戻す。新品や0x0500のままならスキップ。

```bash
sudo rmmod ftdi_sio

cat > ~/reset_bcddevice.py <<'EOF'
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

### ftdi_sioの無効化

毎回 `sudo rmmod ftdi_sio` を実行するか、以下で恒久的にブラックリスト登録する。

```bash
echo "blacklist ftdi_sio" | sudo tee /etc/modprobe.d/blacklist-ftdi.conf
echo "blacklist usbserial" | sudo tee -a /etc/modprobe.d/blacklist-ftdi.conf
sudo update-initramfs -u
# 再起動後は自動的にFTDIドライバがロードされなくなる
```

### openFPGALoader / openOCD のインストール

```bash
sudo apt install openfpgaloader openocd
```

---

## ワークフローA: openFPGALoaderで直接FPGAを書き込む

Vivadoを使わずにSRAM/フラッシュへビットストリームを書き込む最もシンプルな方法。

```bash
sudo rmmod ftdi_sio

# JTAGチェーン確認
openFPGALoader --detect
```

正常時の出力例（EBAZ4205 Zynq xc7z010）：

```text
No cable or board specified: using direct ft2232 interface
Jtag frequency : requested 6.00MHz   -> real 6.00MHz
index 0:
    idcode   0x4ba00477
    type     ARM cortex A9
    irlength 4
index 1:
    idcode 0x03722093
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

> **Tip**: `--freq` でJTAGクロックを指定可能（例: `--freq 3000000`）。

---

## ワークフローB: Vivado / Vitis をXVC経由で利用

Vivado Hardware ManagerやVitis (XSCT/Classic含む) のJTAG機能をFT2232Dで使用する。

### ステップ1: openFPGALoaderをXVCサーバーとして起動（ターミナル1）

```bash
sudo rmmod ftdi_sio
openFPGALoader -c ft2232 --freq 1000000 --xvc
# INFO: To connect to this xvcServer instance, use: TCP:hostname:3721
```

- `--freq` はFT2232Dの配線品質に合わせて 0.5〜3MHz で調整。
- 起動メッセージに表示されるホスト名/ポート（デフォルト3721）をVivado側で使用。

### ステップ2: Vivado / Vitis (XSCT) から接続（ターミナル2）

```bash
vivado -mode tcl   # または xsct
```

```tcl
open_hw_manager
connect_hw_server -url localhost:3121
set_param hw_server.xvc_jtag_frequency 1000000
open_hw_target -xvc_url localhost:3721
open_hw_target -xvc_url localhost:3721
refresh_hw_target
get_hw_devices
# arm_dap_0 xc7z010_1
```

- `open_hw_target -xvc_url ...` は2回実行する（1回目で接続、2回目でターゲットが安定）。
- `set_param hw_server.xvc_jtag_frequency` はVivado/Vitisが要求するJTAG周波数をHz単位で指定。
- Vitis Classicでも同じコマンドでPSデバッグ（`targets`, `dow`, `con` 等）が可能。

> **トラブルシューティング**
> - `mpsse_write: fail to write ...` が出る場合は `--freq` と `xvc_jtag_frequency` をさらに下げる。
> - `unable to claim usb device` が出た場合は `lsusb -t` で `Driver=ftdi_sio` などが付いていないか確認し、`rmmod` または USB再接続を行う。

---

## ワークフローC: openOCDでJTAG制御・PS/PLプログラム

openOCD単体でJTAGアクセスやビットストリーム書き込みを行う手順。

### 1. インターフェース設定ファイル

`~/openocd-ft2232d.cfg` など任意のパスに保存する。

```tcl
interface ftdi
transport select jtag
adapter speed 1000              ;# 1MHz。必要に応じて調整

ftdi_vid_pid 0x0403 0x6010
ftdi_channel 0
ftdi_layout_init 0x0000 0x000b  ;# AD0-AD3を出力、残り入力

# Zynqのリセット信号を配線している場合のみ有効化
# ftdi_layout_signal nSRST -data 0x0080
# ftdi_layout_signal nTRST -data 0x0100
```

### 2. 起動とJTAG確認

```bash
sudo rmmod ftdi_sio
openocd -f ~/openocd-ft2232d.cfg -f target/zynq_7000.cfg
```

ログに `Info : JTAG tap: xc7z010.cpu tap/device found` 等が出れば接続成功。

### 3. PLビットストリーム書き込み

```bash
openocd -f ~/openocd-ft2232d.cfg -f target/zynq_7000.cfg \
  -c "init; pld load 0 build/your_design.bit; shutdown"
```

### 4. PS (ARM) デバッグやELFロード

```bash
openocd -f ~/openocd-ft2232d.cfg -f target/zynq_7000.cfg \
  -c "init; halt; load_image ps_app.elf; resume; shutdown"
```

> **補足**
> - `target/zynq_7000.cfg` はopenOCD同梱の定義。Versal/Artixなど別デバイスでは適切なcfgに置き換え。
> - openOCD起動後は `telnet localhost 4444` や `gdb-multiarch` から通常通り制御可能。

---

## まとめ

### 用途別ツール選択

| 用途 | 推奨ツール | コマンド例 |
| --- | --- | --- |
| FPGA書き込み | openFPGALoader | `openFPGALoader -c ft2232 design.bit` |
| Vivado ILA/VIO/PSデバッグ | openFPGALoader XVC | `openFPGALoader -c ft2232 --xvc` |
| ARM PSブート/ELFロード | openOCD | `openocd -f openocd-ft2232d.cfg -f target/zynq_7000.cfg` |

EEPROMの設定手順は `programming-guide.md` を参照し、必ずバックアップを取得した上で作業すること。
