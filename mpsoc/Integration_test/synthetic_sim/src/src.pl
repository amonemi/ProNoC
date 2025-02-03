#!/usr/bin/perl -w

use lib "../perl_lib";

use List::MoreUtils qw(uniq);
use Proc::Background;
use File::Path qw( rmtree );
use File::Path qw( make_path );
use Cwd qw(realpath);
use Cwd 'abs_path';

my $script_path = dirname(__FILE__);
my $dirname = realpath("$script_path/..");
my $root = realpath("$dirname/../..");
my $confs_dir="$dirname/configurations";

print "Script Path: $script_path\n";
print "confs_dir: $confs_dir\n";
print "Root: $root\n";


my $rtl_dir = "$ENV{PRONOC_WORK}/verify/rtl";
my $work    = "$ENV{PRONOC_WORK}/verify/work";
my $verify  = "$ENV{PRONOC_WORK}/verify";



my $src_verilator = "$root/src_verilator";
my $src_c = "$root/src_c";
my $src = "$script_path";
my $report = "$dirname/report";

#require "$root/perl_gui/lib/perl/common.pl";
require "$root/perl_gui/lib/perl/topology.pl";

use strict;
use warnings;

my $pp;
	$pp= do "$src/deafult_noc_param";
	die "Error reading: $@" if $@;

	my $param = $pp->{'noc_param'};
	my %default_noc_param=%{$param};
	my @params=object_get_attribute_order($pp,'noc_param');



#read default param


sub recompile_synful {
    # Define the command to recompile Synful
    my $cmd = "cd $src_c/synfull/traffic-generator/src && make; wait;";

    print "******************* Compile Synful *******************\n";
    print "Executing command: $cmd\n";

    # Run the command and capture its exit status
    my $output = `$cmd 2>&1`; # Capture both stdout and stderr
    my $exit_status = $? >> 8; # Extract exit code

    # Check for errors
    if ($exit_status != 0) {
        die "Error: Compilation of Synful failed with exit code $exit_status. Output:\n$output\n";
    } else {
        print "Synful compiled successfully.\n";
    }
}

sub gen_noc_param_h{
	my $mpsoc=shift;
	my $param_h="\n\n//NoC parameters\n";
	
	my $topology = $mpsoc->object_get_attribute('noc_param','TOPOLOGY');
	$topology =~ s/"//g;
	$param_h.="\t#define  IS_${topology}\n";
	
	my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info($mpsoc);
	
	my @params=$mpsoc->object_get_attribute_order('noc_param');
	my $custom_topology = $mpsoc->object_get_attribute('noc_param','CUSTOM_TOPOLOGY_NAME');
	foreach my $p (@params){
		my $val=$mpsoc->object_get_attribute('noc_param',$p);
		next if($p eq "CUSTOM_TOPOLOGY_NAME");
		next if($p eq "int VC_CONFIG_TABLE [MAX_ROUTER][MAX_PORT]");
		$val=$custom_topology if($p eq "TOPOLOGY" && $val eq "\"CUSTOM\"");
		if($p eq "MCAST_ENDP_LIST" || $p eq "ESCAP_VC_MASK"){
			$val="$NE".$val if($p eq 'MCAST_ENDP_LIST');
			$val =~ s/\'/\\\'/g;
			$val="\"$val\"";			
		}
		$param_h=$param_h."\t#define $p\t$val\n";
		
		#print "$p:$val\n";
		
	}


	my $v=$mpsoc->object_get_attribute('noc_param',"V")-1;
	my $escape=$mpsoc->object_get_attribute('noc_param',"ESCAP_VC_MASK");
	if (! defined $escape){
		#add_text_to_string (\$param_h,"\tlocalparam [$v	:0] ESCAP_VC_MASK=1;\n");
		#add_text_to_string (\$pass_param,".ESCAP_VC_MASK(ESCAP_VC_MASK),\n"); 
	}
	#add_text_to_string (\$param_h," \tlocalparam  CVw=(C==0)? V : C * V;\n");
	#add_text_to_string (\$pass_param,".CVw(CVw)\n");
	
	#remove 'b and 'h
	#$param_h =~ s/\d\'b/ /g;
	#$param_h =~ s/\'h/ /g;
	
	
	return  $param_h;	
}


