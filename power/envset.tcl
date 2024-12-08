#####################################################
#Read design data & technology
#####################################################

set CURRENT_PATH [pwd]
set TOP_DESIGN pipeline_top

set search_path [list "./" "../" "/afs/umich.edu/class/eecs470/lib/synopsys/"]

## Add libraries below
## technology .db file, and memory .db files
set target_library "/afs/umich.edu/class/eecs470/lib/synopsys/lec25dscc25_TT.db"

set LINK_PATH [concat  "*" $target_library]

## Replace with your complete file paths
set SDC_FILE      	$CURRENT_PATH/top_design.sdc
set NETLIST_FILE	$CURRENT_PATH/../synth/$TOP_DESIGN.vg

## Replace with your instance hierarchy
set STRIP_PATH    testbench/top0

## Replace with your activity file dumped from vcs simulation
set ACTIVITY_FILE 	$CURRENT_PATH/$TOP_DESIGN.vcd

######## Timing Sections ########
set	START_TIME 1.0
set	END_TIME 1000.0
