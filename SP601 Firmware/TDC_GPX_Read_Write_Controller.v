//////////////////////////////////////////////////////////////////////////////////
//
// A TDC-GPX Read/Write Controller Module which handles the timing of the various
// signals required to perform a read or write operation on the TDC-GPX.
//
// Designed by: Andrei Hanu 
// 
// Create Date:    07/24/2012 
// Last Edited:	 02/22/2013
//
//////////////////////////////////////////////////////////////////////////////////
module TDC_GPX_Read_Write_Controller(
		// Synchronous Clock & Asynchronous Reset
		input wire clk, reset,
		
		// To & From The Main Controller
		output wire ready,              				// Controller status signal
		output wire [27:0] data_out,					// Data from the TDC-GPX
		input wire [27:0] data_in,     				// Data to the TDC-GPX	
		input wire [3:0] addr,          				// Address on TDC-GPX
		input wire read_write,		     				// Specifies read (1) or write (0) operation
		input wire mem_op,				  				// Initiate memory operation ( mem_op == 1 )		
		output wire data_ready,							// Data ready strobe (1 clock cycle)
		
		// To & From TDC-GPX Chip
		inout wire [27:0] tdc_d,		 				// Bi-directional data bus
		output wire [3:0] tdc_addr,		  			// Address Register
		output wire tdc_wrn,				 				// Write Enable Pin (Active Low)
		output wire tdc_rdn,            				// Read Enable Pin (Active Low)
		output wire tdc_csn,            				// Chip Select Pin (Active Low)
		output wire tdc_oen            				// Output Enable Pin (Active Low)
	);
	// Symbolic State Declaration
	localparam [3:0]
		idle 		= 4'b0000,
		write1 	= 4'b0001,
		write2 	= 4'b0010,
		write3 	= 4'b0011,
		write4 	= 4'b0100,
		read1 	= 4'b0101,
		read2 	= 4'b0110,
		read3 	= 4'b0111,
		read4 	= 4'b1000;
		
	// Internal Signal Declaration
	reg ready_reg, ready_buff;
	reg [3:0] state_reg, state_next;					// State register
	reg [27:0] data_out_reg, data_out_next;		// Data from TDC to FPGA
	reg [27:0] data_in_reg, data_in_next;			// Data from FPGA to TDC
	reg [3:0] addr_reg, addr_next;					// Address on TDC-GPX register
	reg tri_reg, tri_buff;								// Tri-state buffer (Active Low)
	reg tdc_wrn_reg, tdc_wrn_buff;					// Write Enable 
	reg tdc_rdn_reg, tdc_rdn_buff;					// Read Enable 
	reg tdc_csn_reg, tdc_csn_buff;					// Chip Select 
	reg tdc_oen_reg, tdc_oen_buff;					// Output Enable
	reg data_ready_reg, data_ready_buff;			// Data ready strobe
	
	// FSMD state & data registers
	always @(posedge clk, posedge reset) 
	begin
		if (reset) 
			begin
				state_reg <= idle;
				ready_reg <= 1;
				data_out_reg <= 0;
				data_in_reg <= 0;
				addr_reg <= 0;
				tri_reg <= 1;
				tdc_wrn_reg <= 1;
				tdc_rdn_reg <= 1;
				tdc_csn_reg <= 1;
				tdc_oen_reg <= 1;
				data_ready_reg <= 0;
			end
		else 
			begin
				state_reg <= state_next;
				ready_reg <= ready_buff;
				data_out_reg <= data_out_next;
				data_in_reg <= data_in_next;
				addr_reg <= addr_next;
				tri_reg <= tri_buff;
				tdc_wrn_reg <= tdc_wrn_buff;
				tdc_rdn_reg <= tdc_rdn_buff;
				tdc_csn_reg <= tdc_csn_buff;
				tdc_oen_reg <= tdc_oen_buff;
				data_ready_reg <= data_ready_buff;
			end
	end	
	
	// FSMD next-state logic
	always @*
	begin
		// Default Conditions (keep same value)
		data_out_next = data_out_reg;
		data_in_next = data_in_reg;
		addr_next = addr_reg;		
		
		case (state_reg)
			idle:
				begin					
					if (~mem_op) 
						// Loop the same state
						state_next = idle;
					else 
						begin
							// Load the address
							addr_next = addr;
							// Read or Write operation
							if (read_write) 
								// Read Operation
								begin									
									state_next = read1;		
								end
							else 
								// Write Operation
								begin
									data_in_next = data_in;  
									state_next = write1;
								end							
						end
				end
			write1:
				begin
					state_next = write2;															
				end
			write2:
				begin
					state_next = write3;									
				end
			write3:
				begin					
					state_next = write4;
				end
			write4:
				begin
					state_next = idle;			
				end
			read1:
				begin					
					state_next = read2;	
				end
			read2:
				begin					
					state_next = read3;
				end
			read3:
				begin										
					state_next = read4;
				end
			read4:
				begin						
					data_out_next = tdc_d;
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
		ready_buff = 1'b0;
		tri_buff = 1'b1;									// (Active LOW)
		tdc_wrn_buff = 1'b1;								// (Active LOW)
		tdc_rdn_buff = 1'b1;								// (Active LOW)
		tdc_csn_buff = 1'b1;								// (Active LOW)
		tdc_oen_buff = 1'b1;								// (Active LOW)
		data_ready_buff = 1'b0;
		
		case (state_next)
		idle:
			begin
				ready_buff = 1'b1;	
				if (state_reg == read4) begin
					data_ready_buff = 1'b1;
				end
			end
		write1:
			begin
			end
		write2:
			begin
				tdc_wrn_buff = 1'b0;
				tdc_csn_buff = 1'b0;
				tri_buff = 1'b0;
			end
		write3:
			begin
				tdc_wrn_buff = 1'b0;
				tdc_csn_buff = 1'b0;
				tri_buff = 1'b0;
			end
		write4:
			begin
				tri_buff = 1'b0;
			end
		read1:
			begin
			end
		read2:
			begin
				tdc_rdn_buff = 1'b0;
				tdc_csn_buff = 1'b0;
				tdc_oen_buff = 1'b0;
			end
		read3:
			begin
				tdc_rdn_buff = 1'b0;
				tdc_csn_buff = 1'b0;
				tdc_oen_buff = 1'b0;
			end
		read4:
			begin
				tdc_rdn_buff = 1'b0;
				tdc_csn_buff = 1'b0;
				tdc_oen_buff = 1'b0;
			end
		endcase
	end
	
	// To Main System
	assign ready = ready_reg;
	assign data_out = data_out_reg;
	assign data_ready = data_ready_reg;
	
	// To TDC-GPX
	assign tdc_addr = addr_reg;
	assign tdc_wrn = tdc_wrn_reg;
	assign tdc_rdn = tdc_rdn_reg;
	assign tdc_csn = tdc_csn_reg;
	assign tdc_oen = tdc_oen_reg;
	
	// Bi-directional bus to and from TDC-GPX (tri-stated)
	// In write state, tri_reg is LOW and the bus carries the data from the FPGA
	// In read state, tri_reg is HIGH and the bus carries the data from the TDC
	assign tdc_d = (~tri_reg) ? data_in_reg : 28'bZ;


endmodule