sub gen_sim_parameter_h {
	my ($param_h,$includ_h,$ne,$nr,$router_p,$fifow)=@_;
	
	$param_h =~ s/\d\'b/ /g;
	my $text=  "
#ifndef     INCLUDE_PARAM
	#define   INCLUDE_PARAM \n \n 

	$param_h 
	 	
 	#define NE  $ne
 	#define NR  $nr
 	#define ROUTER_P_NUM $router_p
 	
	extern Vtraffic		*traffic[NE];
	extern Vpck_inj     *pck_inj[NE];
	extern int reset,clk;
	
	//simulation parameter	
	#define MAX_RATIO   1000
	#define AVG_LATENCY_METRIC \"HEAD_2_TAIL\"
	#define TIMSTMP_FIFO_NUM   $fifow
	
	$includ_h
\n \n \#endif" ; 
	return $text;	
}	


sub extract_and_update_noc_sim_statistic {
	my ($stdout)=@_;
	my $avg_latency =capture_number_after("average packet latency =",$stdout);
	my $avg_flit_latency =capture_number_after("average flit latency =",$stdout);
	my $sd_latency =capture_number_after("standard_dev =",$stdout);
	my $avg_thput =capture_number_after("Avg throughput is:",$stdout);
	my $total_time =capture_number_after("simulation clock cycles:",$stdout);
	my $latency_perhop = capture_number_after("average latency per hop =",$stdout);
	my %packet_rsvd_per_core = capture_cores_data("total number of received packets:",$stdout);
	my %worst_rsvd_delay_per_core = capture_cores_data('worst-case-delay of received packets \(clks\):',$stdout);
	my %packet_sent_per_core = capture_cores_data("total number of sent packets:",$stdout);
	my %worst_sent_delay_per_core = capture_cores_data('worst-case-delay of sent packets \(clks\):',$stdout);


}

sub get_model_parameter {
	my $model =shift;	
	my $o;
	$o= do $model;
	my %new_param=%{$o};
    die "Error reading: $@" if $@;
	my %temp;
	foreach my $p (@params){
		$temp{$p} = $default_noc_param{$p};       
	}
	foreach my $p (sort keys %new_param){
		$temp{$p} = $new_param{$p};
	}
	return %temp;
}

sub gen_noc_localparam_v {
	my ($m,$ref) = @_;
	my %model = %{$ref};
	my %temp;

    
	foreach my $p (@params){
		$temp{$p} = $default_noc_param{$p};
        $m->{noc_param}{$p}=$default_noc_param{$p};
	}
	foreach my $p (sort keys %model){
		$temp{$p} = $model{$p};
		$m->{noc_param}{$p}=$model{$p};
	}

	object_add_attribute_order($m,'noc_param',@params);

	my $param_v="`ifdef NOC_LOCAL_PARAM \n";
	foreach my $p (@params){
		$param_v.="localparam $p = $temp{$p};\n";
	}
	$param_v.="`endif\n";

	my ($nr,$ne,$router_p,$ref_tops,$includ_h) = get_noc_verilator_top_modules_info($m);
	my %tops = %{$ref_tops};	
	$tops{Vtraffic} = "--top-module traffic_gen_top";	
	$tops{Vpck_inj} = "--top-module packet_injector_verilator";	




	my $param_h=gen_noc_param_h($m);
	$includ_h = gen_sim_parameter_h($param_h,$includ_h,$ne,$nr,$router_p,'16');	

	return ($param_v,$includ_h,\%tops);

}


