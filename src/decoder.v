`include "define.vh"

module decoder(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    
    input wire rob_flush_in,

    input wire instqueue_inst_en,
    input wire[`INSTRUCTION_WIDTH] instqueue_inst_in,
    input wire[`ADDRESS_WIDTH] instqueue_pc_in,

    output reg dispatcher_en_out,
    output reg[`INST_TYPE_WIDTH] dispatcher_inst_type_out,
    output reg[`REGISTER_WIDTH] dispatcher_rs1_out,
    output reg[`REGISTER_WIDTH] dispatcher_rs2_out,
    output reg[`REGISTER_WIDTH] dispatcher_rd_out, 
    output reg[`INSTRUCTION_WIDTH] dispatcher_imm_out,
    output reg[`ADDRESS_WIDTH] dispatcher_pc_out
);

always @(*) begin
    dispatcher_en_out <= `DISABLE;
    dispatcher_inst_type_out <= `NULL;
    dispatcher_rs1_out <= `NULL;
    dispatcher_rs2_out <= `NULL;
    dispatcher_rd_out <= `NULL;
    dispatcher_imm_out <= `NULL;
    dispatcher_pc_out <= `NULL;
    if (rst_in || !instqueue_inst_en || rob_flush_in) begin
        dispatcher_en_out <= `DISABLE;
        dispatcher_inst_type_out <= `NULL;
        dispatcher_rs1_out <= `NULL;
        dispatcher_rs2_out <= `NULL;
        dispatcher_rd_out <= `NULL;
        dispatcher_imm_out <= `NULL;
        dispatcher_pc_out <= `NULL;
    end
    else begin
        dispatcher_en_out <= `ENABLE;
        dispatcher_pc_out <= instqueue_pc_in;
        case (instqueue_inst_in[`OPCODE_WIDTH]) 
            7'b0000011: begin
                dispatcher_rd_out <= instqueue_inst_in[11 : 7];
                dispatcher_rs1_out <= instqueue_inst_in[19 : 15];
                dispatcher_imm_out <= $signed(instqueue_inst_in[31 : 20]);
                case (instqueue_inst_in[14 : 12])
                    3'b000: dispatcher_inst_type_out <= `LB;
                    3'b001: dispatcher_inst_type_out <= `LH;
                    3'b010: dispatcher_inst_type_out <= `LW;
                    3'b100: dispatcher_inst_type_out <= `LBU;
                    3'b101: dispatcher_inst_type_out <= `LHU;
                endcase
            end
            7'b0100011: begin
                dispatcher_rs1_out <= instqueue_inst_in[19 : 15];
                dispatcher_rs2_out <= instqueue_inst_in[24 : 20];
                dispatcher_imm_out <= $signed({instqueue_inst_in[31 : 25] , instqueue_inst_in[11 : 7]});
                case (instqueue_inst_in[14 : 12])
                    3'b000: dispatcher_inst_type_out <= `SB;
                    3'b001: dispatcher_inst_type_out <= `SH;
                    3'b010: dispatcher_inst_type_out <= `SW;
                endcase
            end
            7'b0110011: begin
                dispatcher_rd_out <= instqueue_inst_in[11 : 7];
                dispatcher_rs1_out <= instqueue_inst_in[19 : 15];
                dispatcher_rs2_out <= instqueue_inst_in[24 : 20];
                case (instqueue_inst_in[14 : 12])
                    3'b000: begin
                        if (instqueue_inst_in[31 : 25] == 7'b0000000) dispatcher_inst_type_out <= `ADD; 
                        else dispatcher_inst_type_out <= `SUB; 
                    end
                    3'b100: dispatcher_inst_type_out <= `XOR;
                    3'b110: dispatcher_inst_type_out <= `OR;
                    3'b111: dispatcher_inst_type_out <= `AND;
                    3'b001: dispatcher_inst_type_out <= `SLL;
                    3'b101: begin
                        if (instqueue_inst_in[31 : 25] == 7'b0000000) dispatcher_inst_type_out <= `SRL;
                        else dispatcher_inst_type_out <= `SRA;
                    end
                    3'b010: dispatcher_inst_type_out <= `SLT;
                    3'b011: dispatcher_inst_type_out <= `SLTU;
                endcase
            end
            7'b0010011: begin
                dispatcher_rd_out <= instqueue_inst_in[11 : 7];
                dispatcher_rs1_out <= instqueue_inst_in[19 : 15];
                dispatcher_imm_out <= $signed(instqueue_inst_in[31 : 20]);
                case (instqueue_inst_in[14 : 12])
                    3'b000: dispatcher_inst_type_out <= `ADDI; 
                    3'b100: dispatcher_inst_type_out <= `XORI;
                    3'b110: dispatcher_inst_type_out <= `ORI;
                    3'b111: dispatcher_inst_type_out <= `ANDI;
                    3'b001: begin
                        dispatcher_inst_type_out <= `SLLI;
                        dispatcher_imm_out <= $unsigned(instqueue_inst_in[25 : 20]);
                    end
                    3'b101: begin
                        if (instqueue_inst_in[31 : 26] == 6'b0) begin
                            dispatcher_inst_type_out <= `SRLI;
                            dispatcher_imm_out <= $unsigned(instqueue_inst_in[25 : 20]);
                        end
                        else begin
                            dispatcher_inst_type_out <= `SRAI;
                            dispatcher_imm_out <= $unsigned(instqueue_inst_in[25 : 20]);
                        end
                    end
                    3'b010: dispatcher_inst_type_out <= `SLTI;
                    3'b011: dispatcher_inst_type_out <= `SLTIU;
                endcase
            end
            7'b0110111: begin
                dispatcher_rd_out <= instqueue_inst_in[11 : 7];
                dispatcher_imm_out <= {instqueue_inst_in[31 : 12] , 12'b0};
                dispatcher_inst_type_out <= `LUI;
            end
            7'b0010111: begin
                dispatcher_rd_out <= instqueue_inst_in[11 : 7];
                dispatcher_imm_out <= {instqueue_inst_in[31 : 12] , 12'b0};
                dispatcher_inst_type_out <= `AUIPC;
            end
            7'b1100011: begin
                dispatcher_rs1_out <= instqueue_inst_in[19 : 15];
                dispatcher_rs2_out <= instqueue_inst_in[24 : 20];
                dispatcher_imm_out <= $signed({instqueue_inst_in[31] , instqueue_inst_in[7] , instqueue_inst_in[30 : 25] , instqueue_inst_in[11 : 8] , 1'b0});
                case (instqueue_inst_in[14 : 12])
                    3'b000: dispatcher_inst_type_out <= `BEQ; 
                    3'b001: dispatcher_inst_type_out <= `BNE;
                    3'b100: dispatcher_inst_type_out <= `BLT;
                    3'b101: dispatcher_inst_type_out <= `BGE;
                    3'b110: dispatcher_inst_type_out <= `BLTU;
                    3'b111: dispatcher_inst_type_out <= `BGEU;
                endcase
            end
            7'b1101111: begin
                dispatcher_rd_out <= instqueue_inst_in[11 : 7];
                dispatcher_imm_out <= $signed({instqueue_inst_in[31] , instqueue_inst_in[19 : 12] , instqueue_inst_in[20] , instqueue_inst_in[30 : 21] , 1'b0});
                dispatcher_inst_type_out <= `JAL;
            end
            7'b1100111: begin
                dispatcher_rd_out <= instqueue_inst_in[11 : 7];
                dispatcher_rs1_out <= instqueue_inst_in[19 : 15];
                dispatcher_imm_out <= $signed(instqueue_inst_in[31 : 20]);
                dispatcher_inst_type_out <= `JALR;
            end
        endcase
    end
end

endmodule