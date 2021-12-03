`include "define.vh"

module register(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire dispatcher_en_in,
    input wire[`REGISTER_WIDTH] dispatcher_rs1_in,
    input wire[`REGISTER_WIDTH] dispatcher_rs2_in,
    input wire[`REGISTER_WIDTH] dispatcher_rd_in,
    input wire[`ROB_WIDTH] dispatcher_rd_dest_in,
    output wire[`INSTRUCTION_WIDTH] dispatcher_rs1_data_out,
    output wire dispatcher_rs1_busy_out,
    output wire[`ROB_WIDTH] dispatcher_rs1_dest_out, 
    output wire[`INSTRUCTION_WIDTH] dispatcher_rs2_data_out, 
    output wire dispatcher_rs2_busy_out,
    output wire[`ROB_WIDTH] dispatcher_rs2_dest_out,

    input wire rob_en_in,
    input wire[`REGISTER_WIDTH] rob_reg_pos_in,
    input wire[`ROB_WIDTH] rob_dest_in,
    input wire[`INSTRUCTION_WIDTH] rob_value_in
);

localparam regwidth = 32;

reg[`INSTRUCTION_WIDTH] register_data[regwidth - 1 : 0];
reg register_busy[regwidth - 1 : 0];
reg[`ROB_WIDTH] register_rob_num[regwidth - 1 : 0];
integer i;

always @(posedge clk_in) begin
    if (rst_in) begin
        for (i = 0 ; i <= regwidth - 1; i = i + 1) begin
            register_data[i] <= `NULL;
            register_busy[i] <= `NULL;
            register_rob_num[i] <= `NULL;
        end 
    end
    else if (rdy_in) begin
        if (dispatcher_en_in && dispatcher_rd_in != 1'b0) begin
            register_busy[dispatcher_rd_in] <= `BUSY;
            register_rob_num[dispatcher_rd_in] <= dispatcher_rd_dest_in;
        end
        if (rob_en_in && rob_reg_pos_in != 1'b0) begin
            register_data[rob_reg_pos_in] <= rob_value_in;
            if (register_rob_num[rob_reg_pos_in] == rob_dest_in) begin
                register_busy[rob_reg_pos_in] <= `IDLE;
                register_rob_num[rob_reg_pos_in] <= `NULL;
            end
        end
    end 
end

assign dispatcher_rs1_data_out = (dispatcher_rs1_in == 1'b0) ? `NULL : register_data[dispatcher_rs1_in];
assign dispatcher_rs1_busy_out = (dispatcher_rs1_in == 1'b0) ? `NULL : register_busy[dispatcher_rs1_in];
assign dispatcher_rs1_dest_out = (dispatcher_rs1_in == 1'b0) ? `NULL : register_rob_num[dispatcher_rs1_in];
assign dispatcher_rs2_data_out = (dispatcher_rs2_in == 1'b0) ? `NULL : register_data[dispatcher_rs2_in];
assign dispatcher_rs2_busy_out = (dispatcher_rs2_in == 1'b0) ? `NULL : register_busy[dispatcher_rs2_in];
assign dispatcher_rs2_dest_out = (dispatcher_rs2_in == 1'b0) ? `NULL : register_rob_num[dispatcher_rs2_in];

endmodule