sub copy_src_files {
    # Check if PRONOC_WORK environment variable is set
    unless (defined $ENV{PRONOC_WORK}) {
        die "Error: Please set the PRONOC_WORK environment variable first!\n";
    }
    rmtree("$verify");
    print "\n******************* copy source files *******************\n";
    # Ensure working directory exists, creating it recursively if necessary
    print "Creating working directory: $rtl_dir\n";
    make_path($rtl_dir, { mode => 0700 }) or die "Error: Cannot create directory $rtl_dir: $!\n";
    $rtl_dir=realpath ($rtl_dir);

    # Define source directories
    my %src_dirs = (
        "$root/rtl/src_noc"    => "$rtl_dir/src_noc",
        "$root/rtl/src_topology" => "$rtl_dir/src_topology",
    );

    # Copy source directories
    for my $src (keys %src_dirs) {
        my $dest = $src_dirs{$src};
        unless (-d $dest) {
            dircopy($src, $dest) or die "Error: Cannot copy $src to $dest: $!\n";
        }
    }

    # Remove specific file if it exists in the destination
    my $noc_localparam_file = "$rtl_dir/src_noc/noc_localparam.v";
    unlink $noc_localparam_file if -e $noc_localparam_file;

    # Copy individual Verilog files from root RTL directory
    for my $file (glob "$root/rtl/*.v") {
        copy($file, $rtl_dir) or die "Error: Cannot copy $file to $rtl_dir: $!\n";
    }

    print "Source files copied successfully.\n";
}





sub gen_file_list{
	my $path=shift;
	my $f="+incdir+$rtl_dir/
+incdir+$rtl_dir/src_noc/
+incdir+$path
";

	my @files = File::Find::Rule->file()
                          ->name( '*.v','*.V','*.sv' )
                          ->in( "$rtl_dir" );

 	#make sure source files have key word 'module' 
	my @sources;
	foreach my $p (@files){
		push (@sources,$p)	if(check_file_has_string($p,'endpackage')); 
	}
	foreach my $p (@files){
		push (@sources,$p)	if(check_file_has_string($p,'module')); 
	}
	my $files = join ("\n",@sources);
	$f.=$files;
 

	open(FILE,  ">$path/file_list.f") || die "Can not open: $!";
	print FILE $f;
	close FILE;
}

sub gen_verilator_sh{
	my ($ref,$file)=@_;
	my %tops = %{$ref};
	my $make_lib="";
    my $jobs=0;
	my $cmd= '#!/bin/bash
	SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
	SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)

	cmn="-O3  -CFLAGS -O3"
	currentver=$(verilator --version | head -n1 | cut -d" " -f2)	
	requiredver="4.0.0"
 	if [ "$(printf \'%s\n\' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then 
        echo "Verilator vesrion Greater than or equal to ${requiredver}, compile with -Wno-TIMESCALEMOD flag"
		cmn=" $cmn -Wno-TIMESCALEMOD";
 	else
        echo "Verilator vesrion is Less than ${requiredver}"
 	fi
';

	foreach my $top (sort keys %tops) {
		$cmd.= "verilator  -f \$SCRPT_DIR_PATH/file_list.f --cc $tops{$top}  --prefix \"$top\" \$cmn & \n";
	}
	$cmd.="wait\n";
	foreach my $top (sort keys %tops) {
		
		$cmd.=" 
	if ! [ -f \$SCRPT_DIR_PATH/obj_dir/$top.cpp ]; then
		echo  \"Failed to generate: \$SCRPT_DIR_PATH/obj_dir/$top.cpp \"
		exit 1	
	fi\n";
		$make_lib.="make lib$jobs &\n";
		$jobs++;
	}


	$cmd.="
cd \$SCRPT_DIR_PATH/obj_dir/
$make_lib
wait

make sim
";
	save_file("$file",$cmd);
	
}

