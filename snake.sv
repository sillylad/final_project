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
    output logic buzz,
    output snake_move curr_dir,
    output logic [5:0] snake_length,
    output logic [5:0] head_pos,
    output logic is_snake
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
    // // 8x8 array of snake_tiles for fruit and display logic
    // snake_style_t [63:0] snake_tiles;

    // 64-element shift register for snake motion tracking
    logic [63:0][5:0] snake_data;
    logic [63:0] snake_valid;
    logic snake_init, grow, snake_enable;
    logic [5:0] snake_length;

    assign snake_init = 1'b0;
    assign snake_enable = 1'b1;
    assign grow = (head_pos == fruit_pos);
    // Stores the current snake data and updates the snake position as needed
    // Output snake_data array for use by other blocks
    Snake_Register sreg (.clk(clk), .rst_n(rst_n), .game_clk(game_clk),
                    .snake_enable(snake_enable), .snake_init(snake_init),
                    .dir(sticky_dir), .start_game(start_game), .grow(grow),
                    .snake_data(snake_data),
                    .snake_length(snake_length), .curr_dir(curr_dir));

    assign head_pos = snake_data[0]; // pull out of snake_register for debug
    
    // Fruit
    logic [5:0] fruit_pos;
    PRNG fruit_gen (.clk(clk), .game_clk(game_clk), .rst_n(rst_n),
                    .snake_data(snake_data), .snake_valid(snake_valid),
                    .grow(grow), .fruit_pos(fruit_pos));

    // Scoring

    // Audio

    // Color
    Color_Gameboard cgb(.snake_data(snake_data),
                        .snake_length(snake_length),
                        .snake_valid(snake_valid),
                        .fruit_pos(fruit_pos),
                        .row(row), .col(col), .is_snake(is_snake), .*);

    // Overall Game Handling FSM

endmodule : Snake


