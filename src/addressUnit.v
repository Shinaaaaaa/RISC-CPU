`include "define.vh"

module addressUnit(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire lsqueue_en_in,
    input wire[`INSTRUCTION_WIDTH] lsqueue_A_in,
    input wire[`INSTRUCTION_WIDTH] lsqueue_vj_in,
    input wire[`ROB_WIDTH] lsqueue_dest_in,
    input wire[`INST_TYPE_WIDTH] lsqueue_inst_type_in,

    output wire lbuffer_en_out,
    output wire[`INSTRUCTION_WIDTH] lbuffer_A_out,
    output wire[`ROB_WIDTH] lbuffer_dest_out,
    output wire[`INST_TYPE_WIDTH] lbuffer_inst_type_out,

    output wire rob_en_out,
    output wire[`ROB_WIDTH] rob_dest_out,
    output wire[`ADDRESS_WIDTH] rob_address_out
);

assign lbuffer_en_out = lsqueue_en_in && (`LB <= lsqueue_inst_type_in && lsqueue_inst_type_in <= `LHU);
assign lbuffer_A_out = lsqueue_A_in + lsqueue_vj_in;
assign lbuffer_dest_out = lsqueue_dest_in;
assign lbuffer_inst_type_out = lsqueue_inst_type_in;

assign rob_en_out = lsqueue_en_in && (`SB <= lsqueue_inst_type_in && lsqueue_inst_type_in <= `SW);
assign rob_dest_out = lsqueue_dest_in;
assign rob_address_out =  lsqueue_A_in + lsqueue_vj_in;

endmodule