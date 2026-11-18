# Run from the repository root directory.
if {[file exists work]} {vdel -lib work -all}
vlib work
vlog -sv rtl/sync_fifo.sv tb/fifo_if.sv tb/fifo_tb_pkg.sv tb/fifo_properties.sv tb/tb_top.sv
vsim -c -coverage tb_top
run -all
quit -f
