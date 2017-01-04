#!/usr/bin/perl -w
use strict;
use warnings;
use List::Util 'shuffle';
require "widget.pl"; 				


use constant RESET_CMD 		=> " $ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main -n 127 -d \"I:1,D:1:1,I:0\" ";
use constant UNRESET_CMD 	=> " $ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main -n 127 -d \"I:1,D:1:0,I:0\" ";
use constant READ_DONE_CMD 	=> " $ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main -n 127 -d \"I:2,R:1:0,I:0\" ";
use constant UPDATE_WB_ADDR  	=> 0x7;
use constant UPDATE_WB_WR_DATA  => 0x6;
use constant UPDATE_WB_RD_DATA  => 0x5;
use constant RD_WR_STATUS	=> 0x4;
use constant PROBE_ST 		=> 0x2;
use constant SOURCE_ST		=> 0x1;
use constant BYPAS_ST 		=> 0x0;
				

sub get_data{					
				    
	my ( $x, $y, $ref, $traffic, $ratio_in,$num, $line_num, $dest)=@_;
	my %noc_info= %$ref;
	my $C=$noc_info{C};
	my $xn=$noc_info{NX};
	my $yn=$noc_info{NY};				
	my $MAX_PCK_NUM   = $noc_info{MAX_PCK_NUM};
	my $MAX_SIM_CLKs  = $noc_info{MAX_SIM_CLKs};
	my $MAX_PCK_SIZ   = $noc_info{MAX_PCK_SIZ};


	my $Xw          =   log2($xn);   # number of node in x axis
        my $Yw          =   log2($yn);   # number of node in y axis
        my $Cw          =  ($C > 1)? log2($C): 1;
        #$Fw          =   2+V+Fpay,
        my $RATIOw      =   log2(100),
        my $PCK_CNTw    =   log2($MAX_PCK_NUM+1),
        my $CLK_CNTw    =   log2($MAX_SIM_CLKs+1),
        my $PCK_SIZw    =   log2($MAX_PCK_SIZ+1);

	my $Dw=$PCK_CNTw+ $RATIOw + $PCK_SIZw + $Xw + $Yw + $Cw +1;  				
	my $val=0;
	my $q=0;
	my $i=0;
	my $last_adr=($traffic eq 'random' && $line_num<($xn* $yn)-2 )? 0 : 1; 
	#print "my $last_adr=($traffic eq 'random' && $line_num<($xn* $yn)-2 )? 0 : 1; \n";
	my @fileds=get_ram_line($C, $x, $y, $xn, $yn, $traffic,$ratio_in,$line_num,$dest,$last_adr);
	my ($pck_num_to_send_,$ratio_in_,$pck_size_,$dest_x_,$dest_y_,$pck_class_in_,$last_adr_)=@fileds;
	my @sizes= ($PCK_CNTw, $RATIOw , $PCK_SIZw , $Xw , $Yw , $Cw ,1);
					
	foreach my $p (@fileds){
		$val= $val << $q;	
		$val= $val + $p;
		$i++;
		$q=$sizes[$i] if(defined $sizes[$i]);
	} 
					
	my $sum = 0;
 
	foreach my $num (@sizes){
			$sum = $sum + $num;
	}
	my $result = sprintf("%010x", $val);
	#print"$result\n";	
	return ($result,$last_adr,$Dw);
					
					
					
					

#ram_do= {pck_num_to_send_,ratio_in_,pck_size_,dest_x_,dest_y_,pck_class_in_,last_adr_}; 


}

sub get_ram_line{
	my ($C, $x, $y, $xn, $yn, $traffic,$ratio_in,$line_num,$dest,$last_adr_)=@_;
	
	my $pck_num_to_send_=2000000;
	my $pck_size_=4;
	my $pck_class_in_=0;
	

	my $xw=log2($xn);
	my $yw=log2($yn);
	
	#print "$traffic\n";
	my $dest_x_;
	my $dest_y_;

	if( $traffic eq "transposed 1"){
		 $dest_x_= $xn-$y-1;
		 $dest_y_= $yn-$x-1;
		
	} elsif( $traffic eq "transposed 2"){
		 
		$dest_x_  = $y;
		$dest_y_  = $x;
	} elsif( $traffic eq "bit reverse"){
		my $joint_addr= ($x << log2($xn))+$y;
		my $reverse_addr=0;
		my $pos=0;
		for(my $i=0; $i<($xw+$yw); $i++){#reverse the address
			 $pos= ((($xw+$yw)-1)-$i);
			 $reverse_addr|= (($joint_addr >> $pos) & 0x01) << $i;
                   # reverse_addr[i]  = joint_addr [((Xw+Yw)-1)-i];
		}
		$dest_x_  = $reverse_addr>>$yw;
		$dest_y_  = $reverse_addr&(0xFF>> (8-$yw));

	 } elsif( $traffic  eq "bit complement") {

		 $dest_x_   = (~$x) &(0xFF>> (8-$xw));
		 $dest_y_   = (~$y) &(0xFF>> (8-$yw));


    }  elsif( $traffic eq "tornado") {
		 
		#[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		 $dest_x_   = (($x + (($xn/2)-1))%$xn);
		 $dest_y_   = (($y + (($yn/2)-1))%$yn);

	} elsif( $traffic eq "random") {
		 #my $num=($y * $xn) +	$x;
		 $pck_num_to_send_=2;
		 $dest_x_   = $dest % $xn;
		 $dest_y_   = $dest  / $xn;
		
		
		
	}else{#off
		 print "***********************************$traffic is not defined*******************************************\n";
		 $dest_x_= $x;
		 $dest_y_= $y;
		
	}

	#print"  ($pck_num_to_send_,$ratio_in,$pck_size_,$dest_x_,$dest_y_,$pck_class_in_,$last_adr_);\n";
	return  ($pck_num_to_send_,$ratio_in,$pck_size_,$dest_x_,$dest_y_,$pck_class_in_,$last_adr_);


}





