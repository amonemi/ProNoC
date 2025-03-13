#!/usr/bin/perl -w
use strict;
use warnings;
use List::Util 'shuffle';
require "widget.pl";
require "traffic_pattern.pl";

use constant SIM_RAM_GEN    => 0;
use constant JTAG_STATIC_INDEX    => 124;
use constant JTAG_RAM_INDEX    => 125;
use constant JTAG_COUNTER_INDEX=>126;
use constant JTAG_DONE_RESET_INDEX    => 127;
use constant STATISTIC_NUM =>8;
use constant CLK_CNTw=> 30; #log2(MAX_SIM_CLKs);
#use constant RESET_NOC         => " $ENV{'JTAG_INTFC'} -n ".JTAG_DONE_RESET_INDEX." -d \"I:1,D:2:1,I:0\" ";
#use constant UNRESET_NOC     => " $ENV{'JTAG_INTFC'} -n ".JTAG_DONE_RESET_INDEX." -d \"I:1,D:2:0,I:0\" ";
use constant READ_DONE_CMD     => " \" -n ".JTAG_DONE_RESET_INDEX." -d I:2,R:2:0,I:0 \" ";
use constant READ_COUNTER_CMD => " \" -n ".JTAG_COUNTER_INDEX." -d I:2,R:".CLK_CNTw.":0,I:0 \" ";
use constant UPDATE_WB_ADDR      => 0x7;
use constant UPDATE_WB_WR_DATA  => 0x6;
use constant UPDATE_WB_RD_DATA  => 0x5;
use constant RD_WR_STATUS    => 0x4;
use constant PROBE_ST         => 0x2;
use constant SOURCE_ST        => 0x1;
use constant BYPAS_ST         => 0x0;
#use constant RAM_BIN_FILE    => "$ENV{'PRONOC_WORK'}/emulate/emulate_ram.bin";
#use constant RAM_SIM_FILE    => "$ENV{'PRONOC_WORK'}/emulate/ram";

sub reset_cmd {
    my ($ctrl_reset, $noc_reset,$jtag_intfc)=@_;
    my $reset_vector= (($ctrl_reset & 0x1) << 1) +  ($noc_reset & 0x1);
    my $cmd = "bash $jtag_intfc \" -n ".JTAG_DONE_RESET_INDEX."  -d I:1,D:2:$reset_vector,I:0 \" ";
    #print "$cmd\n";
    return    $cmd;
}

sub set_time_limit_cmd {
    my ($time_limit,$jtag_intfc)=@_;
    my $hex = sprintf("0x%X", $time_limit);
    my $cmd = "bash $jtag_intfc \" -n ".JTAG_COUNTER_INDEX."  -d I:1,D:".CLK_CNTw.":$hex,I:0 \" ";
    #print "$cmd\n";
    return    $cmd;
}

