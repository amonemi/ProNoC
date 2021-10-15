proc main {} {
	# ... put the real main code in here ...
	open_hw  
	connect_hw_server 
	open_hw_target
    set devices  [get_hw_devices]
	puts "*RESULT:$devices" 
   	
	exit
}

if {[catch {main} msg options]} {
    puts stderr "unexpected script error: $msg"
    
    # Reserve code 1 for "expected" error exits...
    exit 2
}