sub help {
		print 
"	usage: ./ram_gen X  Y TRAFFIC
		X:  number of node in X direction 2<x<=16
		Y:  number of node in Y direction 2<y<=16
		TRAFFIC : select one of the following traffic patterns :
			tornado,
			transposed 1,
			transposed 2,
			random, 
			
";	
	
}	






sub gen_ram{
	my ($data,$mem_width)=get_data(@_);
	my $result = sprintf("%8x", $data);

	
	
	return $result;
	
	
}	

sub random_dest_gen {
	my $n=shift;
	my @c=(0..$n-1);
	my @o;	
	for (my $i=0; $i<$n; $i++){
		my @l= shuffle @c;
		@l=remove_scolar_from_array(\@l,$i);
		$o[$i]=\@l;
		
	}
	return \@o;

}

sub run_cmd_update_info {
	my ($cmd,$info)=@_;
	my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
		if($exit){
			add_info($info, "$stdout\n") if(defined $stdout);
			add_info($info, "$stderr\n") if(defined $stderr);
			
		}
	return $exit;
}








sub programe_pck_gens{
	my ($ref, $traffic,$ratio_in,$info)= @_;
	my %noc_info= %$ref;
	my $C=$noc_info{C};
	my $xn=$noc_info{NX};
	my $yn=$noc_info{NY};
    #print( "@_\n" );
	my @traffics=("tornado", "transposed 1", "transposed 2", "bit reverse", "bit complement","random", "hot spot" );
	my $xc=$xn * $yn;
	my @randoms=@{random_dest_gen($xc)};

	if ( !defined $xn || $xn!~ /\s*\d+\b/ ){ add_info($info,"programe_pck_gens:invalid X value\n"); help(); return 0;}
	if ( !defined $yn || $yn!~ /\s*\d+\b/ ){ add_info($info,"programe_pck_gens:invalid Y value\n"); help(); return 0;}
	if ( !grep( /^$traffic$/, @traffics ) ){add_info($info,"programe_pck_gens:$traffic is an invalid Traffic name\n"); help(); return 0;}
	if ( $xn <2 || $xn >16 ){ add_info($info,"programe_pck_gens:invalid X value: ($xn). should be between 2 and 16 \n"); help(); return 0;}
	if ( $yn <2 || $yn >16 ){ add_info($info,"programe_pck_gens:invalid Y value:($yn). should be between 2 and 16 \n"); help(); return 0;}

	#reset the FPGA board	
	#run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl reset");
	return if(run_cmd_update_info(RESET_CMD,$info));
	

my $argument='';
my $argument2='';

for (my $x=0; $x<$xn; $x=$x+1){
	for (my $y=0; $y<$yn; $y=$y+1){
		my $num=($y * $xn) +	$x;
		$num= ($num<=9)? "0$num" : $num;
		#add_info($info, "programe M$num\n");
		my $line=0;
		my ($ram_val,$end,$Dw);
		my $repeat=($traffic eq 'random')? "0x2710" : "0x0"; # 10000 : 0;
		
		$argument=undef;
		do{
			($ram_val,$end,$Dw)=get_data($x, $y, $ref, $traffic,$ratio_in,$num,$line,@{$randoms[$num]}[$line]);
			if(!defined $argument ) { #first row
				$argument="-n $num -d \"I:".UPDATE_WB_ADDR.",D:$Dw:0,I:".UPDATE_WB_WR_DATA.",D:$Dw:0x$ram_val"; 
			}
			#$argument="$argument M$num $line $ram_val";
			else {
				$argument=$argument.",D:$Dw:0x$ram_val";

			}
			#$argument="$argument M$num $line $ram_val";
			$line++;
			#print "\$line=$line\n";
		} while($end == 0);
		$argument=$argument.",I:0\"";
		#program the memory
		#print "$cmd\n";
		my $cmd="$ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main $argument";
 		return if(run_cmd_update_info ($cmd,$info));
		my $source_index=$num+128;
		
		$cmd= "$ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main -n $source_index -d \"I:".SOURCE_ST.",D:100:$repeat,I:0\"";
		return if(run_cmd_update_info ($cmd,$info));		
		#$argument2="$argument2 P$num $repeat";



		#my $file="./RAM/M$num.mif\n";
		#unless(open FILE, '>'.$file) { die "\nUnable to create $file\n";}

		# Write data to the file.
		#my $ram_content= gen_ram(0, $x, $y, $xn, $yn, $traffic,"M$num");
		#print FILE $ram_content;
		# close the file.
		#close FILE;
	
	}	
}
#print "quartus_stp -t ./lib/tcl/mem.tcl $argument\n";
# ($result,$exit)=run_cmd_in_back_ground_get_stdout("quartus_stp -t ./lib/tcl/mem.tcl $argument");
#add_info($info,"update packet generators\n");
#print "($result,$exit)\n";
#return 0 if ($exit);
#print "quartus_stp -t ./lib/tcl/source.tcl $argument2\n";
#($result,$exit)=run_cmd_in_back_ground_get_stdout("quartus_stp -t ./lib/tcl/source.tcl $argument2");
#print "($result,$exit)\n";
#return 0 if ($exit);

# deassert the reset
	
	return if(run_cmd_update_info (UNRESET_CMD,$info));
#run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl unreset");
#add_info($info,"$r\n");

return 1;

}



