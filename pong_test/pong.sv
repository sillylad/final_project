`default_nettype none

//Main pong module, instantiates all the game components inside
//and controls them using the pong_fsm
module pong
   (input logic serve_L_async, reset_L, CLOCK_50,
                R_move_async, R_up_async, L_move_async, L_up_async,
    output logic [7:0] VGA_R, VGA_G, VGA_B,
    output logic HS, VS, blank);

    logic [8:0] row, sum_left, sum_right, Q_BR, LPad_row, RPad_row;
    logic [9:0] col, Q_BC;
    logic is_btwn_LPad, is_btwn_RPad,
          reset_paddle, reset_ballcol, reset_ballrow,
          preset_left, reset_left,
          preset_up, reset_up,
          clr_score,
          en_BR, en_BC, en_LPadR, en_RPadR, en_Lscore, en_Rscore,
          showScoreRight, showScoreLeft, LWin, RWin,
          D_left, VS_display_done,
          rightHit, leftHit;
    logic up, left;
    logic in_done, out_done;
    logic R_move, R_up, L_move, L_up, serve_L;
    logic isB_L1, isB_R1, isB_L2, isB_R2, isB_L3, isB_R3, isB_L4, isB_R4;

    //Instantiating all submodules
    vga vg(.reset(~reset_L), .CLOCK_50(CLOCK_50), .HS(HS), .VS(VS),
           .blank(blank), .row(row), .col(col));

    Synchronizer sync1(.async(serve_L_async), .clock(CLOCK_50), .sync(serve_L)),
                 sync2(.async(R_move_async), .clock(CLOCK_50), .sync(R_move)),
                 sync3(.async(R_up_async), .clock(CLOCK_50), .sync(R_up)),
                 sync4(.async(L_move_async), .clock(CLOCK_50), .sync(L_move)),
                 sync5(.async(L_up_async), .clock(CLOCK_50), .sync(L_up));

    pong_fsm pfsm(.*);

    Ball b(.clock(CLOCK_50), .*);

    Paddle leftPaddle(.en_P(en_LPadR), .move(L_move),
                      .clock(CLOCK_50), .reset_paddle(reset_paddle),
                      .up(L_up), .Q_P(LPad_row));
    Paddle rightPaddle(.en_P(en_RPadR), .move(R_move),
                      .clock(CLOCK_50), .reset_paddle(reset_paddle),
                      .up(R_up), .Q_P(RPad_row));

    Color c(.VGA_row(row), .VGA_col(col), .Q_BR(Q_BR), .Q_BC(Q_BC),
            .Q_LP(LPad_row), .Q_RP(RPad_row), .VGA_R(VGA_R), .VGA_G(VGA_G),
            .VGA_B(VGA_B), .showScoreRight(showScoreRight),
                .showScoreLeft(showScoreLeft), .*);

     Scoring s (.*);

     //Logic to update the game state (signal is on for just one clock cycle)
     DFlipFlop doneff (.D(in_done), .Q(out_done), .clock(CLOCK_50),
                       .preset_L(), .reset_L());

    //tells us when we're done with a VS display period
    always_comb begin
        if (VS_display_done) in_done = 1'b1;
        else in_done = 1'b0;
    end

    assign VS_display_done = ((row == 9'd479) && (col == 10'd639)
                                              && (~out_done)) ? 1'b1 : 1'b0;

    //Computations for checking if the ball has collided with either paddle
    Adder #(9) addL(.A(Q_BR), .B(9'd3), .Cin(1'b0), .Sum(sum_left),
                    .Cout());
    Adder #(9) addR(.A(Q_BR), .B(9'd3), .Cin(1'b0), .Sum(sum_right),
                    .Cout());
    OffsetCheck #(9) oc_left(.low(LPad_row), .delta(9'd51), .val(sum_left),
                             .is_between(is_btwn_LPad));
    OffsetCheck #(9) oc_right(.low(RPad_row), .delta(9'd51), .val(sum_right),
                              .is_between(is_btwn_RPad));

    //update logic, this is just the horizontal bounce logic
    always_comb begin
        if (is_btwn_RPad && rightHit && VS_display_done) begin
            D_left = 1'b1; // Set direction to left
        end
        else if (is_btwn_LPad && leftHit && VS_display_done) begin
            D_left = 1'b0; // Set direction to right
        end
        else D_left = left;
    end

endmodule : pong

//Controls the registers and game updates for all modules (ball/paddle movement,
//color displayed on VGA monitor, scoring
module pong_fsm
   (input logic serve_L, reset_L, LWin, RWin, CLOCK_50, VS_display_done,
    output logic reset_paddle, reset_ballcol, reset_ballrow,
                 preset_left, preset_up, reset_left, reset_up,
                 clr_score,
                 en_BR, en_BC, en_LPadR, en_RPadR, en_Lscore, en_Rscore,
                 showScoreRight, showScoreLeft);

    //State definitions and flipflops to store current state
    enum logic [3:0] {resetState = 4'b0000, waitServe = 4'b0001,
                     leftDown = 4'b0010, rightDown = 4'b0011,
                     display = 4'b0100, leftWin = 4'b0101,
                     rightWin = 4'b0110, waitLeftWin = 4'b0111,
                     waitRightWin = 4'b1000,
                     display2 = 4'b1001} currState, nextState;

    DFlipFlop dff0(.D(nextState[0]), .Q(currState[0]), .clock(CLOCK_50),
                     .reset_L(reset_L), .preset_L(1'b1)),
             dff1(.D(nextState[1]), .Q(currState[1]), .clock(CLOCK_50),
                     .reset_L(reset_L), .preset_L(1'b1)),
             dff2(.D(nextState[2]), .Q(currState[2]), .clock(CLOCK_50),
                     .reset_L(reset_L), .preset_L(1'b1)),
             dff3(.D(nextState[3]), .Q(currState[3]), .clock(CLOCK_50),
                     .reset_L(reset_L), .preset_L(1'b1));

    //FSM LOGIC (NEXT STATE, CONTROL)
    always_comb begin
        reset_paddle = 1'b0;
        reset_ballcol = 1'b0;
        reset_ballrow = 1'b0;
        preset_left = 1'b0;
        preset_up = 1'b0;
        reset_left = 1'b0;
        reset_up = 1'b0;
        clr_score = 1'b0;
        en_BR = 1'b0;
        en_BC = 1'b0;
        en_LPadR = 1'b0;
        en_RPadR = 1'b0;
        en_Lscore = 1'b0;
        en_Rscore = 1'b0;
        showScoreLeft = 1'b0;
        showScoreRight = 1'b0;

        unique case (currState)
            resetState: begin
                nextState = waitServe;
                reset_up = 1'b1;
                reset_left = 1'b1;
                reset_paddle = 1'b1;
                reset_ballcol = 1'b1;
                reset_ballrow = 1'b1;
                clr_score = 1'b1;
                en_BR = 1'b1;
                en_BC = 1'b1;
                en_LPadR = 1'b1;
                en_RPadR = 1'b1;
            end

            //FSM waits here after reset until serve key is pressed
            waitServe: begin
                if(~serve_L && VS_display_done) nextState = rightDown;
                else nextState = waitServe;
            end
            //State for serving down and to the left direction, after the
            //right player has scored
            leftDown: begin
                nextState = display;
                preset_left = 1'b1;
                reset_up = 1'b1;
                en_BR = 1'b1;
                en_BC = 1'b1;
                en_LPadR = 1'b1;
                en_RPadR = 1'b1;
            end
            //State for serving down and to the right, after reset or after
            //the left player has scored
            rightDown: begin
                nextState = display;
                reset_left = 1'b1;
                reset_up = 1'b1;
                en_BR = 1'b1;
                en_BC = 1'b1;
                en_LPadR = 1'b1;
                en_RPadR = 1'b1;
            end
            //Display state, this just prevents our counters from
            //updating more than once every game update period
            display: begin
                if(LWin && VS_display_done) nextState = leftWin;
                else if(RWin && VS_display_done) nextState = rightWin;
                else if (VS_display_done) nextState = display2;
                else nextState = display;
            end
            //Secondary display state, re-enables counters/registers
            display2: begin
               nextState = display;
                en_BR = 1'b1;
                en_BC = 1'b1;
                en_LPadR = 1'b1;
                en_RPadR = 1'b1;
            end
            //State for when the left player has scored, enables score counters
            //and resets ball and paddle to their centerpoints
            leftWin: begin
                nextState = waitLeftWin;
                reset_up = 1'b1;
                reset_paddle = 1'b1;
                reset_ballcol = 1'b1;
                reset_ballrow = 1'b1;
                en_BR = 1'b1;
                en_BC = 1'b1;
                en_Lscore = 1'b1;
                en_LPadR = 1'b1;
                en_RPadR = 1'b1;
            end
            //Same as leftwin but after the right player has scored
            rightWin: begin
                nextState = waitRightWin;
                reset_up = 1'b1;
                reset_paddle = 1'b1;
                reset_ballcol = 1'b1;
                reset_ballrow = 1'b1;
                en_BR = 1'b1;
                en_BC = 1'b1;
                en_Rscore = 1'b1;
                en_LPadR = 1'b1;
                en_RPadR = 1'b1;
            end
            //Waiting state after the left player has scored, stays
            //here until the serve key is pressed
            waitLeftWin: begin
                if(~serve_L && VS_display_done) nextState = rightDown;
                else nextState = waitLeftWin;
                showScoreLeft = 1'b1;
            end
            //Same as waitLeftWin but after the right player has scored
            waitRightWin: begin
                if(~serve_L && VS_display_done) nextState = leftDown;
                else nextState = waitRightWin;
                showScoreRight = 1'b1;
            end
        endcase
    end
endmodule : pong_fsm
