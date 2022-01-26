// Copyright (C) 2019 MentalCollatz
// Copyright (C) 2019-2022 AtomMiner LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
`timescale 1ns / 1ps

`define  THROUGHPUT 4

module cmp_256(clk, in, read, target, out, write);
	input clk;
	input [255:0] in;
	input read;
	input [255:0] target;
	output reg out = 1'b0;
	output reg write;
	
	reg [15:0] greater = 16'h0, less = 16'h0;
	reg progress;
									reg read_r = 1'b0;
	initial progress = 0;
	initial write = 0;
	
	genvar i;
	generate
	for (i = 0; i < 16; i = i+1)
	begin : loop
		always @(posedge clk)
		begin
			greater[i] <= (in[16*i+15:16*i] > target[16*i+15:16*i]);
			less[i] <= (in[16*i+15:16*i] < target[16*i+15:16*i]);
		end
	end
	endgenerate
	
	always @(posedge clk) read_r <= read;
	always @(posedge clk) if (read_r)  out <= (greater < less); else out <= 1'b0;
	
	always @(posedge clk)
	begin
		progress <= read;
		write <= progress;
	end
endmodule

module odo_keccak(clk, in, read, target, out, write);
	input clk;
	input [639:0] in;
	input read;
	input [255:0] target;
	output out; //ticket2moon
	output write;

	wire [639:0] midstate;
	wire midread;
	wire [255:0] pow_hash;
	wire has_hash;

	encrypt_4encrypt crypt(clk, in, read, midstate, midread);
	keccak_hasher #(640, `THROUGHPUT) hash(clk, midstate, midread, pow_hash, has_hash);
	cmp_256 compare(clk, pow_hash, has_hash, target, out, write);
endmodule

module miner(clk, header, target, start_hash, res, nonce);
	input clk;
	input [607:0] header;
	input [255:0] target;
	input start_hash;
	output wire res;
	output reg [31:0] nonce;

	reg [31:0] nonce_in = 32'h0;
	reg [31:0] nonce_out = 32'h0;

	reg [6:0] counter;
	reg advance;
	initial counter = `THROUGHPUT-1;
	initial advance = 0;

	wire has_res;
	reg [5:0] cou_deltanonce = 6'b0; 
	reg nonce_out_go = 1'b0; 

	odo_keccak worker(clk, {nonce_in, header}, advance, target, res, has_res);
	
	always @(posedge clk)
	begin
		if (~start_hash)  
		begin
			counter <= 0;
			advance <= 1'b0;
		end
		else if (counter == `THROUGHPUT-1 & start_hash)
		begin
			counter <= 0;
			advance <= 1;
		end
		else
		begin
			counter <= counter + 1;
			advance <= 0;
		end
		if (~start_hash)
			nonce_in <= 32'h0;
		else if (advance & start_hash)
			nonce_in <= nonce_in + 1;
		if (~start_hash)
			nonce_out <= 32'h0;
		else if (has_res & start_hash & nonce_out_go)
		begin
			if (res) nonce <= nonce_out;
			nonce_out <= nonce_out + 1;
		end
	end

always @ (posedge clk)
	if (~start_hash)   cou_deltanonce <= 6'b0;                                                                                
	else if (advance)  cou_deltanonce <= cou_deltanonce + 1'b1;

always @ (posedge clk)
	if (~start_hash) nonce_out_go <= 1'b0;
	else if ( cou_deltanonce == 6'h33)  nonce_out_go <= 1'b1;             

endmodule

module miner_top(osc_clk, header, target, start_hash, ticket2moon, nonce);
	input osc_clk;
	input [607:0] header;
	input [255:0] target;
	input start_hash;

	output ticket2moon;
	output [31:0] nonce;

	wire miner_clk;
	wire res;
	assign miner_clk = osc_clk;

	miner miner (miner_clk, header, target, start_hash, res, nonce);
	
	assign ticket2moon = res;
	
endmodule
	
