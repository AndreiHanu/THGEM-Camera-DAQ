
© Copyright 2010-2012, Xilinx, Inc. All rights reserved.
This file contains confidential and proprietary information of Xilinx, Inc. and is
protected under U.S. and international copyright and other intellectual property laws.

Disclaimer:
  This disclaimer is not a license and does not grant any rights to the materials
  distributed herewith. Except as otherwise provided in a valid license issued to you
  by Xilinx, and to the maximum extent permitted by applicable law: (1) THESE MATERIALS
  ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL
  WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED
  TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR
  PURPOSE; and (2) Xilinx shall not be liable (whether in contract or tort, including
  negligence, or under any other theory of liability) for any loss or damage of any
  kind or nature related to, arising under or in connection with these materials,
  including for any direct, or any indirect, special, incidental, or consequential
  loss or damage (including loss of data, profits, goodwill, or any type of loss or
  damage suffered as a result of any action brought by a third party) even if such
  damage or loss was reasonably foreseeable or Xilinx had been advised of the
  possibility of the same.

CRITICAL APPLICATIONS
  Xilinx products are not designed or intended to be fail-safe, or for use in any
  application requiring fail-safe performance, such as life-support or safety devices
  or systems, Class III medical devices, nuclear facilities, applications related to
  the deployment of airbags, or any other applications that could lead to death,
  personal injury, or severe property or environmental damage (individually and
  collectively, "Critical Applications"). Customer assumes the sole risk and
  liability of any use of Xilinx products in Critical Applications, subject only to
  applicable laws and regulations governing limitations on product liability.

THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES. 



-------------------------------------------------------------------------------------------------
UART Macros for Spartan-6, Virtex-6 and 7-Series Devices 
-------------------------------------------------------------------------------------------------

Release 2.

30th April 2012

Ken Chapman - Xilinx Ltd - email:chapman@xilinx.com


Welcome to the second release of the UART macros optimised for Spartan-6, Virtex-6 and 7-Series 
devices and ideally suited for use with PicoBlaze (KCPSM6). 

There have been no changes to the actual UART macros since the first release. This update 
adds a verilog version of the hardware reference design and the software reference code is
now defined by two PSM files to provide an example of the INCLUDE directive and to make the 
UART code more portable. Some small changes and corrections have been made to the documentation.

Xilinx Technical Support is available to answer your questions. However it is recommended that
you take the time to consider exactly what your issue is before asking any questions. Just 
because your design contains the UART macros (and probably a PicoBlaze processor) it doesn't 
mean you actually have a problem with either! Page 13 of the 'UART6_User_Guide' recommends 
steps to debug a UART communication link and every item on this list should be checked before 
contacting Xilinx Technical Support.

http://www.xilinx.com/support/clearexpress/websupport.htm


-------------------------------------------------------------------------------------------------
Principle Features of 'uart_tx6' and 'uart_rx6' macros.
-------------------------------------------------------------------------------------------------

  - 8-bit data, 1 stop bit, no parity.
  - User definable baud rate.
  - Integrated 16-byte FIFO buffers.
  - Performance of >10mbps (baud rate) achievable depending on device family and clock rate. 
  - No handshake but signals provided facilitate implementation of soft or hardware schemes.
  - Each macro is only 5 Slices including the FIFO buffer.
  - Ideal peripherals for PicoBlaze (KCPSM6).


-------------------------------------------------------------------------------------------------
'UART' Directory Contents
-------------------------------------------------------------------------------------------------


               UART6_README.txt - This file!

 UART6_User_Guide_30April12.pdf - The main UART6 User Guide document.

                   uart_tx6.vhd - UART transmitter with integrated 16-byte FIFO buffer.

                   uart_rx6.vhd - UART receiver with integrated 16-byte FIFO buffer.

                uart6_ml605.vhd - KCPSM6 reference design using 'uart_tx6' and 'uart_rx6'.
                                  Design is described in the PDF document.
                                  Can be used as provided with the ML605 evaluation board.

               uart_control.psm - Top level KCPSM6 program for 'uart6_ml605' reference design.
                                  INCLUDE directive used to include 'uart_interface_routines.psm'.
 
    uart_interface_routines.psm - UART interface definition and UART routines.

                uart6_ml605.ucf - Constraints file when using reference with ML605 board.
 
                     uart_tx6.v - Verilog equivalent of 'uart_tx6.vhd'.
 
                     uart_rx6.v - Verilog equivalent of 'uart_rx6.vhd'.

                  uart6_ml605.v - Verilog equivalent of 'uart6_ml605.vhd'.


-------------------------------------------------------------------------------------------------
Requirements
-------------------------------------------------------------------------------------------------

ISE v12.x or later.

To state the obvious, these macros are optimised for Spartan-6 and Virtex-6 devices. They will
NOT map to any previous generations of device including Spartan-3 Generation and Virtex-5.

The KCPSM6 reference design requires the KCPSM6 Assembler v1.21 or later. In theory you are only 
reading this file because you have a complete PicoBlaze package that contains v2.00 of the 
assembler so just make sure you run that version from now on. Alternatively, please visit the 
PicoBlaze Lounge (www.xilinx.com/picoblaze) and download the latest KCPSM6 package (ZIP file).

-------------------------------------------------------------------------------------------------
Changes and Additions
-------------------------------------------------------------------------------------------------


Since Release 1
---------------

Enhancements to documentation only.



-------------------------------------------------------------------------------------------------
Known Issues
-------------------------------------------------------------------------------------------------



Terminal only displays everything on one line
---------------------------------------------

As shown in the 'uart_control.psm' reference program it is common practice for each line to end 
with only a carriage return character (0D hex). Your terminal should be configured to append a 
line feed automatically to a carriage return. In HyperTerminal this is the 'Append line feeds 
to incoming line ends' option in the ASCII Setup menu. 



