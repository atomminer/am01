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

module usb3_interface(
	input						clk_h,					// in  system clk
	input						clk_100,				// in  interface master clk = 100M
	input						lock_100,
	output					res_clk,				// out 
	input						lock_h,					// in
	input						host_break,
	// bus ports clk_100 domain
	input [31:0]		DQ_inbuf_reg,
	input						strobe_data_reg,
	output [31:0]		DQ_outbuf_r,
	output					DQ_outenbuf,
	//
	input						FX3_ready,			//in   J20    GPIO[45] active low
	output					artix_ready ,		//out  J19    GPIO[51] active low 
	//
	output [31:0]		data_from_host,	//out { block data[31:0] =  20DWords, target[31:0] = 8 DWords, reserve[31:0] = reserve }
	output reg			get_midstate = 1'b0,
	output reg			get_block = 1'b0,
	output reg			get_target = 1'b0,
	//
	output reg      start_hash = 1'b0,
	input [31:0]    nonce,
	input           ticket2moon,
	input           hash_cmplt
);
//
wire system_ram_we_100;
wire [9:0]  system_ram_addr_100;
reg  [9:0]  system_ram_addr_h = 10'h0;
wire [31:0] data_to_systemram_100;
reg  [31:0] status4_coin = 32'h0;
reg  [31:0] golden_nonce = 32'h0;
reg  go_success = 1'b0;
reg  go_unsuccess = 1'b0;
wire data_from_host_rdy;
//
reg [6:0] send_block_sm = 7'h1;
reg [4:0] block_cou = 5'h0;

reg block_cou_res = 1'b0, block_cou_en = 1'b0;
reg data_from_host_rdyh_r1 = 1'b0; 
reg data_from_host_rdyh_r2 = 1'b0; 
reg data_from_host_rdyh_r3 = 1'b0; 
reg data_from_host_rdyh    = 1'b0;
reg data_from_host_rdyh1 = 1'b0;
reg get_midstate_go = 1'b0;
wire get_block_go, get_target_go, get_start_go;

//System_RAM
usb3_system_ram usb3_system_ram
(
	.clka(clk_100),								// input wire clka
	.wea(system_ram_we_100),			// input wire [0 : 0] wea
	.addra(system_ram_addr_100),	// input wire [9 : 0] addra
	.dina(data_to_systemram_100),	// input wire [31 : 0] dina
	.douta(DQ_outbuf_r),					// output wire [31 : 0] douta
	.clkb(clk_h),									// input wire clkb
	.web(1'b0),										// input wire [0 : 0] web
	.addrb({5'h0, block_cou}),		// input wire [9 : 0] addrb
	.dinb(32'h0),									// input wire [31 : 0] dinb
	.doutb(data_from_host)				// output wire [31 : 0] doutb
);

always @ (posedge clk_h)
begin
	data_from_host_rdyh_r1 <= data_from_host_rdy;
	data_from_host_rdyh_r2 <= data_from_host_rdyh_r1;
	data_from_host_rdyh_r3 <= data_from_host_rdyh_r2;
	data_from_host_rdyh <= data_from_host_rdyh_r3 & ~data_from_host_rdyh_r2;
end

always @ (posedge clk_h)
	if (start_hash) block_cou_en <= 1'b0;
	else if (data_from_host_rdyh) block_cou_en <= 1'b1;
										
always @ (posedge clk_h)
	if (host_break) start_hash <= 1'b0;
	else if (get_start_go) start_hash <= 1'b1;

always @ (posedge clk_h) 
begin
	data_from_host_rdyh1 <= data_from_host_rdyh;
	get_midstate_go <= data_from_host_rdyh1; 
end
 
delreg_varbits_vardel  
#( .data_width(1), .clock_cycles(7) )
delreg_varbits_vardel_getblock (
	.clk(clk_h),
	.en(1'b1),
	.data_in(get_midstate_go),
	.data_out(get_block_go)
);

delreg_varbits_vardel  
#( .data_width(1), .clock_cycles(10) )
delreg_varbits_vardel_gettarget (
	.clk(clk_h),
	.en(1'b1),
	.data_in(get_block_go),
	.data_out(get_target_go)
);

delreg_varbits_vardel  
#( .data_width(1), .clock_cycles(6) )
delreg_varbits_vardel_getstart (
	.clk(clk_h),
	.en(1'b1),
	.data_in(get_target_go),
	.data_out(get_start_go)
);

always @ (posedge clk_h)
	if (start_hash) block_cou <= 5'h0;
	else if (block_cou_en) block_cou <= block_cou + 1'b1;

always @ (posedge clk_h)
	if (start_hash) 
	begin
		get_midstate <= 1'b0;
		get_block <= 1'b0;
		get_target <= 1'b0; 
	end
	else if (get_midstate_go) 
	begin
		get_midstate <= 1'b1;
		get_block <= 1'b0;
		get_target <= 1'b0; 
	end
	else if (get_block_go) 
	begin
		get_midstate <= 1'b0;
		get_block <= 1'b1;
		get_target <= 1'b0; 
	end
	else if (get_target_go) 
	begin
		get_midstate <= 1'b0;
		get_block <= 1'b0;
		get_target <= 1'b1; 
	end

// Interface status SM
usb3_sm_v3 usb3_sm_v3
(
	.clk_100(clk_100),
	.lock_h(lock_h),
	.lock_100(lock_100),
	.FX3_ready( FX3_ready ),
	.strobe_data(strobe_data_reg),
	.DQ_inbuf(DQ_inbuf_reg),
	.status4_coin(status4_coin),
	.golden_nonce(golden_nonce),
	.res_clk(res_clk),
	.artix_ready(artix_ready),
	.DQ_outenbuf(DQ_outenbuf),
	.system_ram_we_100(system_ram_we_100),
	.system_ram_addr_100(system_ram_addr_100),
	.data_to_systemram_100(data_to_systemram_100),
	.data_from_host_rdy(data_from_host_rdy)
 );

//clock transfer
always @ (posedge clk_h)
	if (strobe_data_reg)
	begin
		go_success <= 1'b0;
		go_unsuccess <= 1'b0;
	end
	else if (ticket2moon) go_success <= 1'b1;
	else if (hash_cmplt) go_unsuccess <= 1'b1;

always @ (posedge clk_100)
	if (go_success)
	begin
		status4_coin <= {3'h0, start_hash, 16'h2121, 12'h0};
		golden_nonce <= nonce;// - 8'h88
	end
	else if (go_unsuccess)
	begin
		status4_coin <= {3'h0, start_hash, 16'hffff, 12'h0};
		golden_nonce <= 32'hffffffff;
	end
	else
	begin
		status4_coin <= {3'h0, start_hash, 16'h0, 12'h0};
		golden_nonce <= 32'h0;
	end

endmodule
