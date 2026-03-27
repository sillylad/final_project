module simple_480p (
    input       logic clk_pix,   // pixel clock
    input       logic rst_pix,   // reset in pixel clock domain
    output      logic [9:0] col,  // horizontal screen position
    output      logic [9:0] row,  // vertical screen position
    output      logic HS,     // horizontal sync
    output      logic VS,     // vertical sync
    output      logic de         // data enable (low in blanking interval)
    );

    // horizontal timings
    parameter HA_END = 639;           // end of active pixels
    parameter HS_STA = HA_END + 16;   // sync starts after front porch
    parameter HS_END = HS_STA + 96;   // sync ends
    parameter LINE   = 799;           // last pixel on line (after back porch)

    // vertical timings
    parameter VA_END = 479;           // end of active pixels
    parameter VS_STA = VA_END + 10;   // sync starts after front porch
    parameter VS_END = VS_STA + 2;    // sync ends
    parameter SCREEN = 524;           // last line on screen (after back porch)

    always_comb begin
        HS = ~(col >= HS_STA && col < HS_END);  // invert: negative polarity
        VS = ~(row >= VS_STA && row < VS_END);  // invert: negative polarity
        de = (col <= HA_END && row <= VA_END);
    end

    // calculate horizontal and vertical screen position
    always_ff @(posedge clk_pix) begin
        if (col == LINE) begin  // last pixel on line?
            col <= 0;
            row <= (row == SCREEN) ? 0 : row + 1;  // last line on screen?
        end else begin
            col <= col + 1;
        end
        if (rst_pix) begin
            col <= 0;
            row <= 0;
        end
    end
endmodule


//Testbench of vga module, same as the test pattern given in the lab handout
module vga_tb
   (input logic [9:0] col,
    input logic [9:0] row,
    output logic [7:0] VGA_R, VGA_G, VGA_B);


    logic red, green1, green2, blue1, blue2, blue3, blue4, black;

    RangeCheck #(10) rc1(.val(col), .low(10'd320), .high(10'd639),
                        .is_between(red));
    RangeCheck #(10) rc2(.val(col), .low(10'd160), .high(10'd319),
                        .is_between(green1));
    RangeCheck #(10) rc3(.val(col), .low(10'd480), .high(10'd639),
                        .is_between(green2));
    RangeCheck #(10) rc4(.val(col), .low(10'd80), .high(10'd159),
                        .is_between(blue1));
    RangeCheck #(10) rc5(.val(col), .low(10'd240), .high(10'd319),
                        .is_between(blue2));
    RangeCheck #(10) rc6(.val(col), .low(10'd400), .high(10'd479),
                        .is_between(blue3));
    RangeCheck #(10) rc7(.val(col), .low(10'd560), .high(10'd639),
                        .is_between(blue4));

    RangeCheck #(9) rc8(.val(row), .low(9'd240), .high(9'd479),
                        .is_between(black));

    assign VGA_R = ((red) && (~black)) ? 8'hff : 0;
    assign VGA_G = ((green1 || green2) && (~black)) ? 8'hff : 0;
    assign VGA_B = ((blue1 || blue2 || blue3 || blue4) && ~black) ? 8'hff : 0;

endmodule : vga_tb

// Compares val to high and low using two MagComp modules.
// Sets is_between to 1, if val is between high and low (inclusive)
module RangeCheck
    #(parameter WIDTH = 8)
    (input logic [(WIDTH - 1):0] val, high, low,
     output logic is_between);

    logic valLtHigh, valGtHigh, valEqHigh, valLtLow, valGtLow, valEqLow;

    // Instantiating the two MagComp modules, with WIDTH = WIDTH
    MagComp #(WIDTH) comp1 (.A(val), .B(high), .AeqB(valEqHigh),
                            .AgtB(valGtHigh), .AltB(valLtHigh));
    MagComp #(WIDTH) comp2 (.A(val), .B(low), .AeqB(valEqLow),
                            .AgtB(valGtLow), .AltB(valLtLow));

    // Set is_between to 0 if val > high or val < low
    // Set is_between to 1 if
    // (val < low and val > high), or val == low, or val == high
    always_comb begin
        if (valGtHigh | valLtLow)
            is_between = 1'b0;
        else
            is_between = 1'b1;
    end

endmodule: RangeCheck

// Increments or decrements the stored multibit value by 1
// every clock cycle, can load a starting value
// or clear if needed
module Counter
   #(parameter WIDTH = 8)
   (input logic en, clear, load, up, clock,
    input logic [WIDTH-1:0] D,
    output logic [WIDTH-1:0] Q);

    always_ff @(posedge clock)
       if(clear)
          Q <= '0;
       else if (load)
          Q <= D;
       else if (en & up)
          Q <= Q + 1;
       else if (en & ~up)
          Q <= Q - 1;

endmodule : Counter

// Stores a single bit, updated every clock cycle
// Can be reset to 0 or preset to 1 if needed
module DFlipFlop
   (output logic Q,
    input  logic D, clock, reset_L, preset_L);

    always_ff @(posedge clock, negedge reset_L, negedge preset_L)
       if(~reset_L)
          Q <= 0;
       else if (~preset_L)
          Q <= 1;
       else
          Q <= D;

endmodule : DFlipFlop

module MagComp
    #(parameter WIDTH = 8)
    (input logic [(WIDTH - 1):0] A, B,
     output logic AltB, AeqB, AgtB);

    assign AeqB = (A == B);
    assign AltB = (A < B);
    assign AgtB = (A > B);

endmodule: MagComp