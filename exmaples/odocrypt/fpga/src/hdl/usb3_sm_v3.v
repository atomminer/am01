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

module usb3_sm_v3(
	input           clk_100,
	input           lock_h,
	input           lock_100,
	input           FX3_ready,
	input           strobe_data,
	input  [31:0]   DQ_inbuf,
	input  [31:0]   status4_coin,
	input  [31:0]   golden_nonce,

	output reg          res_clk = 1'b0,
	output reg          artix_ready = 1'b1,
	output reg          DQ_outenbuf = 1'b0,
	output reg          system_ram_we_100 = 1'b0,
	output reg [9:0]    system_ram_addr_100 = 10'h0,
	output reg [31:0]   data_to_systemram_100 = 32'h0,
	output reg          data_from_host_rdy = 1'b0
);
//
localparam	STATUS_IDLE             = 4'b0000,
						STATUS_SEND             = 4'b0001,
						STATUS_ACQUIRE_WAITEOS  = 4'b0010,
						STATUS_ACQUIRE          = 4'b0011,
						STATUS_ACQUIREND        = 4'b0100,
						STATUS_WR1              = 4'b0101,
						STATUS_WR2              = 4'b0110,
						STATUS_READDNA          = 4'b0111,
						STATUS_WRITEDNA1        = 4'b1000,
						STATUS_WRITEDNA2        = 4'b1001,
						STATUS_WAIT_AUX         = 4'b1101;
//     
reg [3:0]    status_sm_state = 4'b0;
reg [3:0]    status_sm_state_next = 4'b0;                  
//   
reg [24:0] out_milestones_cou = 25'h0;
reg status_go = 1'b0;
reg status_stop = 1'b0; 
//
reg DQ_outenbuf_r = 1'b0;
reg DQ_outenbuf_rr = 1'b0;
reg DQ_outenbuf_rrr = 1'b0;
//  
reg dna_rd = 1'b0;
reg dna_rd_r = 1'b0;
reg dna_rd_end = 1'b0;
reg dna_shift = 1'b0;
reg dna_shift_r = 1'b0;
reg power_up_seq = 1'b0;
//reg power_up_seq_r = 1'b0;
wire dna_1bit;
reg [56:0]  dev_id = 57'h0;
//
reg [6:0] xadc_daddr_in = 7'h0;
reg xadc_den_in = 1'b0;
wire [15:0] xadc_do_out;
wire xadc_drdy_out;
reg xadc_drdy_out_r = 1'b0;
reg xadc_drdy_out_rr = 1'b0;
wire xadc_temp_alarm_out;
wire vccint_alarm_out;
wire vccaux_alarm_out;
wire xadc_overtempalarm_out;
wire [4:0] channel_out;
wire eoc_out;
wire alarm_out;
wire eos_out;
wire xadc_busy_out;
reg xadc_acquire = 1'b0;
reg xadc_acquire_r = 1'b0;
reg acquire_alarms = 1'b0;
reg acquire_alarms_r = 1'b0;
reg strobe_data_r = 1'b0;
reg [4:0] datawr_addr = 5'h0;
reg FX3_ready_r = 1'b0;
reg FX3_ready_rr = 1'b0;
//
always @ (posedge clk_100)
begin
	FX3_ready_r <= FX3_ready;
	FX3_ready_rr <= FX3_ready_r;
	res_clk <= FX3_ready_rr & ~FX3_ready_r;
end

always @ (posedge clk_100)
	if (lock_h) artix_ready <= 1'b0;

//  events counter     
always @ (posedge clk_100)
	if (FX3_ready | status_go)
		out_milestones_cou <= 25'h0; // 200ms / 100MHz => 20000000 clocks or 25'h1312D00    or  100ms / 100MHz => 10000000 clocks or 25'h989680   
	else if (dna_shift  | ~artix_ready)
		out_milestones_cou <= out_milestones_cou + 1'b1;

//  events counter decoder
always @ (posedge clk_100)
begin 
		dna_rd_end <= out_milestones_cou == 25'h59;
		status_go <=  out_milestones_cou == 25'h186a0;	// SIM only 25'h400
		status_stop <= out_milestones_cou == 25'h1F;		// SIM 25'h20
end

// SM
always @ (posedge clk_100)
begin
	status_sm_state <= status_sm_state_next;
	DQ_outenbuf_rr <= DQ_outenbuf_r;
	DQ_outenbuf_rrr <= DQ_outenbuf_rr;
	DQ_outenbuf <= DQ_outenbuf_rrr;
end

