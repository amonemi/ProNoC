proc main {} {


	if { $::argc == 0 } {
		    puts "The script requires board_part to be input."
		    puts "Please try again."
		exit
	} 



	if { $::argc >1 } {
		set path [lindex $::argv 1] 
		set_param board.repoPaths [list "$path"]
	}
		   
	set board_part [lindex $::argv 0]

	create_project -force "$::env(PRONOC_WORK)/tmp" 
	 
	set_property "board_part" $board_part [current_project]     
	set parts [get_parts [get_property PART_NAME [current_board_part]]]
	puts "*RESULT:$parts"


	exit
}


if {[catch {main} msg options]} {
    puts stderr "unexpected script error: $msg"
    
    # Reserve code 1 for "expected" error exits...
    exit 2
}





