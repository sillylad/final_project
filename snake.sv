`default_nettype none

// Snake tile style - convention is the direction in the name is the side
// where the snake tile connects to another tile
// e.g. LEFT_RIGHT is just a horizontal piece
typedef enum logic [3:0]   {UP_RIGHT, UP_LEFT, DOWN_RIGHT, DOWN_LEFT,
                            UP_TAIL, LEFT_TAIL, RIGHT_TAIL, DOWN_TAIL,
                            UP_HEAD, LEFT_HEAD, RIGHT_HEAD, DOWN_HEAD,
                            UP_DOWN, LEFT_RIGHT,
                            EMPTY} snake_style_t;

// data struct for a single snake tile
typedef struct packed {
    logic valid_snake;
    snake_style_t tile_style;
} snake_tile;

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
    // 16x16 array of snake_tiles
    snake_tile [15:0][15:0] snake_data;
    logic snake_init, grow, snake_enable;
    logic [7:0] snake_length;

    // Stores the current snake data and updates the snake position as needed
    // Output snake_data array for use by other blocks
    Snake_Register (.clk(clk), .rst_n(rst_n), .game_clk(game_clk),
                    .snake_enable(snake_enable), .snake_init(snake_init),
                    .dir(sticky_dir), .start_game(start_game), .grow(grow),
                    .snake_data(snake_data), .snake_length(snake_length));
    
    // Fruit

    // Scoring

    // Audio

    // Color

    // Overall Game Handling FSM

endmodule : Snake


module Snake_Register (
    input logic clk, rst_n, game_clk,
    input logic [3:0] dir,
    input logic start_game, grow, snake_enable,
    output snake_tile [15:0][15:0] snake_data,
    output logic [7:0] snake_length;
);

    snake_tile [15:0][15:0] next_snake_data;
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

    // Update snake register
    always_ff @(posedge clk, negedge rst_n) begin
        // reset snake in the middle of the board
        if(~rst_n | snake_init) begin
            // Initial snake length is 4 tiles
            snake_length <= 7'd4;

            // Initial snake tiles = horizontal snake facing left
            foreach(snake_data[r,c]) begin
                case ({r[3:0], c[3:0]})
                    {4'd7, 4'd4}:  begin
                        snake_data[r][c].valid <= 1'b1;
                        snake_data[r][c].tile_style <= LEFT_RIGHT;
                    end
                    {4'd7, 4'd5}:  begin
                        snake_data[r][c].valid <= 1'b1;
                        snake_data[r][c].tile_style <= LEFT_RIGHT;
                    end
                    {4'd7, 4'd6}:  begin
                        snake_data[r][c].valid <= 1'b1;
                        snake_data[r][c].tile_style <= LEFT_RIGHT;
                    end
                    {4'd7, 4'd7}:  begin
                        snake_data[r][c].valid <= 1'b1;
                        snake_data[r][c].tile_style <= LEFT_HEAD;
                    end
                    default: begin
                        snake_data[r][c].valid <= 1'b0;
                        snake_data[r][c].tile_style <= EMPTY;
                    end
                endcase
            end
        end
        // Only update the snake on the game_clk so it doesn't zoom across
        // the screen...
        else if(game_clk) begin
            // Only move the snake if a game has commenced
            if(snake_enable) begin
                // Snake has collided with apple, replace head and increment length
                if(grow) begin
                    snake_length <= snake_length + 7'd1;

                    // Update tiles
                end

                // just keep moving
                else begin
                    unique case (decoded_dir):
                        MOVE_UP:
                        MOVE_RIGHT:
                        MOVE_LEFT:
                        MOVE_DOWN:
                    endcase
                end
            end
        end
        else begin
            snake_data <= snake_data;
        end
    end

    

endmodule : Snake_Register

// 8-bit PRNG
// Generate "random" value between 0 -> 255 (256 tiles) to get next fruit pos
module PRNG (
    input logic clk, rst_n,
    input logic 
);

endmodule : PRNG