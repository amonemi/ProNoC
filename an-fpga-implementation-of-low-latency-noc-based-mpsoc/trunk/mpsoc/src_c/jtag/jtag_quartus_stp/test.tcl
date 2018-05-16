#quartus_stp -t 
#This portion of the script is derived from some of the examples from Altera
global usbblaster_name
global test_device
# List all available programming hardwares, and select the USBBlaster.
# (Note: this example assumes only one USBBlaster connected.)
# Programming Hardwares:
foreach hardware_name [get_hardware_names] {
	puts $hardware_name
	if { [string match "DE-SoC *" $hardware_name] } {
		set usbblaster_name $hardware_name
	}
}


puts "\nSelect JTAG chain connected to $usbblaster_name.\n";

# List all devices on the chain, and select the first device on the chain.
#Devices on the JTAG chain:


foreach device_name [get_device_names -hardware_name $usbblaster_name] {
	puts $device_name
	if { [string match "@2*" $device_name] } {
		set test_device $device_name
	}
}
puts "\nSelect device: $test_device.\n";

# Open device 
proc openport {} {
	global usbblaster_name
        global test_device
	open_device -hardware_name $usbblaster_name -device_name $test_device
}

# Close device.  Just used if communication error occurs
proc closeport { } {
	catch {device_unlock}
	catch {close_device}
}



openport   
device_lock -timeout 10000

device_virtual_ir_shift -instance_index 127 -ir_value 1 -no_captured_ir_value
device_virtual_dr_shift -dr_value 3 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex
device_virtual_dr_shift -dr_value 2 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex
device_virtual_ir_shift -instance_index 127 -ir_value 0 -no_captured_ir_value
catch {device_unlock}

after 1000

device_lock -timeout 10000
device_virtual_ir_shift -instance_index 127 -ir_value 1 -no_captured_ir_value
device_virtual_dr_shift -dr_value 3 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex
device_virtual_dr_shift -dr_value 0 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex
device_virtual_ir_shift -instance_index 127 -ir_value 0 -no_captured_ir_value
catch {device_unlock}

after 1000

device_lock -timeout 10000
device_virtual_ir_shift -instance_index 127 -ir_value 1 -no_captured_ir_value
device_virtual_dr_shift -dr_value 3 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex
set data [device_virtual_dr_shift -dr_value 2 -instance_index 127  -length 2  -value_in_hex]
puts $data
device_virtual_ir_shift -instance_index 127 -ir_value 0 -no_captured_ir_value
catch {device_unlock}

after 1000

closeport










