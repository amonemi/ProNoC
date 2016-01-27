use lib 'lib/perl';

use strict;
use warnings;
use soc;
use ip;



##################
#     header file gen
##################




sub aemb_generate_header{ 
	my ($soc)= @_;
	my $soc_name=$soc->soc_get_soc_name();
	$soc_name = uc($soc_name);
	if(!defined $soc_name){$soc_name='soc'};
	
	my @instances=$soc->soc_get_all_instances();
	my $system_h="#ifndef $soc_name\_SYSTEM_H\n\t#define $soc_name\_SYSTEM_H\n";
	add_text_to_string(\$system_h, "\n #include <stdio.h> \n #include <stdlib.h> \n #include \"aemb/core.hh\"");


	my $ip = ip->lib_new ();
	
	
	foreach my $id (@instances){
		my $module 		=$soc->soc_get_module($id);
		my $module_name	=$soc->soc_get_module_name($id);
		my $category 	=$soc->soc_get_category($id);
		my $inst   		=$soc->soc_get_instance_name($id);
		
		add_text_to_string(\$system_h,"\n \n /*  $inst   */ \n");	
		$inst=uc($inst);
		# print base address
		my @plugs= $soc->soc_get_all_plugs_of_an_instance($id);
		foreach my $plug (@plugs){
			my @nums=$soc->soc_list_plug_nums($id,$plug);
			foreach my $num (@nums){
				my ($addr,$base,$end,$name,$connect_id,$connect_socket,$connect_socket_num)=$soc->soc_get_plug($id,$plug,$num);
					#wishbone slave address
					if((defined $connect_socket) && ($connect_socket eq 'wb_slave')){
						
						#print "$addr,$base,$end,$connect_id,$connect_socket,$connect_socket_num\n";
						my $base_hex=sprintf("0X%08x", $base);
						my $end_hex=sprintf("0X%08x", $end);
						
						add_text_to_string(\$system_h,"#define $inst\_BASE_ADDR$num \t\t 	$base_hex\n");
						add_text_to_string(\$system_h,"#define $inst\_BASE_ADDR \t\t 	$inst\_BASE_ADDR0\n") if ($num==0);
								
					
					}
					#intrrupt 
					if((defined $connect_socket) && ($connect_socket eq 'interrupt_peripheral')){
						add_text_to_string(\$system_h,"//intrrupt flag location\n");
						add_text_to_string(\$system_h," #define $inst\_INT (1<<$connect_socket_num)\n") if(scalar (@nums)==1);
						add_text_to_string(\$system_h," #define $inst\_$num\_INT    (1<<$connect_socket_num)\n") if(scalar (@nums)>1);
					}
					
			}
		}
		
		
		my $hdr 		=$ip->ip_get_hdr($category,$module);
		if(defined $hdr){
			#replace IP name
			my $key='\$IP\\\\';
			($hdr=$hdr)=~s/$key/$inst/g;

			$key='\$IP';
			($hdr=$hdr)=~s/$key/$inst/g;
			
			#replace BASE addr
			$key='\$BASE';
			($hdr=$hdr)=~s/$key/$inst\_BASE_ADDR/g;
			
			add_text_to_string(\$system_h,"$hdr\n");
		}
		
	}
	
	add_text_to_string(\$system_h,"#endif\n");
	return $system_h;

}


1
