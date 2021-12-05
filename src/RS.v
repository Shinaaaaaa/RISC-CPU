`include "define.vh"

module RS(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire rob_flush_in,

    output wire instqueue_rdy_out,

    input wire dispatcher_en_in,
    input wire[`INSTRUCTION_WIDTH] dispatcher_vj_in,
    input wire[`ROB_WIDTH] dispatcher_qj_in,
    input wire[`INSTRUCTION_WIDTH] dispatcher_vk_in,
    input wire[`ROB_WIDTH] dispatcher_qk_in,
    input wire[`INST_TYPE_WIDTH] dispatcher_inst_type_in,
    input wire[`INSTRUCTION_WIDTH] dispatcher_A_in,
    input wire[`ROB_WIDTH] dispatcher_dest_in,
    input wire[`ADDRESS_WIDTH] dispatcher_pc_in,

    output reg alu_en_out,
    output reg[`INSTRUCTION_WIDTH] alu_vj_out,
    output reg[`INSTRUCTION_WIDTH] alu_vk_out,
    output reg[`INSTRUCTION_WIDTH] alu_A_out,
    output reg[`ROB_WIDTH] alu_dest_out,
    output reg[`ADDRESS_WIDTH] alu_pc_out,
    output reg[`INST_TYPE_WIDTH] alu_inst_type_out,

    input wire cdb_alu_en_in,
    input wire[`ROB_WIDTH] cdb_alu_dest_in,
    input wire[`INSTRUCTION_WIDTH] cdb_alu_value_in,

    input wire cdb_lbuffer_en_in,
    input wire[`ROB_WIDTH] cdb_lbuffer_dest_in,
    input wire[`INSTRUCTION_WIDTH] cdb_lbuffer_value_in
);

localparam RSlength = 16;

reg busy[RSlength - 1 : 0];
reg[`INST_TYPE_WIDTH] inst_type[RSlength - 1 : 0];
reg[`INSTRUCTION_WIDTH] vj[RSlength - 1 : 0];
reg[`INSTRUCTION_WIDTH] vk[RSlength - 1 : 0];
reg[`ROB_WIDTH] qj[RSlength - 1 : 0];
reg[`ROB_WIDTH] qk[RSlength - 1 : 0];
reg[`ROB_WIDTH] dest[RSlength - 1 : 0];
reg[`INSTRUCTION_WIDTH] A[RSlength - 1 : 0];
reg[`INSTRUCTION_WIDTH] pc[RSlength - 1 : 0];

integer i;

reg[`RS_WIDTH] issue_tag;
reg[`RS_WIDTH] idle_pos;
reg[`RS_WIDTH] idle_new;

always @(posedge clk_in) begin
    alu_en_out <= `DISABLE;
    if (rst_in) begin
        issue_tag <= `NULL;
        idle_pos <= 1'b0;
        idle_new <= 1'b1;
        for (i = 0 ; i <= RSlength - 1; i = i + 1) begin
            busy[i] <= `NULL;
        end
    end
    else if (rdy_in) begin
        if (rob_flush_in) begin
            issue_tag <= `NULL;
            idle_pos <= 1'b0;
            idle_new <= 1'b1;
            for (i = 0 ; i <= RSlength - 1; i = i + 1) begin
                busy[i] <= `NULL;
            end
        end 
        else begin
            idle_pos <= idle_new;
            idle_new <= `NULL;
            if (dispatcher_en_in) begin
                busy[idle_pos] <= `BUSY;
                inst_type[idle_pos] <= dispatcher_inst_type_in;
                vj[idle_pos] <= dispatcher_vj_in;
                vk[idle_pos] <= dispatcher_vk_in;
                qj[idle_pos] <= dispatcher_qj_in;
                qk[idle_pos] <= dispatcher_qk_in;
                dest[idle_pos] <= dispatcher_dest_in;
                A[idle_pos] <= dispatcher_A_in;
                pc[idle_pos] <= dispatcher_pc_in;
            end
            if (issue_tag != `NULL) begin
                busy[issue_tag] <= `IDLE;
                issue_tag <= `NULL;
            end
            for (i = 1 ; i <= RSlength - 1 ; i = i + 1) begin
                if (busy[i] && i != issue_tag) begin
                    if (cdb_alu_en_in) begin
                        if (qj[i] == cdb_alu_dest_in) begin
                            vj[i] <= cdb_alu_value_in;
                            qj[i] <= `NULL;
                        end
                        if (qk[i] == cdb_alu_dest_in) begin
                            vk[i] <= cdb_alu_value_in;
                            qk[i] <= `NULL;
                        end
                    end
                    if (cdb_lbuffer_en_in) begin
                        if (qj[i] == cdb_lbuffer_dest_in) begin
                            vj[i] <= cdb_lbuffer_value_in;
                            qj[i] <= `NULL;
                        end
                        if (qk[i] == cdb_lbuffer_dest_in) begin
                            vk[i] <= cdb_lbuffer_value_in;
                            qk[i] <= `NULL;
                        end
                    end
                    if (inst_type[i] == `JAL || 
                        inst_type[i] == `LUI ||
                        inst_type[i] == `AUIPC
                        ) begin
                        alu_en_out <= `ENABLE;
                        alu_A_out <= A[i];
                        alu_dest_out <= dest[i];
                        alu_pc_out <= pc[i];
                        alu_inst_type_out <= inst_type[i];
                        issue_tag <= i;
                    end
                    else if (`BEQ <= inst_type[i] && inst_type[i] <= `BGEU ||
                            inst_type[i] == `ADD ||
                            inst_type[i] == `SUB || 
                            inst_type[i] == `XOR ||
                            inst_type[i] == `OR  ||
                            inst_type[i] == `AND || 
                            inst_type[i] == `SLL || 
                            inst_type[i] == `SRL || 
                            inst_type[i] == `SRA || 
                            inst_type[i] == `SLT || 
                            inst_type[i] == `SLTU
                            ) begin
                        if (qj[i] == `NULL && qk[i] == `NULL) begin
                            alu_en_out <= `ENABLE;
                            alu_A_out <= A[i];
                            alu_vj_out <= vj[i];
                            alu_vk_out <= vk[i];
                            alu_dest_out <= dest[i];
                            alu_pc_out <= pc[i];
                            alu_inst_type_out <= inst_type[i];
                            issue_tag <= i;
                        end
                    end
                    else if (inst_type[i] == `JALR ||
                            inst_type[i] == `ADDI || 
                            inst_type[i] == `XORI ||
                            inst_type[i] == `ORI || 
                            inst_type[i] == `ANDI || 
                            inst_type[i] == `SLLI || 
                            inst_type[i] == `SRLI || 
                            inst_type[i] == `SRAI || 
                            inst_type[i] == `SLTI || 
                            inst_type[i] == `SLTIU
                            ) begin
                        if (qj[i] == `NULL) begin
                            alu_en_out <= `ENABLE;
                            alu_A_out <= A[i];
                            alu_vj_out <= vj[i];
                            alu_dest_out <= dest[i];
                            alu_pc_out <= pc[i];
                            alu_inst_type_out <= inst_type[i];
                            issue_tag <= i;
                        end
                    end
                end
                else begin
                    if (i != idle_pos && i != idle_new) idle_new <= i;
                end
            end
        end
    end
end

assign instqueue_rdy_out = idle_new != `NULL && idle_pos != `NULL;

endmodule