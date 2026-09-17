package require ::quartus::project
set project [lindex $quartus(args) 0]
set fp [open "project_settings.txt" r]
set settings [read $fp]
close $fp
project_new $project -overwrite
# QSF uses literal bus names; protect them when evaluating as ordinary Tcl.
set settings [string map [list "\[" "\\\[" "\]" "\\\]"] $settings]
eval $settings
export_assignments
project_close
