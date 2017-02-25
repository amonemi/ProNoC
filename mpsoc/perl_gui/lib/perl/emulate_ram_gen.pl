#!/usr/bin/perl -w
use strict;
use warnings;
use List::Util 'shuffle';
require "widget.pl"; 	


use constant SIM_RAM_GEN	=> 0;			

use constant JTAG_RAM_INDEX	=> 128;
use constant JTAG_DONE_RESET_INDEX	=> 127;
use constant RESET_NOC 		=> " $ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main -n ".JTAG_DONE_RESET_INDEX." -d \"I:1,D:2:1,I:0\" ";
use constant UNRESET_NOC 	=> " $ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main -n ".JTAG_DONE_RESET_INDEX." -d \"I:1,D:2:0,I:0\" ";

use constant READ_DONE_CMD 	=> " $ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main -n ".JTAG_DONE_RESET_INDEX." -d \"I:2,R:2:0,I:0\" ";

use constant UPDATE_WB_ADDR  	=> 0x7; 
use constant UPDATE_WB_WR_DATA  => 0x6;
use constant UPDATE_WB_RD_DATA  => 0x5;
use constant RD_WR_STATUS	=> 0x4;
use constant PROBE_ST 		=> 0x2;
use constant SOURCE_ST		=> 0x1;
use constant BYPAS_ST 		=> 0x0;
use constant RAM_BIN_FILE	=> "$ENV{'PRONOC_WORK'}/emulate/emulate_ram.bin";
use constant RAM_SIM_FILE	=> "$ENV{'PRONOC_WORK'}/emulate/ram";
			




sub reset_cmd {
	my ($ctrl_reset, $noc_reset)=@_;
	my $reset_vector= (($ctrl_reset & 0x1) << 1) +  ($noc_reset & 0x1);
	my $cmd = " $ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main -n ".JTAG_DONE_RESET_INDEX." -d \"I:1,D:2:$reset_vector,I:0\" ";
	#print "$cmd\n";
	return	$cmd;

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
	#print	"\n$cmd \n $stdout";
	return $exit;
}


sub synthetic_destination{
	my($traffic,$x,$y,$xn,$yn,$line_num,$rnd)=@_;
	my $dest_x;
	my $dest_y;
	my $xw          =   log2($xn); 
	my $yw          =   log2($yn); 

	if( $traffic eq "transposed 1"){
		 $dest_x= $xn-$y-1;
		 $dest_y= $yn-$x-1;
		
	} elsif( $traffic eq "transposed 2"){
		 
		$dest_x  = $y;
		$dest_y  = $x;
	} elsif( $traffic eq "bit reverse"){
		my $joint_addr= ($x << log2($xn))+$y;
		my $reverse_addr=0;
		my $pos=0;
		for(my $i=0; $i<($xw+$yw); $i++){#reverse the address
			 $pos= ((($xw+$yw)-1)-$i);
			 $reverse_addr|= (($joint_addr >> $pos) & 0x01) << $i;
                   # reverse_addr[i]  = joint_addr [((Xw+Yw)-1)-i];
		}
		$dest_x  = $reverse_addr>>$yw;
		$dest_y  = $reverse_addr&(0xFF>> (8-$yw));
	 } elsif( $traffic  eq "bit complement") {

		 $dest_x   = (~$x) &(0xFF>> (8-$xw));
		 $dest_y   = (~$y) &(0xFF>> (8-$yw));


	}elsif( $traffic eq "tornado") {
		 
		#[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		 $dest_x   = (($x + (($xn/2)-1))%$xn);
		 $dest_y   = (($y + (($yn/2)-1))%$yn);
	}elsif( $traffic eq "random") {
		 #my $num=($y * $xn) +	$x;
		
		my $xc=$xn * $yn;
		my @randoms=@{$rnd};
		my $num=($y * $xn) +	$x; 
		my $dest = @{$randoms[$num]}[$line_num-1];
		#print "$num:$dest, "; # \@{ \$randoms\[$num\]\}\[$line_num\]"; 
		$dest_x   = $dest % $xn;
		$dest_y   = $dest  / $xn;
		
	} else{#off
		 print "***********************************$traffic is not defined*******************************************\n";
		 $dest_x= $x;
		 $dest_y= $y;
		
	}

	return ($dest_x,$dest_y);

}






