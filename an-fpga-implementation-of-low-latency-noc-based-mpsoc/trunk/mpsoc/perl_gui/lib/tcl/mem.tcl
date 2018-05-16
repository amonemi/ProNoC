#!/usr/bin/tclsh

## Setup USB hardware - assumes only USB Blaster is installed and
## an FPGA is the only device in the JTAG chain


set usb [lindex [get_hardware_names] 0]
set device_name [lindex [get_device_names -hardware_name $usb] 0]
	


proc hold_reset {} {
	
	global device_name usb
	start_insystem_source_probe -device_name $device_name -hardware_name $usb
	write_source_data -instance_index 127 -value 0x1 -value_in_hex
	end_insystem_source_probe
}

proc release_reset {} {
	
	global device_name usb
	start_insystem_source_probe -device_name $device_name -hardware_name $usb
	write_source_data -instance_index 127 -value 0x0 -value_in_hex
	end_insystem_source_probe
}





proc update_memory { mem_name  mem_word_addr mem_content } {
	global device_name usb

	foreach instance [get_editable_mem_instances -hardware_name $usb -device_name $device_name] {
		set inst_name 	[lindex $instance 5]
		set inst_index	[lindex $instance 0]
		#puts $inst_name 
		#puts $inst_index
 		#set xx [string range  $inst_name 0 1]
		#set yy [string range  $inst_name 2 end]
		#puts $xx
		#puts $yy
		if { $inst_name eq $mem_name } {
			write_content_to_memory -instance_index $inst_index -start_address $mem_word_addr -word_count 1 -content $mem_content -content_in_hex
			puts "memory ${inst_name} is programed with  $mem_content value"
		}
	
	}
	

}






if { [lindex $::argv 0] eq "reset" } { 
	hold_reset 
 	puts "reset the system!\n"

} elseif { [lindex $::argv 0] eq "unreset" } { 
	release_reset
 	puts "unreset the system!\n"

}  elseif { $::argc > 0 } {
		
		puts $usb
		puts $device_name
		# Initiate a editing sequence
		begin_memory_edit -hardware_name $usb -device_name $device_name
		
		set write_num  $::argc
		for {set i 0} {$i < $write_num} {incr i 3 } {
			set mem_name [lindex $::argv $i]
			set mem_word_addr  [lindex $::argv $i+1]
			set mem_content  [lindex $::argv $i+2]
			update_memory   $mem_name $mem_word_addr $mem_content
		}
		# End of editing sequence
		end_memory_edit


} else {
    puts "no command line argument passed"
}












