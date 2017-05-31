//////////////////////////////////////////////////////////////////////////////////
// 
// A generalized control module for the TDC DAQ system on the Spartan 6 SP601 FPGA
//
// Designed by: Andrei Hanu 
//
// Create Date:    02/19/2013 
// Last Edited:	 02/20/2013
//
//////////////////////////////////////////////////////////////////////////////////

module Core(
		input wire SYSCLK_P, SYSCLK_N,			// 200 MHz Differential Clock
		input wire reset,	
		
		// UART
		input wire uart_rx,
		output wire uart_tx,
		
		// GPIO Test Headers
		output wire GPIO_HDR0,
		output wire GPIO_HDR1,
		output wire GPIO_HDR2,
		output wire GPIO_HDR3,
		output wire GPIO_HDR4,
		output wire GPIO_HDR5,
		output wire GPIO_HDR6,
		output wire GPIO_HDR7,
		output wire GPIO_LED_0,
		output wire GPIO_LED_1,
		output wire GPIO_LED_2,
		output wire GPIO_LED_3,
		
		// TDC-GPX Signals	
		input wire tdc_ef1,							// FIFO 1 Empty Flag (Active HIGH)
		//input wire tdc_lf1,							// FIFO 1 Load Flag (Active HIGH)
		input wire tdc_irflag,						// Interrupt Flag (Active HIGH)
		//input wire tdc_errflag,						// Error Flag (Active HIGH)
		output wire [3:0] tdc_addr,		 		// Address Register
		output wire tdc_startdis,					// Disable Input 'TStar' (Active HIGH)
		output wire tdc_stopdis,					// Disable Inputs 'TStop1 -> TStop4' (Active HIGH)
		output wire tdc_puresn,						// Power-Up Reset (Active LOW)
		output wire tdc_wrn,				  			// Write Enable Pin (Active LOW)
		output wire tdc_rdn,            			// Read Enable Pin (Active LOW)
		output wire tdc_csn,            			// Chip Select Pin (Active LOW)
		output wire tdc_oen,             		// Output Enable Pin (Active LOW)	
		inout wire [27:0] tdc_d,	  				// Bi-directional data bus
		
		// DDR2 Memory Device Interface Signals
		inout wire [15:0] DDR2_DQ,
		output wire [12:0] DDR2_A,
		output wire [2:0] DDR2_BA,
		output wire DDR2_RAS_N,
		output wire DDR2_CAS_N,
		output wire DDR2_WE_N,
		output wire DDR2_ODT,
		output wire DDR2_CKE,
		output wire DDR2_CK,
		output wire DDR2_CK_N,
		inout wire DDR2_DQS,
		inout wire DDR2_DQS_N,
		inout wire DDR2_UDQS,
		inout wire DDR2_UDQS_N,
		output wire DDR2_UDM,
		output wire DDR2_DM,
		inout wire DDR2_RZQ,
		inout wire DDR2_ZIO
	);
	
	// UART TX Signals 
	wire tx_ready;
	wire [31:0] tx_data_in;
	wire tx_data_ready;
	
	// TDC-GPX Core Control Signals
	wire cntrlPuReSN;
	wire cntrlConfigure;
	wire cntrlStartStop;
	
	// Readout Logic Control Signals
	wire cntrlClearMemory;
	wire cntrlReadData;
	wire [29:0] readAddrStart;
	wire [29:0] readAddrEnd;
	
	// DDR2 MCB Interface	
	wire c3_clk0;
	wire c3_rst0;
	wire c3_calib_done;
	
	// Memory Read/Write Controller Port 0
	wire p0_ready;
	wire [31:0] p0_data_out;
	wire [31:0] p0_data_in;
	wire [29:0] p0_addr;
	wire p0_read_write;
	wire p0_mem_op;
	wire p0_data_ready;
	
	// DDR2 Port 0 Interface
	wire c3_p0_cmd_en;
	wire [2:0] c3_p0_cmd_instr;
	wire [5:0] c3_p0_cmd_bl;
	wire [29:0] c3_p0_cmd_addr;
	wire c3_p0_cmd_empty;
	wire c3_p0_cmd_full;
	wire c3_p0_wr_en;
	wire [3:0]c3_p0_wr_mask;
	wire [31:0] c3_p0_wr_data;
	wire c3_p0_wr_full;
	wire c3_p0_wr_empty;
	wire [6:0] c3_p0_wr_count;
	wire c3_p0_wr_underrun;
	wire c3_p0_wr_error;
	wire c3_p0_rd_en;
	wire [31:0] c3_p0_rd_data;
	wire c3_p0_rd_full;
	wire c3_p0_rd_empty;
	wire [6:0] c3_p0_rd_count;
	wire c3_p0_rd_overflow;
	wire c3_p0_rd_error;
	
	// Memory Read/Write Controller Port 1
	wire p1_ready;
	wire [31:0] p1_data_out;
	wire [31:0] p1_data_in;
	wire [29:0] p1_addr;
	wire p1_read_write;
	wire p1_mem_op;
	wire p1_data_ready;

	// DDR2 Port 1 Interface
	wire c3_p1_cmd_en;
	wire [2:0] c3_p1_cmd_instr;
	wire [5:0] c3_p1_cmd_bl;
	wire [29:0] c3_p1_cmd_addr;
	wire c3_p1_cmd_empty;
	wire c3_p1_cmd_full;
	wire c3_p1_wr_en;
	wire [3:0]c3_p1_wr_mask;
	wire [31:0] c3_p1_wr_data;
	wire c3_p1_wr_full;
	wire c3_p1_wr_empty;
	wire [6:0] c3_p1_wr_count;
	wire c3_p1_wr_underrun;
	wire c3_p1_wr_error;
	wire c3_p1_rd_en;
	wire [31:0] c3_p1_rd_data;
	wire c3_p1_rd_full;
	wire c3_p1_rd_empty;
	wire [6:0] c3_p1_rd_count;
	wire c3_p1_rd_overflow;
	wire c3_p1_rd_error;
	
	// TDC FIFO Signals
	wire [31:0] fifo_tdc_din;
	wire fifo_tdc_wr_en;
	wire fifo_tdc_rd_en;
	wire [31:0] fifo_tdc_dout;
	wire fifo_tdc_full;
	wire fifo_tdc_empty;
	wire fifo_tdc_valid;
	
	// TDC-GPX Read/Write Controller Signals
	wire rw_ready;
	wire [27:0] rw_data_out;
	wire [27:0] rw_data_in;
	wire [3:0] rw_addr;
	wire rw_read_write;
	wire rw_mem_op;	
	wire rw_data_ready;
		
	// Signals used to define baud rate
	reg [10:0] baud_count;							// Baud Rate Counter
	reg en_16_x_baud;	
		
	/////////////////////////////////////////////////////////////////////////////////////////
	// UART TX Controller
	/////////////////////////////////////////////////////////////////////////////////////////
	
	UART_TX_Controller UART_TX_Controller (
		.clk(c3_clk0), 
		.en_16_x_baud(en_16_x_baud), 
		.reset(reset), 
		.uart_tx(uart_tx),
		.ready(tx_ready),
		.data_in(tx_data_in),
		.data_ready(tx_data_ready)
	);
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// UART RX Controller
	/////////////////////////////////////////////////////////////////////////////////////////
	
	UART_RX_Controller UART_RX_Controller (
		.clk(c3_clk0), 
		.en_16_x_baud(en_16_x_baud), 
		.reset(reset), 
		.uart_rx(uart_rx),
		.cntrlPuReSN(cntrlPuReSN),
		.cntrlConfigure(cntrlConfigure),
		.cntrlStartStop(cntrlStartStop),
		.cntrlClearMemory(cntrlClearMemory),
		.cntrlReadData(cntrlReadData),
		.readAddrStart(readAddrStart),
		.readAddrEnd(readAddrEnd)
	);	
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// DDR2 Memory Controller Block (MCB)
	/////////////////////////////////////////////////////////////////////////////////////////
	
	ddr2 # (
		.C3_P0_MASK_SIZE(4),
		.C3_P0_DATA_PORT_SIZE(32),
		.C3_P1_MASK_SIZE(4),
		.C3_P1_DATA_PORT_SIZE(32),
		.DEBUG_EN(0),
		.C3_MEMCLK_PERIOD(3200),
		.C3_CALIB_SOFT_IP("TRUE"),
		.C3_SIMULATION("FALSE"),
		.C3_RST_ACT_LOW(0),
		.C3_INPUT_CLK_TYPE("DIFFERENTIAL"),
		.C3_MEM_ADDR_ORDER("ROW_BANK_COLUMN"),
		.C3_NUM_DQ_PINS(16),
		.C3_MEM_ADDR_WIDTH(13),
		.C3_MEM_BANKADDR_WIDTH(3),
		// multiplier from input source clock to 2x DRAM clock
		.C3_CLKFBOUT_MULT(25),			// 200 * (25/8) = 625 MHz 
		.C3_DIVCLK_DIVIDE(8),
		// user clock generation
		.C3_CLKOUT2_DIVIDE(6)	  		// 625/6 = 104.16 MHz
	)	ddr2_int	(
		.c3_sys_clk_p           (SYSCLK_P),
		.c3_sys_clk_n           (SYSCLK_N),
		.c3_sys_rst_i           (reset),       
		.c3_clk0		        		(c3_clk0),
		.c3_rst0		        		(c3_rst0), 
		.c3_calib_done          (c3_calib_done),		
		.mcb3_dram_dq           (DDR2_DQ),  
		.mcb3_dram_a            (DDR2_A),  
		.mcb3_dram_ba           (DDR2_BA),
		.mcb3_dram_ras_n        (DDR2_RAS_N),                        
		.mcb3_dram_cas_n        (DDR2_CAS_N),                        
		.mcb3_dram_we_n         (DDR2_WE_N),                          
		.mcb3_dram_odt          (DDR2_ODT),
		.mcb3_dram_cke          (DDR2_CKE),                          
		.mcb3_dram_ck           (DDR2_CK),                          
		.mcb3_dram_ck_n         (DDR2_CK_N),       
		.mcb3_dram_dqs          (DDR2_DQS),                          
		.mcb3_dram_dqs_n        (DDR2_DQS_N),
		.mcb3_dram_udqs         (DDR2_UDQS),                           
		.mcb3_dram_udqs_n       (DDR2_UDQS_N),  
		.mcb3_dram_udm          (DDR2_UDM),     
		.mcb3_dram_dm           (DDR2_DM),		
		.mcb3_rzq               (DDR2_RZQ),
      .mcb3_zio               (DDR2_ZIO),
      .c3_p0_cmd_clk          (c3_clk0),
		.c3_p0_cmd_en           (c3_p0_cmd_en),
		.c3_p0_cmd_instr        (c3_p0_cmd_instr),
		.c3_p0_cmd_bl           (c3_p0_cmd_bl),
		.c3_p0_cmd_byte_addr    (c3_p0_cmd_addr),
		.c3_p0_cmd_empty        (c3_p0_cmd_empty),
		.c3_p0_cmd_full         (c3_p0_cmd_full),
		.c3_p0_wr_clk           (c3_clk0),
		.c3_p0_wr_en            (c3_p0_wr_en),
		.c3_p0_wr_mask          (c3_p0_wr_mask),
		.c3_p0_wr_data          (c3_p0_wr_data),
		.c3_p0_wr_full          (c3_p0_wr_full),
		.c3_p0_wr_empty         (c3_p0_wr_empty),
		.c3_p0_wr_count         (c3_p0_wr_count),
		.c3_p0_wr_underrun      (c3_p0_wr_underrun),
		.c3_p0_wr_error         (c3_p0_wr_error),
		.c3_p0_rd_clk           (c3_clk0),
		.c3_p0_rd_en            (c3_p0_rd_en),
		.c3_p0_rd_data          (c3_p0_rd_data),
		.c3_p0_rd_full          (c3_p0_rd_full),
		.c3_p0_rd_empty         (c3_p0_rd_empty),
		.c3_p0_rd_count         (c3_p0_rd_count),
		.c3_p0_rd_overflow      (c3_p0_rd_overflow),
		.c3_p0_rd_error         (c3_p0_rd_error),
		.c3_p1_cmd_clk          (c3_clk0),
		.c3_p1_cmd_en           (c3_p1_cmd_en),
		.c3_p1_cmd_instr        (c3_p1_cmd_instr),
		.c3_p1_cmd_bl           (c3_p1_cmd_bl),
		.c3_p1_cmd_byte_addr    (c3_p1_cmd_addr),
		.c3_p1_cmd_empty        (c3_p1_cmd_empty),
		.c3_p1_cmd_full         (c3_p1_cmd_full),
		.c3_p1_wr_clk           (c3_clk0),
		.c3_p1_wr_en            (c3_p1_wr_en),
		.c3_p1_wr_mask          (c3_p1_wr_mask),
		.c3_p1_wr_data          (c3_p1_wr_data),
		.c3_p1_wr_full          (c3_p1_wr_full),
		.c3_p1_wr_empty         (c3_p1_wr_empty),
		.c3_p1_wr_count         (c3_p1_wr_count),
		.c3_p1_wr_underrun      (c3_p1_wr_underrun),
		.c3_p1_wr_error         (c3_p1_wr_error),
		.c3_p1_rd_clk           (c3_clk0),
		.c3_p1_rd_en            (c3_p1_rd_en),
		.c3_p1_rd_data          (c3_p1_rd_data),
		.c3_p1_rd_full          (c3_p1_rd_full),
		.c3_p1_rd_empty         (c3_p1_rd_empty),
		.c3_p1_rd_count         (c3_p1_rd_count),
		.c3_p1_rd_overflow      (c3_p1_rd_overflow),
		.c3_p1_rd_error         (c3_p1_rd_error)
	);
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// Memory Read\Write Controller (Port 0)
	/////////////////////////////////////////////////////////////////////////////////////////
	
	Memory_Read_Write_Controller P0_RW (
		.clk(c3_clk0), 
		.reset(reset), 
		.ready(p0_ready), 
		.data_out(p0_data_out), 
		.data_in(p0_data_in), 
		.addr(p0_addr), 
		.read_write(p0_read_write), 
		.mem_op(p0_mem_op), 
		.data_ready(p0_data_ready),
		.pX_cmd_en(c3_p0_cmd_en), 
		.pX_cmd_instr(c3_p0_cmd_instr), 
		.pX_cmd_bl(c3_p0_cmd_bl), 
		.pX_cmd_addr(c3_p0_cmd_addr), 
		.pX_cmd_empty(c3_p0_cmd_empty), 
		.pX_cmd_full(c3_p0_cmd_full),
		.pX_wr_en(c3_p0_wr_en), 
		.pX_wr_mask(c3_p0_wr_mask), 
		.pX_wr_data(c3_p0_wr_data), 
		.pX_wr_full(c3_p0_wr_full), 
		.pX_wr_empty(c3_p0_wr_empty), 
		.pX_wr_count(c3_p0_wr_count), 
		.pX_wr_underrun(c3_p0_wr_underrun), 
		.pX_wr_error(c3_p0_wr_error),		
		.pX_rd_en(c3_p0_rd_en), 
		.pX_rd_data(c3_p0_rd_data), 
		.pX_rd_full(c3_p0_rd_full), 
		.pX_rd_empty(c3_p0_rd_empty), 
		.pX_rd_count(c3_p0_rd_count), 
		.pX_rd_overflow(c3_p0_rd_overflow), 
		.pX_rd_error(c3_p0_rd_error));
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// Memory Read\Write Controller (Port 1)
	/////////////////////////////////////////////////////////////////////////////////////////
		
	Memory_Read_Write_Controller P1_RW (
		.clk(c3_clk0), 
		.reset(reset), 
		.ready(p1_ready), 
		.data_out(p1_data_out), 
		.data_in(p1_data_in), 
		.addr(p1_addr), 
		.read_write(p1_read_write), 
		.mem_op(p1_mem_op), 
		.data_ready(p1_data_ready),
		.pX_cmd_en(c3_p1_cmd_en), 
		.pX_cmd_instr(c3_p1_cmd_instr), 
		.pX_cmd_bl(c3_p1_cmd_bl), 
		.pX_cmd_addr(c3_p1_cmd_addr), 
		.pX_cmd_empty(c3_p1_cmd_empty), 
		.pX_cmd_full(c3_p1_cmd_full),
		.pX_wr_en(c3_p1_wr_en), 
		.pX_wr_mask(c3_p1_wr_mask), 
		.pX_wr_data(c3_p1_wr_data), 
		.pX_wr_full(c3_p1_wr_full), 
		.pX_wr_empty(c3_p1_wr_empty), 
		.pX_wr_count(c3_p1_wr_count), 
		.pX_wr_underrun(c3_p1_wr_underrun), 
		.pX_wr_error(c3_p1_wr_error),
		.pX_rd_en(c3_p1_rd_en), 
		.pX_rd_data(c3_p1_rd_data), 
		.pX_rd_full(c3_p1_rd_full), 
		.pX_rd_empty(c3_p1_rd_empty), 
		.pX_rd_count(c3_p1_rd_count), 
		.pX_rd_overflow(c3_p1_rd_overflow), 
		.pX_rd_error(c3_p1_rd_error));	

	/////////////////////////////////////////////////////////////////////////////////////////
	// Readout Controller (DDR2 Readout)
	/////////////////////////////////////////////////////////////////////////////////////////
	
	Readout_Controller Readout_Controller (
		.clk(c3_clk0), 
		.reset(reset), 
		.cntrlReadData(cntrlReadData),
		.cntrlClearMemory(cntrlClearMemory),		
		.readAddrStart(readAddrStart), 
		.readAddrEnd(readAddrEnd),
		.tx_ready(tx_ready),
		.tx_data_in(tx_data_in),
		.tx_data_ready(tx_data_ready),
		.pX_ready(p1_ready), 
		.pX_data_out(p1_data_in), 
		.pX_data_in(p1_data_out), 
		.pX_data_ready(p1_data_ready), 
		.pX_addr(p1_addr), 
		.pX_read_write(p1_read_write), 
		.pX_mem_op(p1_mem_op));
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// TDC-GPX Core Controller
	/////////////////////////////////////////////////////////////////////////////////////////
	TDC_GPX_Controller TDC_GPX_Controller (
		.clk(c3_clk0), 
		.reset(reset), 
		.cntrlPuReSN(cntrlPuReSN), 
		.cntrlConfigure(cntrlConfigure), 
		.cntrlStartStop(cntrlStartStop), 
		.tdc_startdis(tdc_startdis), 
		.tdc_stopdis(tdc_stopdis), 
		.tdc_puresn(tdc_puresn), 
		.tdc_ef1(tdc_ef1), 
		//.tdc_lf1(tdc_lf1), 
		.tdc_irflag(tdc_irflag), 
		//.tdc_errflag(tdc_errflag), 
		.rw_ready(rw_ready), 
		.rw_data_out(rw_data_out), 
		.rw_data_in(rw_data_in), 
		.rw_addr(rw_addr), 
		.rw_read_write(rw_read_write), 
		.rw_mem_op(rw_mem_op),
		.rw_data_ready(rw_data_ready),
		.fifo_full(fifo_tdc_full),
		.fifo_din(fifo_tdc_din),
		.fifo_wr_en(fifo_tdc_wr_en));
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// TDC-GPX Read/Write Controller
	/////////////////////////////////////////////////////////////////////////////////////////
	TDC_GPX_Read_Write_Controller TDC_GPX_Read_Write_Controller (
		.clk(c3_clk0), 
		.reset(reset), 
		.ready(rw_ready), 
		.data_out(rw_data_out), 
		.data_in(rw_data_in), 
		.addr(rw_addr), 
		.read_write(rw_read_write), 
		.mem_op(rw_mem_op), 
		.data_ready(rw_data_ready),
		.tdc_d(tdc_d), 
		.tdc_addr(tdc_addr), 
		.tdc_wrn(tdc_wrn), 
		.tdc_rdn(tdc_rdn), 
		.tdc_csn(tdc_csn), 
		.tdc_oen(tdc_oen));
		
	/////////////////////////////////////////////////////////////////////////////////////////
	// FIFO between TDC Core Controller and Histograming Logic Controller
	/////////////////////////////////////////////////////////////////////////////////////////		
	FIFO FIFO_TDC (
		.clk(c3_clk0),
		.rst(reset),
		.din(fifo_tdc_din),
		.wr_en(fifo_tdc_wr_en),
		.rd_en(fifo_tdc_rd_en),
		.dout(fifo_tdc_dout),
		.full(fifo_tdc_full),
		.empty(fifo_tdc_empty),
		.valid(fifo_tdc_valid));
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// Histogramming Logic Controller
	/////////////////////////////////////////////////////////////////////////////////////////
	
	Histogramming_Controller Histogramming_Controller (
		.clk(c3_clk0), 
		.reset(reset),		
		.pX_ready(p0_ready), 
		.pX_data_out(p0_data_in), 
		.pX_data_in(p0_data_out), 
		.pX_data_ready(p0_data_ready), 
		.pX_addr(p0_addr), 
		.pX_read_write(p0_read_write), 
		.pX_mem_op(p0_mem_op),
		.fifo_dout(fifo_tdc_dout),
		.fifo_rd_en(fifo_tdc_rd_en),
		.fifo_empty(fifo_tdc_empty),
		.fifo_valid(fifo_tdc_valid));
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// GPIO Connections
	/////////////////////////////////////////////////////////////////////////////////////////
	assign GPIO_HDR0 = tdc_ef1;
	assign GPIO_HDR1 = tdc_irflag;
	//assign GPIO_HDR2 = 0;			
	assign GPIO_HDR2 = rw_ready;			
	//assign GPIO_HDR3 = 0;
	assign GPIO_HDR3 = tdc_rdn;
	//assign GPIO_HDR4 = 0;
	assign GPIO_HDR4 = 0;
	//assign GPIO_HDR5 = 0;
	assign GPIO_HDR5 = 0;
	assign GPIO_HDR6 = 0;
	assign GPIO_HDR7 = 0;
	
	assign GPIO_LED_0 = fifo_tdc_empty;
	assign GPIO_LED_1 = fifo_tdc_full;
	assign GPIO_LED_2 = p0_ready;
	assign GPIO_LED_3 = p1_ready;
	
	
	/////////////////////////////////////////////////////////////////////////////////////////
	// RS232 (UART) baud rate 
	/////////////////////////////////////////////////////////////////////////////////////////
	//
	// To get a desired baud rate, the en_16_x_baud must pulse at 16 times faster than the 
	// bit clock.
	//
	// List of baud rate calculations (104.16 MHz clock):
	//
	// 57600 x 16 = 921,600 Hz --> 104.16E6/921600 = 113.028 --> baud_count = 113
	

	always @ (posedge c3_clk0)
	begin
		// Baud Rate: 57600
		if (baud_count == 113) 						
			begin       	
				baud_count <= 11'd0;
				// single cycle enable pulse
				en_16_x_baud <= 1'b1;                 			
			end
		else 
			begin
				baud_count <= baud_count + 11'd1;
				en_16_x_baud <= 1'b0;
			end
	end


endmodule
