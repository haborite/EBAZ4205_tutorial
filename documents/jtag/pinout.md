# FT2232D ピン配置詳細

## FT2232Dのピン配置

### DIP-40パッケージ（秋月電子モジュール）

```
         FT2232D
        +-------+
   GND  |1    40| GND
   OSC1 |2    39| OSC2
RSTOUT# |3    38| EECS
  REF#  |4    37| EECLK
 PWREN# |5    36| EEDATA
SUSPEND#|6    35| WU
 USBDP  |7    34| VCCIO
 USBDM  |8    33| ADBUS7 (SRST_B)
  3V3OUT|9    32| ADBUS6 (POR_B)
  GND   |10   31| ADBUS5 (OE_B)
  VCC   |11   30| ADBUS4 (VCCO_ON)
  VCC   |12   29| ADBUS3 (TMS)
  TEST  |13   28| ADBUS2 (TDO)
  GND   |14   27| ADBUS1 (TDI)
BDBUS0  |15   26| ADBUS0 (TCK)
BDBUS1  |16   25| GND
BDBUS2  |17   24| BDBUS7
BDBUS3  |18   23| BDBUS6
BDBUS4  |19   22| BDBUS5
  GND   |20   21| ACBUS0
        +-------+
```

## Channel A (JTAG用)

### ADBUS0-7 (Bank A Data Bus)

| ピン番号 | 信号名 | JTAG機能 | 方向 | 説明 |
|---------|--------|----------|------|------|
| 26 | ADBUS0 | TCK | 出力 | JTAGクロック信号 |
| 27 | ADBUS1 | TDI | 出力 | JTAGデータ入力（FPGA側から見て） |
| 28 | ADBUS2 | TDO | 入力 | JTAGデータ出力（FPGA側から見て） |
| 29 | ADBUS3 | TMS | 出力 | JTAGモード選択信号 |
| 30 | ADBUS4 | VCCO_ON | 入力 | ターゲット電源検出 |
| 31 | ADBUS5 | OE_B | 出力 | 出力イネーブル（アクティブLow） |
| 32 | ADBUS6 | POR_B | 出力 | パワーオンリセット（アクティブLow） |
| 33 | ADBUS7 | SRST_B | 出力 | システムリセット（アクティブLow） |

## Channel B (UART/GPIO用)

### BDBUS0-7 (Bank B Data Bus)

| ピン番号 | 信号名 | 代表的な用途 | 方向 | 説明 |
|---------|--------|--------------|------|------|
| 15 | BDBUS0 | TXD | 出力 | UART送信 / GPIO |
| 16 | BDBUS1 | RXD | 入力 | UART受信 / GPIO |
| 17 | BDBUS2 | RTS# | 出力 | UART RTS / GPIO |
| 18 | BDBUS3 | CTS# | 入力 | UART CTS / GPIO |
| 19 | BDBUS4 | DTR# | 出力 | UART DTR / GPIO |
| 22 | BDBUS5 | DSR# | 入力 | UART DSR / GPIO |
| 23 | BDBUS6 | DCD# | 入力 | UART DCD / GPIO |
| 24 | BDBUS7 | RI# | 入力 | UART RI / GPIO |

## 電源ピン

| ピン番号 | 信号名 | 電圧 | 説明 |
|---------|--------|------|------|
| 11, 12 | VCC | 5V | USB電源入力 |
| 9 | 3V3OUT | 3.3V | 内蔵レギュレータ出力（最大5mA） |
| 34 | VCCIO | 1.8-3.3V | I/O電圧リファレンス |
| 1, 10, 14, 20, 25 | GND | 0V | グランド |

**重要**: 
- VCCIOは3.3Vに接続してください（FT2232Dは3.3V I/O固定）
- 3V3OUTは内部レギュレータ出力で、外部回路への電流供給能力は限定的です

## EEPROM接続

FT2232DはI2C/SPIではなく、専用の3線式インターフェイスでEEPROMと通信します：