sub get_model_names {
	my ($mref,$inref) = @_;
	my @models = @{$mref};
	my ($paralel_run,$MIN,$MAX,$STEP,$model_dir)=@{$inref};
	my $full_path;
	$full_path = "$model_dir" if (-d "$model_dir");
	$full_path = "$confs_dir/$model_dir" if (-d "$confs_dir/$model_dir");
	if (!defined  $full_path){
		 die "Error the model directory  $model_dir or $confs_dir/$model_dir is not found\n";	
	}
	my @m;
	if(scalar @models == 0){
		@m = glob("$full_path/*");
		return @m;
	}
	foreach my $p (@models) {
		push (@m,"$full_path/$p");
	}
	return @m;
}


sub check_models_are_exsited {
	my ($mref, $inref) = @_;
	my @models = get_model_names(@_);
	foreach my $m (@models){
		unless (-f $m ){
			die "Error: no such file $m";
		}
	}
}


sub gen_models {
	my ($mref, $inref) = @_;
	my @models = get_model_names(@_);	

    mkdir("$work", 0700);
    $work=realpath($work);
    
	foreach my $m (@models){
		print "$m\n";
		unless (-f $m ){
			die "Error: no such file $m";
		}
		#make noc localparam
		my $o;
		$o= do $m;
        die "Error reading: $@" if $@;
		my $param = $o->{'noc_param'};
		my ($fname,$fpath,$fsuffix) = fileparse("$m",qr"\..[^.]*$");


		my $name = $fname;
		my $make =$o->{'makefile'};
		
        
		my 	($param_v,$include_h,$tops)=   gen_noc_localparam_v( $o,$param);

		mkdir("$work/$name", 0700);
		rmtree("$work/$name/obj_dir");
        mkdir("$work/$name/obj_dir", 0700);
		save_file("$work/$name/noc_localparam.v",$param_v);
		
		#generate file list		
		gen_file_list("$work/$name");
		gen_verilator_sh($tops,"$work/$name/verilator.sh");

		#copy C files
		my @files = File::Find::Rule->file()
                          ->name( '*.h' )
                          ->in( "$src_verilator" );
		foreach my $p (@files){
			copy $p, "$work/$name/obj_dir/";
		}
		copy "$src_verilator/simulator.cpp", "$work/$name/obj_dir/testbench.cpp";

		#copy nettrace & synful
	    dircopy("$src_c/netrace-1.0","$work/$name/obj_dir/netrace-1.0");
	    dircopy("$src_c/synfull","$work/$name/obj_dir/synful");

		#generate make file
		gen_verilator_makefile($tops,"$work/$name/obj_dir/Makefile");
		#generate param.h file
		
	
		save_file("$work/$name/obj_dir/parameter.h",$include_h);
		
		 
	}

}






sub compile_models{
	my($self,$inref,$mref)=@_;
    my ($paralel_run,$MIN,$MAX,$STEP) = @{$inref};
	

	my @models = get_model_names($mref,$inref);
	
	#generate compile command
	my $i=0;
	my $cmd;
	foreach my $m (@models){
		my ($fname,$fpath,$fsuffix) = fileparse("$m",qr"\..[^.]*$");
		$cmd.=" cd $work/$fname;  bash verilator.sh >  $work/$fname/out.log 2>&1  &\n";
		$i++;
		$cmd.="wait\n" if(($i % $paralel_run)==0) ;
	}
	$cmd.="wait\n" if(($i % $paralel_run)!=0) ;
	#run command in terminal
	print "*******************compile models******************\n$cmd\n";
	my $proc1 = Proc::Background->new($cmd);
	$proc1->alive;
	$proc1->wait;
	$proc1->die;

}
sub check_compilation_log {
	my ($name,$ref,$inref) = @_;
    my @log_report_match =@{$ref};
	my ($paralel_run,$MIN,$MAX,$STEP) = @{$inref};
	my $logfile	= "$work/$name/out.log";	
	
	my @found;
	foreach my $m (@log_report_match){ 
		open my $INPUT, '<', $logfile;
		push(@found , grep ( /$m/, <$INPUT>)) ;
		close($INPUT);
	}	
	
	foreach my $line (@found) {
              append_text_to_file($report,"\t $line\n");
    }
}





