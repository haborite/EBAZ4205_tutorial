HDMI AXI Pattern Generator - Vitis Application Source
======================================================

EBAZ4205 (Zynq-7010) 用 HDMI テストパターンジェネレータの PS 側制御アプリケーションです。

ファイル構成
------------
  hdmi_axi.h  - ドライバヘッダ (API定義、レジスタマップ、enum)
  hdmi_axi.c  - ドライバ実装
  main.c      - デモアプリケーション

レジスタマップ (0x00: Control Register)
---------------------------------------
  [1:0]  timing_sel   - 0=VGA 640x480, 1=480p 720x480, 2=720p 1280x720
  [5:2]  pattern_sel  - 0..9 (下記参照)

  (0x04: Status Register, Read-Only)
  [0]    locked        - MMCM ロック状態
  [1]    reconfig_busy - MMCM リコンフィグ中

パターン一覧
------------
  0: Color Bars      - 8本カラーバー
  1: Checkerboard    - 32x32 白黒格子
  2: H-Gradation     - 水平グラデーション
  3: Crosshatch      - 64px グリッド線
  4: Border          - 1px 白枠
  5: RGB Field       - R/G/B/W 全面 (フレーム周期切替)
  6: V-Gradation     - 垂直グラデーション
  7: Walking Bar     - 移動する白バー (アニメーション)
  8: SMPTE Bars      - SMPTE風カラーバー + PLUGE
  9: Zone Plate      - 同心円パターン

ビルド手順
----------
  1. Vivado で Export Hardware (.xsa) を行う
  2. Vitis でプラットフォームプロジェクトを作成
  3. Application Project を作成 (Hello World テンプレート等)
  4. 生成された helloworld.c を削除し、本フォルダの3ファイルを src/ にコピー
  5. hdmi_axi.h 内の HDMI_AXI_BASE_ADDR を xparameters.h の値に合わせる
     (main.c 内の HDMI_AXI_BASE_ADDR も同様)
  6. Build → Run As → Launch on Hardware

デモ動作
--------
  main.c は全3タイミング × 全10パターンを順番に表示します (各3秒、合計約90秒)。
  タイミング切替時は MMCM DRP リコンフィグが発行され、完了を待ってから表示します。

注意事項
--------
  - ベースアドレスは Vivado Block Design のアドレスエディタで確認してください
  - timing_sel を変更すると自動的に MMCM リコンフィグが開始されます
  - リコンフィグ中は映像出力が一時停止します (数十us)
  - pattern_sel のみの変更はリコンフィグ不要 (即時反映、次フレーム境界で切替)
