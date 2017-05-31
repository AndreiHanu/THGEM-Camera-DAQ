//////////////////////////////////////////////////////////////////////////////////
// 
// In this module, the raw TDC-GPX timestamps are read from the TDC-GPX Core Controller. 
// Once read, the timebin and channel number are extracted from the raw timestamps and an
// address is generated for the memory location. 
// 
// A read operation is initiated on the DDR2 Memory Controller Module at the
// address previously generated. The returned value is incremented by 1, and a
// write operation is send to the Memory Controller at the same address but with
// the new value.
//
// Designed by: Andrei Hanu 
//
// Create Date:    01/20/2013 
// Last Edited:	 02/02/2013
//
//////////////////////////////////////////////////////////////////////////////////
module Histogramming_Controller(
		// Synchronous Clock & Asynchronous Reset
		input wire clk, reset,		
				
		// DDR2 Memory Controller Ports
		input wire pX_ready,							// Ready Status
		output reg [31:0] pX_data_out,			// Data to memory
		input wire [31:0] pX_data_in,				// Data from memory
		input wire pX_data_ready,					// Data Ready Status
		output reg [29:0] pX_addr,					// Address location on memory
		output reg pX_read_write,					// Specifies read (1) or write (0) operation
		output reg pX_mem_op,
				
		// FIFO Read
		input wire [31:0] fifo_dout,				// FIFO data out
		output reg fifo_rd_en,						// FIFO read enable
		input wire fifo_empty,						// FIFO empty flag
		input wire fifo_valid						// FIFO data valid flag
		
	);
	
	localparam offset	 = 131071;					// Used to offset negative time differences (2^18/2 - 1)
	localparam min_time = 130559;					// offset - 512	
	localparam max_time = 131582;					// offset + 511
	
	// Symbolic State Declaration
	localparam [3:0]
		idle 					= 	4'd0,		
		GetTime				=	4'd1,
		ClrTime				=	4'd2,
		GetSum				=	4'd3,
		GetDiff				=	4'd4,
		GenAddr				= 	4'd5,
		IncMem_Read			=	4'd6,
		IncMem_Read_Wait	=	4'd7,
		IncMem_Modify		=	4'd8,
		IncMem_Write		=	4'd9,
		IncMem_Write_Wait	=	4'd10;
		
	
	// Internal Signal Declaration
	reg [3:0] state_reg;
	reg [7:0] cnt_reg;
	reg [16:0] CH1_reg;								// CH1 Timestamp Register	
	reg [16:0] CH2_reg;								// CH2 Timestamp Register	
	reg [16:0] CH3_reg;								// CH3 Timestamp Register	
	reg [16:0] CH4_reg;								// CH4 Timestamp Register
	reg CH1_hit_reg;									// CH1 Hit Register
	reg CH2_hit_reg;									// CH2 Hit Register	
	reg CH3_hit_reg;									// CH3 Hit Register
	reg CH4_hit_reg;									// CH4 Hit Register
	reg [17:0] CH1_CH2_diff_reg;					// Difference between CH1 and CH2 + offset
	reg [17:0] CH3_CH4_diff_reg;					// Difference between CH3 and CH4 + offset
	reg [7:0] hits_reg;								// Keeps track of the number of timestamps during an event
	
	// Synchronous FSM
	always @(posedge clk, posedge reset) 
	begin
		// Asynchronous Reset
		if (reset) begin	
			state_reg <= idle;
			cnt_reg <= 0;
			pX_addr <= 0;
			pX_read_write <= 1;
			pX_mem_op <= 0;
			fifo_rd_en <= 0;
			
			CH1_reg <= 0;
			CH2_reg <= 0;			
			CH3_reg <= 0;
			CH4_reg <= 0;
			CH1_hit_reg <= 0;
			CH2_hit_reg <= 0;
			CH3_hit_reg <= 0;
			CH4_hit_reg <= 0;
			CH1_CH2_diff_reg <= 0;
			CH3_CH4_diff_reg <= 0;
			hits_reg <= 0;	
		end
		else begin
			// Defaults
			pX_mem_op <= 0;
			pX_read_write <= 1;
			fifo_rd_en <= 0;
			
			case (state_reg)
			idle:
				begin
					// Check if the FIFO contains data
					if (~fifo_empty) begin
						// FIFO read enable
						fifo_rd_en <= 1;
						// Go to GetTime state
						state_reg <= GetTime;
					end
				end
			GetTime:
				begin		
					// Check if the FIFO contains valid data
					if (fifo_valid) begin
						// Check for START timestamp (all ones)
						if (fifo_dout == 32'hFFFFFFFF) begin	
							// Default ClrTime
							state_reg <= ClrTime;
							// Subtract timestamps
							if (hits_reg == 4) begin
								if (CH1_hit_reg && CH2_hit_reg && CH3_hit_reg && CH4_hit_reg) begin
									CH1_CH2_diff_reg <= offset;
									CH3_CH4_diff_reg <= offset;
									// Generate memory address
									state_reg <= GetSum;
								end
							end
						end
						else begin
							// Go to idle
							state_reg <= idle;
							// Increment hit counter
							hits_reg <= hits_reg + 1;
							
							// Check Channel Code
							if (fifo_dout[27:26] == 2'b00) begin
								// Channel 1
								CH1_reg <= fifo_dout[16:0];							
								CH1_hit_reg <= 1;
							end
							else if (fifo_dout[27:26] == 2'b01) begin
								// Channel 2
								CH2_reg <= fifo_dout[16:0];
								CH2_hit_reg <= 1;
							end
							else if (fifo_dout[27:26] == 2'b10) begin
								// Channel 3
								CH3_reg <= fifo_dout[16:0];
								CH3_hit_reg <= 1;
							end
							else if (fifo_dout[27:26] == 2'b11) begin
								// Channel 4
								CH4_reg <= fifo_dout[16:0];
								CH4_hit_reg <= 1;
							end							
						end
					end
				end
			ClrTime:
				begin
					// Reset CH1-CH4 timestamp registers
					CH1_reg <= 0;
					CH2_reg <= 0;
					CH3_reg <= 0;
					CH4_reg <= 0;
					// Reset CH1-CH4 hit registers
					CH1_hit_reg <= 0;
					CH2_hit_reg <= 0;
					CH3_hit_reg <= 0;
					CH4_hit_reg <= 0;
					// Reset the difference registers
					CH1_CH2_diff_reg <= 0;
					CH3_CH4_diff_reg <= 0;
					// Reset the hits counter
					hits_reg <= 0;					
					// Go to idle
					state_reg <= idle;					
				end
			GetSum:
				begin
					CH1_CH2_diff_reg <= CH1_CH2_diff_reg + CH1_reg[16:1];
					CH3_CH4_diff_reg <= CH3_CH4_diff_reg + CH3_reg[16:1];
					state_reg <= GetDiff;
				end
			GetDiff:
				begin
					CH1_CH2_diff_reg <= CH1_CH2_diff_reg - CH2_reg[16:1];
					CH3_CH4_diff_reg <= CH3_CH4_diff_reg - CH4_reg[16:1];
					state_reg <= GenAddr;
				end
			GenAddr:
				begin	
					// Default ClrTime state
					state_reg <= ClrTime;
					// Check First Axis Difference
					if ((CH1_CH2_diff_reg >= min_time) && (CH1_CH2_diff_reg <= max_time)) begin
						// Check Second Axis Difference
						if ((CH3_CH4_diff_reg >= min_time) && (CH3_CH4_diff_reg <= max_time)) begin
							// Generate Address							
							pX_addr[1:0] <= 2'b00;
							pX_addr[11:2] <= CH1_CH2_diff_reg - min_time;						
							pX_addr[21:12] <= CH3_CH4_diff_reg - min_time;						
							pX_addr[29:22] <= 8'b00000000;						
							// Go to IncMem state
							state_reg <= IncMem_Read;	
						end
					end
				end
			IncMem_Read:
				begin
					// Loop same state until data ready
					state_reg <= IncMem_Read;	
					// Check if memory controller is ready
					if (pX_ready) begin
						// Load the counter 1 clk cycle
						cnt_reg <= 2;
						// Read Operation
						pX_read_write <= 1;						
						// Memory Operation
						pX_mem_op <= 1;
						// Go to wait state						
						state_reg <= IncMem_Read_Wait;
					end
				end
			IncMem_Read_Wait:
				begin
					// Check counter
					if (cnt_reg > 0) begin
						// Memory Operation
						pX_mem_op <= 1;
						// Read Operation
						pX_read_write <= 1;
						// Decrement counter
						cnt_reg <= cnt_reg - 1;
					end 
					else begin
						// Check if data is ready
						if (pX_data_ready) begin
							// Write back the data
							pX_data_out <= pX_data_in;
							// Go to the modify state
							state_reg <= IncMem_Modify;
						end
					end
				end
			IncMem_Modify:
				begin
					// Increment data to be written
					pX_data_out <= pX_data_out + 1;
					state_reg <= IncMem_Write;
				end
			IncMem_Write:
				begin
					// Check if memory controller is ready
					if (pX_ready) begin
						// Load the counter 1 clk cycle
						cnt_reg <= 1;
						// Write Operation
						pX_read_write <= 0;						
						// Memory Operation
						pX_mem_op <= 1;
						// Go to wait state
						state_reg <= IncMem_Write_Wait;							
					end
				end
			IncMem_Write_Wait:
				begin
					// Check counter
					if (cnt_reg > 0) begin
						// Memory Operation
						pX_mem_op <= 1;
						// Write Operation
						pX_read_write <= 0;
						// Decrement counter
						cnt_reg <= cnt_reg - 1;
					end 
					else begin
						// Check if controller is ready
						if (pX_ready) begin
							// Go back to ClrTime
							state_reg <= ClrTime;
						end
					end
				end
			default: 
				state_reg <= idle;
			endcase
		end
	end	
endmodule