sub check_compilation {
	my ($self,$ref1,$inref,$mref)=@_;
	
	my @models = get_model_names($mref,$inref);

	foreach my $m (@models){
		my ($name,$fpath,$fsuffix) = fileparse("$m",qr"\..[^.]*$");
		append_text_to_file($report,"****************************$name : Compile *******************************:\n");
		#check if testbench is generated successfully	
		if(-f "$work/$name/obj_dir/testbench"){
			append_text_to_file($report,"\t model is generated successfully.\n"); 
			check_compilation_log($name,$ref1,$inref);

		}else{
			append_text_to_file($report,"\t model generation is FAILED.\n"); 
			check_compilation_log($name,$ref1,$inref);
		}

	}
}


sub run_all_models {
	my ($self,$inref,$mref) =@_;
    my ($paralel_run,$MIN,$MAX,$STEP) = @{$inref};
	my @models = get_model_names($mref,$inref);	
    foreach my $m (@models){
		run_traffic ($self,$m,'random',$inref);
	}
	foreach my $m (@models){
		run_traffic ($self,$m,'transposed 1',$inref);
	}
}



sub run_traffic {
	my ($self,$model,$traffic,$inref)=@_;
     my ($paralel_run,$MIN,$MAX,$STEP) = @{$inref};
	my ($name,$fpath,$fsuffix) = fileparse("$model",qr"\..[^.]*$");
	
	my %param = get_model_parameter($model);
	my $min_pck = $param{'MIN_PCK_SIZE'};
	
    append_text_to_file($report,"****************************$name	: $traffic traffic *******************************:\n");
	unless (-f "$work/$name/obj_dir/testbench"){
		append_text_to_file($report,"\t Failed. Simulation model is not avaialable\n");
		return;
	}

	

	my $file_name="${traffic}_results";
    $file_name =~ s/\s+//g;

	mkdir("$work/$name/$file_name/", 0700);

	my $i=0;
	my $cmd;


	for (my $inject=$MIN; $inject<=$MAX; $inject+=$STEP){
		$cmd.="$work/$name/obj_dir/testbench -t \"$traffic\"   -m \"R,$min_pck,10\"  -n  20000  -c	10000   -i $inject -p \"100,0,0,0,0\" >  $work/$name/$file_name/sim$inject 2>&1  &\n";
		$i++;
		$cmd.="wait\n" if(($i % $paralel_run)==0) ;
	}
	$cmd.="wait\n" if(($i % $paralel_run)!=0) ;
	#run command in terminal
	print "*******************Run simulation for $name******************\n$cmd\n";
	my $proc1 = Proc::Background->new($cmd);
	$proc1->alive;
	$proc1->wait;
	$proc1->die; 

	check_sim_results($self,$name,$traffic,$inref);

}


sub extract_result {
	my ($self,$file,$filed)=@_;

	my @r = unix_grep($file,$filed);
    my $string = $r[0];
    $string =~ s/[^0-9.]+//g;
	return $string;

}

sub get_zero_load_and_saturation{
	my ($self,$name,$traffic,$path)=@_;
	my %results;	
	my $ref = $self->{'name'}{"$name"}{'traffic'}{$traffic}{"packet_latency"};
	return if !defined $ref;
	%results = %{$ref}; 
	
	my $zero_latency=9999999;	
    my $saturat_inject=100;
    my $zero_inject;
    my $saturat_latency='-';

	my $txt = "#name:$name\n";

	foreach my $inj (sort {$a <=> $b} keys %results){
		$txt.="$inj $results{$inj}\n";
		if ($zero_latency > $results{$inj}) {
			$zero_latency = $results{$inj};
			$zero_inject  = $inj;
		}
	} 
	# assum saturation happens when the latency is 5 times of zero load
	foreach my $inj (sort {$a <=> $b} keys %results){
		if($results{$inj} >= 5 * $zero_latency ) {
			if($saturat_inject > $inj){
				$saturat_inject	=$inj;	
				$saturat_latency=$results{$inj};
			}
		}
	} 
	$txt.="\n";
	save_file("$path/packet_latency.sv",$txt);


	return ($zero_inject,$zero_latency, $saturat_inject,$saturat_latency);
}




