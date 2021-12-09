# A Simple Tomasulo CPU by Verilog
### 一个含ICache（分支预测总是跳转）的乱序执行CPU

## timeline
* 11.29 代码完成，通过编译
* 11.30 不可抗力，摸了
* 12.01 输出 Hello World！
* 12.03 iverilog测试，通过测试点
* 12.04 ICache
* 12.05 带ICache，iverilog通过测试点
* 12.06 开始上板
* 12.07 资源爆炸
* 12.09 FPGA pass！
* 开摆

## testcases pass
| testcases | time     |
| -------   | -------  |
| bulgarian | 1.234474 |
| hanoi     | 1.226053 |
| pi        | 3.560139 |
| qsort     | 6.386864 |
| queens    | 2.945716 |
| uartboom  | 0.774486 |
| superloop | 0.018287 |