`default_nettype none

//vga module keeps track of all timing information
module vga_640_480
   (input logic CLOCK_50, reset,
    output logic HS, VS, blank,
    output logic [8:0] row,
    output logic [9:0] col);

    logic en_vs, en_hs, en_row, en_col;
    logic clear_vs, clear_hs, clear_row, clear_col;
    logic [19:0] Q_VS, D_VS;
    logic [10:0] Q_HS, D_HS;
    logic [8:0] Q_row, D_row;
    logic [9:0] Q_col, D_col;
    logic load_vs, load_hs, load_row, load_col;
    logic VS_done, HS_done;

    logic isB_vp, isB_vd;
    logic isB_hp, isB_hd;

    //Checks if a horizontal or vertical sync period has been completed
    MagComp #(20) vs_done(.A(Q_VS), .B(20'd833599), .AeqB(VS_done),
                                                    .AgtB(), .AltB());
    MagComp #(11) hs_done(.A(Q_HS), .B(11'd1599), .AeqB(HS_done),
                                                    .AgtB(), .AltB());

    //Counts the clock cycles that have occurred during a VS or HS period
    Counter #(20) VSCounter(.en(en_vs), .clear(clear_vs), .load(load_vs),
                             .up(1'b1),  .clock(CLOCK_50), .D(D_VS), .Q(Q_VS));
    Counter #(11) HSCounter(.en(en_hs), .clear(clear_hs), .load(load_hs),
                             .up(1'b1),  .clock(CLOCK_50), .D(D_HS), .Q(Q_HS));
    //Counts the current row and col being displayed on the monitor
    Counter #(9) RowCounter(.en(en_row), .clear(clear_row), .load(load_row),
                             .up(1'b1),  .clock(CLOCK_50),
                                    .D(D_row), .Q(Q_row));
    Counter #(10) ColCounter(.en(en_col), .clear(clear_col), .load(load_col),
                             .up(1'b1),  .clock(CLOCK_50),
                                    .D(D_col), .Q(Q_col));

    //Logic to check which part of the VS or HS signal we are in
    RangeCheck #(20) VS_pulse(.val(Q_VS), .high(20'd3199), .low(20'd0),
                              .is_between(isB_vp));
    RangeCheck #(20) VS_display(.val(Q_VS), .high(20'd817599), .low(20'd49600),
                                .is_between(isB_vd));

    RangeCheck #(11) HS_pulse(.val(Q_HS), .high(11'd191), .low(11'd0),
                             .is_between(isB_hp));
    RangeCheck #(11) HS_display(.val(Q_HS), .high(11'd1567), .low(11'd288),
                                .is_between(isB_hd));

    //Defining states and flipflops for controlling FSM
    enum logic [1:0] {resetState = 2'b00,
                        counting = 2'b01, done = 2'b10} currState, nextState;

    DFlipFlop dff0(.D(nextState[0]), .Q(currState[0]), .clock(CLOCK_50),
                                        .reset_L(~reset), .preset_L(1'b1));
    DFlipFlop dff1(.D(nextState[1]), .Q(currState[1]), .clock(CLOCK_50),
                                        .reset_L(~reset), .preset_L(1'b1));

    //CONTROL POINT LOGIC
    assign en_col = ((~Q_HS[0]) & isB_hd);
    assign en_row = HS_done & isB_vd;
    assign en_hs = ~HS_done;
    assign clear_hs = HS_done;
    assign clear_col = HS_done | (currState == 2'b00);

    //NEXT STATE AND CONTROL LOGIC
    always_comb begin
        en_vs = 1'b0;
        load_vs = 1'b0;
        load_hs = 1'b0;
        clear_vs = 1'b0;
        D_HS = 11'd0;
        D_VS = 20'd0;
        clear_row = 1'b0;

        //Reset state
        unique case(currState)
            resetState: begin
                nextState = counting;
                clear_row = 1'b1;
                load_vs = 1'b1;
                load_hs = 1'b1;
                D_HS = 11'd1;
                D_VS = 20'd1;
                en_vs = 1'b0;
            end
            //Counting all relevant values within a VS cycle
            counting: begin
                if(VS_done) begin
                    nextState = done;
                    clear_vs = 1'b1;
                    clear_row = 1'b1;
                    en_vs = 1'b0;
                end
                else begin
                    nextState = counting;
                    en_vs = 1'b1;
                    clear_row = 1'b0;
                    load_vs = 1'b0;
                    load_hs = 1'b0;
                end
            end
            //When a VS cycle is done, prepares for next VS cycle
            done: begin
                nextState = counting;
                en_vs = 1'b1;
                clear_vs = 1'b0;
                clear_row = 1'b0;
            end
        endcase
    end

    //FINAL OUTPUTS OF VGA MODULE
    assign HS = ~isB_hp;
    assign VS = ~isB_vp;
    assign blank = ~(isB_vd & isB_hd);
    assign row = Q_row;
    assign col = Q_col;

endmodule : vga_640_480

//Testbench of vga module, same as the test pattern given in the lab handout
module vga_test
   (input logic [9:0] col,
    input logic [8:0] row,
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

endmodule : vga_test

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