| ピン番号 | 信号名 | 接続先 | 説明 |
|---------|--------|--------|------|
| 37 | EECLK | EEPROM CLK | EEPROMクロック |
| 36 | EEDATA | EEPROM DATA | EEPROMデータ（双方向） |
| 38 | EECS | EEPROM CS | EEPROMチップセレクト |

推奨EEPROM: 93LC56B (2Kbit, Microwire)

## USB接続

| ピン番号 | 信号名 | 説明 |
|---------|--------|------|
| 7 | USBDP | USB D+ |
| 8 | USBDM | USB D- |

## その他の制御信号

| ピン番号 | 信号名 | 機能 |
|---------|--------|------|
| 3 | RSTOUT# | パワーオンリセット出力 |
| 4 | REF# | USB速度選択（GND=Full Speed） |
| 5 | PWREN# | USB電源管理 |
| 6 | SUSPEND# | USBサスペンド状態表示 |
| 13 | TEST | テストモード（通常GND接続） |

## MPSSEモードでのピン機能

MPSSEモード（Multi-Protocol Synchronous Serial Engine）では、ADBUS0-7が以下のように機能します：

### Channel A (MPSSE有効)

| ADBUS | 標準機能 | MPSSE機能 | JTAG用途 |
|-------|----------|-----------|----------|
| 0 | AD0 | TCK/SK | TCK |
| 1 | AD1 | TDI/DO | TDI |
| 2 | AD2 | TDO/DI | TDO |
| 3 | AD3 | TMS/CS | TMS |
| 4 | AD4 | GPIOL0 | VCCO_ON |
| 5 | AD5 | GPIOL1 | OE_B |
| 6 | AD6 | GPIOL2 | POR_B |
| 7 | AD7 | GPIOL3 | SRST_B |

## 秋月電子モジュールの実装

秋月電子の「FT2232D USBシリアル2ch変換モジュールキット」では：

### 実装済みコンポーネント
- FT2232D（DIP40パッケージ）
- 93LC56B EEPROM
- 12MHz水晶振動子
- 12kΩ抵抗（USBプルアップ用）
- バイパスコンデンサ

### ピンヘッダ配置

モジュールは以下のピンを外部に引き出しています：

```
[USB Type-B コネクタ]
        |
    [FT2232Dモジュール]
        |
   [ピンヘッダ]
    ADBUS0-7 (Channel A)
    BDBUS0-7 (Channel B)
    ACBUS0-3 (Channel A Control)
    VCC, 3V3OUT, VCCIO, GND
```

詳細は[秋月電子のマニュアル](https://akizukidenshi.com/goodsaffix/AE-FT2232_AE-FT2232withEEPROM_20211124.pdf)を参照してください。

## レベル変換接続例

### 3.3V FPGA向け

```
FT2232D        直接接続         FPGA (3.3V)
ADBUS0 (3.3V) -------------> TCK
ADBUS1 (3.3V) -------------> TDI
ADBUS2 (3.3V) <------------- TDO
ADBUS3 (3.3V) -------------> TMS
VCCIO (3.3V)  ----+
                  |
GND --------------+---------- GND
```

**注意**: 同一電源でも推奨はレベル変換ICを使用することです。

### 1.8V FPGA向け（レベル変換必須）

```
FT2232D      SN74AVC4T3144      FPGA (1.8V)
           VCCA=3.3V VCCB=1.8V
ADBUS0 ----> A1 ----> B1 -----> TCK
ADBUS1 ----> A2 ----> B2 -----> TDI
ADBUS2 <---- A3 <---- B3 <----- TDO
ADBUS3 ----> A4 ----> B4 -----> TMS
ADBUS5 ----> OE (Low=Enable)
3.3V ------> VCCA
1.8V -----------> VCCB
GND -------> GND <------------ GND
```

## 配線時の注意事項

1. **信号長**: JTAGクロック速度を考慮し、配線は可能な限り短く
2. **グラウンド**: FT2232DとFPGAのグラウンドを確実に接続
3. **電源デカップリング**: VCC、3V3OUT、VCCIOの近くにバイパスコンデンサを配置
4. **ESD保護**: USB信号にはESD保護素子の追加を推奨
5. **ノイズ対策**: 高速信号には適切なグラウンドプレーンを確保
