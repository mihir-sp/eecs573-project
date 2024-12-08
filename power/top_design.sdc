create_clock -period 30.0 [get_ports clock]

 

  set WIRE_LOAD tsmcwire
  set LOGICLIB lec25dscc25_TT
  set design_name pipeline_top

  set_wire_load_model -name $WIRE_LOAD -lib $LOGICLIB $design_name
  set_wire_load_mode top
