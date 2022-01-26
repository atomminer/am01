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

module odo_block_data(
	input         clk_h, 
	input  [31:0] data_from_host_in,
	input         get_midstate_in,
	input         get_block_in,
	input         get_target_in,
	//
	output wire [607:0] header,
	output wire [255:0] target
);

reg [31:0] header0  = 32'h0, header1  = 32'h0, header2  = 32'h0, header3  = 32'h0,
					 header4  = 32'h0, header5  = 32'h0, header6  = 32'h0, header7  = 32'h0,
					 header8  = 32'h0, header9  = 32'h0, header10 = 32'h0, header11 = 32'h0,
					 header12 = 32'h0, header13 = 32'h0, header14 = 32'h0, header15 = 32'h0,
					 header16 = 32'h0, header17 = 32'h0, header18 = 32'h0;           

reg [31:0] target0  = 32'h0, target1  = 32'h0, target2  = 32'h0, target3  = 32'h0,
					 target4  = 32'h0, target5  = 32'h0, target6  = 32'h0, target7  = 32'h0;           

always @ (posedge clk_h)
	if (get_midstate_in |  get_block_in)
	begin
		header18 <=  data_from_host_in; 
		header17  <= header18;
		header16  <= header17; 
		header15  <= header16;
		header14  <= header15; 
		header13  <= header14;
		header12  <= header13; 
		header11  <= header12;
		header10  <= header11;
		header9  <= header10;
		header8 <= header9; 
		header7 <= header8;
		header6 <= header7; 
		header5 <= header6;
		header4 <= header5; 
		header3 <= header4;
		header2 <= header3;
		header1 <= header2;
		header0 <= header1;  
	end   

assign  header = {header18, header17, header16, header15, header14, header13, header12, header11, header10, header9, header8, 
									header7, header6, header5, header4, header3, header2, header1, header0};
// 
always @ (posedge clk_h)
	if (get_target_in) 
	begin
		target0 <=  data_from_host_in; 
		target1  <= target0;
		target2  <= target1; 
		target3  <= target2;
		target4  <= target3; 
		target5  <= target4;
		target6  <= target5; 
		target7  <= target6;
	end   

assign  target = {target7,  target6,  target5,  target4,  target3,  target2,  target1,  target0};

endmodule


module host_break_sm(
	input clk_h,
	input host_break,
	input ticket2moon,
	input hash_cmplt,

	output reg sha_host_break = 1'b0
);

reg sha_host_break_res = 1'b0;
reg [4:0] host_break_del = 5'h0;

always @ (posedge clk_h)
	if (sha_host_break_res)
		sha_host_break <= 1'b0;	
	else if (host_break | ticket2moon | hash_cmplt)
		sha_host_break <= 1'b1;

always @ (posedge clk_h)
	if (sha_host_break_res)
		host_break_del <= 5'b0; 
	else if (sha_host_break)
	host_break_del <= host_break_del + 1'b1;

always @ (posedge clk_h)
	sha_host_break_res	<= &host_break_del ;

endmodule


module delreg_varbits_vardel
#(
		parameter data_width = 64,
							clock_cycles = 16
)
(
	input clk,
	input en,
	input [data_width-1 :0] data_in,

	output reg [data_width-1 :0] data_out = {data_width*1'b0}
);

reg [clock_cycles-1:0] shift_reg [data_width-1:0];  
integer srl_index;

initial
	for (srl_index = 0; srl_index < data_width; srl_index = srl_index + 1)
		shift_reg[srl_index] = {clock_cycles{1'b0}};

wire [data_width-1 :0] data_out_r;

genvar i;
generate
	for (i=0; i < data_width; i=i+1)
	begin: del_reg
		always @(posedge clk)
			if (en)
				shift_reg[i] <= {shift_reg[i][clock_cycles-2:0], data_in[i]};

		assign data_out_r[i] = shift_reg[i][clock_cycles-1];
	end
endgenerate

always @ (posedge clk)
	if (en)
		data_out <= data_out_r; 

endmodule