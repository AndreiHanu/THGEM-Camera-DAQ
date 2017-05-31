//////////////////////////////////////////////////////////////////////////////////
//
// This controller handles read and write operation from external controllers to
// the DDR2 RAM on the SP601 FPGA through the Memory Controller Block (MCB).
//
// Designed by: Andrei Hanu 
// 
// Create Date:    01/16/2013 
// Last Edited:	 01/30/2013
//
//////////////////////////////////////////////////////////////////////////////////

module Memory_Read_Write_Controller(
		// Input Clock & Reset
		input wire clk, reset,
		
		// To & From Main Controller
		output wire ready,					// Controller status signal (1 == IDLE == ready)
		output wire [31:0] data_out,		// Data from RAM
		input wire [31:0] data_in,			// Data to be written to RAM
		input wire [29:0] addr,				// Address location on the RAM
		input wire read_write,				// Specifies read (1) or write (0) operation
		input wire mem_op,					// Initiate memory operation ( mem_op == 1 )
		output wire data_ready,				// Data ready strobe (1 clock cycle)
		
		// To & From MCB		
		// Command Port
		output wire pX_cmd_en,				// Command FIFO write enable (Active HIGH)
		output wire [2:0] pX_cmd_instr,	// Command FIFO command code
		output wire [5:0] pX_cmd_bl,		// Command FIFO burst length
		output wire [29:0] pX_cmd_addr,	// Command FIFO byte start address
		input wire pX_cmd_empty,			// Command FIFO Empty Flag (Active HIGH)
		input wire pX_cmd_full,				// Command FIFO Full Flag (Active HIGH)
		
		// Write Port		
		output wire pX_wr_en,				// Write FIFO write enable (Active HIGH)
		output wire [3:0] pX_wr_mask,		// Write FIFO data mask bits 
		output wire [31:0] pX_wr_data,	// Write FIFO data value to be loaded into memory
		input wire pX_wr_full,				// Write FIFO full flag (Active HIGH)
		input wire pX_wr_empty,				// Write FIFO empty flag (Active HIGH)
		input wire [6:0] pX_wr_count,		// Write FIFO count value 
		input wire pX_wr_underrun,			// Write FIFO underrun flag (Active HIGH)
		input wire pX_wr_error,				// Write FIFO error flag (Active HIGH)
		
		// Read Port
		output wire pX_rd_en,				// Read FIFO read enable (Active HIGH)
		input wire [31:0] pX_rd_data,		// Read FIFO data value from memory
		input wire pX_rd_full,				// Read FIFO full flag (Active HIGH)
		input wire pX_rd_empty,				// Read FIFO empty flag (Active HIGH)
		input wire [6:0] pX_rd_count,		// Read FIFO count value 
		input wire pX_rd_overflow,			// Read FIFO overflow flag (Active HIGH)
		input wire pX_rd_error				// Read FIFO error flag (Active HIGH)
		
   );
	
	// Symbolic State Declaration
	localparam [2:0]
		idle 		= 		3'b000,
		read1 	= 		3'b001,
		read2 	= 		3'b010,
		read3 	= 		3'b011,
		write1	=		3'b100,
		write2	=		3'b101;
		
	// Symbolic State for Command Code Instructions
	localparam [2:0]
		write		=		3'b000,						// Write
		read		=		3'b001,						// Read
		write_p	=		3'b010,						// Write with Auto Precharge
		read_p	=		3'b011;						// Read with Auto Precharge
	
	// Internal Signals/Registers
	reg ready_reg;
	reg [2:0] state_reg;								// State register
	reg [31:0] data_out_reg;						// Data from RAM to FPGA
	reg [31:0] data_in_reg;							// Data from FPGA to RAM
	reg [29:0] addr_reg;								// Address from FPGA
	reg [2:0] cmd_instr_reg;						// Command Code Register
	reg cmd_en_reg;
	reg wr_en_reg;
	reg rd_en_reg;
	reg data_ready_reg;								// Data ready strobe
	
		
	// Synchronous FSM
	always @(posedge clk, posedge reset) 
	begin		
		if (reset) begin	
			ready_reg <= 1;
			state_reg <= idle;
			data_out_reg <= 0;
			data_in_reg <= 0;
			addr_reg <= 0;
			cmd_instr_reg <= read_p;				// Read as default	
			cmd_en_reg <= 0;
			wr_en_reg <= 0;
			rd_en_reg <= 0;
			data_ready_reg <= 0;			
		end
		else begin	
		
			ready_reg <= 1;
			cmd_en_reg <= 0;
			wr_en_reg <= 0;
			rd_en_reg <= 1;
			data_ready_reg <= 0;	
			
			case (state_reg)
				idle:
					begin					
						if (mem_op) begin														
							// Load Address
							addr_reg <= addr;
							if (read_write) begin
								// Read Operation
								cmd_instr_reg <= read_p;
								state_reg <= read1;
							end
							else begin
								// Write Operation
								cmd_instr_reg <= write_p;
								data_in_reg <= data_in;
								state_reg <= write1;
							end
							// Not ready anymore
							ready_reg <= 0;
						end
					end
				read1:
					begin
						ready_reg <= 0;						
						if (pX_rd_empty) begin
							if (~pX_cmd_full) begin
								cmd_en_reg <= 1;
								state_reg <= read2;
							end
						end
					end
				read2:
					begin
						ready_reg <= 0;
						if (~pX_rd_empty) begin						
							data_out_reg <= pX_rd_data;						
							state_reg <= read3;
						end						
					end
				read3:
					begin	
						ready_reg <= 0;
						data_ready_reg <= 1;							
						state_reg <= idle;
					end
				write1:
					begin
						ready_reg <= 0;
						if (~pX_wr_full) begin
							wr_en_reg <= 1;
							state_reg <= write2;							
						end						
					end
				write2:
					begin
						ready_reg <= 0;
						if (~pX_wr_empty) begin
							if (~pX_cmd_full) begin	
								cmd_en_reg <= 1;
								state_reg <= idle;
							end
						end						
					end
				default: 
					state_reg <= idle;
			endcase
		end
	end
	
	// To FPGA
	assign ready = ready_reg;
	assign data_out = data_out_reg;
	assign data_ready = data_ready_reg;
	
	// Command FIFO
	assign pX_cmd_en = cmd_en_reg;
	assign pX_cmd_instr = cmd_instr_reg;
	assign pX_cmd_bl = 6'b000000;				// Burst Length = 1
	assign pX_cmd_addr = addr_reg;
	
	// Write FIFO
	assign pX_wr_en = wr_en_reg;
	assign pX_wr_mask = 4'b0000;
	assign pX_wr_data = data_in_reg;
	
	// Read FIFO
	assign pX_rd_en = rd_en_reg;

endmodule
