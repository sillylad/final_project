`default_nettype none

// Top level module for pong game
module ChipInterfacePong
    (input logic clk,
     input logic [6:0] btn,
    output logic R0, R1, G0, G1, B0, B1, VGA_HS, VGA_VS,
    output logic [7:0] led);

    logic reset, blank;
    logic [8:0] row;
    logic [9:0] col;
    logic [3:0] L1, L2, L3, L4, R1, R2, R3, R4;
    logic isB_L1, isB_R1;

    //Sets up VGA values
    assign VGA_SYNC_N = 1'b0;
    assign VGA_BLANK_N = ~blank;
    assign VGA_CLK = ~CLOCK_50;
    logic 

    //Instantiates main pong module with VGA
    pong DUT (.serve_L_async(btn[3]), .reset_L(btn[0]), .CLOCK_50(CLOCK_50),
                .R_move_async(btn[1]), .R_up_async(btn[2]), .L_move_async(btn[4]),
                     .L_up_async(btn[5]),
                .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .HS(VGA_HS),
                .VS(VGA_VS), .blank(blank), .*);
    
    assign 

endmodule: ChipInterfacePong
