 /*
 * INPUT AND OUTPUT SPECIFICATIONS
 * 
 *
 * clock - Main clock signal for the controller. This signal is separate from
 *         the keyboard's clock signal, PS2_CLK. This input should be plugged
 *         into the same clock as the rest of the system is synchronized to.
 *
 * reset - Synchronous active-low reset signal. Resetting the controller will
 *         turn off all active keys. Calling a reset while holding keys on the
 *         keyboard may cause only the most recently pressed key to register
 *         again, as a consequence of keyboard protocol.
 *
 * PS2_CLK and PS2_DAT -
 *    These inputs correspond to the PS2_CLK and PS2_DAT signals from the board.
 *    Do NOT use PS2_CLK2 or PS2_DAT2 unless using a PS/2 splitter cable, or else
 *    neither input will be connected to anything.
 *
 * w, a, s, d, left, right, up, down, space, enter -
 *    Signals corresponding to WASD, the four arrow keys, the space bar, and
 *    enter. How these signals operate depends on the setting of PULSE_OR_HOLD.
 *
 *
 * #################
 * ACKNOWLEDGEMENTS
 * #################
 *
 * Credit for low-level PS/2 driver module (also a resource for PS/2 protocol):
 * http://www.eecg.toronto.edu/~jayar/ece241_08F/AudioVideoCores/ps2/ps2.html
 *
 */
 
module PS2_Keyboard_Controller( //main top level
    input CLOCK_50,
	 input resetn,
	 
	 inout PS2_CLK,
	 inout PS2_DAT,
	 
	 output left, right, up, down, space, enter, flag
	 );
	 
	 keyboard_tracker #(.PULSE_OR_HOLD(0)) tester( //use enable signals for each key, keyboard_tracker module detects data & break code
	     .clock(CLOCK_50),
		  .reset(resetn),
		  .PS2_CLK(PS2_CLK),
		  .PS2_DAT(PS2_DAT),
		  .w(up),
		  .a(left),
		  .s(down),
		  .d(right),
		  .up(flag),
		  .space(space),
		  .enter(enter)
		  );
endmodule
 
 
 
 //Any key can be implemented based on the format of the keys already made
