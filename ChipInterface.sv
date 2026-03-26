`default_nettype none

module ChipInterface (
    input logic clk,
    input logic [6:0] btn,
    output logic R0, R1, G0, G1, B0, B1, VGA_HS, VGA_VS,
    output logic [7:0] led
);

    logic [9:0] col;
    logic [8:0] row;
    logic [7:0] VGA_R, VGA_G, VGA_B;
    logic blank;

    logic pll_locked1, clk50;
    pll_half p50 (.clk(clk), .clkout0(clk50), .locked(pll_locked1));

    vga_640_480 vga640480 (.CLOCK_50(clk50), .reset(~btn[0]), .HS(VGA_HS), .VS(VGA_VS),
                    .blank(blank), .row(row), .col(col));
    // vga vga800600 (.clk_40(clk), .rst_n(~btn[0]), .HS(VGA_HS), .VS(VGA_VS),
    //                 .blank(), .row(row), .col(col));
    // vga_test vt(.col(col), .row(row), .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B));

    assign {R1, R0, G1, G0, B1, B0} = (~blank) ? 6'b101010 : '0;
    assign led = {R1, R0, G1, G0, B1, B0};


endmodule : ChipInterface

// diamond 3.7 accepts this PLL
// diamond 3.8-3.9 is untested
// diamond 3.10 or higher is likely to abort with error about unable to use feedback signal
// cause of this could be from wrong CPHASE/FPHASE parameters
module pll_half
(
    input clk, // 25 MHz, 0 deg
    output clkout0, // 50 MHz, 0 deg
    output locked
);
(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOP="50" *)
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
        .CLKI_DIV(1),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(12),
        .CLKOP_CPHASE(5),
        .CLKOP_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(2)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clk),
        .CLKOP(clkout0),
        .CLKFB(clkout0),
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