# Create and map the work library
vlib work
vmap work work

# Compile the SystemVerilog testbench
vlog -sv tb_serialize.sv

# Start simulation with optimization turned off for full visibility
vsim -voptargs=+acc work.tb_serialize

# Configure the wave window
view wave

# Add the internal driving clock as a reference
add wave -divider "Internal Clock"
add wave -color "Cyan" sim:/tb_serialize/bfm_inst/i_dclk

# Add the physical interface signals
add wave -divider "Physical Interface"
add wave -color "Yellow" sim:/tb_serialize/bfm_inst/reset
add wave -color "Yellow" sim:/tb_serialize/bfm_inst/i_clk_p
add wave -color "Yellow" sim:/tb_serialize/bfm_inst/i_clk_n
add wave -color "Yellow" sim:/tb_serialize/bfm_inst/i_track
add wave -color "Magenta" sim:/tb_serialize/bfm_inst/i_valid
add wave -color "White" -radix hex sim:/tb_serialize/bfm_inst/i_data

# Run the simulation
run -all

# Zoom the wave window to fit the entire transaction perfectly
wave zoom full