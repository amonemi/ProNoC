#!/usr/bin/tclsh

## Setup USB hardware - assumes only USB Blaster is installed and
## an FPGA is the only device in the JTAG chain


set usb [lindex [get_hardware_names] 0]
set device_name [lindex [get_device_names -hardware_name $usb] 0]
	





proc update_src { src_name   src_content } {
	global device_name usb
	foreach instance [get_insystem_source_probe_instance_info -hardware_name $usb -device_name $device_name] {
		set name [lindex $instance 3]
		if {[regexp {P[0-9]+} $name var] } {	
			
			set index [lindex $instance 0]
			set index_name [lindex $instance 3]

			global device_name usb				


			if { $index_name eq $src_name } {
				start_insystem_source_probe -device_name $device_name -hardware_name $usb
				write_source_data -instance_index $index -value $src_content -value_in_hex
				puts "src_ ${index_name} is programed with  $src_content value"
				# End of editing sequence
				end_insystem_source_probe
			}
	
		}
	}

}




if { $::argc > 0 } {
		
		puts $usb
		puts $device_name
		# Initiate a editing sequence
		
		
		set write_num  $::argc
		#start_insystem_source_probe -device_name $device_name -hardware_name $usb
		for {set i 0} {$i < $write_num} {incr i 2 } {
			set src_name [lindex $::argv $i]
			set src_content  [lindex $::argv $i+1]
			update_src   $src_name  $src_content
		}
		


} else {
    puts "no command line argument passed"
}












