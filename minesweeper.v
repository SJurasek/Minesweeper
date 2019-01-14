`timescale 1ns/1ns

module minesweeper
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,							// On Board Keys
		SW,							// On board Switches
		HEX0,							// On board HEX displays: 0 thru 5
		HEX1,							//
		HEX3,							//
		HEX2,							//
		HEX4,							//
		HEX5,							//
		LEDR,							// On board LEDs
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		PS2_CLK,
		PS2_DAT
	);

	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;
	input [9:0] SW;
	
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output [9:0] LEDR;
	
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [5:0] colour; // connection between game module and vga adapter
	wire [7:0] x; // vga x coordinate
	wire [6:0] y; // vga y coordinate
	wire writeEn; // vga write enable

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn), // global reset
			.clock(CLOCK_50), // 50MHz
			.colour(colour), // 6 bit colour
			.x(x),				// 8 bit x coordinate
			.y(y),				// 7 bit y coordinate
			.plot(writeEn),	// write to vga
			// Signals for the DAC to drive the monitor.
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 2; // define 2 bits per channel
	defparam VGA.BACKGROUND_IMAGE = "black.mif"; // background isnt really needed or used

	// Bidirectional connections for the PS2 keyboard
	inout				PS2_CLK;
	inout				PS2_DAT;
	
	wire [6:0] draw;
	// 0 - down; 1 - up; 2 - left; 3 - right; 4 - space; 5 - enter; 6 - flag;
	
	// PS2 keyboard module which sends controlled signals determined from ps2 keyboard signals
	PS2_Keyboard_Controller keycontrol(
		.CLOCK_50(CLOCK_50), //	50MHz clock
		.resetn(resetn),		//	global reset 
		.PS2_CLK(PS2_CLK),	//	
		.PS2_DAT(PS2_DAT),	//
		.left(draw[2]),		// Keyboard signals
		.right(draw[3]),		//	//
		.up(draw[1]),			// //
		.down(draw[0]),		// //
		.space(draw[4]),		// //
		.enter(draw[5]),		// //
		.flag(draw[6])			// //
	);
	
	// Non VGA outputs from the main game module
	wire [11:0] timer;
	wire ld_board, ld_mine, win;
	
	// Instance of the main game module
	grid_select G0( 
			.clock(CLOCK_50), 	// 50 MHz clock
			.resetn(resetn), 		// global reset
			
			.data_in(SW[8:0]),	// data_in for board size and num of mines
			
			.up(draw[1]), 				// Keyboard signals:
		 	.down(draw[0]), 			// 
			.left(draw[2]), 			// up, down, left, and right are WASD, respectively.
			.right(draw[3]), 			// clear is space bar
			.clear(draw[4]),			// click is enter
			.click(draw[5]),			// flag is up arrow (numpad up arrow only)
			.flag(draw[6]),			//
			
			.ld_board(ld_board), // load board size
			.ld_mine(ld_mine),	// load number of mines
			.win(win),				// win state is active i.e. game has been won
			
			.Xout(x), 				// VGA x coordinate
			.Yout(y),				// VGA y coordinate
			.ColourOut(colour), 	// VGA 6 bit colour
			.writeEn(writeEn),	// VGA write enable
			.timer(timer),			// game timer (scorekeeper)
			
	);
	
	// All on-board outputs
	
	// since i don't have backgrounds to prompt the user to enter board size, mine size, and display win
	// i need to use the LEDs to display which state it is in
	assign LEDR[4:0] = (win | ld_board) ? 5'b11111 : 5'b00000;
	assign LEDR[9:5] = (win | ld_mine) ? 5'b11111 : 5'b00000;
	
	// display the SW amount on the lower three HEX displays
	hex_decoder H0( .hex_digits(SW[3:0]), .segments(HEX0) );
	hex_decoder H1( .hex_digits(SW[7:4]), .segments(HEX1) );
	hex_decoder H2( .hex_digits({3'b000, SW[8]}), .segments(HEX2) );
	
	// display the timer on the upper three HEX displays
	// timer stops on win, resets on mine_reset, starts on an enter on the board
	hex_decoder H3( .hex_digits(timer[3:0]), .segments(HEX3) );
	hex_decoder H4( .hex_digits(timer[7:4]), .segments(HEX4) );
	hex_decoder H5( .hex_digits(timer[11:8]), .segments(HEX5) );
	
endmodule

// The main game managing module
// 
module grid_select
	(
		input clock, resetn,
		
		input up, down, left, right, clear, click, flag,
		input [8:0] data_in,
		
		output [7:0] Xout,
		output [6:0] Yout,
		output [5:0] ColourOut,
		output writeEn,
		output [11:0] timer,
		output ld_board, ld_mine, win
	);
	
	// ALL CONTROL SIGNALS //
	
	wire en_x, en_y, op_x, op_y; 									//
	wire plot_en, erase_en, clear_en, ld_clr;					
	
	wire countPul, grid_pulse, framePulse;						//
	
	wire mine_reset, mine_write, draw_mine, draw_click;	//
	wire mine_pulse, reset_pulse;									//
	wire en_mine_count, read_mine, en_shift;					//
	wire clickPul;														//
	wire [3:0] select_sprite;										//
	
	wire write_click;													//
	wire [8:0] reset_count;											//
	wire en_click_count;												//
	wire [3:0] tile;													//
	
	wire [8:0] second_address;										//
	wire ld_add, en_neighbour_count, en_neighbour;			//
	wire neighbour_pulse;											//
	wire [3:0] neighbour_count;									//
	wire en_back, background_pulse, backup, draw_badflag;	//
	wire is_mine;
	wire [8:0] Position;
	
	
	
	
	reg [4:0] boardX; 	// X board size register
	reg [3:0] boardY;		// Y board size register
	reg [8:0] num_mine;	// mine number register
	
	// X and Y board size loaded in parallel; 5 bits and 4 bits respectively
	always@(posedge clock)begin
		if(resetn == 1'b0)
			begin
				boardX <= 5'b00000;
				boardY <= 4'b0000;
			end
		else if(ld_board == 1'b1)
			begin
				boardX <= data_in[8:4]; // upper 5 switches control X size
				boardY <= data_in[3:0];	// lower 4 switches control y size
			end
	end
	
	// mine number loaded as a 9 bit register
	always@(posedge clock)begin
		if(resetn == 1'b0)
			num_mine <= 9'b000000000;
		else if(ld_mine == 1'b1)
			num_mine <= data_in;
	end
		
		
	assign writeEn = backup | en_back; // VGA write enable is high when plotting sprite or plotting background
	
	
	// Minesweeper FSM
	control C0 (
			.clock(clock),										//I//	50 MHz clock
			.resetn(resetn),									//I//
			
			.ld_board(ld_board),								//O// load board size
			.ld_mine(ld_mine),								//O// load mine number
			
			.boardX(boardX),									//I// x board size
			.boardY(boardY),									//I// y board size
			.num_mine(num_mine),								//I// number of mines
			.win(win),											//I// is win
			
			.up(up),												//I// move up
			.down(down),										//I// move down
			.left(left),										//I// move left
			.right(right),										//I// move right
			.clear(clear),										//I// space bar / clear board
			.click(click),										//I// enter key / click tile 
			.flag(flag),										//I// flag tile (up arrow)
			
			.countPul(countPul),								//I// sprite draw counter pulse
			.grid_pulse(grid_pulse),						//I// grid traverse counter pulse
			.framePulse(framePulse),						//I// frame pulse (1 framer for 60 fps)
			.reset_pulse(reset_pulse), //13				//I// 320 word RAM reset counter pulse
			
			.en_x(en_x),										//O// enable x cursor counter
			.en_y(en_y),										//O// enabler y cursor counter
			.op_x(op_x),										//O// 0: add 1: subtract from x cursor counter
			.op_y(op_y),										//O// 0: add 1: subtract from y cursor counter
			
			.is_mine(is_mine),								//I// signal if mine at position
			.mine_reset(mine_reset),						//O// game reset/clear data i.e. new game
			.draw_mine(draw_mine),							//O// draw mine sprite
			.draw_badflag(draw_badflag),					//O// draw badflag sprite
			.draw_click(draw_click),						//O// draw any other sprite on a click
			.mine_pulse(mine_pulse),						//I// mine generator counter pulse
			.mine_write(mine_write),						//O// write to mine RAM i.e. create new mine @ position
			
			.plot_en(plot_en),								//O// enable sprite drawing counter
			.erase_en(erase_en),								//O// 0: add red to sprite value or 1: not
			.clear_en(clear_en),								//O// enabler grid traversing counter
			.ld_clr(ld_clr), //27							//O// use the grid traverser position (1) or not (0)
			
			.en_mine_count(en_mine_count),				//O// increment number of mines generated
			.read_mine(read_mine),							//O// read from mine RAM
			.en_shift(en_shift),								//O// shift the LFSRs
			.write_click(write_click), //31				//O// write to the clicked tile RAM
			
			.en_click_count(en_click_count),				//O// enable number of clicks counter
			.clickPul(clickPul),							//I// clicks counter pulse (when this is sent the game is won)
			.timer(timer),										//O// timer
			.select_sprite(select_sprite),				//I// select which clicked sprite to draw
			.tile(tile),										//O// encoded tile status
			
			.ld_add(ld_add),									//O// load neighbouring coordinates to current pos
			.en_neighbour_count(en_neighbour_count),	//O// enable neighbouring mines counter
			.en_neighbour(en_neighbour),					//O// enabler neighbouring tile traverser counter
			.neighbour_count(neighbour_count),			//I// number of neighbouring mines count
			.neighbour_pulse(neighbour_pulse), //41	//I// neighbouring tile traverser counter
			
			.en_back(en_back),								//O// enabler black background counter
			.background_pulse(background_pulse)			//I// black background counter pulse
	);
	
	// main drawing and game state storage datapath
	datapath D0 (
			.clock(clock),								//I//
			.resetn(resetn),							//I//
			
			.countPul(countPul),						//O//
			.grid_pulse(grid_pulse), 				//O//
			.framePulse(framePulse),				//O//
			
			.boardX(boardX),							//I//
			.boardY(boardY),							//I//
			.num_mine(num_mine),						//I//
			
			.en_x(en_x),								//I//
			.en_y(en_y),								//I//
			.op_x(op_x),								//I//
			.op_y(op_y), //12							//I//
			
			.plot_en(plot_en),						//I//
			.erase_en(erase_en),						//I//
			.clear_en(clear_en),						//I//
			.ld_clr(ld_clr),							//I//
			
			.Position(Position),						//O// Position of interest (cursor, grid_select, or neighbours)
			
			.draw_mine(draw_mine),					//I//
			.draw_badflag(draw_badflag),			//I//
			.draw_click(draw_click),				//I//
			
			.writeEn(backup),							//O// backup is write enabler in parallel with 8x8 sprite colours
			
			.Xout(Xout),								//O// VGA X coordinate
			.Yout(Yout),								//O// VGA Y coordinate
			.ColourOut(ColourOut),					//O// VGA colour
			.mine_reset(mine_reset),				//I//
			
			.write_click(write_click),				//I//
			.reset_count(reset_count),				//I// 320 word click RAM reset (increments over each address)
			.select_sprite(select_sprite),		//O//
			
			.en_click_count(en_click_count),		//I//
			.clickPul(clickPul),						//O//
			.tile(tile), //30							//I//
			.second_address(second_address),		//O// Address (board position) associated with neighbour
			.en_neighbour(en_neighbour),			//I//
			.neighbour_pulse(neighbour_pulse), 	//O//
			
			.en_back(en_back),						//I//
			.background_pulse(background_pulse)	//O//
	);	
	
	// mine data storage and processing datapath
	mine_datapath D1 (
			.clock(clock),										//I//
			.resetn(resetn),									//I//
			
			.mine_reset(mine_reset),						//I//
			.en_write(mine_write),							//I//
			.en_shift(en_shift),								//I//
			
			.boardX(boardX),									//I//
			.boardY(boardY),									//I//
			.num_mine(num_mine),								//I//
			
			.position(Position),								//I//
			
			.is_mine(is_mine), // 10						//O//
			.mine_pulse(mine_pulse),						//O//
			.reset_pulse(reset_pulse),						//O//
			
			.read_mine(read_mine),							//I//
			.en_count(en_mine_count),						//I//
			.reset_count(reset_count),						//O//
			.second_address(second_address),				//I//
			.ld_add(ld_add),									//I//
			.en_neighbour_count(en_neighbour_count),	//I//
			.neighbour_count(neighbour_count) //19		//O//
	);
	
endmodule


// control for grid_select
module control
	(
		input clock, resetn,
		
		input [4:0] boardX,
		input [3:0] boardY,
		input [8:0] num_mine,
		
		input countPul, grid_pulse, framePulse, mine_pulse, reset_pulse,
		input up, down, left, right, clear, click, flag,
		input is_mine,
		input [3:0] select_sprite,
		input clickPul,
		input neighbour_pulse,
		input [3:0] neighbour_count,
		input background_pulse,
		
		output reg en_x, en_y,
		output reg op_x, op_y,
		output reg plot_en, clear_en, ld_clr, mine_reset, mine_write,
		output reg erase_en, draw_mine, draw_click, en_shift,
		output reg read_mine, en_mine_count,
		output reg write_click,
		output reg [11:0] timer,
		output reg en_click_count,
		output reg win,
		output reg [3:0] tile,
		output reg ld_add, en_neighbour_count, en_neighbour,
		output reg ld_board, ld_mine,
		output reg en_back, draw_badflag
		
	);
	
	reg firstn; // first move indicator
	reg [5:0] current_state, next_state;
	
	localparam 	S_DRAW_BACK 		= 6'd0, 	// draw a black background
					S_START_BOARD		= 6'd1, 	// take switch input for board size
					S_START_BOARD_WAIT= 6'd2, 	// wait for click release
					S_START_MINE		= 6'd3, 	// take switch input for num of mines
					S_START_MINE_WAIT	= 6'd4, 	// wait for click release
					S_ERASE_GRID 		= 6'd5, 	// Draw default grid sprite
					S_INCR_GRID			= 6'd6, 	// increment grid select
					S_CLEAR_WAIT		= 6'd7, 	// reset game state and go erase grid
					S_WAIT				= 6'd8, 	// wait for user input
					S_ERASE_UP			= 6'd9, 	// // Draw original sprite without cursor highlight
					S_ERASE_DOWN		= 6'd10, // // do the same as previous
					S_ERASE_LEFT		= 6'd11, // // same thing
					S_ERASE_RIGHT		= 6'd12, // // Needs to remember which direction was clicked that's it
					S_INCR_UP			= 6'd13, // Incr cursor up
					S_INCR_DOWN			= 6'd14, // incr cursor down
					S_INCR_LEFT			= 6'd15,	// incr cursor left
					S_INCR_RIGHT		= 6'd16,	// incr cursor right
					S_READ_DRAW 		= 6'd17,	// read from click RAM to determine which sprite to draw at location
					S_DRAW				= 6'd18,	// draw the sprite
					S_DRAW_WAIT			= 6'd19,	// after drawing, wait for key release
					S_FRAME_WAIT		= 6'd20,	// wait for a frame. nothing happens here
					S_READ_MINE			= 6'd21,	// read from mine RAM
					S_READ_MINE_WAIT	= 6'd22,	// mine RAM has been read, process is_mine
					S_SHIFT_MINE		= 6'd23, // shift LFSRs, then go to read mine
					S_GENERATE			= 6'd24, // creates a new mine in RAM and increments mine count
					S_DRAW_MINE_R		= 6'd25,	// draw a mine at positon
					S_INCR_PLOT_FAIL	= 6'd26, // upon game over, traverse grid to find mines
					S_LOAD_MINE			= 6'd27, // read from mine RAM and click RAM (after game over)
					S_LOAD_MINE_WAIT 	= 6'd28, // determine to draw mine or badflag
					S_DRAW_BADFLAG		= 6'd29, // draw a badflag at position (game over)
					S_FAIL_WAIT			= 6'd30, // wait for a new game after game over
					S_WRITE_CLICK 		= 6'd31, // write to click RAM the data of the current tile
					S_WIN					= 6'd32, // win state. wait for game reset
					S_WRITE_FLAG		= 6'd33, // write to click RAM flag data
					S_REMOVE_FLAG		= 6'd34, // write to click RAM default data
					S_INCR_LOCAL		= 6'd35, // traverse through tile neighbours
					S_CHECK_LOCAL		= 6'd36, // check tile neighbour for mine
					S_INCR_ADDMINE		= 6'd37, // if a neighbour has a mine, incr neighbour count
					S_LOCAL_WAIT		= 6'd38; // read from mine RAM, then check local
					
					
					
	// State Table
	always@(*)
	begin: state_table
		case(current_state)
			S_DRAW_BACK: next_state = background_pulse ? S_START_BOARD : S_DRAW_BACK;
			S_START_BOARD: next_state = (boardX <= 5'd20 && boardX > 5'd0 && boardY > 4'd0 && boardY < 4'd14) ? (click ? S_START_BOARD_WAIT : S_START_BOARD) : S_START_BOARD;
			S_START_BOARD_WAIT: next_state = click ? S_START_BOARD_WAIT : S_START_MINE;
			S_START_MINE: next_state = (num_mine < (boardX * boardY - 9'd1)) ? ( click ? S_START_MINE_WAIT : S_START_MINE ) : S_START_MINE;
			S_START_MINE_WAIT: next_state = click ? S_START_MINE_WAIT : S_CLEAR_WAIT;
			S_ERASE_GRID: next_state = countPul ? S_INCR_GRID : S_ERASE_GRID;
			S_INCR_GRID: next_state = grid_pulse ? S_READ_DRAW : S_ERASE_GRID;
			S_CLEAR_WAIT: next_state = reset_pulse ? S_ERASE_GRID : S_CLEAR_WAIT;
			S_WAIT:
				begin
					if(clickPul == 1'b1)
						next_state = S_WIN;
					else if(up == 1'b1)
						next_state = S_ERASE_UP;
					else if(down == 1'b1)
						next_state = S_ERASE_DOWN;
					else if(left == 1'b1)
						next_state = S_ERASE_LEFT;
					else if(right == 1'b1)
						next_state = S_ERASE_RIGHT;
					else if(clear == 1'b1)
						next_state = S_CLEAR_WAIT;
					else if(flag == 1'b1 && select_sprite == 4'd0 && firstn == 1'b1)
						next_state = S_WRITE_FLAG;
					else if(flag == 1'b1 && select_sprite == 4'd10 && firstn == 1'b1)
						next_state = S_REMOVE_FLAG;
					else if(click == 1'b1 && firstn == 1'b0 && select_sprite == 4'd0)
						next_state = S_READ_MINE;
					else if(click == 1'b1 && firstn == 1'b1 && is_mine == 1'b0 && select_sprite == 4'd0)
						next_state = S_LOCAL_WAIT; // if it hasnt been clicked yet write the click
					else if(click == 1'b1 && firstn == 1'b1 && is_mine == 1'b1 && select_sprite == 4'd0)
						next_state = S_LOAD_MINE;
					else
						next_state = S_WAIT;
				end
			S_ERASE_UP: next_state = countPul ? S_INCR_UP : S_ERASE_UP;
			S_ERASE_DOWN: next_state = countPul ? S_INCR_DOWN : S_ERASE_DOWN;
			S_ERASE_LEFT: next_state = countPul ? S_INCR_LEFT : S_ERASE_LEFT;
			S_ERASE_RIGHT: next_state = countPul ? S_INCR_RIGHT : S_ERASE_RIGHT;
			S_INCR_UP: next_state = S_READ_DRAW;
			S_INCR_DOWN: next_state = S_READ_DRAW;
			S_INCR_LEFT: next_state = S_READ_DRAW;
			S_INCR_RIGHT: next_state = S_READ_DRAW;
			S_DRAW: next_state = countPul ? S_DRAW_WAIT : S_DRAW;
			S_DRAW_WAIT: next_state = ( up == 1'b0 && down == 1'b0 && left == 1'b0 && right == 1'b0 && click == 1'b0 && clear == 1'b0 && flag == 1'b0) ? S_FRAME_WAIT : S_DRAW_WAIT;
			S_FRAME_WAIT: next_state = framePulse ? S_WAIT : S_FRAME_WAIT;
			S_READ_MINE: next_state = S_READ_MINE_WAIT;
			S_READ_MINE_WAIT: next_state = is_mine ? S_SHIFT_MINE : S_GENERATE;
			S_SHIFT_MINE : next_state = S_READ_MINE;
			S_GENERATE: next_state = mine_pulse ? S_LOCAL_WAIT : S_READ_MINE;
			S_WRITE_CLICK: next_state = S_READ_DRAW;
			S_READ_DRAW: next_state = S_DRAW;
			S_LOAD_MINE: next_state = S_LOAD_MINE_WAIT;
			S_LOAD_MINE_WAIT: next_state = is_mine ? S_DRAW_MINE_R : ((select_sprite == 4'd10) ? S_DRAW_BADFLAG : S_INCR_PLOT_FAIL);
			S_DRAW_MINE_R: next_state = countPul ? S_INCR_PLOT_FAIL : S_DRAW_MINE_R;
			S_INCR_PLOT_FAIL: next_state = grid_pulse ? S_FAIL_WAIT : S_LOAD_MINE;
			S_FAIL_WAIT: next_state = clear ? S_CLEAR_WAIT : S_FAIL_WAIT;
			S_WIN: next_state = clear ? S_CLEAR_WAIT : S_WIN;
			S_WRITE_FLAG: next_state = S_READ_DRAW;
			S_REMOVE_FLAG: next_state = S_READ_DRAW;
			S_LOCAL_WAIT: next_state = S_CHECK_LOCAL;
			S_INCR_LOCAL: next_state = neighbour_pulse ? S_WRITE_CLICK : S_LOCAL_WAIT;
			S_CHECK_LOCAL: next_state =  is_mine ? S_INCR_ADDMINE : S_INCR_LOCAL;
			S_INCR_ADDMINE: next_state = S_INCR_LOCAL;
			S_DRAW_BADFLAG: next_state = countPul ? S_INCR_PLOT_FAIL : S_DRAW_BADFLAG;
			default: next_state = S_DRAW_BACK;
		endcase
	end
	
	// Output signals
	always@(*)
	begin: enable_signals
		en_x = 1'b0;
		en_y = 1'b0;
		op_x = 1'b0;
		op_y = 1'b0;
		plot_en = 1'b0;
		erase_en = 1'b0;
		clear_en = 1'b0;
		ld_clr = 1'b0;
		mine_reset = 1'b0;
		mine_write = 1'b0;
		draw_mine = 1'b0;
		draw_click = 1'b0;
		en_shift = 1'b0;
		read_mine = 1'b0;
		en_mine_count = 1'b0;
		write_click = 1'b0;
		en_click_count = 1'b0;
		win = 1'b0;
		tile = 4'b0000;
		ld_add = 1'b0;
		en_neighbour = 1'b0;
		en_neighbour_count = 1'b0;
		ld_board = 1'b0;
		ld_mine = 1'b0;
		en_back = 1'b0;
		draw_badflag = 1'b0;
		
		case(current_state)
			S_DRAW_BACK: en_back = 1'b1;
			S_START_BOARD: ld_board = 1'b1;
			S_START_MINE: ld_mine = 1'b1;
			S_ERASE_GRID:
				begin
					erase_en = 1'b1;
					plot_en = 1'b1;
					ld_clr = 1'b1;
				end
			S_INCR_GRID:
				begin
					erase_en = 1'b1;
					clear_en = 1'b1;
					ld_clr = 1'b1;
				end
			S_CLEAR_WAIT: mine_reset = 1'b1;
			S_WAIT: en_shift = 1'b1;
			S_ERASE_UP:
				begin
					erase_en = 1'b1;
					plot_en = 1'b1;
				end
			S_ERASE_DOWN:
				begin
					erase_en = 1'b1;
					plot_en = 1'b1;
				end
			S_ERASE_LEFT:
				begin
					erase_en = 1'b1;
					plot_en = 1'b1;
				end
			S_ERASE_RIGHT:
				begin
					erase_en = 1'b1;
					plot_en = 1'b1;
				end
			S_INCR_UP:
				begin
					erase_en = 1'b1;
					en_y = 1'b1;
					op_y = 1'b1;
				end
			S_INCR_DOWN:
				begin
					erase_en = 1'b1;
					en_y = 1'b1;
					op_y = 1'b0;
				end
			S_INCR_LEFT:
				begin
					erase_en = 1'b1;
					en_x = 1'b1;
					op_x = 1'b1;
				end
			S_INCR_RIGHT:
				begin
					erase_en = 1'b1;
					en_x = 1'b1;
					op_x = 1'b0;
				end
			S_DRAW: plot_en = 1'b1;
			S_READ_MINE: read_mine = 1'b1;
			S_READ_MINE_WAIT: read_mine = 1'b1;
			S_SHIFT_MINE: en_shift = 1'b1;
			S_GENERATE:
				begin
					mine_write = 1'b1;
					en_mine_count = 1'b1;
					read_mine = 1'b1;
				end
			S_WRITE_CLICK:
				begin
					write_click = 1'b1;
					en_click_count = 1'b1;
					tile = (neighbour_count == 4'b0000) ? 4'd9 : neighbour_count;
				end
			S_INCR_LOCAL:
				begin
					ld_add = 1'b1;
					en_neighbour = 1'b1;
				end
			S_LOCAL_WAIT: ld_add = 1'b1;
			S_CHECK_LOCAL: ld_add = 1'b1;
			S_INCR_ADDMINE:
				begin
					ld_add = 1'b1;
					en_neighbour_count = 1'b1;
				end
			S_LOAD_MINE: ld_clr = 1'b1;
			S_LOAD_MINE_WAIT: ld_clr = 1'b1;
			S_DRAW_MINE_R:
				begin
					draw_mine = 1'b1;
					plot_en = 1'b1;
					ld_clr = 1'b1;
				end
			S_DRAW_BADFLAG:
				begin
					draw_badflag = 1'b1;
					plot_en = 1'b1;
					ld_clr = 1'b1;
				end
			S_INCR_PLOT_FAIL:
				begin
					clear_en = 1'b1;
					ld_clr = 1'b1;
				end
			S_WIN: win = 1'b1;
			S_WRITE_FLAG:
				begin
					write_click = 1'b1;
					tile = 4'd10;
				end
			S_REMOVE_FLAG:
				begin
					write_click = 1'b1;
					tile = 4'd0;
				end
		endcase
	end
	
	// State FFs
	always@(posedge clock)
	begin: state_FFs
		if(resetn == 1'b0)
			current_state <= S_DRAW_BACK;
		else
			current_state <= next_state;
	end
	
	// register to hold if first move has occurred yet
	always@(posedge clock)begin
		if(resetn == 1'b0 || mine_reset == 1'b1)
			firstn <= 1'b0;
		else if(click == 1'b1 && current_state == S_WAIT) // upon pressing enter during game, timer starts
			firstn <= 1'b1;
	end
	
	wire second_pulse; // pulse that counts one second
	
	// timer counter
	always@(posedge clock)begin
		if(resetn == 1'b0 || mine_reset == 1'b1)
			timer <= 12'b000000000000;
		else if(second_pulse == 1'b1 && firstn == 1'b1 && win == 1'b0) // timer counts every second after first click, and game isnt over
			timer <= timer + 1;
	end
	
	// Rate divider instance. Kind of copied from Lab 5.
	RateDivider RATE1(.R(26'b10111110101111000001111111), .Clock(clock), .Qpul(second_pulse) );

endmodule


// datapath for grid select
module datapath
	(
		input clock, resetn,
		
		input en_x, en_y,
		input op_x, op_y,
		input plot_en, erase_en, clear_en, ld_clr, //10
		input draw_click, draw_mine, draw_badflag,
		input en_back, draw_back,
		
		input write_click,
		input mine_reset,
		input [8:0] reset_count,
		
		input [4:0] boardX,
		input [3:0] boardY,
		input [8:0] num_mine,
		input [3:0] tile, //19
		
		input en_click_count, en_neighbour,
		
		output countPul, grid_pulse, framePulse, clickPul,
		
		output reg writeEn,
		
		output [8:0] Position,
		
		output [5:0] ColourOut, //28
		output [6:0] Yout,
		output [7:0] Xout,
		output [3:0] select_sprite,
		output [8:0] second_address,
		output neighbour_pulse, //33
		output background_pulse
	);
	
	reg [4:0] grid_x;
	reg [3:0] grid_y;
	reg [8:0] grid_count;
	reg [5:0] plot_count;
	reg [5:0] address;
	
	reg eraser, clickr, miner, badder;
	reg [8:0] click_count;
	reg [11:0] msg_count;
	reg [14:0] background_count;
	reg [7:0] background_count_x;
	reg [6:0] background_count_y;
	
	// Sprite wires
	wire [5:0] grey_square; // correspond to outputs of RAM module
	wire [5:0] sprite_1;
	wire [5:0] sprite_2;
	wire [5:0] sprite_3;
	wire [5:0] sprite_4;
	wire [5:0] sprite_5;
	wire [5:0] sprite_6;
	wire [5:0] sprite_7;
	wire [5:0] sprite_8;
	wire [5:0] sprite_click;
	wire [5:0] sprite_flag;
	wire [5:0] sprite_mine;
	wire [5:0] sprite_badflag;
	
	wire [8:0] Xpos; // position of pixel on the VGA
	wire [7:0] Ypos; // position of pixel on the VGA
	
	reg [5:0] pixel; // pixel colour
	
	reg [2:0] neighbour_sel;
	reg [3:0] neighbour_add;
	
	// X position on the grid
	always@(posedge clock)begin
		if(resetn == 1'b0 || grid_pulse == 1'b1)
			grid_x <= 5'b00000;
		else if(en_x == 1'b1)
			begin
				if(op_x == 1'b0)
					begin
						if(grid_x == boardX - 1)
							grid_x <= 5'b00000;
						else
							grid_x <= grid_x + 1;
					end
				else
					begin
						if(grid_x == 5'b00000)
							grid_x <= boardX - 1;
						else
							grid_x <= grid_x - 1;
					end
			end
	end
	
	// Y position on the grid
	always@(posedge clock)begin
		if(resetn == 1'b0 || grid_pulse == 1'b1)
			grid_y <= 4'b0000;
		else if(en_y == 1'b1)
			begin
				if(op_y == 1'b0)
					begin
						if(grid_y == boardY - 1)
							grid_y <= 4'b0000;
						else
							grid_y <= grid_y + 1;
					end
				else
					begin
						if(grid_y == 4'b0000)
							grid_y <= boardY - 1;
						else
							grid_y <= grid_y - 1;
					end
			end
	end
	
	assign Position = {(ld_clr ? grid_count[8:4] : grid_x), (ld_clr ? grid_count[3:0] : grid_y)};
	
	assign Xpos = (ld_clr ? grid_count[8:4] : grid_x) * 4'b1000;
	assign Ypos = (ld_clr ? grid_count[3:0] : grid_y) * 4'b1000;
	
	assign Xout = en_back ? background_count_x : (Xpos + plot_count[2:0] + 8'd80 - (5'd8 * (boardX >> 1))); // shift to centre of screen
	assign Yout = en_back ? background_count_y : (Ypos + plot_count[5:3] + 7'd60 - (4'd8 * (boardY >> 1))); // shift to centre of screen (48, 28)
	
	// registers for x and y colours by pixel, as well as erase_en
	// for Xout and Yout and eraser
	always@(posedge clock)begin
		if(resetn == 1'b0)
			begin
				eraser <= 1'b0;
				miner <= 1'b0;
				plot_count <= 6'b000000;
				writeEn <= 1'b0;
				badder <= 1'b0;
			end
		else
			begin
				eraser <= erase_en; // eraser is just a clock cycle behind erase_en
				miner <= draw_mine;
				plot_count <= address;
				writeEn <= plot_en;
				badder <= draw_badflag;
			end
	end
	
	// Plot counter
	always@(posedge clock)begin
		if(resetn == 1'b0)
			address <= 6'b000000;
		else if(plot_en == 1'b1)
			address <= address + 1;
	end
	
	assign countPul = (address == 6'b111111) ? 1'b1 : 1'b0;
	
	always@(posedge clock)begin
		if(resetn == 1'b0)
			grid_count <= 9'b000000000;
		else if(clear_en == 1'b1)
			begin
				if(grid_count[3:0] == boardY - 1)
					begin
						if(grid_count[8:4] == boardX - 1)
							grid_count[8:4] <= 5'b00000;
						else
							grid_count[8:4] <= grid_count[8:4] + 1;
						grid_count[3:0] <= 4'b0000;
					end
				else
					grid_count[3:0] <= grid_count[3:0] + 1;
			end
	end
	
	assign grid_pulse = (grid_count[8:4] == boardX - 1 && grid_count[3:0] == boardY - 1) ? 1'b1 : 1'b0;
	
	
	// Colour management
	
	// RAM Modules
	grey_square_64x6 RAM1( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(grey_square)); // RAM for a grey square image
	click_sprite_64x6 RAM2( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_click));
	mine_sprite_64x6 RAM3( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_mine));
	flag_sprite_64x6 RAM4( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_flag));
	badflag_sprite_64x6 RAM5( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_badflag));
	one_sprite_64x6 RAM6( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_1));
	two_sprite_64x6 RAM7( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_2));
	three_sprite_64x6 RAM8( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_3));
	four_sprite_64x6 RAM9( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_4));
	five_sprite_64x6 RAM10( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_5));
	six_sprite_64x6 RAM11( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_6));
	seven_sprite_64x6 RAM12( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_7));
	eight_sprite_64x6 RAM13( .address(address), .clock(clock), .data(6'b000000), .wren(1'b0), .q(sprite_8));
	
	
	// MUX
	//assign ColourOut = clickr ? 6'b111111 : (miner ? (6'b011101) : (eraser ? grey_square : {2'b11, grey_square[3:0]}));
	assign ColourOut = en_back ? 6'b000000 : (miner ? ( (select_sprite == 4'd10) ? sprite_flag : sprite_mine ) : (badder ? sprite_badflag : ( eraser ? pixel : pixel + 6'b110000) ) );
	//
	// Rate Divider the counts 1 frame
	RateDivider RATE0(.R(26'd833333), .Clock(clock), .Qpul(framePulse));
	
	
	always@(*)begin
		case(select_sprite)
			4'd0: pixel = grey_square;
			4'd1: pixel = sprite_1;
			4'd2: pixel = sprite_2;
			4'd3: pixel = sprite_3;
			4'd4: pixel = sprite_4;
			4'd5: pixel = sprite_5;
			4'd6: pixel = sprite_6;
			4'd7: pixel = sprite_7;
			4'd8: pixel = sprite_8;
			4'd9: pixel = sprite_click;
			4'd10: pixel = sprite_flag;
			default: pixel = 6'b000000;
		endcase
	end
	
	// Click storage
	click_data_320x4 BIGINFO
	(
			.clock(clock),
			.wren(mine_reset | write_click), // wren should be enabled on mine_reset or 
			.address(mine_reset ? reset_count : Position),
			.data(mine_reset ? 4'b0000 : tile), // either 0 or the number at that position
			.q(select_sprite)
	);
	
	// Count number of unique clicks
	always@(posedge clock)begin
		if(resetn == 1'b0 || mine_reset == 1'b1)
			click_count <= 9'd0;
		else if(en_click_count == 1'b1)
			begin
				if(click_count == boardX * boardY - num_mine)
					click_count <= 9'd0; // redundant since it will be reset after win state
				else
					click_count <= click_count + 1;
			end
	end
	
	assign clickPul = (click_count == boardX * boardY - num_mine) ? 1'b1 : 1'b0;
	
	always@(posedge clock)begin
		if(resetn == 1'b0 || mine_reset == 1'b1)
			neighbour_sel <= 3'b000;
		else if(en_neighbour == 1'b1)
			neighbour_sel <= neighbour_sel + 1;
	end
	
	assign neighbour_pulse = (neighbour_sel == 3'b111) ? 1'b1 : 1'b0;
	
	
//	always@(*)begin
//		case(neighbour_sel)
//			3'b000: neighbour_add = (grid_x == 5'b00000 || grid_y == 4'b0000) ? 4'b0101 : 4'b0000;
//			3'b001: neighbour_add = (grid_x == 5'b00000) ? 4'b0101 : 4'b0001;
//			3'b010: neighbour_add = {(grid_x == 5'b00000) ? 2'b01: 2'b00, (grid_y == boardY - 1) ? 2'b01: 2'b10};
//			3'b011: neighbour_add = (grid_y == 4'b0000) ? 4'b0101 : 4'b0100;
//			3'b100: neighbour_add = (grid_y == boardY - 1) ? 4'b0101 : 4'b0110;
//			3'b101: neighbour_add = {(grid_x == boardX - 1) ? 2'b01: 2'b10, (grid_y == 4'b0000) ? 2'b01: 2'b00};
//			3'b110: neighbour_add = (grid_x == boardX - 1) ? 4'b0101 : 4'b1001;
//			3'b111: neighbour_add = (grid_x == boardX - 1 || grid_y == boardY - 1) ? 4'b0101 : 4'b1010;
//			default: neighbour_add = 4'b0101;
//		endcase
//	end
	
	always@(*)begin
		case(neighbour_sel)
			3'b000: neighbour_add = 4'b0000;
			3'b001: neighbour_add = 4'b0001;
			3'b010: neighbour_add = 4'b0010;
			3'b011: neighbour_add = 4'b0100;
			3'b100: neighbour_add = 4'b0110;
			3'b101: neighbour_add = 4'b1000;
			3'b110: neighbour_add = 4'b1001;
			3'b111: neighbour_add = 4'b1010;
			default: neighbour_add = 4'b0000;
		endcase
	end
	
	assign second_address[8:4] = grid_x - 1 + neighbour_add[3:2];
	assign second_address[3:0] = grid_y - 1 + neighbour_add[1:0];

	always@(posedge clock)begin
		if(resetn == 1'b0)
			begin
				background_count_x <= 8'b00000000;
				background_count_y <= 7'b0000000;
			end
		else if(en_back == 1'b1)
			begin
				if(background_count_y == 7'd119)
					begin
						if(background_count_x == 8'd159)
							background_count_x <= 8'b00000000;
						else
							background_count_x <= background_count_x + 8'd1;
						background_count_y <= 7'b0000000;
					end
				else
					background_count_y <= background_count_y + 7'd1;
			end
	end
	
	assign background_pulse = (background_count_y == 7'd119 && background_count_x == 8'd159) ? 1'b1 : 1'b0;
//	
//	//black_background_19200x6 RAM17( .address(msg_count), .clock(clock), .data(6'b000000), .wren(1'b0), .q(black_background) );
	assign black_background = 6'b000000;
	
endmodule

// Rate divider which provides a signal that a frame has passed
module RateDivider(input [25:0] R, input Clock, output Qpul); // reset is needed for simulations
	
	reg [25:0] Q;
	
	always@(posedge Clock)begin
		if(Qpul == 1'b1) // When pulse is sent, reset to R!
			Q <= R;
		else
			Q <= Q-1;
	end
	
	assign Qpul = ~|Q; // NOR of all bits of Q, when Q is 0
	
endmodule

// Seven segment decoder
module hex_decoder(input [3:0] hex_digits, output reg [6:0] segments);
	
	always @(*)begin
        case (hex_digits)
            4'h0: segments = 7'b1000000;
            4'h1: segments = 7'b1111001;
            4'h2: segments = 7'b0100100;
            4'h3: segments = 7'b0110000;
            4'h4: segments = 7'b0011001;
            4'h5: segments = 7'b0010010;
            4'h6: segments = 7'b0000010;
            4'h7: segments = 7'b1111000;
            4'h8: segments = 7'b0000000;
            4'h9: segments = 7'b0011000;
            4'hA: segments = 7'b0001000;
            4'hB: segments = 7'b0000011;
            4'hC: segments = 7'b1000110;
            4'hD: segments = 7'b0100001;
            4'hE: segments = 7'b0000110;
            4'hF: segments = 7'b0001110;   
            default: segments = 7'h7f;
		  endcase
	end
	
endmodule