always @ (status_sm_state or status_go or status_stop or FX3_ready_rr or dna_rd_end or lock_h or xadc_drdy_out or eos_out or xadc_drdy_out_rr or lock_100)
begin
	status_sm_state_next <= 4'b0;
	//dna_done_r = 1'b0;
	DQ_outenbuf_r <= 1'b0;
	dna_rd_r <= 1'b0;
	dna_shift_r <= 1'b0;
	xadc_acquire_r <= 1'b0;
	acquire_alarms_r <= 1'b0;

	case (status_sm_state)
		STATUS_IDLE: //0000 
		begin 
			if (status_go & lock_h & lock_100) 
			begin
				status_sm_state_next <= STATUS_SEND;
			end
			else status_sm_state_next <= STATUS_IDLE;
		end

		STATUS_SEND:  // 0001
		begin 
			if (status_stop) 
			begin 
				DQ_outenbuf_r <= 1'b1; 
				dna_rd_r <= 1'b1;
				status_sm_state_next <= STATUS_READDNA;
			end
			else 
			begin 
				DQ_outenbuf_r <= 1'b1;
				status_sm_state_next <= STATUS_SEND;
			end
		end

		STATUS_READDNA: //0111
		begin
			if (dna_rd_end) 
				status_sm_state_next <= STATUS_WRITEDNA1;
			else 
			begin
				dna_shift_r <= 1'b1;
				status_sm_state_next <= STATUS_READDNA;   
			end
		end  

		STATUS_WRITEDNA1: //1000
		begin status_sm_state_next <= STATUS_WRITEDNA2; end

		STATUS_WRITEDNA2: //1001
		begin  status_sm_state_next <= STATUS_ACQUIRE_WAITEOS; end

		STATUS_ACQUIRE_WAITEOS:  //0010
		begin
		if (eos_out) begin 
			acquire_alarms_r <= 1'b1;
			status_sm_state_next <= STATUS_ACQUIRE; 
		end
		else 
			status_sm_state_next <= STATUS_ACQUIRE_WAITEOS; 
		end

		STATUS_ACQUIRE: // 0011
		begin
			if (eos_out)
			begin
				xadc_acquire_r <= 1'b1;
				status_sm_state_next <= STATUS_ACQUIREND;
			end
			else
			begin
				xadc_acquire_r <= 1'b1;
				status_sm_state_next <= STATUS_ACQUIRE;
			end
		end

		STATUS_ACQUIREND: //0100
		begin
			if (xadc_drdy_out_rr)
			begin
				xadc_acquire_r <= 1'b1;
				status_sm_state_next <= STATUS_WAIT_AUX;//STATUS_WR1
			end
			else 
			begin
				xadc_acquire_r <= 1'b1;
				status_sm_state_next <= STATUS_ACQUIREND;//
			end
		end

		STATUS_WAIT_AUX: //1101 
		begin
			xadc_acquire_r <= 1'b1;
			status_sm_state_next <= STATUS_WR1;
		end

		STATUS_WR1: //  0101
		begin status_sm_state_next <= STATUS_WR2; end
			//
		STATUS_WR2: //0110
		begin   status_sm_state_next <= STATUS_IDLE; end

		default : begin
			status_sm_state_next <= STATUS_IDLE;
		end
	endcase
end         

always @ (posedge clk_100)
begin
	strobe_data_r <= strobe_data;
	data_from_host_rdy <= strobe_data_r & ~strobe_data;
	dna_shift <= dna_shift_r;
	dna_rd <= dna_rd_r;
	acquire_alarms <= acquire_alarms_r;
	xadc_acquire <= xadc_acquire_r;
end

always @ (posedge clk_100)
	if (data_from_host_rdy) datawr_addr <= 5'h0;
	else if (strobe_data_r) datawr_addr <= datawr_addr + 1'b1;

