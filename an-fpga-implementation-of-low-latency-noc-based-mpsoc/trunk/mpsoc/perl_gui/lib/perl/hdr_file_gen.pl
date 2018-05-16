use lib 'lib/perl';

use strict;
use warnings;
use soc;
use ip;



##################
#     header file gen
##################



sub get_instance_global_variable{
	my ($soc,$id)	= @_;
	my $module 	=$soc->soc_get_module($id);
	my $module_name	=$soc->soc_get_module_name($id);
	my $category 	=$soc->soc_get_category($id);
	my $inst   	=$soc->soc_get_instance_name($id);
	my @plugs= $soc->soc_get_all_plugs_of_an_instance($id);
	my %params= $soc->soc_get_module_param($id);
	#add two extra variable the instance name and base addresses
	my $core_id= $soc->object_get_attribute('global_param','CORE_ID');
	$params{CORE_ID}=(defined $core_id)? $core_id: 0;
	$params{IP}=$inst;
	$params{CORE}=$id;
	foreach my $plug (@plugs){
		my @nums=$soc->soc_list_plug_nums($id,$plug);
		foreach my $num (@nums){
			my ($addr,$base,$end,$name,$connect_id,$connect_socket,$connect_socket_num)=$soc->soc_get_plug($id,$plug,$num);
			#wishbone slave address
			if((defined $connect_socket) && ($connect_socket eq 'wb_slave')){
				#print "$addr,$base,$end,$connect_id,$connect_socket,$connect_socket_num\n";
				my $base_hex=sprintf("0X%08x", $base);
				my $end_hex=sprintf("0X%08x", $end);
				my $val="BASE".$num;
				$params{$val}=$base_hex;
		
			}
					
					
		}
	}
	$params{BASE}=$params{BASE0} if(defined $params{BASE0});
	

	return (\%params);
}


sub replace_golb_var{
	my ($hdr,$ref)=@_;
	my %params= %{$ref};
	foreach my $p (sort keys %params){
		my $pattern=  '\$\{?' . $p . '(\}|\b)';
		($hdr=$hdr)=~s/$pattern/$params{$p}/g;
	}
	return $hdr;

}



sub generate_header_file{ 
	my ($soc,$project_dir,$sw_path,$hw_path,$dir)= @_;
	my $soc_name=$soc->object_get_attribute('soc_name');
	$soc_name = uc($soc_name);
	if(!defined $soc_name){$soc_name='soc'};
	
	my @instances=$soc->soc_get_all_instances();
	my $system_h="#ifndef $soc_name\_SYSTEM_H\n\t#define $soc_name\_SYSTEM_H\n";
	#add_text_to_string(\$system_h, "\n #include <stdio.h> \n #include <stdlib.h> \n #include \"aemb/core.hh\"");


	my $ip = ip->lib_new ();
	
	
	foreach my $id (@instances){
		my $module 		=$soc->soc_get_module($id);
		my $module_name	=$soc->soc_get_module_name($id);
		my $category 	=$soc->soc_get_category($id);
		my $inst   		=$soc->soc_get_instance_name($id);

		add_text_to_string(\$system_h,"\n \n /*  $inst   */ \n");	
		#$inst=uc($inst);
		# print base address
		my @plugs= $soc->soc_get_all_plugs_of_an_instance($id);


		my %params= %{get_instance_global_variable($soc,$id)};
		

		foreach my $plug (@plugs){
			my @nums=$soc->soc_list_plug_nums($id,$plug);
			foreach my $num (@nums){
				my ($addr,$base,$end,$name,$connect_id,$connect_socket,$connect_socket_num)=$soc->soc_get_plug($id,$plug,$num);
					#intrrupt 
					if((defined $connect_socket) && ($connect_socket eq 'interrupt_peripheral')){
						add_text_to_string(\$system_h,"//intrrupt flag location\n");
						add_text_to_string(\$system_h," #define $inst\_INT (1<<$connect_socket_num)\n") if(scalar (@nums)==1);
						add_text_to_string(\$system_h," #define $inst\_$num\_INT    (1<<$connect_socket_num)\n") if(scalar (@nums)>1);
					}
					
			}
		}
		
		
		my $hdr 		=$ip->ip_get($category,$module,"system_h");
		#print "$hdr";
		
		
		#   \$\{?IP(\b|\})
		if(defined $hdr){
			$hdr=replace_golb_var($hdr,\%params);
			add_text_to_string(\$system_h,"$hdr\n");
		}

		# Write Software gen files
		my @sw_file_gen = $ip->ip_get_list($category,$module,"gen_sw_files");		
		foreach my $file (@sw_file_gen){
			if(defined $file ){
				my ($path,$rename)=split('frename_sep_t',$file);
				$rename=replace_golb_var($rename,\%params);
				#read the file content
				my $content=read_file_cntent($path,$project_dir);
				$content=replace_golb_var($content,\%params);


				if(defined $rename){
			
					open(FILE,  ">lib/verilog/tmp") || die "Can not open: $!";
					print FILE $content;
					close(FILE) || die "Error closing file: $!";
					move ("$dir/lib/verilog/tmp","$sw_path/$rename"); 

				
				}
			}
		}

		# Write Hardware gen files
		my @hw_file_gen = $ip->ip_get_list($category,$module,"gen_hw_files");		
		foreach my $file (@hw_file_gen){
			if(defined $file ){
				my ($path,$rename)=split('frename_sep_t',$file);
				$rename=replace_golb_var($rename,\%params);
				#read the file content
				my $content=read_file_cntent($path,$project_dir);
				$content=replace_golb_var($content,\%params);


				if(defined $rename){
			
					open(FILE,  ">lib/verilog/tmp") || die "Can not open: $!";
					print FILE $content;
					close(FILE) || die "Error closing file: $!";
					move ("$dir/lib/verilog/tmp","$hw_path/$rename"); 

				
				}
			}
		}


		
	}
	
	add_text_to_string(\$system_h,"#endif\n");
	my $name=$soc->object_get_attribute('soc_name');
	open(FILE,  ">lib/verilog/$name.h") || die "Can not open: $!";
			print FILE $system_h;
			close(FILE) || die "Error closing file: $!";
			move ("$dir/lib/verilog/$name.h","$sw_path/");


	

}


1
