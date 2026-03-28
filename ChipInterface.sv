`default_nettype none

module ChipInterface (
    input logic clk,
    input logic [6:0] btn,
    output logic R0, R1, G0, G1, B0, B1, VGA_HS, VGA_VS,
    output logic [7:0] led
);

    logic [9:0] col;
    logic [9:0] row;
    logic [7:0] VGA_R, VGA_G, VGA_B;
    logic blank;

    logic pll_locked, clk_40;
    
    // 40Mhz needed for 800x600
    pll40M c40 (.clk_25(clk), .clk_40(clk_40), .locked(pll_locked));
    vga vga_800_600 (.clk(clk_40), .rst_n(btn[0]), .HS(VGA_HS), .VS(VGA_VS),
                    .blank(blank), .row(row), .col(col));


    // generate test pattern
    logic [5:0] rgb;

    vga_test_pattern vtp(.row(row), .col(col), .rgb(rgb));

    assign {R1, R0, G1, G0, B1, B0} = (~blank) ? rgb : '0;
    assign led = {R1, R0, G1, G0, B1, B0};


endmodule : ChipInterface

module vga_test_pattern (
    input logic [9:0] row, col,
    output logic [5:0] rgb
);

    always_comb begin
        if((row == 0) & (col == 0)) begin
            rgb = '1;
        end
        else if((row == 10'd0) | (row == 10'd479)) begin
            rgb = 6'b11_00_11;
        end
        else if((col == 0) | (col == 10'd639)) begin
            rgb = 6'b11_00_00;
        end
        else if((col == 10'd50) | (col == 10'd70) | (col == 10'd100)) begin
            rgb = 6'b00_00_11;
        end

        else if(col <= 10'd639 | col >= 10'd0) begin
            rgb = 6'b00_11_00;
        end
        else begin
            rgb = '0;
        end
    end


endmodule : vga_test_pattern
// diamond 3.7 accepts this PLL
// diamond 3.8-3.9 is untested
// diamond 3.10 or higher is likely to abort with error about unable to use feedback signal
// cause of this could be from wrong CPHASE/FPHASE parameters
module pll40M
(
    input clk_25, // 25 MHz, 0 deg
    output clk_40, // 40 MHz, 0 deg
    output locked
);
(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOP="40" *)
(* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .OUTDIVIDER_MUXA("DIVA"),
        .OUTDIVIDER_MUXB("DIVB"),
        .OUTDIVIDER_MUXC("DIVC"),
        .OUTDIVIDER_MUXD("DIVD"),
        .CLKI_DIV(5),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(15),
        .CLKOP_CPHASE(7),
        .CLKOP_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(8)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clk_25),
        .CLKOP(clk_40),
        .CLKFB(clk_40),
        .CLKINTFB(),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(locked)
	);
endmodule
