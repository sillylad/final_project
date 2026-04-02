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


module Snake (
    input logic clk, rst_n,
    input logic game_clk,
    input logic start_game,
    input logic [3:0] dir,
    input logic [9:0] row, col,
    output logic [3:0] VGA_R, VGA_G, VGA_B,
    output logic buzz
);

    // 16x16 array of snake_tiles
    snake_tile [15:0][15:0] snake_data;

    // Stores the current snake data and updates the snake position as needed
    // Output snake_data array for use by other blocks
    Snake_Register (.clk(clk), .rst_n(rst_n), .game_clk(game_clk),
                    .dir(dir), .start_game(start_game),
                    .snake_data(snake_data));
    
    // Fruit

    // Scoring

    // Audio

    // Color

endmodule : Snake


module Snake_Register (
    input logic clk, rst_n, game_clk,
    input logic [3:0] dir, 
    input logic start_game,
    output snake_tile [15:0][15:0] snake_data;
);

    snake_tile [15:0][15:0] next_snake_data;

    // Update snake register
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
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
            snake_data <= next_snake_data;
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