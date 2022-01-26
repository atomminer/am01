//////////////////////////////////////////////////////////////////////////////////
/*
 *  AtomMiner XCA200T FPGA projects
 *  
 *  Copyright 2015-2022 AtomMiner <atom@atomminer.com>
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 3 of the License, or (at your option)
 * any later version. If not, see <http://www.gnu.org/licenses/>.
 *
 */ 
 //////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module atomminer_odocrypt(
	input					gclk,						// K18	LVCMOS33     system clk = 19.2M
	input					pclk,						// W19	LVCMOS33 GPIO[16] in interface master clk = 100M
	inout [31:0]	DQ,							// LVCMOS33    IO data bus
	input					strobe_data,		// W20 LVCMOS33   GPIO[21]  in_strobe data from FX3
	output				we,							// AA19 LVCMOS33  GPIO[18]  out strobe data to FX3
	input					FX3_ready,			// J20 LVCMOS33   GPIO[45]
	output				artix_ready,		// J19 LVCMOS33   GPIO[51]

	(* IOB="true" *) output	reg led_is_go = 1'b0,	// H17 LVCMOS33  GPIO_LED_0
	input   FX3_sos								// M18 
);

wire clk_h, lock_h, clk_100, lock_100;     
wire res_clk;

wire   [31:0] DQ_outbuf_r;
wire   [31:0] DQ_inbuf;
wire   DQ_outenbuf; 
(* IOB="true" *) reg [31:0] DQ_outbuf = 32'b0;
(* IOB="true" *) reg [31:0] DQ_inbuf_reg = 32'h0;
(* IOB="true" *) reg 				strobe_data_reg = 1'b0;

reg [25:0]  cou_led = 26'h0;
reg         cou_led_end = 1'b0;
reg system_host_break_r0 = 1'b0;
reg system_host_break_r1 = 1'b0;  
reg system_host_break_r2 = 1'b0;
reg system_host_break_pulse = 1'b0; 

wire get_midstate, get_block, get_target; 
wire host_break, start_hash, ticket2moon, hash_cmplt; 
wire [31:0] golden_nonce;
wire [31:0]    data_from_host; 

wire  [607:0] header;
wire  [255:0] target;
	 
reg [7:0] cou_deltanonce_top = 8'b0; 
reg nonce_out_go_top = 1'b0;
reg ticket2moon_i = 1'b0;
//  
	artix200_v3_clocking artix200_v3_clocking
		(
		 // Clock out ports
		 .clk_out1(clk_h),     // output clk_out1
		 // Status and control signals
		 .reset(res_clk), // input reset
		 .locked(lock_h),       // output locked
		// Clock in ports
		 .clk_in1(gclk));    
	//
	clk_pclk clk_pclk
	(
	// Clock out ports
	.clk_out1(clk_100),     // output clk_out1
	// Status and control signals
	.reset(1'b0), // input reset
	.locked(lock_100),       // output locked
	// Clock in ports
	.clk_in1(pclk));      // input clk_in1
	//
	genvar i;
	generate
	 for (i=0; i < 32; i=i+1)
	 begin: BUFs          
	IOBUF #(
	 .DRIVE(12), // Specify the output drive strength
	 .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
	 .IOSTANDARD("LVCMOS33"), // Specify the I/O standard
	 .SLEW("FAST") // Specify the output slew rate
	) IOBUF_inst (
	 .O(DQ_inbuf[i]),     // Buffer output
	 .IO(DQ[i]),   // Buffer inout port (connect directly to top-level port)
	 .I(DQ_outbuf[i]),     // Buffer input
	 .T(~DQ_outenbuf)      // 3-state enable input, high=input, low=output
	);
	end
	endgenerate 
	//
	always @ (posedge clk_100) 
	begin
		DQ_inbuf_reg <= DQ_inbuf;
		strobe_data_reg <= strobe_data;
		DQ_outbuf <= DQ_outbuf_r;
	end
	//
	assign we = DQ_outenbuf;
	//
	always @ (posedge clk_100)    
	 if (cou_led_end)//
		cou_led <= 26'h0;
	else 
		cou_led <= cou_led + 1'b1;
	//
	always @ (posedge clk_100)
	 if (lock_h & lock_100)
		cou_led_end <= cou_led == 26'h2FAF080;//0.5 s 2FAF080   for sim 100
	else if (FX3_ready)
		cou_led_end <= cou_led == 26'h1FAF080;// 0.125s  BEBC20         for sim 40
	else if (~FX3_ready)
		cou_led_end <= cou_led == 26'h17D7840;//0.25 s   17D7840    for sim 80
	//
		always @ (posedge clk_100)
		if (start_hash | ~FX3_sos)
			led_is_go <= 1'b0;
		else if (cou_led_end)
			led_is_go <= ~led_is_go;