module keyboard_tracker #(parameter PULSE_OR_HOLD = 0) (
    input clock,
	 input reset,
	 
	 inout PS2_CLK,
	 inout PS2_DAT,
	 
	 output w, a, s, d,
	 output left, right, up, down,
	 output space, enter
	 );
	 
	 // A flag indicating when the keyboard has sent a new byte.
	 wire byte_received;
	 // The most recent byte received from the keyboard.
	 wire [7:0] newest_byte;
	 	 
	 localparam // States indicating the type of code the controller expects
	            // to receive next.
	            MAKE            = 2'b00,
	            BREAK           = 2'b01,
					SECONDARY_MAKE  = 2'b10,
					SECONDARY_BREAK = 2'b11,
					
					// Make/break codes for all keys that are handled by this
					// controller. Two keys may have the same make/break codes
					// if one of them is a secondary code.
					// TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS	
					W_CODE = 8'h1d,
					A_CODE = 8'h1c,
					S_CODE = 8'h1b,
					D_CODE = 8'h23,
					LEFT_CODE  = 8'h6b,
					RIGHT_CODE = 8'h74,
					UP_CODE    = 8'h75,
					DOWN_CODE  = 8'h72,
					SPACE_CODE = 8'h29,
					ENTER_CODE = 8'h5a;
					
    reg [1:0] curr_state;
	 
	 // Press signals are high when their corresponding key is being pressed,
	 // and low otherwise. They directly represent the keyboard's state.
	 // TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS	 
    reg w_press, a_press, s_press, d_press;
	 reg left_press, right_press, up_press, down_press;
	 reg space_press, enter_press;
	 
	 // Lock signals prevent a key press signal from going high for more than one
	 // clock tick when pulse mode is enabled. A key becomes 'locked' as soon as
	 // it is pressed down.
	 // TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS
	 reg w_lock, a_lock, s_lock, d_lock;
	 reg left_lock, right_lock, up_lock, down_lock;
	 reg space_lock, enter_lock;
	 
	 // Output is equal to the key press wires in mode 0 (hold), and is similar in
	 // mode 1 (pulse) except the signal is lowered when the key's lock goes high.
	 // TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS
    assign w = w_press && ~(w_lock && PULSE_OR_HOLD);
    assign a = a_press && ~(a_lock && PULSE_OR_HOLD);
    assign s = s_press && ~(s_lock && PULSE_OR_HOLD);
    assign d = d_press && ~(d_lock && PULSE_OR_HOLD);

    assign left  = left_press && ~(left_lock && PULSE_OR_HOLD);
    assign right = right_press && ~(right_lock && PULSE_OR_HOLD);
    assign up    = up_press && ~(up_lock && PULSE_OR_HOLD);
    assign down  = down_press && ~(down_lock && PULSE_OR_HOLD);

    assign space = space_press && ~(space_lock && PULSE_OR_HOLD);
    assign enter = enter_press && ~(enter_lock && PULSE_OR_HOLD);
	 
	 // Core PS/2 driver.
	 PS2_Controller #(.INITIALIZE_MOUSE(0)) core_driver(
	     .CLOCK_50(clock),
		  .reset(~reset),
		  .PS2_CLK(PS2_CLK),
		  .PS2_DAT(PS2_DAT),
		  .received_data(newest_byte),
		  .received_data_en(byte_received)
		  );
		  
    always @(posedge clock) begin
	     // Make is default state. State transitions are handled
        // at the bottom of the case statement below.
		  curr_state <= MAKE;
		  
		  // Lock signals rise the clock tick after the key press signal rises,
		  // and fall one clock tick after the key press signal falls. This way,
		  // only the first clock cycle has the press signal high while the
		  // lock signal is low.
		  // TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS
		  w_lock <= w_press;
		  a_lock <= a_press;
		  s_lock <= s_press;
		  d_lock <= d_press;
		  
		  left_lock <= left_press;
		  right_lock <= right_press;
		  up_lock <= up_press;
		  down_lock <= down_press;
		  
		  space_lock <= space_press;
		  enter_lock <= enter_press;
		  
	     if (~reset) begin
		      curr_state <= MAKE;
				
				// TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS
				w_press <= 1'b0;
				a_press <= 1'b0;
				s_press <= 1'b0;
				d_press <= 1'b0;
				left_press  <= 1'b0;
				right_press <= 1'b0;
				up_press    <= 1'b0;
				down_press  <= 1'b0;
				space_press <= 1'b0;
				enter_press <= 1'b0;
				
				w_lock <= 1'b0;
				a_lock <= 1'b0;
				s_lock <= 1'b0;
				d_lock <= 1'b0;
				left_lock  <= 1'b0;
				right_lock <= 1'b0;
				up_lock    <= 1'b0;
				down_lock  <= 1'b0;
				space_lock <= 1'b0;
				enter_lock <= 1'b0;
        end
		  else if (byte_received) begin
		      // Respond to the newest byte received from the keyboard,
				// by either making or breaking the specified key, or changing
				// state according to special bytes.
				case (newest_byte)
				    // TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS
		          W_CODE: w_press <= curr_state == MAKE;
					 A_CODE: a_press <= curr_state == MAKE;
					 S_CODE: s_press <= curr_state == MAKE;
					 D_CODE: d_press <= curr_state == MAKE;
					 
					 LEFT_CODE:  left_press  <= curr_state == MAKE;
					 RIGHT_CODE: right_press <= curr_state == MAKE;
					 UP_CODE:    up_press    <= curr_state == MAKE;
					 DOWN_CODE:  down_press  <= curr_state == MAKE;
					 
					 SPACE_CODE: space_press <= curr_state == MAKE;
					 ENTER_CODE: enter_press <= curr_state == MAKE;

					 // State transition logic.
					 // An F0 signal indicates a key is being released. An E0 signal
					 // means that a secondary signal is being used, which will be
					 // followed by a regular set of make/break signals.
					 8'he0: curr_state <= SECONDARY_MAKE;
					 8'hf0: curr_state <= curr_state == MAKE ? BREAK : SECONDARY_BREAK;
		      endcase
        end
        else begin
		      // Default case if no byte is received.
		      curr_state <= curr_state;
		  end
    end
endmodule