sub read_pack_gen{ 
	my ($ref,$info)= @_;
	my %noc_info= %$ref;
	my $xn=$noc_info{NX};
	my $yn=$noc_info{NY};
#wait for done 
    add_info($info, "wait for done\n");
    my $done=0;
    my $counter=0;
    while ($done ==0){
		
		#my ($result,$exit) = run_cmd_in_back_ground_get_stdout("quartus_stp -t ./lib/tcl/read.tcl done");
		my ($result,$exit) = run_cmd_in_back_ground_get_stdout(READ_DONE_CMD);
		my @q =split  (/###read data#/,$result);
		#print "\$result=$result\n";
		
		
		$done=($q[1] eq "0x0")? 0 : 1;
		#print "\$q[1]=$q[1] done=$done\n";
		usleep(9000);
		$counter++;
		if($counter == 15){ # 
			add_info($info,"Done is not asserted. I reset the board and try again\n");
			return if(run_cmd_update_info (RESET_CMD,$info));
			#run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl reset");
			usleep(300000);
			return if(run_cmd_update_info (UNRESET_CMD,$info));
			#run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl unreset");			
		}
		if($counter>30){
			  #something is wrong
			add_info($info,"Done is not asserted again. I  am going to ignore this test case"); 
			return undef;
		}
	}
    
	add_info($info,"Done is asserted\n");
	#my $i=0;
	my %results;
	my $sum_of_latency=0;
	my $sum_of_pck=0;
	for (my $x=0; $x<$xn; $x=$x+1){
		for (my $y=0; $y<$yn; $y=$y+1){
			my $num=($y * $xn) +	$x; 
			my $source_index=$num+128;
			my $cmd= "$ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main -n $source_index -d \"I:".PROBE_ST.",R:100:0,I:0\"";
			my ($result,$exit) = run_cmd_in_back_ground_get_stdout($cmd);
			my @q =split  (/###read data#/,$result);
			
	
	
		my $d=$q[1];
		#print "num=$num:    ddddd=$d\n";	
		my $s= substr $d,2;
		#print "dddddddd=$s\n";	
		my $latency =substr $s, 0,9;  
		my $got_pck= substr $s, -16, 8;  
		my $sent_pck= substr $s, -8;  
		#print "$latency, $got_pck, $sent_pck\n";	
		
		
		$results{$num}{latency}=hex($latency);
		$results{$num}{got_pck}=hex($got_pck);
		$results{$num}{sent_pck}=hex($sent_pck);
		$sum_of_latency+=hex($latency);
		$sum_of_pck+=hex($got_pck);
		#$i=$i+2;
	}}
	
	foreach my $p (sort keys %results){
		
		
		#print "$p  : \n latency: $results{$p}{latency}\n";
		#print " got_pck : $results{$p}{got_pck}\n";
		#print "sent_pck:$results{$p}{sent_pck}\n\n";

	} 
	my $avg= ($sum_of_pck>0)? $sum_of_latency/$sum_of_pck : 0;
	return sprintf("%.1f", $avg);
}	

