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
// Last Edited:	 02/21/2013
//
//////////////////////////////////////////////////////////////////////////////////
module Readout_Controller(
		// Synchronous Clock & Asynchronous Reset
		input wire clk, reset,
		
		// Control Signals
		input wire cntrlReadData,
		input wire cntrlClearMemory,
		
		// Start and End Address
		input wire [29:0] readAddrStart,
		input wire [29:0] readAddrEnd,
		
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
		tx						=	4'd5,
		tx_wait				=	4'd6;
		
	// Internal Signal Declaration
	reg [3:0] state_reg;
	reg [29:0] readAddrStart_reg;
	reg [29:0] readAddrEnd_reg;
	reg [7:0] cnt_reg;
	
	// Synchronous FSM
	always @(posedge clk, posedge reset) 
	begin
		if (reset) begin
			// Asynchronous Reset
			state_reg <= idle;
			readAddrStart_reg <= 0;
			readAddrEnd_reg <= 0;
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
						readAddrStart_reg <= readAddrStart;
						// Load end address
						readAddrEnd_reg <= readAddrEnd;
						// Load current address (Start Address)
						pX_addr <= readAddrStart;
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
					if (pX_addr <= readAddrEnd_reg) begin
						// Check if memory controller is ready
						if (pX_ready) begin
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
						// Check if controller and UART TX is ready
						if (pX_ready && tx_ready) begin
							// Send data to UART TX
							tx_data_in <= pX_data_in;
							// UART TX Data Ready
							tx_data_ready <= 1;
							// Increment address
							pX_addr <= pX_addr + 4;
							// Load the counter 1 clk cycle
							cnt_reg <= 1;
							// Go back to TX wait state
							state_reg <= tx_wait;
						end
					end
				end
			tx:
				begin
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
							// Go back to read
							state_reg <= read;
						end
					end
				end
			default: 
				state_reg <= idle;
			endcase
		end
	end
	
endmodule
