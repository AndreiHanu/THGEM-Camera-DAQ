//////////////////////////////////////////////////////////////////////////////////
// 
// UART RX Controller
//
// Receives OP codes from the computer and controls the various output signals to 
// to other FPGA modules
//
// Designed by: Andrei Hanu 
//
// Create Date:    02/20/2013 
// Last Edited:	 03/05/2013
//
//////////////////////////////////////////////////////////////////////////////////

module UART_RX_Controller(
		input wire clk,
		input wire en_16_x_baud,
		input wire reset,		
		input wire uart_rx,
		
		// Control Signals
		output reg cntrlPuReSN,
		output reg cntrlConfigure,
		output reg cntrlStartStop,
		output reg cntrlClearMemory,
		output reg cntrlReadData,
		
		// Read Dimensions
		output reg [15:0] readStartX,
		output reg [15:0] readStartY,
		output reg [15:0] readEndX,
		output reg [15:0] readEndY,
		output reg [7:0] readDivide
		
	);
	
	// Symbolic State Declaration
	localparam [3:0]
		idle 				= 	4'd0,
		opcode 			= 	4'd1,
		addrStart1 		= 	4'd2,
		addrStart2 		= 	4'd3,
		addrStart3 		= 	4'd4,
		addrStart4 		= 	4'd5,
		addrEnd1			= 	4'd6,
		addrEnd2			= 	4'd7,
		addrEnd3			= 	4'd8,
		addrEnd4			= 	4'd9,
		imgDivide		=	4'd10,
		readData 		= 	4'd11;
	
	// Internal Signals/Registers
	reg [3:0] state_reg;
	wire [7:0] rx_data_out;
	reg rx_buffer_read;
	wire rx_data_present;
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// UART Receiver with integral 16 byte FIFO buffer
	/////////////////////////////////////////////////////////////////////////////////////////
		
	uart_rx6 UART_RX(
			.serial_in(uart_rx),
			.en_16_x_baud(en_16_x_baud),
			.data_out(rx_data_out),
			.buffer_read(rx_buffer_read),
			.buffer_data_present(rx_data_present),
			.buffer_half_full(),
			.buffer_full(),
			.buffer_reset(reset),              
			.clk(clk));

	/////////////////////////////////////////////////////////////////////////////////////////
	// Synchronous State Machine
	/////////////////////////////////////////////////////////////////////////////////////////
	// Available Input OP Code:
	//
	//	$1 - Power up Reset
	// $2 - Configure TDC-GPX
	// $3 - Start Acquisition
	// $4 - Stop Acquisition
	// $5 - Clear Memory
	// $6 - Read Memory
	always @(posedge clk, posedge reset) 
	begin
		if (reset) begin
			// Asynchronous Reset
			state_reg <= idle;
			rx_buffer_read <= 1'b0;
			
			cntrlPuReSN <= 1'b0;
			cntrlConfigure <= 1'b0;
			cntrlStartStop <= 1'b0;
			cntrlClearMemory <= 1'b0;
			cntrlReadData <= 1'b0;
			
			readStartX <= 16'd0;
			readStartY <= 16'd0;
			readEndX <= 16'd0;
			readEndY <= 16'd0;
			readDivide <= 8'd0;
		end
		else begin
			// Defaults
			rx_buffer_read <= 1'b0;
			cntrlPuReSN <= 1'b0;
			cntrlConfigure <= 1'b0;
			cntrlClearMemory <= 1'b0;
			cntrlReadData <= 1'b0;
			
			case (state_reg)
			idle: 
				begin
					// Check RX for data
					if(rx_data_present) begin		
						// Signal Buffer Read 
						rx_buffer_read <= 1'b1;	
						
						// Check for '$' character (ASCII character 36)
						if (rx_data_out == 8'h24) begin
							// Check OP code
							state_reg <= opcode;								
						end											
					end
				end
			opcode:
				begin
					// Check RX FIFO for data
					if(rx_data_present && ~rx_buffer_read) begin
						
						// Signal Buffer Read 
						rx_buffer_read <= 1'b1;	
						
						// Default: Return to IDLE
						state_reg <= idle;
						
						// Check for OP code
						case (rx_data_out)
						8'h31:
							// $1 - Power up Reset
							cntrlPuReSN <= 1'b1;						
						8'h32:
							// $2 - Configure TDC-GPX
							cntrlConfigure <= 1'b1;
						8'h33:
							// $3 - Start Acquisition
							cntrlStartStop <= 1'b1;
						8'h34:
							// $4 - Stop Acquisition
							cntrlStartStop <= 1'b0;
						8'h35:
							// $5 - Clear Memory
							cntrlClearMemory <= 1'b1;
						8'h36:
							// $6 - Read Memory
							begin	
								// Read Start & End Address
								state_reg <= addrStart1;								
							end
						endcase						
					end
				end
			addrStart1:
				begin
					if(rx_data_present && ~rx_buffer_read) begin
						// Signal Buffer Read 
						rx_buffer_read <= 1'b1;
						// Load the start X register
						readStartX[7:0] <= rx_data_out;
						// Next Byte
						state_reg <= addrStart2;
					end
				end
			addrStart2:
				begin
					if(rx_data_present && ~rx_buffer_read) begin
						// Signal Buffer Read 
						rx_buffer_read <= 1'b1;
						// Load the start X register
						readStartX[15:8] <= rx_data_out;
						// Next Byte
						state_reg <= addrStart3;
					end
				end
			addrStart3:
				begin
					if(rx_data_present && ~rx_buffer_read) begin
						// Signal Buffer Read 
						rx_buffer_read <= 1'b1;
						// Load the start Y register
						readStartY[7:0] <= rx_data_out;
						// Next Byte
						state_reg <= addrStart4;
					end
				end
			addrStart4:
				begin
					if(rx_data_present && ~rx_buffer_read) begin
						// Signal Buffer Read 
						rx_buffer_read <= 1'b1;
						// Load the start Y register
						readStartY[15:8] <= rx_data_out;
						// Get End Address
						state_reg <= addrEnd1;
					end
				end
			addrEnd1:
				begin
					if(rx_data_present && ~rx_buffer_read) begin
						// Signal Buffer Read 
						rx_buffer_read <= 1'b1;
						// Load the end X register
						readEndX[7:0] <= rx_data_out;
						// Next Byte
						state_reg <= addrEnd2;
					end
				end
			addrEnd2:
				begin
					if(rx_data_present && ~rx_buffer_read) begin
						// Signal Buffer Read 
						rx_buffer_read <= 1'b1;
						// Load the end X register
						readEndX[15:8] <= rx_data_out;
						// Next Byte
						state_reg <= addrEnd3;
					end
				end
			addrEnd3:
				begin
					if(rx_data_present && ~rx_buffer_read) begin
						// Signal Buffer Read 
						rx_buffer_read <= 1'b1;
						// Load the end Y register
						readEndY[7:0] <= rx_data_out;
						// Next Byte
						state_reg <= addrEnd4;
					end
				end
			addrEnd4:
				begin
					if(rx_data_present && ~rx_buffer_read) begin
						// Signal Buffer Read 
						rx_buffer_read <= 1'b1;
						// Load the end Y register
						readEndY[15:8] <= rx_data_out;
						// Read Image Divide Factor
						state_reg <= imgDivide;
					end
				end
			imgDivide:
				begin
					if(rx_data_present && ~rx_buffer_read) begin
						// Signal Buffer Read 
						rx_buffer_read <= 1'b1;
						// Load the image divide register
						readDivide <= rx_data_out;
						// Pulse ReadData control signal
						state_reg <= readData;
					end
				end
			readData:
				begin
					if(~rx_buffer_read) begin
						// Signals cntrlReadData
						cntrlReadData <= 1'b1;
						// Return to IDLE
						state_reg <= idle;
					end					
				end
			default:
				state_reg <= idle;
			endcase
		end
	end

endmodule