// Update the snake shift register (location of the snake) and 8x8 grid of 
// snake tiles
module Snake_Register (
    input logic clk, rst_n, game_clk,
    input logic [3:0] dir,
    input logic start_game, grow, snake_enable, snake_init,
    output logic [63:0][5:0] snake_data, // shift register values
    output logic [5:0] snake_length,
    output snake_move curr_dir
);

    snake_move decoded_dir;

    // Have a button priority for simplicity, in case multiple are pressed
    // also reject invalid moves (like moving right when currently moving left, etc.)
    always_comb begin
        if(dir[3] & (curr_dir != MOVE_LEFT)) begin
            decoded_dir = MOVE_RIGHT;
        end
        else if(dir[2] & (curr_dir != MOVE_RIGHT)) begin
            decoded_dir = MOVE_LEFT;
        end
        else if(dir[1] & (curr_dir != MOVE_UP)) begin
            decoded_dir = MOVE_DOWN;
        end
        else if(dir[0] & (curr_dir != MOVE_DOWN)) begin
            decoded_dir = MOVE_UP;
        end
        // keep snake moving in same direction
        else begin
            decoded_dir = curr_dir;
        end
    end

    // reset move direction is just to the right
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            curr_dir <= MOVE_RIGHT;
        end
        else begin
            curr_dir <= decoded_dir;
        end
    end

    task initialize_snake();
        // Initial snake length is 3 tiles
        snake_length <= 6'd3;

        // Initial snake shift register = horizontal snake facing left
        for(int i = 0; i < 64; i++) begin
            // set the initial head of the snake
            if(i == 0) begin
                snake_data[i] <= {3'd3, 3'd3};
            end
            else if(i == 1) begin
                snake_data[i] <= {3'd3, 3'd2};
            end
            // set the initial tail of the snake
            else if(i == 2) begin
                snake_data[i] <= {3'd3, 3'd1};
            end
            else begin
                snake_data[i] <= '0;
            end
        end
    endtask

    logic [5:0] new_head;

    always_comb begin
        unique case(curr_dir)
            MOVE_UP: new_head = {snake_data[0][5:3] - 3'd1, snake_data[0][2:0]};
            MOVE_RIGHT: new_head = {snake_data[0][5:3], snake_data[0][2:0] + 3'd1};
            MOVE_LEFT: new_head = {snake_data[0][5:3], snake_data[0][2:0] - 3'd1};
            MOVE_DOWN: new_head = {snake_data[0][5:3] + 3'd1, snake_data[0][2:0]};
        endcase
    end

    // Update snake register
    always_ff @(posedge clk, negedge rst_n) begin
        // reset snake in the middle of the board
        if(~rst_n) begin
            initialize_snake();
        end
        else if(snake_init) begin
            initialize_snake();
        end
        // else begin
        else if(game_clk) begin
            // Only move the snake if a game has commenced
            if(snake_enable) begin
                // Snake has collided with apple, replace head and increment length
                if(grow) begin
                    snake_length <= snake_length + 5'd1;
                    // Update tiles
                end

                // Snake keeps moving
                else begin
                    for(int i = 63; i > 0; i--) begin
                        snake_data[i] <= snake_data[i-1];
                    end
                    snake_data[0] <= new_head;
                end
            end
        end
        else begin
            snake_data <= snake_data;
            snake_length <= snake_length;
        end
    end
    

endmodule : Snake_Register

// 6-bit PRNG
// Generate "random" value between 0 -> 63 (64 tiles) to get next fruit pos
module PRNG (
    input logic clk, rst_n,
    input logic game_clk,
    input logic [63:0][5:0] snake_data,
    input logic [63:0] snake_valid,
    input logic grow,
    output logic [5:0] fruit_pos
);

    logic valid_fruit, shift, get_new_pos;
    logic [63:0] fruit_on_snake;

    // spin lfsr on faster clock so it can resolve in time
    logic [5:0] seed, lfsr_out;
    assign seed = 6'b1;
    LFSR_6_BIT lfsr(.clk(clk), .rst_n(rst_n), .shift(shift), .seed(seed),
                    .lfsr_out(lfsr_out));

    assign shift = ~valid_fruit & get_new_pos;

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            get_new_pos <= 1'b0;
        end
        // trigger new fruit position search
        else if(grow) begin
            get_new_pos <= 1'b1;
        end
        // stop searching when you found a valid fruit
        else if(valid_fruit & game_clk & get_new_pos) begin
            get_new_pos <= 1'b0;
        end
    end

    // update visible fruit_pos only when a valid tile has been found (max 63 clocks)
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            fruit_pos <= {3'd3, 3'd6};
        end
        // update visible fruit on game clock only (high for 1 clock only)
        else if(game_clk & valid_fruit & get_new_pos) begin
            fruit_pos <= lfsr_out;
        end
    end

    // check if the proposed fruit tile is on top of the snake
    genvar i;
    generate
        for(i = 0; i < 64; i++) begin
            assign fruit_on_snake[i] =  (snake_data[i][5:3] == lfsr_out[5:3]) & 
                                        (snake_data[i][2:0] == lfsr_out[2:0]) & 
                                        (snake_valid[i]);
        end
    endgenerate

    // conditions for valid fruit: not where the snake is, and in a different
    // place than the previous fruit (these conditions should overlap)
    assign valid_fruit = ~(|fruit_on_snake) & (lfsr_out != fruit_pos);

endmodule : PRNG

module LFSR_6_BIT(
    input logic clk, rst_n, shift,
    input logic [5:0] seed,
    output logic [5:0] lfsr_out
);

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            // reset lfsr to seed, but make sure seed isn't 0 else lfsr will lock
            lfsr_out <= (seed == '0) ? 6'b1 : seed;
        end
        else if(shift) begin
            lfsr_out[5] <= lfsr_out[0];
            lfsr_out[4] <= lfsr_out[5] ^ lfsr_out[0];
            lfsr_out[3] <= lfsr_out[4];
            lfsr_out[2] <= lfsr_out[3] ^ lfsr_out[0];
            lfsr_out[1] <= lfsr_out[2] ^ lfsr_out[0];
            lfsr_out[0] <= lfsr_out[1];
        end
        else begin
            lfsr_out <= lfsr_out;
        end
    end

endmodule : LFSR_6_BIT


// Handle all the coloring stuff for the gameboard (snake, fruit)
module Color_Gameboard(
    input logic [63:0][5:0] snake_data,
    input logic [5:0] snake_length,
    input logic [5:0] fruit_pos,
    input logic [9:0] row, col,
    output logic [3:0] VGA_R, VGA_G, VGA_B,
    output logic is_snake,
    output logic [63:0] snake_valid
);
    logic [9:0] game_row, game_col;
    logic vga_in_grid;

    assign vga_in_grid = (row >= 10'd44) & (row < 10'd556) & (col >= 10'd144) & (col < 10'd656);

    // subtract grid origin offsets
    assign game_row = row - 10'd44;
    assign game_col = col - 10'd144;

    // get which tile the VGA row and col are on (integer div by pixel size=64 since 8x8 grid)
    logic [2:0] tile_row, tile_col;
    assign tile_row = game_row >> 10'd6; // 0 -> 7
    assign tile_col = game_col >> 10'd6;

    logic display_snake;
    assign is_snake = display_snake;
    logic [63:0] in_snake;
    
    // thermometer encoding of snake_length to get a mask for the snake_data
    // logic [63:0] snake_valid;
    logic [63:0] ones_mask;

    assign ones_mask = '1;
    assign snake_valid = ones_mask >> (7'd64 - {1'b0, snake_length});


    // figure out if we're supposed to display some snek or not
    genvar i;
    generate 
        for(i = 0; i < 64; i++) begin
            assign in_snake[i] = (snake_data[i][5:3] == tile_row) & (snake_data[i][2:0] == tile_col) & (snake_valid[i]);
        end
    endgenerate

    assign display_snake = |in_snake;

    logic display_fruit;
    assign display_fruit = (tile_row == fruit_pos[5:3]) && (tile_col == fruit_pos[2:0]);

    always_comb begin
        // default black background
        {VGA_R, VGA_G, VGA_B} = '0;
        
        // white game board outline
        if((game_row == 10'd0) | (game_row == 10'd512) | (game_col == 10'd0) | (game_col == 10'd512)) begin
            {VGA_R, VGA_G, VGA_B} = '1;
        end
        else if(vga_in_grid) begin
            // just green snake for now
            if(display_snake) begin
                VGA_R = '0;
                VGA_G = '1;
                VGA_B = '0;
            end

            else if(display_fruit) begin
                VGA_R = '1;
                VGA_G = '0;
                VGA_B = '0;
            end
        end
        // black background
        else begin
            {VGA_R, VGA_G, VGA_B} = '0;
        end
    end

endmodule : Color_Gameboard