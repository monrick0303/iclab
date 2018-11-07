//++++++++++++++ Include DesignWare++++++++++++++++++

//synopsys translate_off
//`include "DW_fp_mult.v"
//`include "DW_fp_addsub.v"
//synopsys translate_on

//+++++++++++++++++++++++++++++++++++++++++++++++++

module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_d,
	in_valid_t,
	in_valid_w1,
	in_valid_w2,
	data_point,
	target,
	weight1,
	weight2,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

// FSM parameters
parameter	ST_IDLE		=	'd0,
			ST_INPUT	=	'd1,
			ST_INPUT2   =   'd2,
			ST_forward1 =  'd3,
			ST_forward2 =	'd4,
			ST_backward2 =	'd5,
			ST_update 	=	'd6,
			ST_OUTPUT	=	'd7;

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid_d, in_valid_t, in_valid_w1, in_valid_w2;
input [inst_sig_width+inst_exp_width:0] data_point, target;
input [inst_sig_width+inst_exp_width:0] weight1, weight2;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0] weight1_store[11:0], weight2_store[2:0], data_store[3:0], target_store, y2,t_1,t_2,t_3,t_4,temp; 
reg [inst_sig_width+inst_exp_width-1:0] y1_1,y1_2,y1_3; 
reg [4:0] count,forward1_cnt,i;
//reg [1:0] forward1_cnt;
reg g2_1,g2_2,g2_3;
reg	[2:0] cs,ns;

// Use for designware
reg [inst_sig_width+inst_exp_width:0] mult_a, mult_b, add_a, add_b;
wire [inst_sig_width+inst_exp_width:0] mult_out, add_out;
reg addsub_op;

