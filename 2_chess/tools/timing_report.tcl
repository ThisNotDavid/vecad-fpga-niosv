set project_name [lindex $quartus(args) 0]
if {$project_name eq ""} {set project_name chess}
project_open $project_name
create_timing_netlist
read_sdc
update_timing_netlist
report_timing -setup -npaths 8 -detail summary -file critical_paths.txt
report_ucp -file unconstrained_paths.txt
delete_timing_netlist
project_close