sub gen_synthetic_traffic_ram_line{
	my ($emulate,  $x, $y,  $sample_num,$ratio ,$line_num,$rnd)=@_;

	
	
	my $ref=$emulate->object_get_attribute("sample$sample_num","noc_info"); 
	my %noc_info= %$ref;
	my $xn=$noc_info{NX};
	my $yn=$noc_info{NY};	
	my $traffic=$emulate->object_get_attribute("sample$sample_num","traffic"); 

	
	my $pck_num_to_send=$emulate->object_get_attribute("sample$sample_num","PCK_NUM_LIMIT");
	my $pck_size=$emulate->object_get_attribute("sample$sample_num","PCK_SIZE");
	my $pck_class_in=0;
	
	
	if($line_num==0){ #first ram line shows how many times the ram content must be read 
		 #In random traffic each node sends 2 packets to other NC-1  nodes for (pck_num_to_send/2) times 
			my $ram_cnt=  ($traffic eq 'random')? ($pck_num_to_send/(2*(($xn * $yn)-1)))+1:0 ;
			return (0,$ram_cnt);
	
	}
	return (0,0) if($line_num>1  && $traffic ne 'random');	
	return (0,0) if( $line_num>= $xn * $yn);  

	

	#assign {pck_num_to_send_in,ratio_in, pck_size_in,dest_x_in, dest_y_in,pck_class_in, last_adr_in}= q_a;
	my $last_adr  = ( $traffic ne 'random') ? 1 : 
			 ($line_num ==($xn * $yn)-1)? 1 :0;

	my ($dest_x, $dest_y)=synthetic_destination($traffic,$x,$y,$xn,$yn,$line_num,$rnd);

	my $vs= ( $traffic eq 'random')? 2 : $pck_num_to_send;
	$vs=($vs << 2 )+ ($ratio >>5) ;

	my $vl= ($ratio %32);
	$vl=($vl << PCK_SIZw )+$pck_size;
	$vl=($vl << MAXXw )+$dest_x;
	$vl=($vl << MAXYw )+$dest_y;
	$vl=($vl << MAXCw )+$pck_class_in;
	$vl=($vl << 1 )+$last_adr;
	
	return ($vs,$vl);
	

	


}





sub generate_synthetic_traffic_ram{
	my ($emulate,$x,$y,$sample_num,$ratio , $file,$rnd,$num)=@_;
	my $RAM_size=MAX_PATTERN+4; 


	
	my $line_num;
	my $line_value;
	my $ram;
	if(SIM_RAM_GEN){
		my $ext= sprintf("%02u.txt",$num);
		open( $ram, '>', RAM_SIM_FILE.$ext) || die "Can not create: \">lib/emulate/emulate_ram.bin\" $!";
	}
	for ($line_num= 0; $line_num<MAX_PATTERN+4; $line_num++ ) {
		my ($value_s,$value_l)=gen_synthetic_traffic_ram_line ($emulate,  $x, $y,  $sample_num, $ratio ,$line_num,$rnd);
		
		
		#printf ("\n%08x\t",$value_s);
		#printf ("%08x\t",$value_l);
		if(SIM_RAM_GEN){
			my $s=sprintf("%08X%08x",$value_s,$value_l);
			print $ram "$s\n";
		}
		print_32_bit( $file, $value_s); # most significent 32 bit
		print_32_bit( $file, $value_l); # list significent 32 bit

	}
	

	if(SIM_RAM_GEN){
		close($ram);
	}
	#print "\n";

	#last ram three rows reserved for reading data from emulator

}


sub print_32_bit {
	my ($file,$v)=@_;
	for (my $i= 24; $i >=0 ; $i-=8) {
		my $byte= ($v >> $i ) & 0xFF;
		print $file pack('C*',$byte);
		#printf ("%02x\t",$byte);
	}
}



sub generate_emulator_ram {
	my ($emulate, $sample_num,$ratio_in,$info)=@_;
	my $ref=$emulate->object_get_attribute("sample$sample_num","noc_info"); 
	my %noc_info= %$ref;
	my $C=$noc_info{C};
	my $xn=$noc_info{NX};
	my $yn=$noc_info{NY};
	my $xc=$xn*$yn;
	my $rnd=random_dest_gen($xc); # generate a matrix of sudo random number
	my $traffic=$emulate->object_get_attribute("sample$sample_num","traffic"); 
	my @traffics=("tornado", "transposed 1", "transposed 2", "bit reverse", "bit complement","random", "hot spot" );
	
	if ( !defined $xn || $xn!~ /\s*\d+\b/ ){ add_info($info,"programe_pck_gens:invalid X value\n"); help(); return 0;}
	if ( !defined $yn || $yn!~ /\s*\d+\b/ ){ add_info($info,"programe_pck_gens:invalid Y value\n"); help(); return 0;}
	if ( !grep( /^$traffic$/, @traffics ) ){add_info($info,"programe_pck_gens:$traffic is an invalid Traffic name\n"); help(); return 0;}
	if ( $xn <2 || $xn >16 ){ add_info($info,"programe_pck_gens:invalid X value: ($xn). should be between 2 and 16 \n"); help(); return 0;}
	if ( $yn <2 || $yn >16 ){ add_info($info,"programe_pck_gens:invalid Y value:($yn). should be between 2 and 16 \n"); help(); return 0;}
	#open file pointer
	#open(my $file, RAM_BIN_FILE) || die "Can not create: \">lib/emulate/emulate_ram.bin\" $!";
	open(my $file, '>', RAM_BIN_FILE) || die "Can not create: \">lib/emulate/emulate_ram.bin\" $!";
	
	#generate each node ram data
	for (my $y=0; $y<$yn; $y=$y+1){
		for (my $x=0; $x<$xn; $x=$x+1){
			my $num=($y * $xn) +	$x;
			generate_synthetic_traffic_ram($emulate,$x,$y,$sample_num,$ratio_in, $file,$rnd,$num);

		}
	}
	close($file);
	return 1;

}

