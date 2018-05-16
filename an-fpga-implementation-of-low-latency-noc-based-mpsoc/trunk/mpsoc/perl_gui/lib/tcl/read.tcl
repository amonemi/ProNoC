#/usr/bin/tclsh









## Setup USB hardware - assumes only USB Blaster is installed and
## an FPGA is the only device in the JTAG chain
set usb [lindex [get_hardware_names] 0]
set device_name [lindex [get_device_names -hardware_name $usb] 0]

puts $usb
puts $device_name




# List information of all In-System Sources and Probes instances
puts "Information on all In-System Sources and Probes instances:"
puts "index,source_width,probe_width,name"

#check if done is asserted

if { [lindex $::argv 0] eq "done" } { 

	start_insystem_source_probe -device_name $device_name -hardware_name $usb
	set val [read_probe_data -instance_index 127  -value_in_hex]
	end_insystem_source_probe
	puts "######\n"
	puts $val
	puts "\n######\n"

} else {



	puts "######\n"


	foreach instance [get_insystem_source_probe_instance_info -hardware_name $usb -device_name $device_name] {
		set name [lindex $instance 3]
	
		if {[regexp {P[0-9]+} $name var] } {	
			#puts $var	
			#puts "[lindex $instance 0],[lindex $instance 1],[lindex $instance 2],[lindex $instance 3]"
			set index [lindex $instance 0]
			set index_name [lindex $instance 3]

			global device_name usb
			start_insystem_source_probe -device_name $device_name -hardware_name $usb
			set val [read_probe_data -instance_index $index  -value_in_hex]
	
			set data "$index_name  $val\n"
			#puts -nonewline $fileId $data 
			puts  $data 
			end_insystem_source_probe



		}
	}
	puts "######\n"

}


