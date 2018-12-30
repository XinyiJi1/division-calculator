vlib work
vlog -timescale 1ns/1ns lab6part3.v
vsim lab6part3
log {/*}
add wave {/*}
force {CLOCK_50} 0 0, 1 5 -r 10
force {KEY[0]} 0 0, 1 10
force {KEY[1]} 1 0, 0 10,1 20,0 30,1 40
force {SW[7:0]} 01110011 0
run 200ns