sub check_sim_results{
	my ($self,$name,$traffic,$inref)=@_;
    my ($paralel_run,$MIN,$MAX,$STEP) = @{$inref};
    my $file_name="${traffic}_results";
    $file_name =~ s/\s+//g;
	my $results_path = "$work/$name/$file_name";

	#my @results = glob("$results_path/*");
	#check for error
	
	for (my $inject=$MIN; $inject<=$MAX; $inject+=$STEP){
		my $file = "$results_path/sim$inject";
	
		my @errors = unix_grep("$file","ERROR:");
		if (scalar @errors  ){
			append_text_to_file($report,"\t Error in running simulation:\n @errors \n");	
			$self->{'name'}{"$name"}{'traffic'}{$traffic}{'overal_result'}="Failed";
			$self->{'name'}{"$name"}{'traffic'}{$traffic}{'message'}="@errors";
			return;						
		}
		my @r = unix_grep($file,"\ttotal,");
    	my $string = $r[0];
		my @fileds=split(',',$string);
		my $val=$fileds[11];
		$val =~ s/[^0-9.]+//g;
	#	my $val = extract_result($self,$file,"average packet latency");		
		if(length $val ==0){
			$self->{'name'}{"$name"}{'traffic'}{$traffic}{'overal_result'}="Failed";
			$self->{'name'}{"$name"}{'traffic'}{$traffic}{'message'}="The average packet latency is undefined for $inject";
			return;						
		}
		$self->{'name'}{"$name"}{'traffic'}{$traffic}{"packet_latency"}{$inject}="$val";
		
	}
	my  ($z,$zl, $s,$sl) = get_zero_load_and_saturation ($self,$name,$traffic,$results_path);
	print "($z,$zl, $s,$sl)\n";

	#save results in a text file 



	append_text_to_file($report,"\t Passed:   zero load ($z,$zl) saturation ($s,$sl)\n");
    $self->{'name'}{"$name"}{'traffic'}{$traffic}{'overal_result'}="passed";		
}


sub object_get_attribute_order{
	my ($self,$attribute)=@_;
	return unless(defined $self->{parameters_order}{$attribute});
	my @order=@{$self->{parameters_order}{$attribute}};
	return uniq(@order)
}

sub save_file {
	my  ($file_path,$text)=@_;
	open my $fd, ">$file_path" or die "could not open $file_path: $!";
	print $fd $text;
	close $fd;	
}

sub object_add_attribute_order{
	my ($self,$attribute,@param)=@_;
	my $r = $self->{'parameters_order'}{$attribute};
	my @a;
	@a = @{$r} if(defined $r);
	push (@a,@param);
	@a=uniq(@a);	
	$self->{'parameters_order'}{$attribute} =\@a;
}

sub append_text_to_file {
	my  ($file_path,$text)=@_;
	open(my $fd, ">>$file_path") or die "could not open $file_path: $!";
	print $fd $text;
	close $fd;
}

sub object_add_attribute{
	my ($self,$attribute1,$attribute2,$value)=@_;
	if(!defined $attribute2){$self->{$attribute1}=$value;}
	else {$self->{$attribute1}{$attribute2}=$value;}

}



sub object_get_attribute{
	my ($self,$attribute1,$attribute2)=@_;
	if(!defined $attribute2) {return $self->{$attribute1};}
	return $self->{$attribute1}{$attribute2};
}

