`ifndef __DEFINE__
    `define __DEFINE__ 

`define INSTRUCTION_WIDTH 31 : 0
`define ADDRESS_WIDTH 31 : 0 
`define RAM_RW_WIDTH 7 : 0 
`define REGISTER_WIDTH 4 : 0
`define INST_TYPE_WIDTH 5 : 0
`define ROB_WIDTH 4 : 0
`define RS_WIDTH 3 : 0
`define LS_QUEUE_WIDTH 3 : 0 
`define LBUFFER_WIDTH 3 : 0 

`define IDLE 1'b0
`define BUSY 1'b1
`define DISABLE 1'b0 
`define ENABLE 1'b1
`define NULL 1'b0

`define OPCODE_WIDTH 6 : 0

`define LB    6'b000000
`define LH    6'b000001
`define LW    6'b000010
`define LBU   6'b000011 
`define LHU   6'b000100
`define SB    6'b000101
`define SH    6'b000110 
`define SW    6'b000111
`define ADD   6'b001000
`define ADDI  6'b001001   
`define SUB   6'b001010
`define LUI   6'b001011
`define AUIPC 6'b001100
`define XOR   6'b001101
`define XORI  6'b001110
`define OR    6'b001111
`define ORI   6'b010000
`define AND   6'b010001
`define ANDI  6'b010010
`define SLL   6'b010011
`define SLLI  6'b010100
`define SRL   6'b010101
`define SRLI  6'b010110
`define SRA   6'b010111
`define SRAI  6'b011000
`define SLT   6'b011001
`define SLTI  6'b011010
`define SLTU  6'b011011
`define SLTIU 6'b011100
`define BEQ   6'b011101
`define BNE   6'b011110
`define BLT   6'b011111
`define BGE   6'b100000
`define BLTU  6'b100001
`define BGEU  6'b100010
`define JAL   6'b100011
`define JALR  6'b100100

`endif