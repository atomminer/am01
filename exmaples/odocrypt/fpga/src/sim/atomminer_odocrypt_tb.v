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

module atomminer_odoscrypt_tb;

reg gclk; // K18   LVCMOS33     system clk = 19.2M
reg pclk; // W19   LVCMOS33 GPIO[16] in  interface master clk = 100M
//
reg  [31:0] DQ_in;
wire [31:0] DQ;
wire [31:0] DQ_out;

reg  strobe_data;
wire we;
reg  FX3_ready;
wire artix_ready;
wire led_is_go; 
reg [31:0] block_word [29:0];

integer j;

assign DQ =  we ? DQ_out : DQ_in;

atomminer_odocrypt UUT (
		.gclk(gclk),
        .pclk(pclk),                 // W19   LVCMOS33 GPIO[16] in  interface master clk = 100M
        .DQ(DQ),                     // LVCMOS33    IO data bus
        .strobe_data(strobe_data),   // W20 LVCMOS33  GPIO[21]  in_strobe data from FX3
        .we(we),                     // A19 LVCMOS33  GPIO[18]  out strobe data to FX3
        .FX3_ready(FX3_ready),       // J20 LVCMOS33  GPIO[45]  active low handshake from FX3
        .artix_ready(artix_ready),   // J19 LVCMOS33  GPIO[51]  active low handshake to FX3
        .led_is_go(led_is_go)
);  

parameter period = 52.100;      // gclk = 19.2M
parameter period_pclk = 10.0;   // pclk = 100M

integer i;

initial
begin
$display("Running 1"); 
gclk = 1'b0;
pclk = 1'b0;
DQ_in = 32'h0;
strobe_data = 1'b0;
FX3_ready = 1'b1; 
//
// test block init goes here 
block_word[ 0]  = 32'h20000e02;   
block_word[ 1]  = 32'hf274793a;       
block_word[ 2]  = 32'hc1b070b2;       
block_word[ 3]  = 32'hf3303660;       
block_word[ 4]  = 32'h2c4a5ca1;       
block_word[ 5]  = 32'h37a0d6f4;       
block_word[ 6]  = 32'h6cc0474f;       
block_word[ 7]  = 32'he51e36a8;       
block_word[ 8]  = 32'h0000042b;       
block_word[ 9]  = 32'h67e51a1d;       
block_word[10]  = 32'hb8691b05;       
block_word[11]  = 32'h525655a6;       
block_word[12]  = 32'hf5acf0f6;       
block_word[13]  = 32'hb7fd2693;       
block_word[14]  = 32'hbcc61c8b;       
block_word[15]  = 32'h35d86dbd;       
block_word[16]  = 32'hea0258c9;       
block_word[17]  = 32'h5d265e38;       
block_word[18]  = 32'h1c5c279b;       
//
// block target 
block_word[19] = 32'h00000021;
block_word[20] = 32'h55340000;
block_word[21] = 32'h00000000;
block_word[22] = 32'h00000000;    
block_word[23] = 32'h00000000;
block_word[24] = 32'h00000000;
block_word[25] = 32'h00000000; 
block_word[26] = 32'h00000000;     

//
#500;
@(posedge pclk); 
FX3_ready = 1'b0;
#(period_pclk *8)

@ (negedge we);
#(period_pclk *768)
//
//wr_block
strobe_data	=  1'b1;
#(period_pclk)
//data
for(j = 0; j < 27; j = j+1)//
begin
    DQ_in = block_word[j];//
    #(period_pclk);//
end
//	
strobe_data	=  1'b0;
//////////////////////////////////////////////////////////////////
@ (negedge we);
#(period_pclk *768)

//wr_block
//
strobe_data	=  1'b1;
#(period_pclk)
//data
for(j = 0; j < 27; j = j+1)//
    begin
        DQ_in = block_word[j];//
        #(period_pclk);//
    end
	
	strobe_data	=  1'b0;

end  

always
begin
 #(period/2) gclk = 1'b1;
 #(period/2) gclk = 1'b0;
end    

always
begin
 #(period_pclk/2) pclk = 1'b1;
 #(period_pclk/2) pclk = 1'b0;
end 

endmodule