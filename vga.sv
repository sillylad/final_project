`default_nettype none

// timing parameters to use
`define NUM_ROWS 600
`define NUM_COLS 800
`define HS_SYNC  1056
`define HS_DISP  800
`define HS_PW    128
`define HS_FP    40
`define HS_BP    88

`define VS_SYNC 628
`define VS_DISP 600
`define VS_PW   4
`define VS_FP   1
`define VS_BP   23
// VGA module for 800x600 resolution
// POSITIVE SYNC POLARITY
module vga
   (input logic clk_40, rst_n,
    output logic HS, VS, blank,
    output logic [9:0] row,
    output logic [9:0] col);

    logic [19:0] VS_count;
    logic [10:0] HS_count;

    logic is_hs_pw, is_hs_bp, is_hs_disp, is_hs_fp;
    logic is_vs_pw, is_vs_bp, is_vs_disp, is_vs_fp;

    // HS, VS counters
    always_ff @(posedge clk_40, negedge rst_n) begin
        if(~rst_n) begin
            {VS_count, HS_count} <= '0;
        end
        else begin
            HS_count <= ((HS_count == (`HS_SYNC - 1'b1)) ? '0 : HS_count + 1'b1);
            if(HS_count == `HS_SYNC - 1'b1) begin
                VS_count <= ((VS_count == (`VS_SYNC - 1'b1)) ? '0 : VS_count + 1'b1);
            end
        end
    end

    // row and column counters
    always_ff @(posedge clk_40, negedge rst_n) begin
        if(~rst_n) begin
            {row, col} <= '0;
        end
        else begin
            // update row at the end of HS line
            if(HS_count == `HS_PW + `HS_BP + `HS_DISP + `HS_FP - 1) begin
                row <= (row == `NUM_ROWS - 1) ? '0 : row + 1;
            end
            // update col during display period (800th col)
            if(is_hs_disp) begin
                col <= (col == `NUM_COLS - 1) ? '0 : col + 1;
            end
        end
    end

    assign is_hs_pw = (11'd0 <= HS_count) && (HS_count < `HS_PW);
    assign is_hs_bp = (`HS_PW <= HS_count) && (HS_count < `HS_PW + `HS_BP);
    assign is_hs_disp = (`HS_PW + `HS_BP <= HS_count) && (HS_count < `HS_PW + `HS_BP + `HS_DISP);
    assign is_hs_fp = (`HS_PW + `HS_BP + `HS_DISP <= HS_count) && (HS_count < `HS_PW + `HS_BP + `HS_DISP + `HS_FP);

    assign is_vs_pw = (20'd0 <= VS_count) && (VS_count < `VS_PW);
    assign is_vs_bp = (`VS_PW <= VS_count) && (VS_count < `VS_PW + `VS_BP);
    assign is_vs_disp = (`VS_PW + `VS_BP <= VS_count) && (VS_count < `VS_PW + `VS_BP + `VS_DISP);
    assign is_vs_fp = (`VS_PW + `VS_BP + `VS_DISP <= VS_count) && (VS_count < `VS_PW + `VS_BP + `VS_DISP + `VS_FP);
    
    //FINAL OUTPUTS OF VGA MODULE
    assign HS = is_hs_pw;
    assign VS = is_vs_pw;
    assign blank = ~(is_hs_disp & is_vs_disp);

endmodule : vga

// module vga_tb();

//     logic clk_40, rst_n, HS, VS, blank;
//     logic [9:0] row, col;
//     vga dut (.*);

//     initial begin
//         clk_40 = 1'b0;
//         rst_n = 1'b0;
//         rst_n <= 1'b1;
//         forever #5 clk_40 = ~clk_40;
//     end

//     initial begin
//         #4000000;
//     end


// endmodule : vga_tb

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