always @ (posedge clk_100)
	if (DQ_outenbuf_r)
	begin
		system_ram_we_100 <= 1'b0;
		system_ram_addr_100 <= {1'b1, out_milestones_cou[8:0]};
		data_to_systemram_100 <= 32'h0;
	end
	else if (strobe_data_r)
	begin
		system_ram_we_100 <= 1'b1;
		system_ram_addr_100 <= {5'b0, datawr_addr};
		data_to_systemram_100 <= DQ_inbuf;
	end
	else if (status_sm_state == 4'b0101)// STATUS_WR1              = 4'b0101,
	begin
		system_ram_we_100 <= 1'b1;
		system_ram_addr_100 <= 10'h20d;
		data_to_systemram_100 <= status4_coin;
	end
	else if (status_sm_state == 4'b0110)
	begin
		system_ram_we_100 <= 1'b1;
		system_ram_addr_100 <= 10'h20e;
		data_to_systemram_100 <= golden_nonce;//[31:0]
	end
	else if (status_sm_state == 4'b1000)
	begin
		system_ram_we_100 <= 1'b1;
		system_ram_addr_100 <= 10'h206;
		data_to_systemram_100 <= {7'b0, dev_id[56:32]};
	end
	else if (status_sm_state == 4'b1001)
	begin
		system_ram_we_100 <= 1'b1;
		system_ram_addr_100 <= 10'h207;
		data_to_systemram_100 <= dev_id[31:0];
	end
	else if (acquire_alarms)
	begin
		system_ram_we_100 <= 1'b1;
		system_ram_addr_100 <= 10'h209;
		data_to_systemram_100 <= {28'h0, vccaux_alarm_out, vccint_alarm_out, xadc_overtempalarm_out};
	end
	else if (xadc_drdy_out_rr & channel_out == 4'h0)
	begin
		system_ram_we_100 <= 1'b1;
		system_ram_addr_100 <= 10'h20a;
		data_to_systemram_100 <= {16'h0, xadc_do_out};
	end
	else if (xadc_drdy_out_rr & channel_out == 4'h1)
	begin
		system_ram_we_100 <= 1'b1;
		system_ram_addr_100 <= 10'h20b;
		data_to_systemram_100 <= xadc_do_out;
	end
	else if (xadc_drdy_out_rr & channel_out == 4'h2)
	begin
		system_ram_we_100 <= 1'b1;
		system_ram_addr_100 <= 10'h20c;
		data_to_systemram_100 <= xadc_do_out;
	end
	else
	begin 
		system_ram_we_100 <= 1'b0;
		system_ram_addr_100 <= 10'h200;
		data_to_systemram_100 <= 32'h0; 
	end

//DNA port
DNA_PORT #(
	.SIM_DNA_VALUE(57'h103456789abcd81) // sample 57-bit DNA value for simulation
)
DNA_PORT_inst (
	.DOUT(dna_1bit),			// 1-bit output: DNA output data.
	.CLK(clk_100),				// 1-bit input: Clock input.
	.DIN(1'b0),						// 1-bit input: User data input pin.
	.READ(dna_rd),				// 1-bit input: Active high load DNA, active low read input.
	.SHIFT(dna_shift)			// 1-bit input: Active high shift enable input.
);

always @ (posedge clk_100)
	if (dna_shift) dev_id[0] <= dna_1bit;

genvar i;
generate for (i=1; i < 57; i=i+1)
begin: ID          
	always @ (posedge clk_100)
		if (dna_shift) dev_id[i] <= dev_id[i-1];
end
endgenerate   

always @ (posedge clk_100)
	xadc_daddr_in <= {2'b0, channel_out};

always @ (posedge clk_100)
if (xadc_acquire) xadc_den_in <=  eoc_out;

// XADC
xadc_artix200_v0  xadc_artix200_v0(
	.di_in(16'h0),															// input wire [15 : 0] di_in
	.daddr_in(xadc_daddr_in),										// input wire [6 : 0] daddr_in
	.den_in(xadc_den_in),												// input wire den_in
	.dwe_in(1'b0),															// input wire dwe_in
	.drdy_out(xadc_drdy_out),										// output wire drdy_out
	.do_out(xadc_do_out),												// output wire [15 : 0] do_out
	.dclk_in(clk_100),													// input wire dclk_in
	.reset_in(res_clk),													// xadc reset
	.vp_in(1'b0),																// input wire vp_in
	.vn_in(1'b1),																// input wire vn_in
	.user_temp_alarm_out(xadc_temp_alarm_out),	// output wire user_temp_alarm_out
	.vccint_alarm_out(vccint_alarm_out),				// output wire vccint_alarm_out
	.vccaux_alarm_out(vccaux_alarm_out),				// output wire vccaux_alarm_out
	.ot_out(xadc_overtempalarm_out),						// output wire ot_out
	.channel_out(channel_out),									// output wire [4 : 0] channel_out
	.eoc_out(eoc_out),													// output wire eoc_out
	.alarm_out(alarm_out),											// output wire alarm_out
	.eos_out(eos_out),													// output wire eos_out
	.busy_out(xadc_busy_out)										// output wire busy_out
);

always @ (posedge clk_100)
begin
	 xadc_drdy_out_r <= xadc_drdy_out;
	 xadc_drdy_out_rr <= xadc_drdy_out_r;
end 
endmodule
