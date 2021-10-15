proc main {} {
	
	open_hw  
	connect_hw_server 
	open_hw_target
    connect
	puts "*RESULT:$devices" 
   	
	exit
}

if {[catch {main} msg options]} {
    puts stderr "unexpected script error: $msg"
    
    # Reserve code 1 for "expected" error exits...
    exit 2
}
