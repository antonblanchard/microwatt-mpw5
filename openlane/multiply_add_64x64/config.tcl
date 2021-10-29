set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) multiply_add_64x64

set ::env(VERILOG_FILES) "\
	$script_dir/src/multiply_add_64x64.v"

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "10"
set ::env(CLOCK_NET) $::env(CLOCK_PORT)

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 550 550"

# Settings for macros
set ::env(DESIGN_IS_CORE) 0
set ::env(FP_PDN_CORE_RING) 0
set ::env(RT_MAX_LAYER) "met4"

# Handle PDN
set ::env(VDD_NETS) [list {VPWR} ]
set ::env(GND_NETS) [list {VGND} ]

# Tuning
set ::env(PL_TARGET_DENSITY) 0.36

# Because the macro uses standard cells
set ::env(SYNTH_READ_BLACKBOX_LIB) 1

set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

if {[catch {exec nproc} result] == 0} {
	set ::env(ROUTING_CORES) $result
} else {
	set ::env(ROUTING_CORES) 4
}

# Fix hold violations by increasing the margin 
set ::env(PL_RESIZER_HOLD_SLACK_MARGIN) "0.4"

#set ::env(DIODE_INSERTION_STRATEGY) 0

set ::env(PL_ROUTABILITY_DRIVEN) 1
set ::env(PL_TIME_DRIVEN) 1

# ext2spice is failing when using the LEF
set ::env(MAGIC_EXT_USE_GDS) 1
# This doesn't work with a gds.spice file for some reason
set ::env(RUN_CVC) 0
