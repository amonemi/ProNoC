#!/usr/bin/perl -w

use Proc::Background;
use File::Path qw( rmtree );

my $script_path = dirname(__FILE__);
my $dirname = "$script_path/..";
my $root = "$dirname/../..";
my $rtl_dir = "$ENV{PRONOC_WORK}/verify/rtl";
my $work    = "$ENV{PRONOC_WORK}/verify/work";
my $src = "$script_path";
my $report = "$dirname/report";

require "$root/perl_gui/lib/perl/common.pl";
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
		$val=$custom_topology if($p eq "TOPOLOGY" && $val eq "\"CUSTOM\"");
		if($p eq "MCAST_ENDP_LIST" || $p eq "ESCAP_VC_MASK"){
			$val="$NE".$val if($p eq 'MCAST_ENDP_LIST');
			$val =~ s/\'/\\\'/g;
			$val="\"$val\"";			
		}
		
		
		$param_h=$param_h."\t#define $p\t$val\n";
		
		
		
	}
	my $class=$mpsoc->object_get_attribute('noc_param',"C");
	my $str;
	if( $class > 1){
		for (my $i=0; $i<=$class-1; $i++){
			my $n="Cn_$i";
			my $val=$mpsoc->object_get_attribute('class_param',$n);
			$param_h=$param_h."\t#define $n\t$val\n";
		}
		$str="CLASS_SETTING  {";
		for (my $i=$class-1; $i>=0;$i--){
			$str=($i==0)?  "${str}Cn_0};\n " : "${str}Cn_$i,";
		}
	}else {
		$str="CLASS_SETTING={V{1\'b1}}\n";
	}	
	#add_text_to_string (\$param_h,"\t#define $str");
	 
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


sub copy_src_files{
	
	if(defined $ENV{PRONOC_WORK}){
		rmtree("$rtl_dir");
	 	unless (-d "$rtl_dir"){
			print "make a working directory inside $rtl_dir\n"; 
			mkdir("$rtl_dir", 0700);

		}
	}else{
			print  "Please set PRONOC_WORK variable first!";
			exit;
	}
	
	dircopy("$root/rtl/src_noc"    , "$rtl_dir/src_noc"    ) or die("$!\n") unless (-d "$rtl_dir/src_noc"    );
    dircopy("$root/rtl/src_topolgy", "$rtl_dir/src_topolgy") or die("$!\n") unless (-d "$rtl_dir/src_topolgy");

    unlink "$rtl_dir/src_noc/noc_localparam.v";
    for my $file (glob "$root/rtl/*.v") {
   		 copy $file, "$rtl_dir" or die $! ; 
	}

	

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



sub gen_models {
	my @models = glob("$dirname/models/*");
    mkdir("$work", 0700);
	foreach my $m (@models){
		print "$m\n";
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
		save_file("$work/$name/noc_localparam.v",$param_v);
		
		#generate file list		
		gen_file_list("$work/$name");
		
		
		
		 
	}

}






sub compile_models{
	my($self,$inref)=@_;
    my ($paralel_run,$MIN,$MAX,$STEP) = @{$inref};
	my @models = glob("$dirname/models/*");
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
	my ($self,$ref1,$ref2)=@_;
	my @models = glob("$dirname/models/*");
	foreach my $m (@models){
		my ($name,$fpath,$fsuffix) = fileparse("$m",qr"\..[^.]*$");
		append_text_to_file($report,"****************************$name : Compile *******************************:\n");
		#check if testbench is generated successfully	
		if(-f "$work/$name/obj_dir/testbench"){
			append_text_to_file($report,"\t model is generated successfully.\n"); 
			check_compilation_log($name,$ref1,$ref2);

		}else{
			append_text_to_file($report,"\t model generation is FAILED.\n"); 
			check_compilation_log($name,$ref1,$ref2);
		}

	}
}


sub run_all_models {
	my ($self,$inref) =@_;
    my ($paralel_run,$MIN,$MAX,$STEP) = @{$inref};
	my @models = glob("$dirname/models/*");
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
		append_text_to_file($report,"\t failed. Simulation model is not avaialable\n");
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
	print "*******************run models******************\n$cmd\n";
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
			append_text_to_file($report,"\t Error in running simulation: @errors \n");	
			$self->{'name'}{"$name"}{'traffic'}{$traffic}{'overal_result'}="Failed";
			$self->{'name'}{"$name"}{'traffic'}{$traffic}{'message'}="@errors";
			return;						
		}
		my @r = unix_grep($file,"total,");
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