sub help {
        print
"    usage: ./ram_gen X  Y TRAFFIC
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

sub random_dest_gen_no_shuffle {
    my $n=shift;
    my @c=(0..$n-1);
    my @o;
    for (my $i=0; $i<$n; $i++){
        my @l=  @c;
        @l=remove_scolar_from_array(\@l,$i);
        $o[$i]=\@l;
    }
    return \@o;
}

sub run_cmd_update_info {
    my ($cmd,$info)=@_;
    my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
        if($exit){
            add_colored_info($info, "$stdout\n",'red') if(defined $stdout);
            add_colored_info($info, "$stderr\n",'red') if(defined $stderr);
        }
    #print    "\n$cmd \n $stdout";
    return $exit;
}

sub synthetic_destination{
    my($self,$sample,$traffic,$endp,$line_num,$rnd)=@_;
    return  pck_dst_gen ($self,$sample,$traffic,$endp,$line_num,$rnd);
}

sub gen_synthetic_traffic_ram_line{
    my ($emulate,  $endp,  $sample,$ratio ,$line_num,$rnd)=@_;
    my ($topology, $T1, $T2, $T3, $V, $Fpay) = get_sample_emulation_param($emulate,$sample);
    my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info_sub ($topology, $T1, $T2, $T3, $V, $Fpay);
    my $traffic=$emulate->object_get_attribute($sample,"traffic");
    my $pck_num_to_send=$emulate->object_get_attribute($sample,"PCK_NUM_LIMIT");
    my $pck_size=$emulate->object_get_attribute($sample,"PCK_SIZE");
    my $pck_class_in=0;
    if($line_num==0){ #first ram line shows how many times the ram content must be read
        #In random traffic each node sends 2 packets to other NC-1  nodes for (pck_num_to_send/2) times
            my $ram_cnt=  ($traffic eq 'random')? ($pck_num_to_send/(2*($NE-1)))+1:0 ;
            return (0,$ram_cnt);
    }
    return (0,0) if($line_num>1  && $traffic ne 'random');
    return (0,0) if( $line_num>= $NE);
    #assign {pck_num_to_send_in,ratio_in, pck_size_in,dest_x_in, dest_y_in,pck_class_in, last_adr_in}= q_a;
    my $last_adr  = ( $traffic ne 'random') ? 1 :
            ($line_num ==$NE-1)? 1 :0;
    my $dest_e_addr=synthetic_destination($emulate,$sample,$traffic,$endp,$line_num,$rnd);
    #print "$endp->$dest_e_addr\n";
    my $vs= ( $traffic eq 'random')? 2 : $pck_num_to_send;
    $vs=($vs << 2 )+ ($ratio >>5) ;
    my $vl= ($ratio %32);
    $vl = ($vl << PCK_SIZw ) + $pck_size;
    $vl = ($vl << MAX_EAw ) + $dest_e_addr;
    $vl = ($vl << MAXCw ) + $pck_class_in;
    $vl = ($vl << 1 ) + $last_adr;
    return ($vs,$vl);
}

sub get_synthetic_traffic_pattern{
    my ($self, $sample)=@_;
    my ($topology, $T1, $T2, $T3, $V, $Fpay) = get_sample_emulation_param($self,$sample);
    my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info_sub ($topology, $T1, $T2, $T3, $V, $Fpay);
    my $rnd=random_dest_gen_no_shuffle($NE);
    my $traffic=$self->object_get_attribute($sample,"traffic");
    my @traffics=("tornado", "transposed 1", "transposed 2", "bit reverse", "bit complement","random", "hot spot", "shuffle", "neighbor", "bit rotation"  );
    #generate each node ram data
    my $pattern="source->\t destination\n";
    $traffic=($traffic eq "hot spot") ? "random" : $traffic;
    my $dest_num = ($traffic eq "hot spot" || $traffic eq "random" ) ? $NE-1 : 1;
    for (my $endp=0; $endp<$NE; $endp++){
        $pattern = $pattern."$endp->\n";
        for (my $num= 0; $num<$dest_num; $num++ ) {
        my $dest_e_addr=synthetic_destination($self,$sample,$traffic,$endp,$num,$rnd);
        my $des_id=endp_addr_decoder($self,$dest_e_addr);
        $pattern = ($des_id == $endp)?$pattern."\t$des_id (Off)\n" : $pattern."\t$des_id\n";
    }}
    return $pattern;
}

sub generate_synthetic_traffic_ram{
    my ($emulate,$endp,$sample,$ratio , $file,$rnd)=@_;
    my $line_num;
    my $line_value;
    my $ram;
    if(SIM_RAM_GEN){
        my $ext= sprintf("%02u.txt",$endp);
        open( $ram, '>', "$ENV{'PRONOC_WORK'}/emulate/ram".$ext) || die "Can not create: \"$ENV{'PRONOC_WORK'}/emulate/ram.$ext\" $!";
    }
    for ($line_num= 0; $line_num<RAM_SIZE; $line_num++ ) {
        my ($value_s,$value_l)=gen_synthetic_traffic_ram_line ($emulate,  $endp,  $sample, $ratio ,$line_num,$rnd);
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
    my ($emulate, $sample,$ratio_in,$info)=@_;
    my ($topology, $T1, $T2, $T3, $V, $Fpay) = get_sample_emulation_param($emulate,$sample);
    my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info_sub ($topology, $T1, $T2, $T3, $V, $Fpay);
    my $rnd=random_dest_gen($NE); # generate a matrix of sudo random number
    my $traffic=$emulate->object_get_attribute($sample,"traffic");
    my @traffics=("tornado", "transposed 1", "transposed 2", "bit reverse", "bit complement","random", "hot spot", "shuffle", "neighbor", "bit rotation"   );
    #if ( !defined $xn || $xn!~ /\s*\d+\b/ ){ add_info($info,"programe_pck_gens:invalid X value\n"); help(); return 0;}
    #if ( !defined $yn || $yn!~ /\s*\d+\b/ ){ add_info($info,"programe_pck_gens:invalid Y value\n"); help(); return 0;}
    if ( !grep( /^$traffic$/, @traffics ) ){add_info($info,"programe_pck_gens:$traffic is an invalid Traffic name\n"); help(); return 0;}
    if ( $EAw >8 ){ add_info($info,"Program_pck_gens:invalid EAw value: ($EAw). should be between 1 and 8 \n"); help(); return 0;}
    #if ( $yn <2 || $yn >16 ){ add_info($info,"programe_pck_gens:invalid Y value:($yn). should be between 2 and 16 \n"); help(); return 0;}
    #open file pointer
    #open(my $file, '>', RAM_BIN_FILE) || die "Can not create: \">lib/emulate/emulate_ram.bin\" $!";
    open(my $file, '>', "$ENV{'PRONOC_WORK'}/emulate/emulate_ram.bin") || die "Can not create: \"$ENV{'PRONOC_WORK'}/emulate/emulate_ram.bin\" $!";
    #generate each node ram data
    for (my $endp=0; $endp<$NE; $endp++){
        #print "generate_synthetic_traffic_ram($emulate,$endp,$sample,$ratio_in, $file,$rnd);\n";
        generate_synthetic_traffic_ram($emulate,$endp,$sample,$ratio_in, $file,$rnd);
    }
    close($file);
    return 1;
}

sub programe_pck_gens{
    my ($emulate, $sample,$ratio_in,$info,$jtag_intfc)= @_;
    if(!generate_emulator_ram($emulate, $sample,$ratio_in,$info)){
        add_colored_info($info, "Error in generate_emulator_ram function\n",'red');
        return 0;
    }
    #reset the FPGA board
    #run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl reset");
    #print "#reset both noc and jtag\n";
    return 0 if(run_cmd_update_info(reset_cmd(1,1,$jtag_intfc),$info)); #reset both noc and jtag
    #print "#enable jtag keep noc in reset\n";
    return 0 if(run_cmd_update_info(reset_cmd(0,1,$jtag_intfc),$info)); #enable jtag keep noc in reset
    #print "#set time limit\n";
    #set time limit
    my $time_limit = $emulate->object_get_attribute($sample,"SIM_CLOCK_LIMIT");
    return 0 if(run_cmd_update_info(set_time_limit_cmd($time_limit,$jtag_intfc),$info));
    #program the packet generators rams
    my $cmd= "bash $jtag_intfc \"-n ".JTAG_RAM_INDEX."  -w 8 -i $ENV{'PRONOC_WORK'}/emulate/emulate_ram.bin -c\" ";
    #my ($result,$exit) = run_cmd_in_back_ground_get_stdout($cmd);
    return 0 if(run_cmd_update_info ($cmd,$info));
    #print $result;
    return 0 if(run_cmd_update_info(reset_cmd(1,1,$jtag_intfc),$info)); #reset both
    return 0 if(run_cmd_update_info(reset_cmd(0,0,$jtag_intfc),$info)); #enable both
#run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl unreset");
#add_info($info,"$r\n");
return 1;
}

sub read_jtag_memory{
    my ($addr,$jtag_intfc,$info)=@_;
    my $cmd= "bash $jtag_intfc \" -n ".JTAG_STATIC_INDEX." -w 8 -d I:".UPDATE_WB_ADDR.",D:64:$addr,I:5,R:64:$addr,I:0\"";
    #print "$cmd\n";
    my ($result,$exit,$stderr) = run_cmd_in_back_ground_get_stdout($cmd);
    if($exit){
            add_colored_info($info, "$result\n",'red') if(defined $result);
            add_colored_info($info, "$stderr\n",'red') if(defined $stderr);
            return undef;
    }
    #print "$result\n";
    my @q =split  (/###read data#/,$result);
    my $d=$q[1];
    my $s= substr $d,2;
    #print "$s\n";
    return hex($s);
}

sub read_statistic_mem {
    my($NE,$jtag_intfc,$info)=@_;
    my %results;
    my $sum_of_latency=0;
    my $sum_of_pck=0;
    my $total_router=0;
    for (my $num=0; $num<$NE; $num++){
            my $read_addr=($num * STATISTIC_NUM);
            my $sent_pck_addr=  sprintf ("%X",$read_addr);
            my $got_pck_addr =  sprintf ("%X",$read_addr+1);
            my $latency_addr =  sprintf ("%X",$read_addr+2);
            my $worst_latency_addr =  sprintf ("%X",$read_addr+3);
            $results{$num}{sent_pck}=read_jtag_memory($sent_pck_addr,$jtag_intfc,$info);
            $results{$num}{got_pck}=read_jtag_memory($got_pck_addr,$jtag_intfc,$info);
            $results{$num}{latency}=read_jtag_memory($latency_addr,$jtag_intfc,$info);
            $results{$num}{worst_latency}=read_jtag_memory($worst_latency_addr,$jtag_intfc,$info);
            add_info($info, "$num, ");
            $sum_of_latency+=$results{$num}{latency};
            $sum_of_pck+=$results{$num}{got_pck};
            $total_router++ if($results{$num}{sent_pck}>0);
        #$i=$i+2;
    }
    add_info($info, "\n");
    return (\%results,$sum_of_latency,$sum_of_pck,$total_router);
}

sub read_statistic_mem_fast {
    my($NE,$jtag_intfc,$info)=@_;
    my %results;
    my $sum_of_latency=0;
    my $sum_of_pck=0;
    my $total_router=0;
    #read static memory
    my $end= STATISTIC_NUM * 8 *$NE;
    $end=sprintf ("%X",$end);
    my $cmd= "bash $jtag_intfc \"-n ".JTAG_STATIC_INDEX."  -w 8 -r -s 0 -e $end\"";
    #print "$cmd\n";
    my ($result,$exit,$stderr) = run_cmd_in_back_ground_get_stdout($cmd);
    if($exit){
            add_colored_info($info, "$result\n",'red') if(defined $result);
            add_colored_info($info, "$stderr\n",'red') if(defined $stderr);
            return undef;
    }
    #print "$result\n";
    my @q =split  (/###read data#\n/,$result);
    my @data= split  (/\n/,$q[1]);
    #print "$data[0]\n";
    for (my $endp=0; $endp<$NE; $endp=$endp+1){
            my $num=$endp;
            my $read_addr=($num * STATISTIC_NUM);
            my $sent_pck_addr=  $read_addr;
            my $got_pck_addr =  $read_addr+1;
            my $latency_addr =  $read_addr+2;
            my $worst_latency_addr =  $read_addr+3;
            $results{$num}{sent_pck}=hex($data[$sent_pck_addr]);
            $results{$num}{got_pck}=hex($data[$got_pck_addr]);
            $results{$num}{latency}=hex($data[$latency_addr]);
            $results{$num}{worst_latency}=hex($data[$worst_latency_addr]);
            #add_info($info, "$num, ");
            #print "$results{$num}{sent_pck}=hex($data[$sent_pck_addr]);\n";
            $sum_of_latency+=$results{$num}{latency};
            $sum_of_pck+=$results{$num}{got_pck};
            $total_router++ if($results{$num}{sent_pck}>0);
        #$i=$i+2;
    }
    #add_info($info, "\n");
    return (\%results,$sum_of_latency,$sum_of_pck,$total_router);
}

sub read_pack_gen{
    my ($emulate,$sample,$info,$jtag_intfc,$ratio_in)= @_;
    my $ref=$emulate->object_get_attribute($sample,"noc_info");
    my ($topology, $T1, $T2, $T3, $V, $Fpay) = get_sample_emulation_param($emulate,$sample);
    my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info_sub ($topology, $T1, $T2, $T3, $V, $Fpay);
#wait for done
    add_info($info, "wait for done\n");
    my $done=0;
    my $counter=0;
    while ($done ==0){
        usleep(300000);
        #my ($result,$exit) = run_cmd_in_back_ground_get_stdout("quartus_stp -t ./lib/tcl/read.tcl done");
        my ($result,$exit) = run_cmd_in_back_ground_get_stdout("bash $jtag_intfc".READ_DONE_CMD);
        if($exit != 0 ){
            add_colored_info($info,$result,'red');
            return undef;
        }
        my @q =split  (/###read data#/,$result);
        #print "\$result=$result\n";
        $done=($q[1] eq "0x0")? 0 : 1;
        #print "\$q[1]=$q[1] done=$done\n";
        $counter++;
        if($counter == 15){ #
            add_info($info,"Done is not asserted. I reset the board and try again\n");
            return if(run_cmd_update_info (reset_cmd(1,1,$jtag_intfc),$info));
            #run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl reset");
            usleep(300000);
            return if(run_cmd_update_info (reset_cmd(0,0,$jtag_intfc),$info));
            #run_cmd_in_back_ground("quartus_stp -t ./lib/tcl/mem.tcl unreset");
        }
        if($counter>30){
            #something is wrong
            add_colored_info($info,"Done is not asserted again. I  am going to ignore this test case\n",'green');
            return undef;
        }
    }
    add_info($info,"Done is asserted\nStart reading statistic data from cores:\n\t");
    #print" Done is asserted\n";
    #my $i=0;
    #my ($results_ref,$sum_of_latency,$sum_of_pck,$total_router)= read_statistic_mem($NE,$jtag_intfc,$info);
    my ($results_ref,$sum_of_latency,$sum_of_pck,$total_router)= read_statistic_mem_fast($NE,$jtag_intfc,$info);
    my %results=%$results_ref;
    foreach my $p (sort keys %results){
        update_result($emulate,$sample,"packet_rsvd_result",$ratio_in,$p,$results{$p}{got_pck} );
        update_result($emulate,$sample,"packet_sent_result",$ratio_in,$p,$results{$p}{sent_pck});
        update_result($emulate,$sample,"worst_delay_rsvd_result",$ratio_in,$p,$results{$p}{worst_latency});
        #print "$p  : \n latency: $results{$p}{latency}\n";
        #print "got_pck : $results{$p}{got_pck}\n";
        #print "sent_pck:$results{$p}{sent_pck}\n\n";
        #print "worst_delay:$results{$p}{worst_latency}\n\n";
    }
    #print "total active router=$total_router\n";
    #read clock counter
    my $clk_counter;
    my ($result,$exit) = run_cmd_in_back_ground_get_stdout("bash $jtag_intfc".READ_COUNTER_CMD);
    if($exit != 0 ){
        add_colored_info($info,$result,'red');
    }else {
        my @q =split  (/###read data#/,$result);
        my $d=$q[1];
        my $s= substr $d,2;
        $clk_counter= hex($s);
    }
    my $avg_latency= ($sum_of_pck>0)? $sum_of_latency/$sum_of_pck : 0;
    my $packet_size=$emulate->object_get_attribute($sample,"PCK_SIZE");
    my $avg_throughput= ($sum_of_pck>0 && $total_router>0 && $clk_counter>0 )? (($sum_of_pck * $packet_size *100)/ $total_router )/$clk_counter:0;
    #print "($sum_of_pck * $packet_size *100)/ $total_router )/$clk_counter = $avg_throughput)";
    #print "$avg = $sum_of_latency/$sum_of_pck ";
    $avg_latency= sprintf("%.1f", $avg_latency);
    update_result ($emulate,$sample,"latency_result",$ratio_in,$avg_latency);
    update_result ($emulate,$sample,"throughput_result",$ratio_in,$avg_throughput);
    update_result ($emulate,$sample,"exe_time_result",$ratio_in,$clk_counter);
    return 1;
}
1;