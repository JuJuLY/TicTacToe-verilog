// Part 2 skeleton

module TicTacToediff
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

	wire resetn, load, draw;
	assign resetn = KEY[0];
	assign load = ~KEY[3];
	assign draw = ~KEY[1];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire [17:0] square;
	wire [3:0] player1;
	wire [3:0] player2;
	wire writeEn;

	assign player1 = SW[3:0];
	assign player2 = SW[7:4];
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
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
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "grid2.mif";

	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.

	  // Instansiate FSM control
	  control c0(CLOCK_50, resetn, load, draw, ld_1, ld_2, countEn, writeEn);
    // Instansiate datapath
	  datapath d0(CLOCK_50, resetn, ldx, ldy, countEn, SW[3:0], SW[7:4], x, y,colour);

endmodule

module control(input clk, input resetn, input load, input draw,
	             output reg ld_1, ld_2, countEn, writeEn);

	 reg[5:0] current_state, next_state;

	 localparam load_x = 3'd0, load_x_wait = 3'd1,
					    load_y = 3'd2, load_y_wait = 3'd3,
					    DRAW = 3'd4;

    always @(*)
	    begin
        case (current_state)
		      load_x: next_state = load ? load_x_wait : load_x;
				  load_x_wait: next_state = load ? load_x_wait : load_y;
				  load_y: next_state = load ? load_y_wait : load_y;
				  load_y_wait: next_state = draw ? DRAW : load_y_wait;
				  DRAW: next_state = draw ? DRAW : load_x;
          default next_state = load_x;
		  endcase
    end

	 always @(*)
	   begin
	     ld_1 = 1'b0; ld_2 = 1'b0; 
		   countEn = 1'b0; writeEn = 1'b0;

		   case (current_state)
		     load_x: begin 
			  ld_1 = 1'b1;
				countEn = 1'b1;
		      writeEn = 1'b1;		
						end
				 load_y: begin 
				 ld_2 = 1'b1; 
				 countEn = 1'b1;
				  writeEn = 1'b1;
				 //ldc = 1'b1;
				 end
				 DRAW: begin
				   countEn = 1'b1;
					 writeEn = 1'b1;
					 end
		  endcase
    end

	  always@(posedge clk)
	  begin
	      if (!resetn)
		      current_state <= load_x;
		    else
		      current_state <= next_state;
	  end
endmodule

module datapath(input clk, input resetn,
	              input ld_1, ld_2, countEn,
	              input [3:0] player1,
				  input [3:0] player2,
	              output reg[7:0] x,
	              output reg[6:0] y,
				  output reg[2:0] colour);

	 reg[7:0] temp_x;
	 reg[6:0] temp_y;
	 reg[2:0] temp_c;
	 reg[3:0] count;

	 always@(posedge clk)
	 begin
	     if (!resetn) begin
		      temp_x <= 8'd0;
			  temp_y <= 7'd0;
			  temp_c <= 3'b110;
				  end
		   else begin
		   
		if (ld_1) begin
		 case(player1[3:0])
			4'b0000: begin
		      temp_x <= 8'd17;
			  temp_y <= 7'd13;
			  temp_c <= 3'b100;
				end
	    	4'b0001: begin
			  temp_x <= 8'd37;
			  temp_y <= 7'd13;
			  temp_c <=3'b100;
			    end
			4'b0010: begin
			  temp_x <= 8'd57;
			  temp_y <= 7'd13;
			  temp_c <= 3'b100;
				end
			4'b0011: begin
              temp_x <= 8'd17;
			  temp_y<= 7'd33;
			  temp_c <= 3'b100;
				end
			4'b0100: begin
			  temp_x <= 8'd37;
			  temp_y <= 7'd33;
			  temp_c <= 3'b100;
			    end
			4'b0101: begin
			  temp_x <= 8'd57;
			  temp_y <= 7'd33;
			  temp_c <= 3'b100;
			    end
			4'b0110: begin
			     temp_x <= 8'd17;
			  temp_y <= 7'd53;
			  temp_c<= 3'b100;
			    end
			4'b0111: begin
			  temp_x <= 8'd37;
			  temp_y <= 7'd53;
			  temp_c <= 3'b100;
			    end
			4'b1000: begin
			  temp_x <=8'd57;
			  temp_y <= 7'd53;
			  temp_c <= 3'b100;
			    end			

		endcase
		end
		if (ld_2) begin
		 case(player2[3:0])
			4'b0000: begin
		      temp_x <= 8'd17;
			  temp_y <= 7'd13;
			  temp_c <= 3'b010;
				end
	    	4'b0001: begin
			  temp_x <= 8'd37;
			  temp_y <= 7'd13;
			  temp_c <= 3'b010;
			    end
			4'b0010: begin
			  temp_x <= 8'd57;
			  temp_y <= 7'd13;
			  temp_c <=3'b010;
				end
			4'b0011: begin
              temp_x <= 8'd17;
			  temp_y <=7'd33;
			 temp_c <= 3'b010;
				end
			4'b0100: begin
			  temp_x <= 8'd37;
			  temp_y <= 7'd33;
			  temp_c <= 3'b010;
			    end
			4'b0101: begin
			  temp_x <= 8'd57;
			  temp_y <= 7'd33;
			  temp_c <= 3'b010;
			    end
			4'b0110: begin
			     temp_x <= 8'd17;
			  temp_y <=7'd53;
			 temp_c <= 3'b010;
			    end
			4'b0111: begin
			  temp_x <= 8'd37;
			  temp_y <= 7'd53;
			  temp_c <= 3'b010;
			    end
			4'b1000: begin
			  temp_x <= 8'd57;
			  temp_y <= 7'd53;
			 temp_c <= 3'b010;
			    end			

		endcase
		end
	 end
	 end

	 always@(posedge clk)
	 begin
	     if (!resetn) count <= 4'b0;
		   else if (countEn) count <= count + 4'b0010;
	 end

	 always@(posedge clk)
	 begin
	     if (!resetn) begin
		      x <= 8'b0;
				  y <= 7'b0;
				  colour <= 3'b0;
				  end
		  else if (countEn) begin
		      x <= temp_x + {6'b0, count[1:0]};
				  y <= temp_y + {5'b0, count[3:2]};
				  colour <= temp_c[2:0];
				  end
	 end
endmodule

/*
module simulation(
    input CLOCK_50,
	 input [9:0] SW,
	 input [3:0] KEY,
	 output [2:0] colour,
	 output [7:0] x,
	 output [6:0] y,
	 output writeEn
	 );

	assign colour = SW[9:7];

	wire resetn, load, draw;
	assign resetn = KEY[0];
	assign load = ~KEY[3];
	assign draw = ~KEY[1];

	control c0(CLOCK_50, resetn, load, draw, ldx, ldy, countEn, writeEn);

	datapath d0(CLOCK_50, resetn, ldx, ldy, countEn, SW[6:0], x, y);

endmodule
*/
