//////////////////////////////////////////////////////////////////////////////////
// 
// This module is responsible for communicating with the memory read-write
// controller and loading the data from DDR2 RAM into a register to be sent out over
// UART.
//
// The module requires a control signal (cntrlReadData), a start 
// address (addressStart), and an end address (addressEnd).
//
//
// Designed by: Andrei Hanu 
//
// Create Date:    01/29/2013 
// Last Edited:	 03/05/2013
//
//////////////////////////////////////////////////////////////////////////////////
module Readout_Controller(
		// Synchronous Clock & Asynchronous Reset
		input wire clk, reset,
		
		// Control Signals
		input wire cntrlReadData,
		input wire cntrlClearMemory,
		
		// Start and End Address
		input wire [15:0] readStartX,
		input wire [15:0] readStartY,
		input wire [15:0] readEndX,
		input wire [15:0] readEndY,
		input wire [7:0] readDivide,
				
		// UART TX Interface
		input wire tx_ready,						// UART TX Ready Status
		output reg [31:0] tx_data_in,			// UART TX Data Out
		output reg tx_data_ready,				// UART TX Write Enable
		
		// DDR2 Memory Controller Ports
		input wire pX_ready,							// Ready Status
		output reg [31:0] pX_data_out,			// Data to memory
		input wire [31:0] pX_data_in,				// Data from memory
		input wire pX_data_ready,					// Data Ready Status
		output reg [29:0] pX_addr,					// Address location on memory
		output reg pX_read_write,					// Specifies read (1) or write (0) operation
		output reg pX_mem_op						 
		
	);
	
	// SP601 Memory Address Limits (128 MB)
	localparam minAddr = 32'd0;	
	localparam maxAddr = 32'd16777212;
	
	// Symbolic State Declaration
	localparam [3:0]
		idle 					= 	4'd0,
		ClrMem				=	4'd1,
		ClrMem_Wait			=	4'd2,
		read					=	4'd3,
		read_wait			=	4'd4,
		subXBoundary		=	4'd5,
		subYBoundary		=	4'd6,
		tx						=	4'd7,
		tx_wait				=	4'd8,
		curXBoundary		=	4'd9;
		
	// Internal Signal Declaration
	reg [3:0] state_reg;
	reg [15:0] startX_reg;							// Starting X location
	reg [15:0] startY_reg;							// Starting Y location
	reg [15:0] endX_reg;								// End X location
	reg [15:0] endY_reg;								// End Y location
	reg [15:0] curX_reg;								// Current X location
	reg [15:0] curY_reg;								// Current Y location
	reg [7:0] pixDiv_reg;							// Image Subdivide Factor
	reg [7:0] cnt_reg;
	
	reg [7:0] subPixelX_reg;
	reg [7:0] subPixelY_reg;
	reg [31:0] subPixelCount_reg;
	
	// Synchronous FSM
	always @(posedge clk, posedge reset) 
	begin
		if (reset) begin
			// Asynchronous Reset
			state_reg <= idle;
			
			startX_reg <= 0;
			startY_reg <= 0;
			endX_reg <= 0;
			endY_reg <= 0;
			curX_reg <= 0;
			curY_reg <= 0;
			pixDiv_reg <= 0;
			
			subPixelX_reg <= 0;
			subPixelY_reg <= 0;
			subPixelCount_reg <= 0;
						
			tx_data_in <= 0;
			tx_data_ready <= 0;
			pX_addr <= 0;
			pX_read_write <= 1;
			pX_mem_op <= 0;
			cnt_reg <= 0;
		end
		else begin			
			// Defaults
			pX_mem_op <= 0;
			pX_read_write <= 1;
			tx_data_ready <= 0;
		
			case (state_reg)
			idle:
				begin
					// Check for read request
					if (cntrlReadData) begin
						// Load start address
						startX_reg <= readStartX;
						startY_reg <= readStartY;												
						// Load end address
						endX_reg <= readEndX;
						endY_reg <= readEndY;
						// Load current address (Start Address)
						curX_reg <= readStartX;
						curY_reg <= readStartY;		
						// Load image divide factor
						pixDiv_reg <= readDivide;
						// Image Subpixel Counters
						subPixelX_reg <= 0;
						subPixelY_reg <= 0;
						subPixelCount_reg <= 0;
						// Go to read state
						state_reg <= read;
					end
					// Check for Clear Memory Request
					else if (cntrlClearMemory) begin	
						// Load the starting address
						pX_addr <= minAddr;
						// Load starting data (Zero)
						pX_data_out <= 0;
						// Go to clear memory state
						state_reg <= ClrMem;
					end
				end
			ClrMem:
				begin
					// Check if we have reached the end address
					if (pX_addr <= maxAddr) begin
						// Check if memory controller is ready
						if (pX_ready) begin
							// Load the counter 1 clk cycle
							cnt_reg <= 1;
							// Write Operation
							pX_read_write <= 0;
							// Memory Operation
							pX_mem_op <= 1;
							// Go to wait state
							state_reg <= ClrMem_Wait;							
						end
					end
					else begin
						// Reached the end address
						state_reg <= idle;
					end
				end
			ClrMem_Wait:
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
							// Increment address
							pX_addr <= pX_addr + 4;
							// Go back to clear state
							state_reg <= ClrMem;
						end
					end
				end
			read:
				begin
					// Check if we have reached the end address
					if (curY_reg <= endX_reg) begin
						// Check if memory controller is ready
						if (pX_ready) begin
							// Generate Address							
							pX_addr[1:0] <= 2'b00;
							pX_addr[11:2] <= curX_reg[9:0] + subPixelX_reg;						
							pX_addr[21:12] <= curY_reg[9:0] + subPixelY_reg;						
							pX_addr[29:22] <= 8'b00000000;	
							// Load the counter 1 clk cycle
							cnt_reg <= 1;
							// Read Operation
							pX_read_write <= 1;
							// Memory Operation
							pX_mem_op <= 1;
							// Go to wait state
							state_reg <= read_wait;
						end
					end
					else begin
						// Reached the end address
						state_reg <= idle;
					end
				end
			read_wait:
				begin
					// Check counter
					if (cnt_reg > 0) begin
						// Read Operation
						pX_read_write <= 1;
						// Memory Operation
						pX_mem_op <= 1;
						// Decrement counter
						cnt_reg <= cnt_reg - 1;
					end 
					else begin
						// Check if controller is ready
						if (pX_ready) begin	
							// Grab Pixel Data
							subPixelCount_reg <= subPixelCount_reg + pX_data_in;
							// Increment SubPixel X
							subPixelX_reg <= subPixelX_reg + 1;
							// Check SubPixel X Boundary
							state_reg <= subXBoundary;
						end
					end
				end
			subXBoundary:
				begin
					// Go back to read
					state_reg <= read;
					// Check SubPixel X Boundary
					if (subPixelX_reg == pixDiv_reg) begin
						// Reset SubPixel X Counter
						subPixelX_reg <= 0;
						// Increment SubPixel Y Counter
						subPixelY_reg <= subPixelY_reg + 1;
						// Check SubPixel Y Boundary
						state_reg <= subYBoundary;
					end
				end
			subYBoundary:
				begin
					// Go back to read
					state_reg <= read;
					// Check SubPixel X Boundary
					if (subPixelY_reg == pixDiv_reg) begin
						// Reset SubPixel Y Counters						
						subPixelY_reg <= 0;
						// Increment Current X
						curX_reg <= curX_reg + pixDiv_reg;
						// Send SubPixel Value
						state_reg <= tx;
					end
				end
			tx:
				begin
					// Check if UART TX is ready
					if (tx_ready) begin
						// Send data to UART TX					
						tx_data_in <= subPixelCount_reg;
						// UART TX Data Ready
						tx_data_ready <= 1;
						// Load the counter 1 clk cycle
						cnt_reg <= 1;
						// Go back to TX wait state
						state_reg <= tx_wait;
					end
				end
			tx_wait:
				begin
					// Check counter
					if (cnt_reg > 0) begin
						// UART TX Data Ready
						tx_data_ready <= 1;
						// Decrement counter
						cnt_reg <= cnt_reg - 1;
					end 
					else begin
						// Check UART TX is ready
						if (~tx_ready) begin
							// Check Current X Boundary
							state_reg <= curXBoundary;
						end
					end
				end
			curXBoundary:
				begin
					// Go back to read
					state_reg <= read;
					// Reset Sub Pixel Count
					subPixelCount_reg <= 0;
					// Increment Current Pixel Location
					if (curX_reg > endX_reg) begin						
						curX_reg <= startX_reg;
						curY_reg <= curY_reg + pixDiv_reg;
					end
				end
			default: 
				state_reg <= idle;
			endcase
		end
	end
	
endmodule