Incorrect removal of logic during implementation
------------------------------------------------

Setting 'global_opt' option in MAP to 'speed', 'area' or 'power' may result in the incorrect 
removal of the serial input to the receiver which leads on to the removal of the whole macro!
A good implementation is realised when 'global_opt' is set to 'off' (the default setting).

This issue was observed when using ISE v12.4 and may also apply to earlier and later versions of
ISE. However, the cause was located and then fixed in ISE v13.4 so you must use ISE v13.4 when 
'global_opt' needs to be used for other parts of your design.

Note that 'global_opt' is only applicable to Spartan-6 and Virtex-6 designs so this should 
never be an issue for 7-Series designs.



The first few characters are corrupted but then everything works as expected
----------------------------------------------------------------------------

This can occur when the UART macros are used to transmit characters to a PC almost immediately 
after the device is configured. The simple solution is to implement a delay (e.g. ~1 second) 
before the first transmission is attempted. This is very easy to arrange when using PicoBlaze. 

Should this issue occur it is almost certainly the case that the UART communications involve a
USB/UART converter device with a corresponding Virtual COM Port driver on the PC. Whilst the UART
transmitter macro transmits characters correctly, it is not entirely fair to blame the USB/UART 
arrangement because the serial communication is ultimately recovering from what is known as a 
'break condition'. In other words, until the FPGA was configured, there was nothing to define 
the state of the serial line. In theory, a serial line should be parked High when not active 
but in this case it has probably been Low which would be consistent with a broken or disconnected
link. Depending on the vendor of the device and driver, it appears that some take more time to 
recover from the break condition. Again to be fair, the serial line really needs to be High 
long enough for the first start bit Low to be recognised correctly and typical baud rates are 
slow relative to the typical clock speeds used in FPGA designs.   




-------------------------------------------------------------------------------------------------
Hints and Tips
-------------------------------------------------------------------------------------------------


Simulation
----------

As covered in the main documentation, a UART can appear very slow relative to the clock so if
you want to see an output from UART_TX6 or simulate an input to UART_RX6 then just remember that 
your simulation may be rather long or you really need to zoom out to see the waveforms.

When performing a functional simulation it is your responsibility to ensure that all your 
stimuli have defined values at time zero to represent what would happen in the real silicon. 
In particular the circuit you use to generate the 'en_16_x_baud' pulses should be such that this
signal also has a defined value before the first rising edge is applied to the clock input of 
UART_TX6. The easiest way to do this is to make sure that initial values are defined. E.g....

signal en_16_x_baud : std_logic := '0';
 


-------------------------------------------------------------------------------------------------
UART pin assignments for commonly used boards
-------------------------------------------------------------------------------------------------


Drigmorn3 (www.enterpoint.co.uk) 
--------------------------------

NET "uart_rx" LOC = "G11" | IOSTANDARD = LVTTL;
NET "uart_tx" LOC = "A11" | IOSTANDARD = LVTTL | SLEW = SLOW | DRIVE = 4;


LX9 Microboard: AES-S6MB-LX9-G (www.em.avnet.com/drc)
-----------------------------------------------------

NET "rs232_rx"  LOC = "R7" | IOSTANDARD = LVCMOS33;
NET "rs232_tx"  LOC = "T7" | IOSTANDARD = LVCMOS33 | SLEW = SLOW | DRIVE = 4;


LX16 Evaluation board: AES-S6EV-LX16-G (www.em.avnet.com/drc)
-------------------------------------------------------------

NET "rs232_rx"  LOC = "H13" | IOSTANDARD = LVCMOS33;
NET "rs232_tx"  LOC = "H14" | IOSTANDARD = LVCMOS33 | SLEW = SLOW | DRIVE = 4;


ATLYS  (www.digilentinc.com)
----------------------------

NET "rs232_rx"  LOC = "A16" | IOSTANDARD = LVCMOS33;
NET "rs232_tx"  LOC = "B16" | IOSTANDARD = LVCMOS33 | SLEW = SLOW | DRIVE = 4;


SP601 
-----

NET "uart_rx" LOC = "K14" | IOSTANDARD = LVCMOS25;
NET "uart_tx" LOC = "L12" | IOSTANDARD = LVCMOS25 | SLEW = SLOW | DRIVE = 4;


SP605  (www.xilinx.com)
-----------------------

NET "uart_rx" LOC = "H17" | IOSTANDARD = LVCMOS25;
NET "uart_tx" LOC = "B21" | IOSTANDARD = LVCMOS25 | SLEW = SLOW | DRIVE = 4;


ML605 (www.xilinx.com)
----------------------

NET "uart_rx" LOC = "J24" | IOSTANDARD = LVCMOS25;
NET "uart_tx" LOC = "J25" | IOSTANDARD = LVCMOS25 | SLEW = SLOW | DRIVE = 4;


KC705 (www.xilinx.com)
----------------------

(Correct for Rev.D board but check pin assignments if using an earlier revision) 

NET "uart_rx" LOC = "M19" | IOSTANDARD = LVCMOS25;
NET "uart_tx" LOC = "K24" | IOSTANDARD = LVCMOS25 | SLEW = SLOW | DRIVE = 4;


VC707 (www.xilinx.com)
----------------------

NET "uart_rx" LOC = "AU33" | IOSTANDARD = LVCMOS18;
NET "uart_tx" LOC = "AU36" | IOSTANDARD = LVCMOS18 | SLEW = SLOW | DRIVE = 4;


-------------------------------------------------------------------------------------------------
End of file 'UART6_README.txt'
-------------------------------------------------------------------------------------------------