sub powi{ # x^y
	my ($x,$y)=@_; # compute x to the y
	my $r=1;
	for (my $i = 0; $i < $y; ++$i ) {
    	$r *= $x;
  	}
  return $r;
}

sub sum_powi{ # x^(y-1) + x^(y-2) + ...+ 1;
	my ($x,$y)=@_; # compute x to the y
	my $r = 0;
    for (my $i = 0; $i < $y; $i++){
    	$r += powi( $x, $i );
    }
  	return $r;
}	

sub log2{
	my $num=shift;
	my $log=($num <=1) ? 1: 0;        
	while( (1<< $log)  < $num) {    
				$log++;    
	}
	return  $log;  
}


sub remove_not_hex {
	my $s=shift;
	$s =~ s/[^0-9a-fA-F]//g;
	return $s;	
}

sub remove_not_number {
	my $s=shift;
	$s =~ s/[^0-9]//g;
	return $s;		
	
}

sub check_file_has_string {
    my ($file,$string)=@_;
    my $r;
    open(FILE,$file);
    if (grep{/$string/} <FILE>){
       $r= 1; #print "word  found\n";
    }else{
       $r= 0; #print "word not found\n";
    }
    close FILE;
    return $r;
}


sub gen_verilator_makefile{
	my ($top_ref,$target_dir) =@_;
	my %tops = %{$top_ref};
	my $p='';
	my $q='';
	my $h='';
	my $l;
	my $lib_num=0;
	my $all_lib="";
	foreach my $top (sort keys %tops) {
		$p = "$p ${top}__ALL.a ";
		$q = $q."lib$lib_num:\n\t\$(MAKE) -f ${top}.mk\n"; 
		$h = "$h ${top}.h "; 
		$l = $top;
		$all_lib=$all_lib." lib$lib_num";
		$lib_num++;
	}

	my $make= "
	
default: sim



include $l.mk

lib: $all_lib

$q


#######################################################################
# Compile flags

CPPFLAGS += -DVL_DEBUG=1
ifeq (\$(CFG_WITH_CCWARN),yes)	# Local... Else don't burden users
CPPFLAGS += -DVL_THREADED=1
CPPFLAGS += -W -Werror -Wall
endif

SLIB = 
HLIB = 
ifneq (\$(wildcard synful/synful.a),) 
SLIB += synful/synful.a
HLIB += synful/synful.h
endif 

#######################################################################
# Linking final exe -- presumes have a sim_main.cpp


sim:	testbench.o \$(VK_GLOBAL_OBJS) $p \$(SLIB)
	\$(LINK) \$(LDFLAGS) -g \$^ \$(LOADLIBES) \$(LDLIBS) -o testbench \$(LIBS) -Wall -O3 -lpthread 2>&1 | c++filt

testbench.o: testbench.cpp $h  \$(HLIB)

clean:
	rm *.o *.a testbench	
";

save_file ($target_dir,$make);

}	


sub get_project_dir{ #mpsoc directory address
	my $dir = Cwd::getcwd();
	my @p=	split('/perl_gui',$dir);
	@p=	split('/Integration_test',$p[0]);
    my $d	  = abs_path("$p[0]/../"); 
     
	return $d;
}

#return lines containig pattern in a givn file
sub unix_grep {
	my ($file,$pattern)=@_;
    open(FILE,$file);
    my @arr = <FILE>;
    my @lines = grep /$pattern/, @arr;
	return @lines;	
}


sub regen_object {
	my $path=shift;
	$path = get_full_path_addr($path);
	my $pp= eval { do $path };
	my $r= ($@ || !defined $pp);
	return ($pp,$r,$@);
}

sub get_full_path_addr{
	my $file=shift;
	my $dir = Cwd::getcwd();
	my $full_path = "$dir/$file";	
	return $full_path  if -f ($full_path );
	return $file;
}
