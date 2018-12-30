vlib work
vlog -timescale 1ns/1ns lab6part3.v
vsim part2
log {/*}
add wave {/*}
force {clk} 0 0, 1 5 -r 10
force {resetn} 0 0, 1 10
force {go} 0 0, 1 10,0 20,1 30,0 40
force {data_in[7: 0]} 10000011 0
run 200ns