`include "define.vh"

module ALU(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire rs_en_in,
    input wire[`INSTRUCTION_WIDTH] rs_vj_in,
    input wire[`INSTRUCTION_WIDTH] rs_vk_in,
    input wire[`INSTRUCTION_WIDTH] rs_A_in,
    input wire[`ROB_WIDTH] rs_dest_in,
    input wire[`ADDRESS_WIDTH] rs_pc_in,
    input wire[`INST_TYPE_WIDTH] rs_inst_type_in,

    input wire rob_flush_in,
    
    output wire cdb_alu_en_out,
    output wire[`ROB_WIDTH] cdb_alu_dest_out,
    output reg[`INSTRUCTION_WIDTH] cdb_alu_value_out,
    output reg[`ADDRESS_WIDTH] cdb_alu_addr_out
);

localparam false = 0;
localparam true = 1;

always @(*) begin
    case (rs_inst_type_in)
        `JAL: begin
            cdb_alu_value_out <= rs_pc_in + 4;
            cdb_alu_addr_out <= rs_pc_in + rs_A_in;
        end 
        `LUI: cdb_alu_value_out <= rs_A_in;
        `AUIPC: cdb_alu_value_out <= rs_pc_in + rs_A_in;
        `BEQ: begin
            if (rs_vj_in == rs_vk_in) cdb_alu_value_out <= true;
            else cdb_alu_value_out <= false;
            cdb_alu_addr_out <= rs_pc_in + rs_A_in; 
        end 
        `BNE: begin
            if (rs_vj_in != rs_vk_in) cdb_alu_value_out <= true;
            else cdb_alu_value_out <= false;
            cdb_alu_addr_out <= rs_pc_in + rs_A_in;
        end
        `BLT: begin
            if ($signed(rs_vj_in) < $signed(rs_vk_in)) cdb_alu_value_out <= true;
            else cdb_alu_value_out <= false;
            cdb_alu_addr_out <= rs_pc_in + rs_A_in;
        end
        `BGE: begin
            if ($signed(rs_vj_in) >= $signed(rs_vk_in)) cdb_alu_value_out <= true;
            else cdb_alu_value_out <= false;
            cdb_alu_addr_out <= rs_pc_in + rs_A_in;
        end
        `BLTU: begin
            if ($unsigned(rs_vj_in) < $unsigned(rs_vk_in)) cdb_alu_value_out <= true;
            else cdb_alu_value_out <= false;
            cdb_alu_addr_out <= rs_pc_in + rs_A_in;
        end
        `BGEU: begin
            if ($unsigned(rs_vj_in) >= $unsigned(rs_vk_in)) cdb_alu_value_out <= true;
            else cdb_alu_value_out <= false;
            cdb_alu_addr_out <= rs_pc_in + rs_A_in;
        end
        `ADD: cdb_alu_value_out <= rs_vj_in + rs_vk_in;
        `SUB: cdb_alu_value_out <= rs_vj_in - rs_vk_in;
        `XOR: cdb_alu_value_out <= rs_vj_in ^ rs_vk_in;
        `OR: cdb_alu_value_out <= rs_vj_in | rs_vk_in;
        `AND: cdb_alu_value_out <= rs_vj_in & rs_vk_in;
        `SLL: cdb_alu_value_out <= rs_vj_in << rs_vk_in[4 : 0];
        `SRL: cdb_alu_value_out <= rs_vj_in >> rs_vk_in[4 : 0]; 
        `SRA: cdb_alu_value_out <= $signed(rs_vj_in >> rs_vk_in[4 : 0]);
        `SLT: cdb_alu_value_out <= ($signed(rs_vj_in) < $signed(rs_vk_in));
        `SLTU: cdb_alu_value_out <= ($unsigned(rs_vj_in) < $unsigned(rs_vk_in));
        `JALR: begin
            cdb_alu_value_out <= rs_pc_in + 4;
            cdb_alu_addr_out <= (rs_vj_in + rs_A_in)&~1;
        end
        `ADDI: cdb_alu_value_out <= rs_vj_in + rs_A_in;
        `XORI: cdb_alu_value_out <= rs_vj_in ^ rs_A_in;
        `ORI: cdb_alu_value_out <= rs_vj_in | rs_A_in;
        `ANDI: cdb_alu_value_out <= rs_vj_in & rs_A_in;
        `SLLI: cdb_alu_value_out <= rs_vj_in << rs_A_in;
        `SRLI: cdb_alu_value_out <= rs_vj_in >> rs_A_in;
        `SRAI: cdb_alu_value_out <= $signed(rs_vj_in >> rs_A_in);
        `SLTI: cdb_alu_value_out <= ($signed(rs_vj_in) < $signed(rs_A_in));
        `SLTIU: cdb_alu_value_out <= ($unsigned(rs_vj_in) < $unsigned(rs_A_in));
    endcase
end

assign cdb_alu_dest_out = rs_dest_in;
assign cdb_alu_en_out = (rst_in || rob_flush_in || !rs_en_in) ? `DISABLE : `ENABLE;

endmodule