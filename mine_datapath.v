`timescale 1ns/1ns

module mine_datapath
	(
		input clock, resetn,
		input mine_reset, en_write, en_shift,
		input [8:0] position,
		input read_mine, en_count, //8
		
		input [4:0] boardX,
		input [3:0] boardY,
		input [8:0] num_mine,
		
		input [8:0] second_address,
		input ld_add,
		input en_neighbour_count,
		
		output reg [3:0] neighbour_count,
		output is_mine,
		output mine_pulse,
		output reset_pulse,
		output reg [8:0] reset_count //19
	);
	
	
	wire [31:0] mine0, mine1, mine2, mine3, mine4, mine5, mine6, mine7, mine8, mine9;
	wire [31:0] mine10, mine11, mine12, mine13, mine14, mine15, mine16, mine17, mine18, mine19;
	wire [31:0] mine20, mine21, mine22, mine23, mine24, mine25, mine26, mine27, mine28, mine29;
	// individual mines without certain repeats max is 105
	
	reg [8:0] mine_count;
	wire [6:0] select;
	reg [8:0] mine_site;
	reg [4:0] mine_site_x;
	reg [3:0] mine_site_y;
	
	assign select = mine_count[6:0];
	
	wire data_out;
	
	assign is_mine = 	data_out | (read_mine == 1'b1 && position[8:4] == mine_site_x && position[3:0] ==  mine_site_y) ? ( 1'b1 ) : ( 1'b0 ); // either dataout is 1 which represents a mine or fakes a mine on mine writing if the coordinate matches the mine site
	assign mine_pulse = (mine_count == num_mine - 1)?1'b1:1'b0;
	assign reset_pulse = (reset_count == 9'd319)?1'b1:1'b0;
	
	always@(posedge clock)begin
		if(resetn == 1'b0 || mine_reset == 1'b1 || ld_add == 1'b0)
			neighbour_count <= 4'b0000;
		else if(en_neighbour_count == 1'b1)
			neighbour_count <= neighbour_count + 1;
	end
	
	// two 32 bit LSFRs with different seeds
	LFSR_32bit L0( .clock(clock), .resetn(resetn), .seed(32'hFE37C0DE), .ld(mine_reset), .en(en_shift), .q(mine0) );
	LFSR_32bit L1( .clock(clock), .resetn(resetn), .seed(32'hDAD50A55), .ld(mine_reset), .en(en_shift), .q(mine1) );
	LFSR_32bit L2( .clock(clock), .resetn(resetn), .seed(32'hB007E8CA), .ld(mine_reset), .en(en_shift), .q(mine2) );
	LFSR_32bit L3( .clock(clock), .resetn(resetn), .seed(32'hADD5D0E5), .ld(mine_reset), .en(en_shift), .q(mine3) );
	LFSR_32bit L4( .clock(clock), .resetn(resetn), .seed(32'h12345678), .ld(mine_reset), .en(en_shift), .q(mine4) );
	LFSR_32bit L5( .clock(clock), .resetn(resetn), .seed(32'h10FEDCBA), .ld(mine_reset), .en(en_shift), .q(mine5) );
	LFSR_32bit L6( .clock(clock), .resetn(resetn), .seed(32'hB3384CFA), .ld(mine_reset), .en(en_shift), .q(mine6) );
	LFSR_32bit L7( .clock(clock), .resetn(resetn), .seed(32'hFFFFFFFF), .ld(mine_reset), .en(en_shift), .q(mine7) );
	LFSR_32bit L8( .clock(clock), .resetn(resetn), .seed(32'hC0041EE5), .ld(mine_reset), .en(en_shift), .q(mine8) );
	LFSR_32bit L9( .clock(clock), .resetn(resetn), .seed(32'hF33D008E), .ld(mine_reset), .en(en_shift), .q(mine9) );
	LFSR_32bit L10( .clock(clock), .resetn(resetn), .seed(32'h8152FAD4), .ld(mine_reset), .en(en_shift), .q(mine10) );
	LFSR_32bit L11( .clock(clock), .resetn(resetn), .seed(32'h7067CE72), .ld(mine_reset), .en(en_shift), .q(mine11) );
	LFSR_32bit L12( .clock(clock), .resetn(resetn), .seed(32'h7503E68A), .ld(mine_reset), .en(en_shift), .q(mine12) );
	LFSR_32bit L13( .clock(clock), .resetn(resetn), .seed(32'hAF686E20), .ld(mine_reset), .en(en_shift), .q(mine13) );
	LFSR_32bit L14( .clock(clock), .resetn(resetn), .seed(32'h51267950), .ld(mine_reset), .en(en_shift), .q(mine14) );
	LFSR_32bit L15( .clock(clock), .resetn(resetn), .seed(32'h6671111C), .ld(mine_reset), .en(en_shift), .q(mine15) );
	LFSR_32bit L16( .clock(clock), .resetn(resetn), .seed(32'h851972A6), .ld(mine_reset), .en(en_shift), .q(mine16) );
	LFSR_32bit L17( .clock(clock), .resetn(resetn), .seed(32'h2A910CD1), .ld(mine_reset), .en(en_shift), .q(mine17) );
	LFSR_32bit L18( .clock(clock), .resetn(resetn), .seed(32'hCA851569), .ld(mine_reset), .en(en_shift), .q(mine18) );
	LFSR_32bit L19( .clock(clock), .resetn(resetn), .seed(32'h2536089d), .ld(mine_reset), .en(en_shift), .q(mine19) );
	LFSR_32bit L20( .clock(clock), .resetn(resetn), .seed(32'hF57A03CC), .ld(mine_reset), .en(en_shift), .q(mine20) );
	LFSR_32bit L21( .clock(clock), .resetn(resetn), .seed(32'hBCCD301E), .ld(mine_reset), .en(en_shift), .q(mine21) );
	LFSR_32bit L22( .clock(clock), .resetn(resetn), .seed(32'hE148EE47), .ld(mine_reset), .en(en_shift), .q(mine22) );
	LFSR_32bit L23( .clock(clock), .resetn(resetn), .seed(32'h77FA9F78), .ld(mine_reset), .en(en_shift), .q(mine23) );
	LFSR_32bit L24( .clock(clock), .resetn(resetn), .seed(32'h6E85FEA9), .ld(mine_reset), .en(en_shift), .q(mine24) );
	LFSR_32bit L25( .clock(clock), .resetn(resetn), .seed(32'hE13F9F40), .ld(mine_reset), .en(en_shift), .q(mine25) );
	LFSR_32bit L26( .clock(clock), .resetn(resetn), .seed(32'h769E93BD), .ld(mine_reset), .en(en_shift), .q(mine26) );
	LFSR_32bit L27( .clock(clock), .resetn(resetn), .seed(32'h3A24C08E), .ld(mine_reset), .en(en_shift), .q(mine27) );
	LFSR_32bit L28( .clock(clock), .resetn(resetn), .seed(32'hF685608E), .ld(mine_reset), .en(en_shift), .q(mine28) );
	LFSR_32bit L29( .clock(clock), .resetn(resetn), .seed(32'h76D814E5), .ld(mine_reset), .en(en_shift), .q(mine29) );
	
	// keep changing position taken off of 32 bit LFSR to produce coordinates
	always@(*)begin
		case(select)
			7'd0: mine_site = mine0[8:0];
			7'd1: mine_site = mine0[17:9];
			7'd2: mine_site = mine0[26:18];
			7'd3: mine_site = {mine0[31:27], mine1[30:27]};
			7'd4: mine_site = mine1[8:0];
			7'd5: mine_site = mine1[17:9];
			7'd6: mine_site = mine1[26:18];
			7'd7: mine_site = mine2[8:0];
			7'd8: mine_site = mine2[17:9];
			7'd9: mine_site = mine2[26:18];
			7'd10: mine_site = {mine2[31:27], mine3[30:27]};
			7'd11: mine_site = mine3[8:0];
			7'd12: mine_site = mine3[17:9];
			7'd13: mine_site = mine3[26:18];
			7'd14: mine_site = mine4[8:0];
			7'd15: mine_site = mine4[17:9];
			7'd16: mine_site = mine4[26:18];
			7'd17: mine_site = {mine4[31:27], mine5[30:27]};
			7'd18: mine_site = mine5[8:0];
			7'd19: mine_site = mine5[17:9];
			7'd20: mine_site = mine5[26:18];
			7'd21: mine_site = mine6[8:0];
			7'd22: mine_site = mine6[17:9];
			7'd23: mine_site = mine6[26:18];
			7'd24: mine_site = {mine6[31:27], mine7[30:27]};
			7'd25: mine_site = mine7[8:0];
			7'd26: mine_site = mine7[17:9];
			7'd27: mine_site = mine7[26:18];
			7'd28: mine_site = mine8[8:0];
			7'd29: mine_site = mine8[17:9];
			7'd30: mine_site = mine8[26:18];
			7'd31: mine_site = {mine8[31:27], mine9[30:27]};
			7'd32: mine_site = mine9[8:0];
			7'd33: mine_site = mine9[17:9];
			7'd34: mine_site = mine9[26:18];
			7'd35: mine_site = mine10[8:0];
			7'd36: mine_site = mine10[17:9];
			7'd37: mine_site = mine10[26:18];
			7'd38: mine_site = {mine10[31:27], mine11[30:27]};
			7'd39: mine_site = mine11[8:0];
			7'd40: mine_site = mine11[17:9];
			7'd41: mine_site = mine11[26:18];
			7'd42: mine_site = mine12[8:0];
			7'd43: mine_site = mine12[17:9];
			7'd44: mine_site = mine12[26:18];
			7'd45: mine_site = {mine12[31:27], mine13[30:27]};
			7'd46: mine_site = mine13[8:0];
			7'd47: mine_site = mine13[17:9];
			7'd48: mine_site = mine13[26:18];
			7'd49: mine_site = mine14[8:0];
			7'd50: mine_site = mine14[17:9];
			7'd51: mine_site = mine14[26:18];
			7'd52: mine_site = {mine14[31:27], mine15[30:27]};
			7'd53: mine_site = mine15[8:0];
			7'd54: mine_site = mine15[17:9];
			7'd55: mine_site = mine15[26:18];
			7'd56: mine_site = mine16[8:0];
			7'd57: mine_site = mine16[17:9];
			7'd58: mine_site = mine16[26:18];
			7'd59: mine_site = {mine16[31:27], mine17[30:27]};
			7'd60: mine_site = mine17[8:0];
			7'd61: mine_site = mine17[17:9];
			7'd62: mine_site = mine17[26:18];
			7'd63: mine_site = mine18[8:0];
			7'd64: mine_site = mine18[17:9];
			7'd65: mine_site = mine18[26:18];
			7'd66: mine_site = {mine18[31:27], mine19[30:27]};
			7'd67: mine_site = mine19[8:0];
			7'd68: mine_site = mine19[17:9];
			7'd69: mine_site = mine19[26:18];
			7'd70: mine_site = mine20[8:0];
			7'd71: mine_site = mine20[17:9];
			7'd72: mine_site = mine20[26:18];
			7'd73: mine_site = {mine20[31:27], mine21[30:27]};
			7'd74: mine_site = mine21[8:0];
			7'd75: mine_site = mine21[17:9];
			7'd76: mine_site = mine21[26:18];
			7'd77: mine_site = mine22[8:0];
			7'd78: mine_site = mine22[17:9];
			7'd79: mine_site = mine22[26:18];
			7'd80: mine_site = {mine22[31:27], mine23[30:27]};
			7'd81: mine_site = mine23[8:0];
			7'd82: mine_site = mine23[17:9];
			7'd83: mine_site = mine23[26:18];
			7'd84: mine_site = mine24[8:0];
			7'd85: mine_site = mine24[17:9];
			7'd86: mine_site = mine24[26:18];
			7'd87: mine_site = {mine24[31:27], mine25[30:27]};
			7'd88: mine_site = mine25[8:0];
			7'd89: mine_site = mine25[17:9];
			7'd90: mine_site = mine25[26:18];
			7'd91: mine_site = mine26[8:0];
			7'd92: mine_site = mine26[17:9];
			7'd93: mine_site = mine26[26:18];
			7'd94: mine_site = {mine26[31:27], mine27[30:27]};
			7'd95: mine_site = mine27[8:0];
			7'd96: mine_site = mine27[17:9];
			7'd97: mine_site = mine27[26:18];
			7'd98: mine_site = mine28[8:0];
			7'd99: mine_site = mine28[17:9];
			7'd100: mine_site = mine28[26:18];
			7'd101: mine_site = {mine28[31:27], mine29[30:27]};
			7'd102: mine_site = mine29[8:0];
			7'd103: mine_site = mine29[17:9];
			7'd104: mine_site = mine29[26:18];
			7'd105: mine_site = mine0[8:0];
			7'd106: mine_site = mine0[17:9];
			7'd107: mine_site = mine0[26:18];
			7'd108: mine_site = {mine0[31:27], mine1[30:27]};
			7'd109: mine_site = mine1[8:0];
			7'd110: mine_site = mine1[17:9];
			7'd111: mine_site = mine1[26:18];
			7'd112: mine_site = mine2[8:0];
			7'd113: mine_site = mine2[17:9];
			7'd114: mine_site = mine2[26:18];
			7'd115: mine_site = {mine2[31:27], mine3[30:27]};
			7'd116: mine_site = mine3[8:0];
			7'd117: mine_site = mine3[17:9];
			7'd118: mine_site = mine3[26:18];
			7'd119: mine_site = mine4[8:0];
			7'd120: mine_site = mine4[17:9];
			7'd121: mine_site = mine4[26:18];
			7'd122: mine_site = {mine4[31:27], mine5[30:27]};
			7'd123: mine_site = mine5[8:0];
			7'd124: mine_site = mine5[17:9];
			7'd125: mine_site = mine5[26:18];
			7'd126: mine_site = mine6[8:0];
			7'd127: mine_site = mine6[17:9];
			default: mine_site = 9'b000000000;
		endcase
	end
	
	// Convert leading 5 bits of mine_site to be within boardX bounds (works for boardX >= 1)
	always@(*)begin
		if(mine_site[8:4] > boardX * 32 - 1)
			mine_site_x = mine_site[8:4] - boardX * 32;
		else if(mine_site[8:4] > boardX * 31 - 1)
			mine_site_x = mine_site[8:4] - boardX * 31;
		else if(mine_site[8:4] > boardX * 30 - 1)
			mine_site_x = mine_site[8:4] - boardX * 30;
		else if(mine_site[8:4] > boardX * 29 - 1)
			mine_site_x = mine_site[8:4] - boardX * 29;
		else if(mine_site[8:4] > boardX * 28 - 1)
			mine_site_x = mine_site[8:4] - boardX * 28;
		else if(mine_site[8:4] > boardX * 27 - 1)
			mine_site_x = mine_site[8:4] - boardX * 27;
		else if(mine_site[8:4] > boardX * 26 - 1)
			mine_site_x = mine_site[8:4] - boardX * 26;
		else if(mine_site[8:4] > boardX * 25 - 1)
			mine_site_x = mine_site[8:4] - boardX * 25;
		else if(mine_site[8:4] > boardX * 24 - 1)
			mine_site_x = mine_site[8:4] - boardX * 24;
		else if(mine_site[8:4] > boardX * 23 - 1)
			mine_site_x = mine_site[8:4] - boardX * 23;
		else if(mine_site[8:4] > boardX * 22 - 1)
			mine_site_x = mine_site[8:4] - boardX * 22;
		else if(mine_site[8:4] > boardX * 21 - 1)
			mine_site_x = mine_site[8:4] - boardX * 21;
		else if(mine_site[8:4] > boardX * 20 - 1)
			mine_site_x = mine_site[8:4] - boardX * 20;
		else if(mine_site[8:4] > boardX * 19 - 1)
			mine_site_x = mine_site[8:4] - boardX * 19;
		else if(mine_site[8:4] > boardX * 18 - 1)
			mine_site_x = mine_site[8:4] - boardX * 18;
		else if(mine_site[8:4] > boardX * 17 - 1)
			mine_site_x = mine_site[8:4] - boardX * 17;
		else if(mine_site[8:4] > boardX * 16 - 1)
			mine_site_x = mine_site[8:4] - boardX * 16;
		else if(mine_site[8:4] > boardX * 15 - 1)
			mine_site_x = mine_site[8:4] - boardX * 15;
		else if(mine_site[8:4] > boardX * 14 - 1)
			mine_site_x = mine_site[8:4] - boardX * 14;
		else if(mine_site[8:4] > boardX * 13 - 1)
			mine_site_x = mine_site[8:4] - boardX * 13;
		else if(mine_site[8:4] > boardX * 12 - 1)
			mine_site_x = mine_site[8:4] - boardX * 12;
		else if(mine_site[8:4] > boardX * 11 - 1)
			mine_site_x = mine_site[8:4] - boardX * 11;
		else if(mine_site[8:4] > boardX * 10 - 1)
			mine_site_x = mine_site[8:4] - boardX * 10;
		else if(mine_site[8:4] > boardX * 9 - 1)
			mine_site_x = mine_site[8:4] - boardX * 9;
		else if(mine_site[8:4] > boardX * 8 - 1)
			mine_site_x = mine_site[8:4] - boardX * 8;
		else if(mine_site[8:4] > boardX * 7 - 1)
			mine_site_x = mine_site[8:4] - boardX * 7;
		else if(mine_site[8:4] > boardX * 6 - 1)
			mine_site_x = mine_site[8:4] - boardX * 6;
		else if(mine_site[8:4] > boardX * 5 - 1)
			mine_site_x = mine_site[8:4] - boardX * 5;
		else if(mine_site[8:4] > boardX * 4 - 1)
			mine_site_x = mine_site[8:4] - boardX * 4;
		else if(mine_site[8:4] > boardX * 3 - 1)
			mine_site_x = mine_site[8:4] - boardX * 3;
		else if(mine_site[8:4] > boardX * 2 - 1)
			mine_site_x = mine_site[8:4] - boardX * 2;
		else if(mine_site[8:4] > boardX * 1 - 1)
			mine_site_x = mine_site[8:4] - boardX * 1;
		else
			mine_site_x = mine_site[8:4];
	end
	
	// Convert last 4 bits of mine_site to within boardY bounds (works for boardY >= 1)
	always@(*)begin
		if(mine_site[3:0] > boardY * 16 - 1)
			mine_site_y = mine_site[3:0] - boardY * 16;
		else if(mine_site[3:0] > boardY * 15 - 1)
			mine_site_y = mine_site[3:0] - boardY * 15;
		else if(mine_site[3:0] > boardY * 14 - 1)
			mine_site_y = mine_site[3:0] - boardY * 14;
		else if(mine_site[3:0] > boardY * 13 - 1)
			mine_site_y = mine_site[3:0] - boardY * 13;
		else if(mine_site[3:0] > boardY * 12 - 1)
			mine_site_y = mine_site[3:0] - boardY * 12;
		else if(mine_site[3:0] > boardY * 11 - 1)
			mine_site_y = mine_site[3:0] - boardY * 11;
		else if(mine_site[3:0] > boardY * 10 - 1)
			mine_site_y = mine_site[3:0] - boardY * 10;
		else if(mine_site[3:0] > boardY * 9 - 1)
			mine_site_y = mine_site[3:0] - boardY * 9;
		else if(mine_site[3:0] > boardY * 8 - 1)
			mine_site_y = mine_site[3:0] - boardY * 8;
		else if(mine_site[3:0] > boardY * 7 - 1)
			mine_site_y = mine_site[3:0] - boardY * 7;
		else if(mine_site[3:0] > boardY * 6 - 1)
			mine_site_y = mine_site[3:0] - boardY * 6;
		else if(mine_site[3:0] > boardY * 5 - 1)
			mine_site_y = mine_site[3:0] - boardY * 5;
		else if(mine_site[3:0] > boardY * 4 - 1)
			mine_site_y = mine_site[3:0] - boardY * 4;
		else if(mine_site[3:0] > boardY * 3 - 1)
			mine_site_y = mine_site[3:0] - boardY * 3;
		else if(mine_site[3:0] > boardY * 2 - 1)
			mine_site_y = mine_site[3:0] - boardY * 2;
		else if(mine_site[3:0] > boardY * 1 - 1)
			mine_site_y = mine_site[3:0] - boardY * 1;
		else
			mine_site_y = mine_site[3:0];
	end
	
	// counter counting how many mines have been added successfully to the RAM
	always@(posedge clock)begin
		if(resetn == 1'b0 || mine_reset == 1'b1)
			 mine_count <= 9'b000000000;
		else if(en_count == 1'b1)
			begin
				if(mine_count == num_mine - 1)
					mine_count <= 9'b000000000;
				else
					mine_count <= mine_count + 1;
			end
	end
	
	// ram holding location of mines
	mine_data_320x1 R0
	( 
			.clock(clock),
			.wren(mine_reset ? 1'b1 : (en_write) ), // specific case to write
			.data(mine_reset ? 1'b0 : 1'b1), 
			.address( mine_reset ? reset_count : (read_mine ? ( {mine_site_x, mine_site_y} ) : (ld_add ? second_address : position)) ), // determine which address to read
			.q(data_out)
	);

	always@(posedge clock)begin
		if(resetn == 1'b0)
			reset_count <= 9'b000000000;
		else if(mine_reset == 1'b1)
			begin
				if(reset_count == 9'd319 || reset_count > 9'd319)
					reset_count <= 9'b000000000;
				else
					reset_count <= reset_count + 1;
			end
	end
	
endmodule


// Random number generator
module LFSR_32bit(input clock, resetn, input [31:0] seed, input ld, en, output reg [31:0] q);
	
	wire end_bit;
	assign end_bit = q[22] ^ q[2] ^ q[1] ^ q[0];
	
	always@(posedge clock)begin
		if(resetn == 1'b0)
			q <= 32'b00000000000000000000000000000000;
		else if(ld == 1'b1)
			q <= seed;
		else if(en == 1'b1)
			begin
				q <= q << 1;
				q[0] <= end_bit;
			end
	end

endmodule


