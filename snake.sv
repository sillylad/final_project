`default_nettype none

// Snake tile style - convention is the direction in the name is the side
// where the snake tile connects to another tile
// e.g. LEFT_RIGHT is just a horizontal piece
typedef enum logic [3:0]   {UP_RIGHT, UP_LEFT, DOWN_RIGHT, DOWN_LEFT,
                            UP_TAIL, LEFT_TAIL, RIGHT_TAIL, DOWN_TAIL,
                            UP_HEAD, LEFT_HEAD, RIGHT_HEAD, DOWN_HEAD,
                            UP_DOWN, LEFT_RIGHT,
                            EMPTY} snake_style_t;

typedef enum logic [1:0] {MOVE_UP, MOVE_LEFT, MOVE_RIGHT, MOVE_DOWN} snake_move;


module Snake (
    input logic clk, rst_n,
    input logic game_clk,
    input logic start_game,
    input logic [3:0] dir,
    input logic [9:0] row, col,
    output logic [3:0] VGA_R, VGA_G, VGA_B,
    output logic buzz
);

    // snake is moving always so dir should be sticky
    logic [3:0] sticky_dir;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            sticky_dir <= 4'b1000; // move right
        end
        else begin
            // only update sticky_dir if at least one button is pressed
            if(dir) begin
                sticky_dir <= dir;
            end
            // no button pressed so hold old set of buttons
            else begin
                sticky_dir <= sticky_dir;
            end
        end
    end
    // 8x8 array of snake_tiles for fruit and display logic
    snake_style_t [7:0][7:0] snake_tiles;

    // 64-element shift register for snake motion tracking
    logic [63:0][2:0][2:0] snake_data;
    logic snake_init, grow, snake_enable;
    logic [5:0] snake_length;

    // Stores the current snake data and updates the snake position as needed
    // Output snake_data array for use by other blocks
    Snake_Register sreg (.clk(clk), .rst_n(rst_n), .game_clk(game_clk),
                    .snake_enable(snake_enable), .snake_init(snake_init),
                    .dir(sticky_dir), .start_game(start_game), .grow(grow),
                    .snake_data(snake_data), .snake_tiles(snake_tiles),
                    .snake_length(snake_length));
    
    // Fruit

    // Scoring

    // Audio

    // Color
    Color_Snake cs (.snake_tiles(snake_tiles), .row(row), .col(col), .*);

    // Overall Game Handling FSM

endmodule : Snake


// Update the snake shift register (location of the snake) and 8x8 grid of 
// snake tiles
module Snake_Register (
    input logic clk, rst_n, game_clk,
    input logic [3:0] dir,
    input logic start_game, grow, snake_enable, snake_init,
    output logic [63:0][2:0][2:0] snake_data, // shift register values
    output snake_style_t [7:0][7:0] snake_tiles, // tile display values
    output logic [5:0] snake_length
);

    // snake_tile [15:0][15:0] next_snake_data;
    snake_move decoded_dir;

    // Have a button priority for simplicity, in case multiple are pressed
    always_comb begin
        if(dir[3]) begin
            decoded_dir = MOVE_RIGHT;
        end
        else if(dir[2]) begin
            decoded_dir = MOVE_LEFT;
        end
        else if(dir[1]) begin
            decoded_dir = MOVE_DOWN;
        end
        else if(dir[0]) begin
            decoded_dir = MOVE_UP;
        end
        // default move right, at the start before any buttons are pressed
        else begin
            decoded_dir = MOVE_RIGHT;
        end
    end

    task initialize_snake();
        // Initial snake length is 2 tiles
        snake_length <= 6'd2;

        // Initial snake shift register = horizontal snake facing left
        for(int i = 0; i < 64; i++) begin
            // set the initial head of the snake
            if(i == 0) begin
                snake_data[i] <= {3'd3, 3'd3};
            end
            // set the initial tail of the snake
            else if(i == 1) begin
                snake_data[i] <= {3'd3, 3'd2};
            end
            else begin
                snake_data[i] <= '0;
            end
        end

        for(int r = 0; r < 8; r++) begin
            for(int c = 0; c < 8; c++) begin
                if((r == 3) && (c == 3)) begin
                    snake_tiles[r][c] <= LEFT_HEAD;
                end
                else if((r == 3) && (c == 2)) begin
                    snake_tiles[r][c] <= RIGHT_TAIL;
                end
                else begin
                    snake_tiles[r][c] <= EMPTY;
                end
            end
        end
    endtask

    // Update snake register
    always_ff @(posedge clk, negedge rst_n) begin
        // reset snake in the middle of the board
        if(~rst_n) begin
            initialize_snake();
        end
        else if(snake_init) begin
            initialize_snake();
        end
        else begin
            snake_data <= snake_data;
            snake_tiles <= snake_tiles;
        end
        // end
        // // Only update the snake on the game_clk so it doesn't zoom across
        // // the screen...
        // else if(game_clk) begin
        //     // Only move the snake if a game has commenced
        //     if(snake_enable) begin
        //         // Snake has collided with apple, replace head and increment length
        //         if(grow) begin
        //             snake_length <= snake_length + 5'd1;

        //             // Update tiles
        //         end

        //         // just keep moving
        //         else begin
        //             unique case (decoded_dir):
        //                 MOVE_UP:
        //                 MOVE_RIGHT:
        //                 MOVE_LEFT:
        //                 MOVE_DOWN:
        //             endcase
        //         end
        //     end
        // end
        // else begin
        //     snake_data <= snake_data;
        // end
    end

    

endmodule : Snake_Register

// 8-bit PRNG
// Generate "random" value between 0 -> 63 (64 tiles) to get next fruit pos
// module PRNG (
//     input logic clk, rst_n,
//     input logic 
// );

// endmodule : PRNG


module Color_Snake(
    input snake_style_t [7:0][7:0] snake_tiles,
    input logic [9:0] row, col,
    output logic [3:0] VGA_R, VGA_G, VGA_B
);
    logic [9:0] game_row, game_col;
    logic vga_in_grid;

    assign vga_in_grid = (row >= 10'd44) & (row <= 10'd556) & (col >= 10'd144) & (col <= 10'd656);

    // subtract grid origin offsets
    assign game_row = row - 10'd44;
    assign game_col = col - 10'd144;

    // get which tile the VGA row and col are on (integer div by pixel size=64 since 8x8 grid)
    logic [2:0] tile_row, tile_col;
    assign tile_row = game_row >> 10'd6; // 0 -> 7
    assign tile_col = game_col >> 10'd6;

    always_comb begin
        if(vga_in_grid & ((snake_tiles[tile_row][tile_col]) != EMPTY)) begin
            VGA_G = '1;
            VGA_R = '0;
            VGA_B = '0;
        end
        // game board outline
        else if((game_row == 10'd0) | (game_row == 10'd512) | (game_col == 10'd0) | (game_col == 10'd512)) begin
            {VGA_R, VGA_G, VGA_B} = '1;
        end
        else begin
            {VGA_R, VGA_G, VGA_B} = '0;
        end
    end

endmodule : Color_Snake