//---------------------------------------------------------------------
//   DesignWare
//---------------------------------------------------------------------
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M0 (.a(mult_a), .b(mult_b), .rnd(3'b000), .z(mult_out));
DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A0 (.a(add_a), .b(add_b), .op(addsub_op), .rnd(3'b000), .z(add_out));

//synopsys dc_script_begin
//set_implementation rtl M0
//set_implementation rtl A0
//synopsys dc_script_end

//---------------------------------------------------------------------
//   ALGORITHM
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) temp <= 0;
	else 
	case(cs)
		ST_IDLE:temp <= 0;
		ST_update:begin
			case(count)
			0:temp <= mult_out;
			4:temp <= mult_out;
			9:temp <= mult_out;
			14:temp <= mult_out;
			default:temp <= temp;
			endcase
		end
		default:temp<=0;
	endcase
end

always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
	begin
		mult_a <= 0;
		mult_b <= 0;
	end
	else 
	case(cs)
		ST_IDLE:begin
			mult_a <= 0;
			mult_b <= 0;
		end
		ST_INPUT2:begin
			case(count)
				0:begin
					mult_a <= weight1_store[0];
					mult_b <= data_store[3];
				end
				1:begin
					mult_a <= weight1_store[1];
					mult_b <= data_store[3];
				end
				2:begin
					mult_a <= weight1_store[2];
					mult_b <= data_store[3];
				end
				3:begin
					mult_a <= weight1_store[3];
					mult_b <= data_store[3];
				end
			endcase
		end
		ST_forward1:begin
			case(forward1_cnt)
				0:begin
				case(count)
					0:begin
						mult_a <= weight1_store[4];
						mult_b <= data_store[0];
					end
					1:begin
						mult_a <= weight1_store[5];
						mult_b <= data_store[1];
					end
					2:begin
						mult_a <= weight1_store[6];
						mult_b <= data_store[2];
					end
					3:begin
						mult_a <= weight1_store[7];
						mult_b <= data_store[3];
					end
					default:begin
						mult_a <= 0;
						mult_b <= 0;
					end
				endcase
				end
				1:begin
				case(count)
					0:begin
						mult_a <= weight1_store[8];
						mult_b <= data_store[0];
					end
					1:begin
						mult_a <= weight1_store[9];
						mult_b <= data_store[1];
					end
					2:begin
						mult_a <= weight1_store[10];
						mult_b <= data_store[2];
					end
					3:begin
						mult_a <= weight1_store[11];
						mult_b <= data_store[3];
					end
					default:begin
						mult_a <= 0;
						mult_b <= 0;
					end
				endcase
				end
			endcase
		end
		ST_forward2:begin
			case(count)
				0:begin
					mult_a <= weight2_store[0];
					mult_b <= {1'b0,y1_2};  //y1_1 vaule on y1_2
				end
				1:begin
					mult_a <= weight2_store[1];
					mult_b <= {1'b0,y1_3}; //y1_2 vaule on y1_3
				end
				2:begin
					mult_a <= weight2_store[2];
					mult_b <= {1'b0,y1_3};
				end
				default:begin
					mult_a <= 0;
					mult_b <= 0;
				end
			endcase
		end
		ST_backward2:begin
			case(count)
				2:begin
				mult_a <= add_out;  //t_1
				mult_b <= weight2_store[0];
				end
				3:begin
				mult_a <= t_1;
				mult_b <= weight2_store[1];
				end
				4:begin
				mult_a <= t_1;
				mult_b <= weight2_store[2];
				end
				5:begin
				mult_a <= 32'b00110111000000000000000000000000; //7.62939x10^-6
				mult_b <= t_1;
				end
				default:begin
					mult_a <= 0;
					mult_b <= 0;
				end
			endcase
		end
		ST_update:begin
			case(count)
				0:begin
				mult_a <= mult_out;
				mult_b <= {1'b0,y1_1};
				end
				1:begin
				mult_a <= temp;
				mult_b <= {1'b0,y1_2};
				end
				2:begin
				mult_a <= temp;
				mult_b <= {1'b0,y1_3};
				end
				3:begin
				mult_a <= 32'b00110111000000000000000000000000; //7.62939x10^-6
				mult_b <= t_2;
				end
				4:begin
				mult_a <= mult_out;
				mult_b <= data_store[0];
				end
				5:begin
				mult_a <= temp; 
				mult_b <= data_store[1];
				end
				6:begin
				mult_a <= temp;
				mult_b <= data_store[2];
				end
				7:begin
				mult_a <= temp;
				mult_b <= data_store[3];
				end
				8:begin
				mult_a <= 32'b00110111000000000000000000000000; //7.62939x10^-6
				mult_b <= t_3;
				end
				9:begin
				mult_a <= mult_out;
				mult_b <= data_store[0];
				end
				10:begin
				mult_a <= temp;
				mult_b <= data_store[1];
				end
				11:begin
				mult_a <= temp;
				mult_b <= data_store[2];
				end
				12:begin
				mult_a <= temp;
				mult_b <= data_store[3];
				end
				/////
				13:begin
				mult_a <= 32'b00110111000000000000000000000000; //7.62939x10^-6
				mult_b <= t_4;
				end
				14:begin
				mult_a <= mult_out;
				mult_b <= data_store[0];
				end
				15:begin
				mult_a <= temp;
				mult_b <= data_store[1];
				end
				16:begin
				mult_a <= temp;
				mult_b <= data_store[2];
				end
				17:begin
				mult_a <= temp;
				mult_b <= data_store[3];
				end
				default:begin
					mult_a <= 0;
					mult_b <= 0;
				end
			endcase
		end
		default:begin
			mult_a <= 0;
			mult_b <= 0;
		end
	endcase
end

always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
	begin
		add_a <= 0;
		add_b <= 0;
		addsub_op <= 0;
	end
	else 
	case(cs)
		ST_IDLE:begin
			add_a <= 0;
			add_b <= 0;
			addsub_op <= 0;
		end
		ST_INPUT2:begin
			add_a <= add_out;
			add_b <= mult_out;
			addsub_op <= 0;
		end
		ST_forward1:begin
			if(count==1)begin
			add_a <= 0;
			add_b <= mult_out;
			addsub_op <= 0;
			end else begin
			add_a <= add_out;
			add_b <= mult_out;
			addsub_op <= 0;
			end
		end
		ST_forward2:begin
			if(count==1)begin
			add_a <= 0;
			add_b <= mult_out;
			addsub_op <= 0;
			end else begin
			add_a <= add_out;
			add_b <= mult_out;
			addsub_op <= 0;
			end
		end
		ST_backward2:begin //2.3.4.5 nothing
			if(count==1)begin
			add_a <= add_out;  //y2
			add_b <= target_store;
			addsub_op <= 1;
			end else if(count==0)begin
			add_a <= add_out;
			add_b <= mult_out;
			addsub_op <= 0;
			end else begin
			add_a <= 0;
			add_b <= 0;
			addsub_op <= 0;
			end
		end
		ST_update:begin
			case(count)
				1:begin
				add_a <= weight2_store[0];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				2:begin
				add_a <= weight2_store[1];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				3:begin
				add_a <= weight2_store[2];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				5:begin
				add_a <= weight1_store[0];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				6:begin
				add_a <= weight1_store[1];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				7:begin
				add_a <= weight1_store[2];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				8:begin
				add_a <= weight1_store[3];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				10:begin
				add_a <= weight1_store[4];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				11:begin
				add_a <= weight1_store[5];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				12:begin
				add_a <= weight1_store[6];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				13:begin
				add_a <= weight1_store[7];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				/////
				15:begin
				add_a <= weight1_store[8];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				16:begin
				add_a <= weight1_store[9];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				17:begin
				add_a <= weight1_store[10];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				18:begin
				add_a <= weight1_store[11];
				add_b <= mult_out;
				addsub_op <= 1;
				end
				default:begin
				add_a <= add_a;
				add_b <= add_b;
				addsub_op <= addsub_op;
				end
			endcase
		end
	endcase
end

always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
	begin
		y1_1 <= 31'b0;
		y1_2 <= 31'b0;
		y1_3 <= 31'b0;
		g2_1 <= 0;
		g2_2 <= 0;
		g2_3 <= 0;
	end
	else 
	case(cs)
		ST_IDLE:begin
			y1_1 <= 31'b0;
			y1_2 <= 31'b0;
			y1_3 <= 31'b0;
			g2_1 <= 0;
			g2_2 <= 0;
			g2_3 <= 0;
		end
		ST_forward1:begin
			if(count==1)begin
				y1_1 <= y1_2;
				g2_1 <= g2_2;
				y1_2 <= y1_3;
				g2_2 <= g2_3;
				y1_3 <= (add_out[31]==0)? add_out[30:0]:32'b0;
				g2_3 <= ((add_out[31]==0)&&(add_out!=0))? 1:0;
			end
		end
		ST_forward2:begin
			if(count==1)begin
				y1_1 <= y1_2;
				g2_1 <= g2_2;
				y1_2 <= y1_3;
				g2_2 <= g2_3;
				y1_3 <= (add_out[31]==0)? add_out[30:0]:32'b0;
				g2_3 <= ((add_out[31]==0)&&(add_out!=0))? 1:0;
			end
		end
	endcase
end

always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
	begin
		y2 <= 0;
	end
	else 
	case(cs)
		ST_IDLE: y2 <= 0;
		ST_backward2:begin
			if(count==1) y2 <= add_out;
		end
		default:y2 <= y2;
	endcase
end

always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
	begin
		t_1 <= 0;
		t_2 <= 0;
		t_3 <= 0;
		t_4 <= 0;
	end
	else 
	case(cs)
		ST_IDLE:begin
			t_1 <= 0;
			t_2 <= 0;
			t_3 <= 0;
			t_4 <= 0;
		end
		ST_backward2:begin
			case(count)
				2:begin
				t_1 <= add_out;
				end
				3:begin
				t_2 <= (g2_1==1)? mult_out:0;
				end
				4:begin
				t_3 <= (g2_2==1)? mult_out:0;
				end
				5:begin
				t_4 <= (g2_3==1)? mult_out:0;
				end
			endcase
		end
	endcase
end

//---------------------------------------------------------------------
//   COUNTER
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
		count <= 0;
	else
	case(cs)
		ST_INPUT2: if(count==3) count <= 0;
		else count <= count + 1;
		ST_forward1: if(count==3) count <= 0;
		else count <= count + 1;
		ST_forward2: if(count==2) count <= 0;
		else count <= count + 1;
		ST_backward2: if(count==5) count <= 0;
		else count <= count + 1;
		ST_update: if(count==19) count <= 0;
		else count <= count + 1;
		default: count <= 0;
	endcase
end

always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
		forward1_cnt <= 0;
	else if(cs == ST_forward1&&count == 3)
		forward1_cnt <= forward1_cnt + 1;
	else if(cs == ST_forward1)
		forward1_cnt <= forward1_cnt;
	else
		forward1_cnt <= 0;
end
//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
		out_valid <= 0;
	else if(cs==ST_OUTPUT)
		out_valid <= 1;
	else
		out_valid <= 0;
end

always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
		out <= 0;
	else if(cs == ST_OUTPUT)
		out <= y2;
	else
		out <= 0;
end

//---------------------------------------------------------------------
//   Finite-State Mechine                                          
//---------------------------------------------------------------------
always@(posedge	clk or negedge rst_n)	begin
	if(!rst_n) 
		cs	<=	ST_IDLE;
	else 
		cs	<=	ns;
end

always@(*)	begin
	case(cs)
		ST_IDLE:	
		begin
			if(in_valid_w1) ns =	ST_INPUT;
			else if(in_valid_d) ns = ST_INPUT2;
			else ns	=	ST_IDLE;
		end
		
		ST_INPUT:	
		begin
			if(!in_valid_w1) ns = ST_IDLE;
			else ns	= ST_INPUT;
		end
		
		ST_INPUT2:	
		begin
			if(!in_valid_d) ns = ST_forward1;
			else ns	= ST_INPUT2;
		end
		
		ST_forward1:
		begin
			if(forward1_cnt==1&&count==3) ns = ST_forward2;
			else ns = ST_forward1;
		end
		
		ST_forward2:
		begin
			if(count==2) ns = ST_backward2;
			else ns = ST_forward2;
		end
		
		ST_backward2:
		begin
			if(count==5) ns = ST_update;
			else ns = ST_backward2;
		end
		
		ST_update:
		begin
			if(count==19) ns = ST_OUTPUT;
			else ns = ST_update;
		end
		
		ST_OUTPUT:
		begin
			ns	= ST_IDLE;
		end
		
		default:	
		begin
			ns	=	ST_IDLE;
		end
	endcase
end

//---------------------------------------------------------------------
//   INPUT to Array
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
	begin
		for(i=0;i<12;i=i+1)begin
		weight1_store[i] <= 0;
		end
	end
	else if(in_valid_w1)
	begin
		weight1_store[0] <= weight1_store[1];
		weight1_store[1] <= weight1_store[2];
		weight1_store[2] <= weight1_store[3];
		weight1_store[3] <= weight1_store[4];
		weight1_store[4] <= weight1_store[5];
		weight1_store[5] <= weight1_store[6];
		weight1_store[6] <= weight1_store[7];
		weight1_store[7] <= weight1_store[8];
		weight1_store[8] <= weight1_store[9];
		weight1_store[9] <= weight1_store[10];
		weight1_store[10] <= weight1_store[11];
		weight1_store[11] <= weight1;
	end
	else if(cs==ST_update)
	begin
		case(count) //subout
			6:begin
				weight1_store[0] <= add_out;
			end
			7:begin
				weight1_store[1] <= add_out;
			end
			8:begin
				weight1_store[2] <= add_out;
			end
			9:begin
				weight1_store[3] <= add_out;
			end
			11:begin
				weight1_store[4] <= add_out;
			end
			12:begin
				weight1_store[5] <= add_out;
			end
			13:begin
				weight1_store[6] <= add_out;
			end
			14:begin
				weight1_store[7] <= add_out;
			end
			16:begin
				weight1_store[8] <= add_out;
			end
			17:begin
				weight1_store[9] <= add_out;
			end
			18:begin
				weight1_store[10] <= add_out;
			end
			19:begin
				weight1_store[11] <= add_out;
			end
		endcase
	end
end

always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
	begin
		weight2_store[0] <= 0;
		weight2_store[1] <= 0;
		weight2_store[2] <= 0;
	end
	else if(in_valid_w2)
	begin
		weight2_store[0] <= weight2_store[1];
		weight2_store[1] <= weight2_store[2];
		weight2_store[2] <= weight2;
	end
	else if(cs==ST_update)
	begin
		case(count) //subout
			2:begin
				weight2_store[0] <= add_out;
			end
			3:begin
				weight2_store[1] <= add_out;
			end
			4:begin
				weight2_store[2] <= add_out;
			end
		endcase
	end
end

always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
	begin
		data_store[0] <= 0;
		data_store[1] <= 0;
		data_store[2] <= 0;
		data_store[3] <= 0;
	end
	else if(in_valid_d)
	begin
		data_store[0] <= data_store[1];
		data_store[1] <= data_store[2];
		data_store[2] <= data_store[3];
		data_store[3] <= data_point;
	end
end

always@(posedge clk or negedge rst_n)	
begin
	if(!rst_n)
	begin
		target_store <= 0;
	end
	else if(in_valid_t)
	begin
		target_store <= target;
	end
end

endmodule
