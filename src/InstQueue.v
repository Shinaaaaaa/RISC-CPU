`include "define.vh"

module InstQueue(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire rob_flush_in,

    input wire rob_rdy_in,

    input wire lsqueue_rdy_in,

    input wire rs_rdy_in,

    output wire ifetch_rdy_out,
    input wire ifetch_en_in,
    input wire[`INSTRUCTION_WIDTH] ifetch_inst_in,
    input wire[`ADDRESS_WIDTH] ifetch_pc_in,

    output reg decoder_en_out,
    output reg[`INSTRUCTION_WIDTH] decoder_inst_out,
    output reg[`ADDRESS_WIDTH] decoder_pc_out
);

localparam queueLen = 5'b10000;

reg[`INSTRUCTION_WIDTH] instQue[queueLen : 0];
reg[`ADDRESS_WIDTH] pcQue[queueLen : 0];

reg[4:0] head;
reg[4:0] tail;
integer i;

always @(posedge clk_in) begin
    decoder_en_out <= `DISABLE;
    if (rst_in) begin
        for (i = 0 ; i < queueLen ; i = i + 1) begin
            instQue[i] <= `NULL;
            pcQue[i] <= `NULL;
        end
        head <= 1'b0;
        tail <= 1'b0;
        decoder_en_out <= `DISABLE;
    end
    else if (rdy_in) begin
        if (rob_flush_in) begin
            for (i = 0 ; i < queueLen ; i = i + 1) begin
                instQue[i] <= `NULL;
                pcQue[i] <= `NULL;
            end
            head <= 1'b0;
            tail <= 1'b0;
            decoder_en_out <= `DISABLE;
        end
        else begin
            if (ifetch_en_in) begin
                instQue[tail] <= ifetch_inst_in;
                pcQue[tail] <= ifetch_pc_in;
                tail <= (tail + 1) % queueLen;
            end
            if (head != tail && rob_rdy_in && rs_rdy_in && lsqueue_rdy_in) begin
                decoder_en_out <= `ENABLE;
                decoder_inst_out <= instQue[head];
                decoder_pc_out <= pcQue[head];
                head <= (head + 1) % queueLen;
            end
        end    
    end
end

assign ifetch_rdy_out = (head != (tail + 1) % queueLen && head != (tail + 2) % queueLen);

endmodule