//
usb3_interface  usb3_interface
(
.clk_h(clk_h),      //in   system clk
.clk_100(clk_100),        //in  interface master clk = 100M
.lock_100(lock_100),
.res_clk(res_clk), // out 
.lock_h(lock_h),  // in 
.host_break(host_break),//
// bus ports  
 .DQ_inbuf_reg(DQ_inbuf_reg),
 .strobe_data_reg(strobe_data_reg),
 .DQ_outbuf_r(DQ_outbuf_r),  
 .DQ_outenbuf(DQ_outenbuf),              
.FX3_ready(FX3_ready),            //in  J20     GPIO[45] active low
.artix_ready(artix_ready),        //out  J19    GPIO[51] active low 
//
// system ports clk_h domain
.data_from_host(data_from_host),          //out { block data[31:0] =  20DWords, target[31:0] = 8 DWords, reserve[31:0] = reserve }
.get_midstate(get_midstate),
.get_block (get_block),
.get_target(get_target),
//
.start_hash(start_hash),// out
.nonce(golden_nonce),                             // in, nonce = 32'hffff - not success, nonce = golden_nonce - success
.ticket2moon(ticket2moon_i),
.hash_cmplt(1'b0)//hash_cmplt
); 
// 
always @ (posedge clk_h)
begin
system_host_break_r0 <= strobe_data_reg;
system_host_break_r1 <= system_host_break_r0;
system_host_break_r2 <= system_host_break_r1;
system_host_break_pulse <= ~system_host_break_r2 & system_host_break_r1;
end
//                
//host_break_machine
//
host_break_sm host_break_sm 
(
.clk_h(clk_h),  
.host_break(system_host_break_pulse),          
.ticket2moon(ticket2moon_i),  //1'b0      
.hash_cmplt (1'b0),//hash_cmplt
//
.sha_host_break(host_break)
); 
//     
	
odo_block_data odo_block_data(
.clk_h(clk_h), 
.data_from_host_in(data_from_host),          //in { block data[31:0] =  20DWords, target[31:0] = 8 DWords, reserve[31:0] = reserve }
.get_midstate_in(get_midstate),
.get_block_in(get_block),
.get_target_in(get_target),
//
// to downcoming core
.header(header),  
.target(target)           
	); 
 
 
 
 
 
 
	
miner_top miner_top(
	.osc_clk(clk_h),
	.header(header),//[607:0] 
	.target(target),//[255:0] 
	.start_hash(start_hash),
	//
	.ticket2moon(ticket2moon),
	.nonce(golden_nonce)//[31:0] 
	
	);    
	
									 
	 always @ (posedge clk_h)
		if (~start_hash)   cou_deltanonce_top <= 8'b0;                                                                                
		else cou_deltanonce_top <= cou_deltanonce_top + 1'b1;
		 //
	 always @ (posedge clk_h)
		if (~start_hash) nonce_out_go_top <= 1'b0;
		 else if ( cou_deltanonce_top == 8'hcd)  nonce_out_go_top <= 1'b1;           
	
		always @ (posedge clk_h) ticket2moon_i <= ticket2moon &  nonce_out_go_top;  
	
	
	
	
	
	
endmodule
