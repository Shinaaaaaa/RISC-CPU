`include "define.vh"

module dispatcher(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    
    input wire decoder_en_in,
    input wire[`INST_TYPE_WIDTH] decoder_inst_type_in,
    input wire[`REGISTER_WIDTH] decoder_rs1_in,
    input wire[`REGISTER_WIDTH] decoder_rs2_in,
    input wire[`REGISTER_WIDTH] decoder_rd_in, 
    input wire[`INSTRUCTION_WIDTH] decoder_imm_in,
    input wire[`ADDRESS_WIDTH] decoder_pc_in,

    output wire register_en_out,
    output reg[`REGISTER_WIDTH] register_rs1_out,
    output reg[`REGISTER_WIDTH] register_rs2_out,
    output wire[`REGISTER_WIDTH] register_rd_out,
    output wire[`ROB_WIDTH] register_rd_robnum_out,
    input wire[`INSTRUCTION_WIDTH] register_rs1_data_in,
    input wire register_rs1_busy_in,
    input wire[`ROB_WIDTH] register_rs1_robnum_in,
    input wire[`INSTRUCTION_WIDTH] register_rs2_data_in,
    input wire register_rs2_busy_in,
    input wire[`ROB_WIDTH] register_rs2_robnum_in,
    
    output wire rob_en_out,
    output wire[`INST_TYPE_WIDTH] rob_inst_type_out,
    output wire[`INSTRUCTION_WIDTH] rob_pc_out,
    output wire[`REGISTER_WIDTH] rob_reg_pos_out,
    output reg[`ROB_WIDTH] rob_rs1_out,
    output reg[`ROB_WIDTH] rob_rs2_out,
    input wire[`ROB_WIDTH] rob_idle_pos_in,
    input wire rob_rs1_rdy_in,
    input wire[`INSTRUCTION_WIDTH] rob_rs1_data_in,
    input wire rob_rs2_rdy_in,
    input wire[`INSTRUCTION_WIDTH] rob_rs2_data_in,

    output wire rs_en_out,
    output wire lsqueue_en_out,

    output reg[`INSTRUCTION_WIDTH] vj_out,
    output reg[`ROB_WIDTH] qj_out,
    output reg[`INSTRUCTION_WIDTH] vk_out,
    output reg[`ROB_WIDTH] qk_out,
    output wire[`INST_TYPE_WIDTH] inst_type_out,
    output wire[`INSTRUCTION_WIDTH] A_out,
    output wire[`ROB_WIDTH] dest_out,
    output wire[`INSTRUCTION_WIDTH] pc_out
);

always @(*) begin
    rob_rs1_out = `NULL;
    rob_rs2_out = `NULL;
    register_rs1_out = `NULL;
    register_rs2_out = `NULL;
    vj_out = `NULL;
    qj_out = `NULL;
    vk_out = `NULL;
    qk_out = `NULL;
    if (!rst_in && decoder_en_in) 
        register_rs1_out = decoder_rs1_in;
        if (register_rs1_busy_in) begin
            rob_rs1_out = register_rs1_robnum_in;
            if (rob_rs1_rdy_in) begin
                vj_out = rob_rs1_data_in;
                qj_out = `NULL;
            end
            else begin
                vj_out = `NULL;
                qj_out = register_rs1_robnum_in;
            end
        end
        else begin
            vj_out = register_rs1_data_in;
            qj_out = `NULL; 
        end 

        register_rs2_out = decoder_rs2_in;
        if (register_rs2_busy_in) begin
            rob_rs2_out = register_rs2_robnum_in;
            if (rob_rs2_rdy_in) begin
                vk_out = rob_rs2_data_in;
                qk_out = `NULL;
            end
            else begin
                vk_out = `NULL;
                qk_out = register_rs2_robnum_in;
            end
        end
        else begin
            vk_out = register_rs2_data_in;
            qk_out = `NULL; 
        end
end

assign register_en_out = decoder_en_in;
assign register_rd_out = decoder_rd_in;
assign register_rd_robnum_out = rob_idle_pos_in;

assign rs_en_out = !(`LB <= decoder_inst_type_in && decoder_inst_type_in <= `SW) && decoder_en_in ? `ENABLE : `DISABLE;
assign inst_type_out = decoder_inst_type_in;
assign A_out = decoder_imm_in;
assign dest_out = rob_idle_pos_in;
assign pc_out = decoder_pc_in;

assign lsqueue_en_out = (`LB <= decoder_inst_type_in && decoder_inst_type_in <= `SW) && decoder_en_in ? `ENABLE : `DISABLE;

assign rob_en_out = decoder_en_in;
assign rob_inst_type_out = decoder_inst_type_in;
assign rob_pc_out = decoder_pc_in;
assign rob_reg_pos_out = decoder_rd_in; 

endmodule