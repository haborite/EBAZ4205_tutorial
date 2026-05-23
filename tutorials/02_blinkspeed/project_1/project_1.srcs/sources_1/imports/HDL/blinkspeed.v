/* Copyright(C) 2020 Cobac.Net All Rights Reserved. */
/* Modified by haborite                             */
/* chapter: 2                                       */
/* project: blinkspeed                              */
/* outline: LED点滅速度をボタンで変更                 */
/* modified for EBAZ4205                            */

module blinkspeed (
    // 外部クロック入力（約33 MHz）
    input               CLK,

    // リセット入力
    // この基板では active-low
    input               RST,

    // ボタン入力
    // BTN[0]
    input       [0:0]   BTN,

    // LED出力
    // active-high
    output  reg [2:0]   LED_RGB
);



// ============================================================
// チャタリング除去
// ============================================================

// ボタン押下検出後の安定化信号
wire btnon;

// debounceモジュール呼び出し
// mechanical switchのチャタリングを除去
debounce d0 (
    .CLK(CLK),
    .RST(!RST),     // debounce側は active-high reset想定
    .BTNIN(BTN),
    .BTNOUT(btnon)
);



// ============================================================
// 点滅速度設定
// ============================================================

// 2bit速度設定レジスタ
// 00〜11
reg [1:0] speed;


// クロック立ち上がり毎
always @(posedge CLK) begin

    // リセット時
    if (!RST)

        // 初期速度
        speed <= 2'h0;

    // ボタン押下時
    else if (btnon)

        // 速度切り替え
        speed <= speed + 2'h1;
end



// ============================================================
// 分周カウンタ
// ============================================================

// 25bitカウンタ
reg [24:0] cnt25;


// クロック毎にカウントアップ
always @(posedge CLK) begin

    // リセット
    if (!RST)

        // 0クリア
        cnt25 <= 25'h0;

    else

        // +1
        cnt25 <= cnt25 + 25'h1;
end



// ============================================================
// LED更新タイミング生成
// ============================================================

// LED更新イネーブル信号
reg ledcnten;


// speed値に応じて更新周期変更
always @* begin

    case (speed)

        // 最低速
        2'h0:
            ledcnten = (cnt25 == 25'h1ffffff);

        // やや速い
        2'h1:
            ledcnten = (cnt25[23:0] == 24'hffffff);

        // さらに速い
        2'h2:
            ledcnten = (cnt25[22:0] == 23'h7fffff);

        // 最高速
        2'h3:
            ledcnten = (cnt25[21:0] == 22'h3fffff);

        default:
            ledcnten = 1'b0;
    endcase
end



// ============================================================
// LED表示パターンカウンタ
// ============================================================

// 3bit状態カウンタ
reg [2:0] cnt3;


// クロック毎
always @(posedge CLK) begin

    // リセット
    if (!RST)

        cnt3 <= 3'h0;

    // LED更新タイミング時
    else if (ledcnten)

        // 最終状態なら最初へ戻る
        if (cnt3 == 3'd4)

            cnt3 <= 3'h0;

        else

            // 次状態
            cnt3 <= cnt3 + 3'h1;
end



// ============================================================
// LEDデコーダ
// ============================================================

// cnt3値に応じてLED点灯パターン生成
always @* begin

    case (cnt3)

        // LED3点灯
        3'd0:
            LED_RGB = 3'b100;

        // LED2点灯
        3'd1:
            LED_RGB = 3'b010;

        // LED3+LED2点灯
        3'd2:
            LED_RGB = 3'b110;

        // LED2点灯
        3'd3:
            LED_RGB = 3'b010;

        // LED3点灯
        3'd4:
            LED_RGB = 3'b100;

        // 全消灯
        3'd5:
            LED_RGB = 3'b000;

        // デフォルト
        default:
            LED_RGB = 3'b000;
    endcase
end

endmodule