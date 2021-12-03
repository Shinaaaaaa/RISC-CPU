`include "define.vh"

module LSQueue(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire lbuffer_rdy_in,

    output wire instqueue_rdy_out,

    input wire dispatcher_en_in,
    input wire[`INSTRUCTION_WIDTH] dispatcher_vj_in,
    input wire[`ROB_WIDTH] dispatcher_qj_in,
    input wire[`INSTRUCTION_WIDTH] dispatcher_vk_in,
    input wire[`ROB_WIDTH] dispatcher_qk_in,
    input wire[`INST_TYPE_WIDTH] dispatcher_inst_type_in,
    input wire[`INSTRUCTION_WIDTH] dispatcher_A_in,
    input wire[`ROB_WIDTH] dispatcher_dest_in,

    input wire cdb_alu_en_in,
    input wire[`ROB_WIDTH] cdb_alu_dest_in,
    input wire[`INSTRUCTION_WIDTH] cdb_alu_value_in,

    input wire cdb_lbuffer_en_in,
    input wire[`ROB_WIDTH] cdb_lbuffer_dest_in,
    input wire[`INSTRUCTION_WIDTH] cdb_lbuffer_value_in,

    input wire rob_flush_in,
    output reg rob_en_out,
    output reg[`ROB_WIDTH] rob_dest_out,
    output reg[`INSTRUCTION_WIDTH] rob_value_out,

    output reg addressUnit_en_out,
    output reg[`INSTRUCTION_WIDTH] addressUnit_A_out,
    output reg[`INSTRUCTION_WIDTH] addressUnit_vj_out,
    output reg[`ROB_WIDTH] addressUnit_dest_out,
    output reg[`INST_TYPE_WIDTH] addressUnit_inst_type_out
);

localparam LSQueuelength = 16;

reg busy[LSQueuelength - 1 : 0];
reg[`INST_TYPE_WIDTH] inst_type[LSQueuelength - 1 : 0];
reg[`INSTRUCTION_WIDTH] vj[LSQueuelength - 1 : 0];
reg[`INSTRUCTION_WIDTH] vk[LSQueuelength - 1 : 0];
reg[`ROB_WIDTH] qj[LSQueuelength - 1 : 0];
reg[`ROB_WIDTH] qk[LSQueuelength - 1 : 0];
reg[`ROB_WIDTH] dest[LSQueuelength - 1 : 0];
reg[`INSTRUCTION_WIDTH] A[LSQueuelength - 1 : 0];

reg[`LS_QUEUE_WIDTH] head;
reg[`LS_QUEUE_WIDTH] tail;
integer i;

always @(posedge clk_in) begin
    rob_en_out <= `DISABLE;
    addressUnit_en_out <= `DISABLE;
    if (rst_in) begin
        head <= `NULL;
        tail <= `NULL;
        rob_en_out <= `DISABLE;
        addressUnit_en_out <= `DISABLE;
        for (i = 0 ; i <= LSQueuelength - 1 ; i = i + 1) begin
            busy[i] <= 1'b0;
        end
    end
    else if (rdy_in) begin
        if (rob_flush_in) begin
            head <= `NULL;
            tail <= `NULL;
            rob_en_out <= `DISABLE;
            addressUnit_en_out <= `DISABLE;
            for (i = 0 ; i <= LSQueuelength - 1 ; i = i + 1) begin
                busy[i] <= 1'b0;
            end
        end
        else begin
            if (dispatcher_en_in) begin
                busy[tail] <= 1'b1;
                inst_type[tail] <= dispatcher_inst_type_in;
                vj[tail] <= dispatcher_vj_in;
                vk[tail] <= dispatcher_vk_in;
                qj[tail] <= dispatcher_qj_in;
                qk[tail] <= dispatcher_qk_in;
                dest[tail] <= dispatcher_dest_in;
                A[tail] <= dispatcher_A_in;
                tail <= (tail + 1) % LSQueuelength;
            end
            for (i = 0 ; i <= LSQueuelength - 1 ; i = i + 1) begin
                if (busy[i]) begin
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
                end
            end
            if (head != tail) begin
                if (lbuffer_rdy_in && `LB <= inst_type[head] && inst_type[head] <= `LHU) begin
                    if (qj[head] == `NULL) begin
                        addressUnit_en_out <= `ENABLE;
                        addressUnit_A_out <= A[head];
                        addressUnit_dest_out <= dest[head];
                        addressUnit_vj_out <= vj[head];
                        addressUnit_inst_type_out <= inst_type[head];
                        head <= (head + 1) % LSQueuelength;
                    end
                end
                else if (`SB <= inst_type[head] && inst_type[head] <= `SW) begin
                    if (qj[head] == `NULL && qk[head] == `NULL) begin
                        rob_en_out <= `ENABLE;
                        rob_dest_out <= dest[head];
                        case (inst_type[head])
                            `SB: rob_value_out <= vk[head][7 : 0];
                            `SH: rob_value_out <= vk[head][15 : 0];
                            `SW: rob_value_out <= vk[head][31 : 0];
                        endcase
                        addressUnit_en_out <= `ENABLE;
                        addressUnit_A_out <= A[head];
                        addressUnit_dest_out <= dest[head];
                        addressUnit_vj_out <= vj[head];
                        addressUnit_inst_type_out <= inst_type[head];
                        head <= (head + 1) % LSQueuelength;
                    end
                end
            end
        end
    end
end

assign instqueue_rdy_out = (head != (tail + 1) % LSQueuelength && head != (tail + 2) % LSQueuelength);

endmodule