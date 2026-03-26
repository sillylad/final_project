`default_nettype none

// timing parameters to use
`define NUM_ROWS 600
`define NUM_COLS 800
`define HS_SYNC  1056
`define HS_DISP  800
`define HS_PW    128
`define HS_FP    40
`define HS_BP    88
`define VS_SYNC  663168
`define VS_DISP  633600
`define VS_PW    4224
`define VS_FP    1056
`define VS_BP    24288

// VGA module for 800x600 resolution
module vga
   (input logic clk_40, rst_n,
    output logic HS, VS, blank,
    output logic [9:0] row,
    output logic [9:0] col);

    logic [19:0] VS_count;
    logic [10:0] HS_count;

    logic is_hs_pw, is_hs_bp, is_hs_disp, is_hs_fp;
    logic is_vs_pw, is_vs_bp, is_vs_disp, is_vs_fp;
    logic cond1, cond2;
    assign cond1 = (VS_count == (`VS_SYNC - 1'b1));
    assign cond2 = (HS_count == (`HS_SYNC - 1'b1));

    // HS, VS counters
    always_ff @(posedge clk_40, negedge rst_n) begin
        if(~rst_n) begin
            {VS_count, HS_count} <= '0;
        end
        else begin
            VS_count <= ((VS_count == (`VS_SYNC - 1'b1)) ? '0 : VS_count + 1'b1);
            HS_count <= ((HS_count == (`HS_SYNC - 1'b1)) ? '0 : HS_count + 1'b1);
        end
    end

    // row and column counters
    always_ff @(posedge clk_40, negedge rst_n) begin
        if(~rst_n) begin
            {row, col} <= '0;
        end
        else begin
            // reset col (800th col)
            if(col == 10'd799) begin
                col <= '0;
            end
            // increment from 0 -> 799 during HS display period
            else if(is_hs_disp) begin
                col <= col + 1;
            end
            // reset row (600th row)
            if(row == 10'd599) begin
                row <= '0;
            end
            // increment row at the end of every HS display period, go from 0 -> 599
            else if(HS_count == 11'd1016) begin
                row <= row + 1;
            end
        end
    end

    assign is_hs_pw = (11'd0 <= HS_count) && (HS_count <= 11'd127);
    assign is_hs_bp = (11'd128 <= HS_count) && (HS_count <= 11'd215);
    assign is_hs_disp = (11'd216 <= HS_count) && (HS_count <= 11'd1015);
    assign is_hs_fp = (11'd1016 <= HS_count) && (HS_count <= 11'd1055);

    assign is_vs_pw = (20'd0 <= VS_count) && (HS_count <= 20'd4223);
    assign is_vs_bp = (20'd4224 <= HS_count) && (HS_count <= 20'd28511);
    assign is_vs_disp = (20'd28512 <= HS_count) && (HS_count <= 20'd662111);
    assign is_vs_fp = (20'd662112 <= HS_count) && (HS_count <= 20'd663167);
    
    //FINAL OUTPUTS OF VGA MODULE
    assign HS = ~is_hs_pw;
    assign VS = ~is_vs_pw;
    assign blank = ~(is_hs_disp & is_vs_disp);

endmodule : vga

// //Testbench of vga module, same as the test pattern given in the lab handout
// module vga_test
//    (input logic [9:0] col,
//     input logic [9:0] row,
//     output logic [7:0] VGA_R, VGA_G, VGA_B);


//     logic red, green1, green2, blue1, blue2, blue3, blue4, black;

//     RangeCheck #(10) rc1(.val(col), .low(10'd320), .high(10'd639),
//                         .is_between(red));
//     RangeCheck #(10) rc2(.val(col), .low(10'd160), .high(10'd319),
//                         .is_between(green1));
//     RangeCheck #(10) rc3(.val(col), .low(10'd480), .high(10'd639),
//                         .is_between(green2));
//     RangeCheck #(10) rc4(.val(col), .low(10'd80), .high(10'd159),
//                         .is_between(blue1));
//     RangeCheck #(10) rc5(.val(col), .low(10'd240), .high(10'd319),
//                         .is_between(blue2));
//     RangeCheck #(10) rc6(.val(col), .low(10'd400), .high(10'd479),
//                         .is_between(blue3));
//     RangeCheck #(10) rc7(.val(col), .low(10'd560), .high(10'd639),
//                         .is_between(blue4));

//     RangeCheck #(9) rc8(.val(row), .low(9'd240), .high(9'd479),
//                         .is_between(black));

//     assign VGA_R = ((red) && (~black)) ? 8'hff : 0;
//     assign VGA_G = ((green1 || green2) && (~black)) ? 8'hff : 0;
//     assign VGA_B = ((blue1 || blue2 || blue3 || blue4) && ~black) ? 8'hff : 0;

// endmodule : vga_test