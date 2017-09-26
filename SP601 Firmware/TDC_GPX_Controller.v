//////////////////////////////////////////////////////////////////////////////////
// 
// Core controller module for the TDC-GPX.
//
// Designed by: Andrei Hanu 
// 
// Create Date:    08/20/2012 
// Last Edited:	 01/19/2013
//
//////////////////////////////////////////////////////////////////////////////////
module TDC_GPX_Controller (
		// Synchronous Clock & Asynchronous Reset
		input wire clk, reset,
		
		// Control Signals
		input wire cntrlPuReSN,
		input wire cntrlConfigure,
		input wire cntrlStartStop,
		
		// TDC-GPX Control Signals
		output wire tdc_startdis,
		output wire tdc_stopdis,
		output wire tdc_puresn,
		input wire tdc_ef1,
		input wire tdc_lf1,
		input wire tdc_irflag,
		input wire tdc_errflag,
		
		// TDC-GPX Read/Write Controller Signals
		input wire rw_ready,
		input wire [27:0] rw_data_out,
		output wire [27:0] rw_data_in,
		output wire [3:0] rw_addr,
		output wire rw_read_write,
		output wire rw_mem_op,
		input wire rw_data_ready,
		
		// FIFO Write Interface
		input wire fifo_full,						
		output wire [31:0] fifo_din,				
		output wire fifo_wr_en
	);	
	
	// Symbolic State Declaration
	localparam [3:0]
		idle 					= 	4'b0000,
		puresn				=	4'b0001,
		configure			=	4'b0010,
		configure_wait		=	4'b0011,
		zero					=	4'b0100,
		zero_wait			=	4'b0101,
		acquire				=	4'b0110,
		read					=	4'b0111,
		read_wait			=	4'b1000,
		master_reset		=	4'b1001,
		master_reset_wait	=	4'b1010;
	
	// Internal Signal Declaration
	reg [3:0] state_reg, state_next;					// State register
	reg [7:0] cnt_reg, cnt_next;
	
	reg tdc_startdis_reg, tdc_startdis_buff;
	reg tdc_stopdis_reg, tdc_stopdis_buff;
	reg tdc_puresn_reg, tdc_puresn_buff;
	
	reg [27:0] rw_data_in_reg, rw_data_in_next;
	reg [3:0] rw_addr_reg, rw_addr_next;
	reg rw_read_write_reg, rw_read_write_next;
	reg rw_mem_op_reg, rw_mem_op_buff;
	
	reg [31:0] fifo_din_reg, fifo_din_next;
	reg fifo_wr_en_reg, fifo_wr_en_buff;
	
	// FSMD state & data registers
	always @(posedge clk, posedge reset) 
	begin
		if (reset) 
			begin
				// Asynchronous Reset
				state_reg <= idle;
				cnt_reg <= 0;
				tdc_startdis_reg <= 1;
				tdc_stopdis_reg <= 1;
				tdc_puresn_reg <= 1;
				rw_data_in_reg <= 0;
				rw_addr_reg <= 0;
				rw_read_write_reg <= 1;
				rw_mem_op_reg <= 0;
				fifo_din_reg <= 0;
				fifo_wr_en_reg <= 0;
			end
		else 
			begin
				// Synchronous CLK edge
				state_reg <= state_next;
				cnt_reg <= cnt_next;
				tdc_startdis_reg <= tdc_startdis_buff;
				tdc_stopdis_reg <= tdc_stopdis_buff;
				tdc_puresn_reg <= tdc_puresn_buff;
				rw_data_in_reg <= rw_data_in_next;
				rw_addr_reg <= rw_addr_next;
				rw_read_write_reg <= rw_read_write_next;
				rw_mem_op_reg <= rw_mem_op_buff;
				fifo_din_reg <= fifo_din_next;
				fifo_wr_en_reg <= fifo_wr_en_buff;
			end
	end
	
	// FSMD next-state logic
	always @*
	begin
		// Default Conditions (keep same value)		
		state_next = state_reg;
		cnt_next = cnt_reg;
		rw_data_in_next = rw_data_in_reg;
		rw_addr_next = rw_addr_reg;
		rw_read_write_next = rw_read_write_reg;
		fifo_din_next = fifo_din_reg;
		
		case (state_reg)
			idle:
				begin
					// Power Up Reset Request
					if (cntrlPuReSN) begin
						cnt_next = 61;				// Load up 60 clock cycles
						state_next = puresn;	
					end
					// Configure TDC-GPX Request
					else if (cntrlConfigure) begin
						cnt_next = 12;
						state_next = configure;
					end
					// Start Acquisition Request
					else if (cntrlStartStop) begin
						if (~tdc_irflag) begin
							state_next = zero;
						end
					end
				end
			puresn:
				begin
					cnt_next = cnt_reg - 1;
					if(cnt_next == 0)
						state_next = idle;						
				end
			configure:
				begin		
					if (rw_ready) begin
						// Write Operation
						rw_read_write_next = 0;
						// Go to a wait state (1 clk cycle)
						state_next = configure_wait;
						// Decrement Counter
						cnt_next = cnt_reg - 1;
						// Which register are we on
						case (cnt_next)
						11:
							begin
								// Register 0
								// Rising edges, Start ring oscillator
								rw_addr_next 		= 	0;
								rw_data_in_next 	= 	28'h007FC81;								
							end
						10:
							begin
								// Register 1
								// Channel Adjustment
								rw_addr_next 		= 	1;
								rw_data_in_next 	= 	28'h0000000;
							end
						9:
							begin
								// Register 2
								// I-Mode
								rw_addr_next 		= 	2;
								rw_data_in_next 	= 	28'h0000002;
							end
						8:
							begin
								// Register 3
								rw_addr_next 		= 	3;
								rw_data_in_next 	= 	28'h0000000;
							end
						7:
							begin
								// Register 4
								// Mtimes trig. by Start, EFlagHiZN
								rw_addr_next 		= 	4;
								rw_data_in_next 	= 	28'h6000000;
							end
						6:
							begin
								// Register 5
								// StartOff1 = 100ns, MasterAluTrig
								rw_addr_next 		= 	5;
								// rw_data_in_next 	= 	28'h0E004DA; // StopDisStart, StartDisStart	
								rw_data_in_next 	= 	28'h0C004DA; // No StopDisStart, StartDisStart
							end
						5:
							begin
								// Register 6
								rw_addr_next 		= 	6;
								rw_data_in_next 	= 	28'h0000000;
							end
						4:
							begin
								// Register 7
								// Resolution = 82.3045ps 																	
								rw_addr_next 		= 	7;
								rw_data_in_next 	= 	28'h0051FB4;	// MTimer = 250 nsec
								// rw_data_in_next 	= 	28'h00A1FB4;	// MTimer = 500 nsec
								// rw_data_in_next 	= 	28'h00F1FB4;	// MTimer = 750 nsec
							end
						3:
							begin
								// Register 11
								rw_addr_next 		= 	11;
								rw_data_in_next 	= 	28'h0000000;
							end
						2:
							begin
								// Register 12
								// Mtimer -> IrFlag
								rw_addr_next 		= 	12;
								rw_data_in_next 	= 	28'h2000000;
							end
						1:
							begin
								// Register 14
								rw_addr_next 		= 	14;
								rw_data_in_next 	= 	28'h0000000;
							end
						0:
							begin								
								// Master Reset
								state_next = master_reset;
							end
						endcase
					end
				end
			configure_wait:
				begin		
					state_next = configure;
				end
			zero:
				begin
					// FIFO Full?
					if (~fifo_full) begin
						// Send timestamp to FIFO
						fifo_din_next = 32'hFFFFFFFF;						
						// Go to wait state
						state_next = zero_wait;
					end
				end
			zero_wait:
				begin
					state_next = acquire;
				end
			acquire:
				begin
					// Check the IrFlag
					// HIGH - End of Time Window Reached
					// LOW - Acquiring
					if (tdc_irflag) begin
						state_next = read;
					end
				end
			read:
				begin
					// Check the TDC FIFO Empty Flag
					// HIGH - FIFO Empty
					// LOW - FIFO Contains Data
					if (tdc_ef1) begin
						// No data available
						state_next = master_reset;
					end
					else begin
						// FIFO Full?
						if (~fifo_full) begin
							// Data available
							if (rw_ready) begin
								// Read Operation
								rw_read_write_next = 1;
								// Register 8	
								rw_addr_next 		= 	8;
								// Go to wait state
								state_next = read_wait;
							end
						end						
					end
				end
			read_wait:
				begin
					// Is data ready?
					if (rw_data_ready) begin
						// Send timestamp to FIFO
						fifo_din_next[27:0] = rw_data_out;
						fifo_din_next[31:28] = 4'h0;
						// Check for more data
						state_next = read;
					end					
				end
			master_reset:
				// Master Reset
				begin
					if (rw_ready) begin
						// Write Operation
						rw_read_write_next = 0;
						// Register 4						
						rw_addr_next 		= 	4;
						rw_data_in_next 	= 	28'h6400000;						
						// Go to wait state
						state_next = master_reset_wait;
					end
				end
			master_reset_wait:
				begin
					// Return to IDLE
					state_next = idle;
				end
			default: 
				state_next = idle;
		endcase
	end
	
	// look-ahead output logic
	always @*
	begin
		// Default Conditions (Buffered Outputs)
		tdc_startdis_buff = 1;
		tdc_stopdis_buff = 1;
		tdc_puresn_buff = 1;
		rw_mem_op_buff = 0;
		fifo_wr_en_buff = 0;
		
		case (state_next)
			idle:
				begin					
				end
			puresn:
				begin
					// Power-up Reset
					tdc_puresn_buff = 0;
				end
			configure:
				begin				
				end
			configure_wait:
				begin	
					// Strobe Memory Operation
					rw_mem_op_buff = 1;
				end
			zero:
				begin					
				end
			zero_wait:
				begin
					// FIFO Write Enable
					fifo_wr_en_buff = 1;
				end
			acquire:
				begin
					// Enable Inputs
					tdc_startdis_buff = 0;
					tdc_stopdis_buff = 0;
				end
			read:
				begin
					if (state_reg == read_wait) begin
						// FIFO Write Enable
						fifo_wr_en_buff = 1;
					end
				end
			read_wait:
				begin
					if (state_reg == read) begin
						// Strobe Memory Operation
						rw_mem_op_buff = 1;
					end
				end
			master_reset:
				begin
				end
			master_reset_wait:
				begin
					// Strobe Memory Operation
					rw_mem_op_buff = 1;
				end
		endcase
	end
	
	// To TDC-GPX	
	assign tdc_startdis = tdc_startdis_reg;
	assign tdc_stopdis = tdc_stopdis_reg; 
	assign tdc_puresn = tdc_puresn_reg; 
	
	// To TDC-GPX Read/Write Controller
	assign rw_data_in = rw_data_in_reg;
	assign rw_addr = rw_addr_reg;
	assign rw_read_write = rw_read_write_reg;
	assign rw_mem_op = rw_mem_op_reg;
	
	// To the FIFO
	assign fifo_din = fifo_din_reg;
	assign fifo_wr_en = fifo_wr_en_reg;
		
endmodule
