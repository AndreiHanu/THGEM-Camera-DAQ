//////////////////////////////////////////////////////////////////////////////////
// 
// UART TX Controller
//
// Receives data from the Readout Controller and sends it out to the PC.
//
// Designed by: Andrei Hanu 
//
// Create Date:    02/20/2013 
// Last Edited:	 02/20/2013
//
//////////////////////////////////////////////////////////////////////////////////
module UART_TX_Controller(
		input wire clk,
		input wire en_16_x_baud,
		input wire reset,		
		output wire uart_tx,
		
		// Status Signals
		output wire ready,
		
		// Readout Controller Signals
		input wire [31:0] data_in,			// Data to be sent to UART
		input wire data_ready				// Data ready strobe
		
	);
	
	// Symbolic State Declaration
	localparam [3:0]
		idle 		= 	4'd0,
		write1 	= 	4'd1,
		wait1		= 	4'd2,
		write2 	= 	4'd3,
		wait2		= 	4'd4,
		write3 	= 	4'd5,
		wait3		= 	4'd6,
		write4 	= 	4'd7,
		wait4		= 	4'd8;
	
	// Internal Signals/Registers
	reg [3:0] state_reg, state_next;
	reg ready_reg, ready_buff;		
	reg [31:0] data_in_reg, data_in_next;	
	
	reg [7:0] tx_data_in_reg, tx_data_in_next;
	reg tx_buffer_write_reg, tx_buffer_write_buff;
	wire tx_full;
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// UART Transmitter with integral 16 byte FIFO buffer
	/////////////////////////////////////////////////////////////////////////////////////////

	uart_tx6 UART_TX(
			.serial_out(uart_tx),
			.en_16_x_baud(en_16_x_baud),
			.data_in(tx_data_in_reg),				
			.buffer_write(tx_buffer_write_reg),
			.buffer_data_present(),
			.buffer_half_full(),
			.buffer_full(tx_full),
			.buffer_reset(reset),              
			.clk(clk));
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// TX State Machine
	/////////////////////////////////////////////////////////////////////////////////////////
	
	// FSMD state & data registers
	always @(posedge clk, posedge reset) 
	begin
		if (reset) begin
			state_reg <= idle;
			ready_reg <= 1'b1;
			data_in_reg <= 32'd0;
			tx_data_in_reg <= 8'd0;			
			tx_buffer_write_reg <= 1'b0;			
		end
		else begin
			state_reg <= state_next;
			ready_reg <= ready_buff;
			data_in_reg <= data_in_next;			
			tx_data_in_reg <= tx_data_in_next;			
			tx_buffer_write_reg <= tx_buffer_write_buff;
		end
	end
	
	// FSMD next-state logic
	always @*
	begin
		// Defaults
		state_next = state_reg;
		data_in_next = data_in_reg;		
		tx_data_in_next = tx_data_in_reg;		
		
		case (state_reg)
		idle:
			begin	
				if (data_ready) begin
					// Read the data
					data_in_next = data_in;
					// Write first byte
					state_next = write1;
				end
			end
		write1:
			begin	
				if (~tx_full) begin
					tx_data_in_next[7:0] = data_in_reg[7:0];
					state_next = wait1;
				end
			end
		wait1:
			begin
				state_next = write2;
			end
		write2:
			begin	
				if (~tx_full) begin
					tx_data_in_next[7:0] = data_in_reg[15:8];
					state_next = wait2;
				end
			end
		wait2:
			begin
				state_next = write3;
			end
		write3:
			begin	
				if (~tx_full) begin
					tx_data_in_next[7:0] = data_in_reg[23:16];
					state_next = wait3;
				end
			end
		wait3:
			begin
				state_next = write4;
			end
		write4:
			begin	
				if (~tx_full) begin
					tx_data_in_next[7:0] = data_in_reg[31:24];
					state_next = wait4;
				end
			end
		wait4:
			begin
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
		tx_buffer_write_buff = 1'b0;
		
		case (state_next)
		idle:
			begin
				ready_buff = 1'b1;				
			end
		write1:
			begin
			end
		wait1:
			begin
				tx_buffer_write_buff = 1'b1;
			end
		write2:
			begin						
			end
		wait2:
			begin
				tx_buffer_write_buff = 1'b1;
			end
		write3:
			begin				
			end
		wait3:
			begin
				tx_buffer_write_buff = 1'b1;
			end
		write4:
			begin				
			end
		wait4:
			begin
				tx_buffer_write_buff = 1'b1;
			end
		endcase
	end
	
	assign ready = ready_reg;


endmodule
