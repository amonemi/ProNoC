set script_dir [file dirname [file normalize [info script]]]

set DESIGN  noc_top
set report_filename $::env(REPORT_FILENAME)

# Waivers:
#sg_read_waiver -file ${script_dir}/waiver.awl
#source ${script_dir}/waiver.tcl

# Reading Intel linting rules 
source $script_dir/lint_rules.tcl


# Replace this with the actual path to your .f file
set filelist_path $::env(FILE_LIST)

# Loop through lines
# File handle and storage
set fp [open $filelist_path r]
while {[gets $fp line] >= 0} {
    set line [string trim $line]

    # Skip empty lines and comments
    if {$line eq "" || [string match "#*" $line]} {
        continue
    }

    # Handle +incdir+<path>
    #if {[string match "+incdir+*" $line]} {
    #    set incdir [string range $line 8 end]
    # set_option include_path $incdir
    #    continue
    #}

    # Add source file
    lappend names_list $line
}
close $fp



analyze -format sverilog    "$names_list"

elaborate $DESIGN

#read_sdc $constraints_path

# Need to add this waiver in here, otherwise is not applicable
#source ${script_dir}/waiver.tcl

check_lint

report_lint -verbose -file ${report_filename}
report_lint
exit 0