sub programe_pck_gens{
	my ($emulate, $sample_num,$ratio_in,$info)= @_;
	
	return 0 if(!generate_emulator_ram($emulate, $sample_num,$ratio_in,$info));

	#reset the FPGA board	
	#run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl reset");
	return 0 if(run_cmd_update_info(reset_cmd(1,1),$info)); #reset both noc and jtag
	return 0 if(run_cmd_update_info(reset_cmd(0,1),$info)); #enable jtag keep noc in reset
	#programe packet generators rams
	my $cmd= "$ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main -n ".JTAG_RAM_INDEX." -w 8 -i ".RAM_BIN_FILE." -c";
	#my ($result,$exit) = run_cmd_in_back_ground_get_stdout($cmd);
	
	return 0 if(run_cmd_update_info ($cmd,$info));
	#print $result;
	
	return 0 if(run_cmd_update_info(reset_cmd(1,1),$info)); #reset both
	return 0 if(run_cmd_update_info(reset_cmd(0,0),$info)); #enable both
#run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl unreset");
#add_info($info,"$r\n");

return 1;

}


sub read_jtag_memory{
	my $addr=shift;
	my $cmd= "$ENV{'PRONOC_WORK'}/toolchain/bin/jtag_main -n ".JTAG_RAM_INDEX." -w 8 -d \"I:".UPDATE_WB_ADDR.",D:64:$addr,I:5,R:64:$addr,I:0\"";
	#print "$cmd\n";	
	my ($result,$exit) = run_cmd_in_back_ground_get_stdout($cmd);
	my @q =split  (/###read data#/,$result);
	my $d=$q[1];
	my $s= substr $d,2;
	#print "$s\n";
	return hex($s);
}






sub read_pack_gen{ 
	my ($emulate,$sample_num,$info)= @_;
	my $ref=$emulate->object_get_attribute("sample$sample_num","noc_info"); 
	my %noc_info= %$ref;
	my $xn=$noc_info{NX};
	my $yn=$noc_info{NY};
#wait for done 
    add_info($info, "wait for done\n");
    my $done=0;
    my $counter=0;
    while ($done ==0){
		usleep(300000);
		#my ($result,$exit) = run_cmd_in_back_ground_get_stdout("quartus_stp -t ./lib/tcl/read.tcl done");
		my ($result,$exit) = run_cmd_in_back_ground_get_stdout(READ_DONE_CMD);
		if($exit != 0 ){
			add_info($info,$result);
			return undef;
		}
		my @q =split  (/###read data#/,$result);
		#print "\$result=$result\n";
		
		
		$done=($q[1] eq "0x0")? 0 : 1;
		#print "\$q[1]=$q[1] done=$done\n";
		
		$counter++;
		if($counter == 15){ # 
			add_info($info,"Done is not asserted. I reset the board and try again\n");
			return if(run_cmd_update_info (reset_cmd(1,1),$info));
			#run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl reset");
			usleep(300000);
			return if(run_cmd_update_info (reset_cmd(0,0),$info));
			#run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl unreset");			
		}
		if($counter>30){
			  #something is wrong
			add_info($info,"Done is not asserted again. I  am going to ignore this test case"); 
			return undef;
		}
	}
    
	add_info($info,"Done is asserted\n");
	#print" Done is asserted\n";
	#my $i=0;
	my %results;
	my $sum_of_latency=0;
	my $sum_of_pck=0;
	for (my $y=0; $y<$yn; $y=$y+1){
		for (my $x=0; $x<$xn; $x=$x+1){
			my $num=($y * $xn) +	$x; 
			my $read_addr=($num * RAM_SIZE) + MAX_PATTERN +1;

			my $sent_pck_addr=  sprintf ("%X",$read_addr);
			my $got_pck_addr =  sprintf ("%X",$read_addr+1);
			my $latency_addr =  sprintf ("%X",$read_addr+2);

			$results{$num}{sent_pck}=read_jtag_memory($sent_pck_addr);
			$results{$num}{got_pck}=read_jtag_memory($got_pck_addr);	
			$results{$num}{latency}=read_jtag_memory($latency_addr);
			print "read pckgen $num\n";
			
			$sum_of_latency+=$results{$num}{latency};
			$sum_of_pck+=$results{$num}{got_pck};
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

