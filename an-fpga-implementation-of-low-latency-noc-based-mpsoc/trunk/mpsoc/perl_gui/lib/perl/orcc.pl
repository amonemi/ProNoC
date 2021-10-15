#!/usr/bin/perl -w
use constant::boolean;
use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;


use String::Scanf; # imports sscanf()


sub select_orcc_generated_srcs {
	my ($self)=@_;
	#my $window = def_popwin_size(80,80,"Generate software using ORCC compiler",'percent');	
	#my $table = def_table(10, 10, FALSE);
	#$table->attach_defaults($infobox,0,20,$row,$row+1);
	
	#pass noc parameter to trace generator
	my %p;
	my $params_ref=$self->object_get_attribute('noc_param');
	if(defined $params_ref ){
		
		$p{'noc_param'}=$params_ref;	
	}
	#pass mpsoc name to trace genrator
	my $mpsoc_name=$self->object_get_attribute('mpsoc_name');
	$p{'mpsoc_name'}=$mpsoc_name;
	
	#pass soc names to trace genrator
	my ($NE, $NR, $RAw, $EAw, $Fw)=get_topology_info($self);	
    for (my $tile_num=0;$tile_num<$NE;$tile_num++){
        my ($soc_name,$num)= $self->mpsoc_get_tile_soc_name($tile_num);
        my $top=$self->mpsoc_get_soc($soc_name);
        if(defined $top){
        	my @nis=get_NI_instance_list($top);
        	my $inst_name=$top->top_get_def_of_instance($nis[0],'instance');
        	$p{'ni_name'}{$tile_num}=$inst_name; 
			$p{'soc_name'}{$tile_num}=$soc_name;
        }
    }
    
    
    
        
    
    			
	my $trace_gen= trace_gen_main('orcc',\%p);#,$window);	

	#$window->add ($trace_gen);
	#$window->show_all();
	
	return $trace_gen;
	my $table;
	
	
	
	
	$self->object_add_attribute("file_id",undef,0);
	$self->object_add_attribute("trace_id",undef,0);
	
	
	
	
	
	my $col=0;
	my $row=0;
	my $add = def_image_button('icons/import.png',"Load");
	set_tip($add,'Select ORCC generated CSV file');
	
	
	$table->attach($add,$col,$col+1,$row,$row+1,'shrink','shrink',2,2);$col++;
    my ($infobox,$info)= create_txview();   
    
    
    
    my $draw = def_image_button('icons/diagram.png');
	set_tip($draw,'View Actor Connection Graph');
	$table->attach($draw,$col,$col+1,$row,$row+1,'shrink','shrink',2,2);$col++;
	$draw->signal_connect ( 'clicked'=> sub{
		show_trace_diagram($self,'trace');
	});
    $row++;
    $col=0;
    my $map=actor_map($self,$info);
	$table->attach_defaults($map,0,5,$row,$row+1);
	
	
	my $i;	
	for ($i=$row; $i<5; $i++){
		
		my $temp=gen_label_in_center(" ");
		$table->attach_defaults ($temp, 0, 6 , $i, $i+1);
	}
	$row=$i;	
	
	
	$col=5;
	my $next=def_image_button('icons/right.png','Next');
	$table->attach($next,$col,$col+1,$row,$row+1,'shrink','shrink',2,2);$col++;
	
	
	
	$add->signal_connect ( 'clicked'=> sub{
		
 		my $file;
        my $dialog = gen_file_dialog('Select the ORCC generated CSV File','csv');
            	
        	
        
        	
		

        	if ( "ok" eq $dialog->run ) {
            		$file = $dialog->get_filename;
					load_orcc_csv($self,$file,$info);
            }
       		$dialog->destroy;	
	});
	
	


}





sub load_orcc_file{
	my($self,$tview)=@_;
 		my $file;
        my $dialog = gen_file_dialog( undef,"csv");
			
        	if ( "ok" eq $dialog->run ) {
            		$file = $dialog->get_filename;
					load_orcc_csv($self,$file,$tview);
            }
       		$dialog->destroy;	
}





sub load_orcc_csv{
	my ($self,$file,$info)=@_;		

	add_info($info,"Use $file for generating actors network\n");
	unless (-e $file){
		add_colored_info($info,"Cannot find $file\n",'red');
		return;
	} 	
	
	my $f_id=$self->object_get_attribute("file_id",undef);
	my $t_id=$self->object_get_attribute("trace_id",undef);
		
	open my $in, "<:encoding(utf8)", $file or die "$file: $!";
	my $sect=0;
	my $net;
	my @actors;
	
	my %chanels;
	
	while (my $line = <$in>) {
    	chomp $line;
    	$line =~ s/[^\S\n]+//g; #remove space
    	
    	if ($line =~ /Name,Package,Actors,Connections/){
    		$sect=1;
    		next;	
    	}
    	if ($line =~ /Name,Incoming,Outgoing,Inputs,Outputs/){
    		$sect=2;
    		next;	
    	}
    	if ($line =~ /Source,SrcPort,Target,TgtPort/){
    		$sect=3;
    		next;	
    	}
    	if($sect==1){
    		my @fileds=split(/\s*,\s*/,$line);
    		if(defined $fileds[0]){$net=$fileds[0] if($fileds[0]=~/^\w/);}
    	}
    	if($sect==2){
			my @fileds=split(/\s*,\s*/,$line);
			if(defined $fileds[0]){ push(@actors,$fileds[0]) if($fileds[0]=~/^\w/);}
    	}
    	if($sect==3){
    		my @fileds=split(/\s*,\s*/,$line);
    		if(defined $fileds[0]){
    			my $src=$fileds[0];
    			my $src_port=$fileds[1];
    			my $dest=$fileds[2];
    			my $dst_port=$fileds[3];
    			my $buff_Size=$fileds[4];   
    			
    			 			
    			$chanels{"${src}:$src_port"}= (defined $chanels{"${src}:$src_port"})? $chanels{"${src}:$src_port"}+1 : 0;  
    			my $cc=$chanels{"${src}:$src_port"};
    			#print "find chanel for  ** ${src}_$src_port -> ${dest}_$dst_port**: $cc\n";
    			  			
    			add_trace($self, "${net}:${f_id}:","raw",$t_id, $src,$dest, 1,$file, $src_port,$dst_port,$buff_Size,$chanels{"${src}:$src_port"},0);	
    			#print "add_trace($self, \"${net}:${f_id}:\",\"raw\",$t_id, $src,$dest, 1,$file, $src_port,$dst_port,$buff_Size,$chanels{\"${src}:$src_port\"});\n";	
    			$t_id++;
    		}
    		
    	}		
    	$self->set_gui_status('ref',0);
    	
	}	
	
	my $num=scalar @actors;
	if($num==0){
		add_colored_info($info,"Could not find any actor in $file\n",'red');
		return;
	}
	add_info($info,"total of $num actors have found:\n\t");
	my $n=1;
	foreach my $act (@actors){
		add_colored_info($info,"$n-$act ",'blue');
		$n++;
	}
	add_info($info,"\n");
	
	$f_id++;
	$self->object_add_attribute("trace_id",undef,$t_id);
	$self->object_add_attribute("file_id",undef,$f_id);
	
	
	
}


sub update_merge_actor_list{
	my ($self,$tview)=@_;	
	
	#delete old merge objects
    remove_all_traces ($self,'merge');
	
	#add not mereged traces 
	my $t_id=0;
	my $ungrouped_ref= $self->object_get_attribute("grouping",'ungrouped');
	my @ungrouped = (defined $ungrouped_ref)? @{$ungrouped_ref}:[];		
	foreach my $actor (@ungrouped){
		my @injectors= get_all_source_traces_of_actr($self,$actor,'raw');
		foreach my $inject (@injectors) {
			my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var,$src_port,$dst_port,$buff_size,$chanel,$vc,$class
			)=get_trace($self,'raw',$inject);
			my $tdst=$self->get_item_group_name('grouping',$dst);
			$dst_port=0 if (!defined $dst_port);
			if($tdst ne $dst){					
					$dst_port="${dst}_$dst_port";
			}
								
			add_trace($self, "$file_id",'merge',$t_id, $src,$tdst,$Mbytes,$file_name, $src_port,$dst_port,$buff_size,$chanel,$vc,$class);
			if(defined $min_pck){
				add_trace_extra($self, "$file_id",'merge',$t_id,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var );						
			}
			$t_id++;
		}		
		
	}
	
	#update group  list
	my $group_num=$self->object_get_attribute("grouping",'group_num');
	my $gname=$self->object_get_attribute("grouping",'group_name_root');
	for(my $i=0;$i<$group_num;$i=$i+1){
		my $gref = $self->object_get_attribute("grouping","$gname($i)");
		next if(! defined $gref);
		my @grouped =  @{$gref};
		next if (scalar @grouped == 0);
			
		
		my $merged_actor =  $self->object_get_attribute('grouping',"group($i)"."_name");
		$merged_actor = "group($i)" if(!defined $merged_actor);		
		#my $tile =get_task_give_tile($self,$merged_actor);
	#	print "my $tile =get_task_give_tile($self,$merged_actor);\n";
		#my $tile_id=get_tile_id($self,$merged_actor);
		#my $tile_id = tile_id_number($tile);
		
		#add_info($tview,"Generating $merged_actor.c grouped actor file from: @grouped  actors\n");
	 
	
		my $mpsoc_name=$self->object_get_attribute('mpsoc_name');
		$mpsoc_name = 'tmp' if (!defined $mpsoc_name);
		my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";
		
		#setp 1 : find local communication ports in merged actor
		foreach my $actor (@grouped) {
			my @injectors= get_all_source_traces_of_actr($self,$actor,'raw');
			#Where does it transfer?
			foreach my $inject (@injectors) {
				my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var,$src_port,$dst_port,$buff_size,$chanel,$vc,$class
				)=get_trace($self,'raw',$inject);
				$dst_port=0 if (!defined $dst_port);
				$src_port=0 if (!defined $src_port);
				my $dst_actor=$dst;
				if (check_scolar_exist_in_array($dst,\@grouped)){
					#print "$src $src_port is locally connected to $dst $dst_port\n";
					 $self->object_add_attribute("locally_connected","${dst}_${dst_port}","${src}_${src_port}");
				}
				else
				{
					#my ($net,$num,$name)=split(':',$src);
					my $merge_src="$merged_actor";
					$src_port="${src}_$src_port";
								
					my $file="$target_dir/sw/$actor.c";
										
					my $tdst=$self->get_item_group_name('grouping',$dst);
				#	($dnet,$dnum,$dname)=split(':',$tdst);
					if($tdst ne $dst){
							#my ($dnet,$dnum,$dname)=split(':',$dst);
							$dst_port="${dst}_$dst_port";
					}					
					
					add_trace($self, "$file_id",'merge',$t_id, $merge_src,$tdst, $Mbytes,$file, $src_port,$dst_port,$buff_size,$chanel,$vc,$class);
					if(defined $min_pck){
						add_trace_extra($self, "$file_id",'merge',$t_id,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var );						
					}
					$t_id++;	
				}#else
			}#$ink=ject
		}#actor	
	}		
}



sub get_port_num{
	my ($self,$hash_ref,$actor,$port_name,$chanel) =@_;
    return undef if(!defined $hash_ref);
    my %hash = %{$hash_ref};
    
    my $port_num =(defined $chanel)?  $hash{$actor}{$port_name}{$chanel} :  $hash{$actor}{$port_name};			
	if(!defined $port_num){
		#its a merged actor
		my $merge_actor=$self->get_item_group_name('grouping',$actor);
		#my($net,$num,$name)=split(':',$merge_actor);
		my $merge_port="${actor}_$port_name";
		return $hash{$merge_actor}{$merge_port}{$chanel} if(defined  $chanel);
		return $hash{$merge_actor}{$merge_port};		
	}	  
	return $port_num;  
}







sub get_fifo_list{
	my ($self)=@_;
	my %fifos;	
	
	my ($NE, $NR, $RAw, $EAw, $Fw)=get_topology_info($self);	
    for (my $tile_num=0;$tile_num<$NE;$tile_num++){	
		my $actor=get_task_assigned_to_tile($self,$tile_num); 
		next if(!defined $actor);
		my $fifo_num=0;
		my $ref = $self->get_items_in_a_group("grouping",$actor);
		my @merge_actors = (defined $ref)? @{$ref} : ($actor);	
		foreach my $actor (@merge_actors){
			my @injectors= get_all_source_traces_of_actr($self,$actor,'raw');
			foreach my $inject (@injectors) {
				my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var,$src_port,$dst_port,$buff_size,$chanel,$vc,$class
				)=get_trace($self,'raw',$inject);				
					
				$fifos{"${actor}_${src_port}"}{'size'}=$buff_size;	
				$fifos{"$actor"}{'file'}="$file_name";
				$fifos{"${actor}_${src_port}"}{'fifo_num'}=$fifo_num;
				$fifos{"${actor}_${src_port}"}{'chanel_num'}= 0 if(!defined $fifos{"${actor}_${src_port}"}{'chanel_num'});
				$fifos{"${actor}_${src_port}"}{'chanel_num'}++;
				$fifo_num++;
				$fifos{"tile_$tile_num"}{'fifo_num'}=$fifo_num;
			}
		}
    }
	
	for (my $tile_num=0;$tile_num<$NE;$tile_num++){	
		my $actor=get_task_assigned_to_tile($self,$tile_num); 
		next if(!defined $actor);
		my $fifo_num=$fifos{"tile_$tile_num"}{'fifo_num'};
		$fifo_num= 0 if(!defined $fifo_num);
		my $ref = $self->get_items_in_a_group("grouping",$actor);
		my @merge_actors = (defined $ref)? @{$ref} : ($actor);
		foreach my $actor (@merge_actors){		
			my @sinkers =   get_all_dest_traces_of_actr ($self,$actor,'raw');
				foreach my $sink (@sinkers){
				my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var,$src_port,$dst_port,$buff_size,$chanel,$vc,$class
					)=get_trace($self,'raw',$sink);				    
				
					$fifos{"${actor}_${dst_port}"}{'size'}=$buff_size;	
					$fifos{"$actor"}{'file'}="$file_name";
					$fifos{"${actor}_${dst_port}"}{'chanel_num'}=$fifos{"${src}_${src_port}"}{'chanel_num'};
					
					my $src_fifo_name= $self->object_get_attribute("locally_connected","${actor}_${dst_port}");
		    		if (defined $src_fifo_name){
		    		#its localy connected.  src fifo num and dst fifo num are identical 
		    			$fifos{"${actor}_${dst_port}"}{'fifo_num'}=$fifos{"$src_fifo_name"}{'fifo_num'};
		    			#print "\$fifos{\"${actor}_${dst_port}\"}{'fifo_num'}=\$fifos{\"$src_fifo_name\"}{'fifo_num'}=$fifos{$src_fifo_name}{'fifo_num'};\n";
		    		}else{
		    			$fifos{"${actor}_${dst_port}"}{'fifo_num'}=$fifo_num;
		    	 		$fifo_num++;
		    	 		$fifos{"tile_$tile_num"}{'fifo_num'}=$fifo_num;
		    		}			
				
				}
			}	
    }
    
  #  print Dumper (\%fifos);
    
    
	return %fifos;
}


sub get_dest_chanel_from_orcc_file{
	my ($actor_file,$actor,$dst_port)=@_;
	#print ("-------------------\n");
	my $str = "${actor}_${dst_port}->read_inds\\s*\\[";
	my $txt = load_file($actor_file);
	my $n = capture_number_after($str,$txt);
	return $n;
}


sub genereate_output_orcc{
	my ($self,$tview,$window)=@_;
	
	# Code each actor destination port
	

	my %soc_names=%{$self->object_get_attribute('soc_name')};
    my %ni_names =%{$self->object_get_attribute('ni_name')};
   
	add_info($tview,"Generating grouped actor files\n");
	my $group_num=$self->object_get_attribute("grouping",'group_num');
	my $gname=$self->object_get_attribute("grouping",'group_name_root');
	
	
	my $mpsoc_name=$self->object_get_attribute('mpsoc_name');
    my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";
	
    update_merge_actor_list ($self,$tview);
	my %srcp_number=get_srcport_constant_list($self,'merge');
	my %dstp_number=get_destport_constant_list($self,'merge');
	
	#print  "srcport:\n". Dumper(%srcp_number);
	#print "dstport:\n".  Dumper(%dstp_number);
	  
	add_info($tview,"Generating source files\n");
	
	my $ungrouped_ref= $self->object_get_attribute("grouping",'ungrouped');
	my @ungrouped = (defined $ungrouped_ref)? @{$ungrouped_ref}:[];		
	
	my %fifos=get_fifo_list($self);
	
	
	my ($NE, $NR, $RAw, $EAw, $Fw)=get_topology_info($self);	
    for (my $tile_num=0;$tile_num<$NE;$tile_num++){	
		my $target_orccdir= "$target_dir/sw/tile${tile_num}/orcc";
   		my $actor_tile ="tile($tile_num)";     			
   		my $actor_tile_id=$tile_num;
   		my $src_lib_file="$target_dir/sw/tile${actor_tile_id}/SOURCE_LIB"; 	
   		my $actor=get_task_assigned_to_tile($self,$tile_num); 
        my $soc_name=$soc_names{$actor_tile_id};
		my $ni_name=$ni_names{$actor_tile_id};
        my $max_dst_port_num=0;
        
        
        
        #remove old orcc lib folder
   		rmtree("$target_orccdir");
              
        #generate main.c  
		my $r;
		my @actors_file_names;
   		my $main_c = "$target_dir/sw/tile${actor_tile_id}/main.c";
   		unlink $main_c; #delete old main.c file 	
		open my $fd, ">$main_c" or $r = "$!\n";
   		if(defined $r) {
    		add_colored_info($tview,"Could not open $main_c to write: $r",'red');
			return;
   		} 
   		
   		#generate source_lib file
   		my $src_lib="SOURCE_LIB += $soc_name.c ";
   		                  		
   		
   		if (!defined $actor){
   			print $fd main_c_template($soc_name);   			
   			close($fd);
   			#write makefile source lib list file
			save_file($src_lib_file,$src_lib);	
   			next;
   		}
   	
   	
   		   		
   		mkpath("$target_orccdir",1,0755);
   	
	   	print $fd autogen_warning();
	   	print $fd get_license_header($main_c);  
		
		my $ref = $self->get_items_in_a_group("grouping",$actor);
		my @merge_actors = (defined $ref)? @{$ref} : ($actor);
		
		my $main_include = "#include <stddef.h>
#include \"$soc_name.h\"
#include \"orcc/orcc_lib.h\"
";
	
		
		
		my $main_def=""; 
		my $main_fifo_def="";
		my $main_fifo_assign="";
		my $main_fifo_rst_ptr="
volatile unsigned char iport_array[${ni_name}_NUM_VCs];
volatile unsigned char oport_array[${ni_name}_NUM_VCs];
unsigned int credit_buff[${ni_name}_NUM_VCs];

void reset_all_fifo_ptr(void){\n";
		
		my $all_got_packet_function="";	
		my $all_sent_packet_done_function="";	
		my $all_check_packet_function="";
		my $all_update_credit=""; 
		my $all_init_actor="";
		my $all_run_actor="";
		my $actors_str='';
	
		
		
		#start generation
		
		
		foreach my $actor (@merge_actors){
			my $actor_file= get_actr_file_name($self,$actor,'raw');
			my ($fname,$fpath,$fsuffix) = fileparse("$actor_file",qr"\..[^.]*$");
   			my $target_actor_file="$target_orccdir/$fname.c";
   			my $target_actor_header="$target_orccdir/$fname.h";
			open my $fc, ">$target_actor_file" or $r = "$!\n";
			if(defined $r) {
		    	add_colored_info($tview,"Could not open $target_actor_file to write: $r",'red');
				return;
			} 
		    
		    my $LH=uc "${fname}";
			my $actor_h="#ifndef\t ${LH}_H\n\t#define\t${LH}_H\n\n"; 
			my $schedul='';
			my $Hw_fifo_define='' ;
			my $transfer_str='';
			my $sink_str='';
			my $crdit_update='';
			
		
		
	
		
			my $actor_got_pck_func= "
char ${actor}_got_packet_function( unsigned char iport, unsigned int v){	
";
			my $actor_update_credit= "
char ${actor}_update_credit (unsigned int credit_port,unsigned int credit_value){
";

			my $actor_check_pck_func= "
char ${actor}_check_packet_function (unsigned char iport,unsigned int size){
";	

			my $actor_sent_pck_done_func= "
char ${actor}_sent_packet_done_function (unsigned char oport){
";	

			my $actor_init="
void ${actor}_init_actor (schedinfo_t * si) { 	
";
	
			my $actor_local_connect;
			
			#schedular function 
		
	    	$schedul ="
			${actor}_scheduler(si);"; 
		
			#For each actor which is mapped to this tile, we need to find all the traces going in and out to this tile 
			#1- get the actor generated C file name:
			
			#push(@actors_file_names,      $actor_file);	   
			#2- where it mapped?
			#		my $actor_tile = $self->object_get_attribute("MAP_TILE",$actor);
			#		my $actor_tile_id=get_tile_id($self,$actor);
			#3- How many traces it transfers?
		
			my @injectors= get_all_source_traces_of_actr($self,$actor,'raw');
		
			#4- Where does it transffer?
			foreach my $inject (@injectors) {
				my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var,$src_port,$dst_port,$buff_size,$chanel,$vc,$class
				)=get_trace($self,'raw',$inject);				
						
				$vc= 0 if(!defined $vc);
				$class= 0 if(!defined $class);
				
				#my $dst_tile = $self->object_get_attribute("MAP_TILE",$dst_actor);
				my $dst_actor=$self->get_item_group_name('grouping',$dst);
				my $dst_tile = get_task_give_tile($self,$dst_actor);
				#my $dst_tile_id=get_tile_id($self,$dst_actor);				
				my $dst_tile_id=tile_id_number($dst_tile);
				
				
				if($dst_tile eq $actor_tile){
					# this trace is connected locally in one tile
					#my $rr="\t\t${dst}_$dst_port->read_inds[$chanel]= ${src}_${src_port}->write_ind;\n";
					#$actor_local_connect=(defined $actor_local_connect)? $actor_local_connect.$rr:$rr;
					next;					
				}
				
				#5-Now generate all transfer functions (add inject ports) 	
				#my ($net,$num,$name)=split(':',$actor);				
				#print "dstp_number{$dst}{$dst_port}= $dstp_number{$dst}{$dst_port};\n";				
				
				my $srcportnum =  get_port_num($self,\%srcp_number,$src,$src_port,$chanel);
				my $dstportnum =  get_port_num($self,\%dstp_number,$dst,$dst_port); 
				
		
				if(!defined $dstportnum){				    
				    print Dumper (\$self);
					print Dumper (\%dstp_number);
					print "my $dstportnum = get_port_num($self,\%dstp_number,$dst,$dst_port);\n"; 
					print "***********************fix me**********\n";
					exit();					
				}
		
		
	
				if($chanel==0){			
					$Hw_fifo_define=$Hw_fifo_define."	
//	transfer ${src_port} port definitions:	
#define ${src_port}_w  $init_weight
#define ${src_port}_v  $vc				
#define ${src_port}_class_num  $class
#define ${src_port}_queue_pointer (unsigned int)&tokens_${src_port}[0]
#define ${src_port}_queue_size_in_byte  (SIZE_${src_port} << ${actor}_${src_port}_size_shift)	
#define ${src_port}_end_index   index_${src_port} 

";

					#$actor_init.="\t${actor}_${src_port}->write_ind=0;\n";

				}
	
				$Hw_fifo_define=$Hw_fifo_define."
// ${src_port} read chanel ${chanel}	definition
#define ${src_port}_ch${chanel}_dest_port_num $dstportnum  
#define ${src_port}_ch${chanel}_dest_phy_addr PHY_ADDR_ENDP_${dst_tile_id}
#define ${src_port}_ch${chanel}_src_port_num   $srcportnum
#define ${src_port}_ch${chanel}_start_index ${actor}_${src_port}->read_inds[$chanel]
#define ${src_port}_ch${chanel}_start_index_in_byte ((${src_port}_ch${chanel}_start_index % SIZE_${src_port}) << ${actor}_${src_port}_size_shift)
#define ${src_port}_ch${chanel}_has_data_to_send    (${src_port}_end_index > ${src_port}_ch${chanel}_start_index)	
#define ${src_port}_ch${chanel}_data_to_send_size   (${src_port}_end_index - ${src_port}_ch${chanel}_start_index)	
#define ${src_port}_ch${chanel}_send_data_size_in_byte   (${src_port}_ch${chanel}_data_to_send_size << ${actor}_${src_port}_size_shift)
 

static unsigned int ${src_port}_ch${chanel}_credit =  ${src_port}_queue_size_in_byte;	
static unsigned int ${src_port}_ch${chanel}_send_data;
";
#$actor_init.="\t${src_port}_ch${chanel}_credit =  ${src_port}_queue_size_in_byte;\n";
				
				#$actor_init.="\t${actor}_${src_port}->read_inds[$chanel]=0;\n";
				
				$transfer_str=$transfer_str."		
	if(${src_port}_ch${chanel}_has_data_to_send){
		// if the sent vc is not busy and the sent_done_isr is not asserted sent a new packet
		if(${ni_name}_send_is_free(${src_port}_v) &&     (oport_array[${src_port}_v]==255) ){  //(${ni_name}_packet_is_sent(${src_port}_v)==0))        {	
		
			//ask NI to transfer the data   
			if(transfer_manage (${src_port}_w, ${src_port}_v, ${src_port}_class_num,${src_port}_ch${chanel}_dest_port_num , ${src_port}_queue_pointer , ${src_port}_queue_size_in_byte, 
			${src_port}_ch${chanel}_start_index_in_byte, ${src_port}_ch${chanel}_send_data_size_in_byte, ${src_port}_ch${chanel}_dest_phy_addr, ${src_port}_ch${chanel}_credit,${src_port}_ch${chanel}_src_port_num, & ${src_port}_ch${chanel}_send_data, & ${src_port}_ch${chanel}_credit )){
							
			}				
		}//has data					 
	}//not busy
	";
	
				$actor_sent_pck_done_func=$actor_sent_pck_done_func."
	
	if(oport == ${src_port}_ch${chanel}_src_port_num){ 
		${src_port}_ch${chanel}_start_index= ${src_port}_ch${chanel}_start_index+ (${src_port}_ch${chanel}_send_data>>${actor}_${src_port}_size_shift);			
		#ifdef ORCC_DEBUG_EN
		if (${src_port}_ch${chanel}_data_to_send_size >  SIZE_${src_port}){
			printf (\"Error the waiting data in ${actor} ${src_port} quque (\%u) is larger than the queue size (\%u)\\n\",${src_port}_ch${chanel}_data_to_send_size,SIZE_${src_port} );			  
		}	
		#endif
		return 1;
	}	
	
	";
	
				$actor_update_credit =$actor_update_credit."	
	if( credit_port  == ${src_port}_ch${chanel}_src_port_num){
		${src_port}_ch${chanel}_credit += (credit_value << ${actor}_${src_port}_size_shift); //credit value in byte
		#ifdef ORCC_DEBUG_EN
		if (${src_port}_ch${chanel}_credit >  (SIZE_${src_port}    << ${actor}_${src_port}_size_shift    )){
			printf (\"Error the credit counter in ${actor} ${src_port}_ch${chanel} (\%u) is larger than the queue size (\%u)\\n\",${src_port}_ch${chanel}_credit,SIZE_${src_port} );			  
		}	
		#endif		
		return 1;
	}	
";

			}# end inject
		
		
		
		
		#6-Where the packet comes from? we need to update the sender with the remaining credit 
		my @sinkers =   get_all_dest_traces_of_actr ($self,$actor,'raw');
		foreach my $sink (@sinkers){
			my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var,$src_port,$dst_port,$buff_size,$chanel,$vc,$class
				)=get_trace($self,'raw',$sink);
						
			my $dst_chnl =get_dest_chanel_from_orcc_file($actor_file,$actor,$dst_port);	
					
			my $srcportnum =  get_port_num($self,\%srcp_number,$src,$src_port,$chanel); 
			my $src_actor=$self->get_item_group_name('grouping',$src);
			my $src_tile = get_task_give_tile($self,$src_actor);
		    #my $src_tile_id=get_tile_id($self,$src);
		    my $src_tile_id=tile_id_number($src_tile);
		    	
		    #print "my $srcportnum = get_port_num($self,\%srcp_number,$src,$src_port,$chanel);\n";
				
				if($src_tile eq $actor_tile){
				
					next;					
				}
												
			if(!defined $srcportnum){				    
				    print Dumper (\$self);
					print Dumper (\%srcp_number);
					print "my $srcportnum = get_port_num($self,\%srcp_number,$src,$src_port,$chanel);\n";
					print "***********************fix me**********\n";
					exit();					
			}
								
			#7 We need to add sink ports 				
			#save the input  port index before running the credit	
#$actor_init.=\t${actor}_${dst_port}->read_inds[0]=0;			
#$actor_init.=\t${actor}_${dst_port}->write_ind=0;

			$actor_init =$actor_init."
\tread_${dst_port}();
\tindex_${dst_port}_sender=index_$dst_port;			
";
		
	my $dstportnum = get_port_num($self,\%dstp_number,$dst,$dst_port); 
	$max_dst_port_num=$dstportnum if($dstportnum > $max_dst_port_num );
			
	$Hw_fifo_define=$Hw_fifo_define."
//	Receiver port  ${dst_port} port definitions:
static unsigned int index_${dst_port}_sender; 

#define ${dst_port}_credit_w  1
#define ${dst_port}_credit_v  0   //Alternatively it can be another VC				
#define ${dst_port}_credit_class_num  0 //Alternatively it can be another class
#define ${dst_port}_credit_dest_port  0 //0 is reserved for credit
#define ${dst_port}_credit_pointer (unsigned int)&credit_send_buff
#define ${dst_port}_credit_size_in_byte  4
#define ${dst_port}_credit_start_index  0
#define ${dst_port}_credit_send_data_size_in_byte   4
#define ${dst_port}_credit_dest_phy_addr PHY_ADDR_ENDP_${src_tile_id}
#define ${dst_port}_has_credit_to_send    (index_$dst_port > index_${dst_port}_sender)
#define ${dst_port}_src_port_num  $srcportnum
#define ${dst_port}_dst_port_num  $dstportnum
#define ${dst_port}_queu_pointer (unsigned int)&tokens_${dst_port}[0]
#define ${dst_port}_queue_size_in_byte  (SIZE_${dst_port} << ${actor}_${dst_port}_size_shift)	
#define ${dst_port}_start_index_in_byte	((${actor}_${dst_port}->write_ind % SIZE_${dst_port})<< ${actor}_${dst_port}_size_shift)
#define ${dst_port}_read_indx    ${actor}_${dst_port}->read_inds[$dst_chnl]
#define ${dst_port}_data_num_to_process (${actor}_${dst_port}->write_ind -${dst_port}_read_indx) 
";
			
			
	$crdit_update=$crdit_update."
	if( ${dst_port}_has_credit_to_send){
		if(${ni_name}_send_is_free(${dst_port}_credit_v) && (oport_array[${dst_port}_credit_v]==255) ){  // (${ni_name}_packet_is_sent(${dst_port}_credit_v)==0)){
			//credit_num  = (SIZE_${dst_port} - ${dst_port}_data_num_to_process)& 0xFFFF;
			credit_num  = (index_$dst_port - index_${dst_port}_sender)& 0xFFFF;				
			credit_send_buff= ( (${dst_port}_src_port_num <<16) |  credit_num ); // most significant 16 bits indicates the port, list  significant 16 bits are credit in word 
			#ifdef ORCC_DEBUG_EN
				if(${dst_port}_data_num_to_process > SIZE_${dst_port}){
					printf(\"Error ${dst_port}_data_num_to_process (\%u) is larger than SIZE_${dst_port} (\%u)\\n\",${dst_port}_data_num_to_process,SIZE_${dst_port});
				}
			#endif
			if( transfer_manage (${dst_port}_credit_w, ${dst_port}_credit_v, ${dst_port}_credit_class_num, ${dst_port}_credit_dest_port, ${dst_port}_credit_pointer, ${dst_port}_credit_size_in_byte, ${dst_port}_credit_start_index, ${dst_port}_credit_send_data_size_in_byte, ${dst_port}_credit_dest_phy_addr, 5,${dst_port}_credit_dest_port, &tmp1,&tmp2 ) ){
				index_${dst_port}_sender=index_${dst_port};					
			}		 
		} 
	}			
	";
	
	$actor_got_pck_func=$actor_got_pck_func."
	if (iport == ${dst_port}_dst_port_num){	
		${ni_name}_receive (v, ${dst_port}_queu_pointer , ${dst_port}_queue_size_in_byte, ${dst_port}_start_index_in_byte);	
		return 1; 
	}				
";
	
	$actor_check_pck_func =$actor_check_pck_func."	
	if(iport==${dst_port}_dst_port_num){
		${actor}_${dst_port}->write_ind = ${actor}_${dst_port}->write_ind + (size >> ${actor}_${dst_port}_size_shift);								
		#ifdef ORCC_DEBUG_EN
		unsigned int diff = ${actor}_${dst_port}->write_ind - ${dst_port}_read_indx;
		if(diff > SIZE_${dst_port})\{
			printf (\"Error in ${actor}_${dst_port}: Write_index(\%u) - Read_index(\%u) is larger than queue size (\%u)\\n\",${actor}_${dst_port}->write_ind , ${dst_port}_read_indx,SIZE_${dst_port});     
		}
		#endif
		return 1; 		
	}						
	";
	
	
	
	
	
	
	#print  "\$fifos{\"$name\"}{'file'}=$file_name\n";
	#print "\$fifos ${name}_${dst_port}'size'=$buff_size;\n";	
	
				
			
		} #sink
		
	
	
	
$actor_h=$actor_h."void ${actor}_initialize(schedinfo_t *);\n";
$actor_h=$actor_h."void ${actor}_scheduler(schedinfo_t *);\n";		
		
$actor_h=$actor_h."char ${actor}_got_packet_function(unsigned char , unsigned int);\n";		
$all_got_packet_function=$all_got_packet_function."\t\t\t\t${actor}_got_packet_function(iport,i);\n";		
$actor_got_pck_func=$actor_got_pck_func."
	#ifdef ORCC_DEBUG_EN
	printf(\"Wrong got pck port \%u\\n\",iport);
	#endif
	return 0;
}	
";

$actor_h=$actor_h."char ${actor}_check_packet_function(unsigned char,unsigned int);\n";
$all_check_packet_function = $all_check_packet_function."\t\t\t\t${actor}_check_packet_function(iport,size);\n";
$actor_check_pck_func=$actor_check_pck_func."
	#ifdef ORCC_DEBUG_EN
	printf(\"Wrong check pck  port \%u\\n\",iport);
	#endif
	return 0;
}	
";
$actor_h=$actor_h."char ${actor}_sent_packet_done_function(unsigned char);\n";
$all_sent_packet_done_function = $all_sent_packet_done_function."\t\t\t\t${actor}_sent_packet_done_function(oport);\n";
$actor_sent_pck_done_func=$actor_sent_pck_done_func."
	#ifdef ORCC_DEBUG_EN
	printf(\"Wrong sent done  port \%u\\n\",oport);
	#endif
	return 0;
}
";
$actor_h=$actor_h."char ${actor}_update_credit(unsigned int, unsigned int);\n";
$all_update_credit=$all_update_credit."\t\t\t\t${actor}_update_credit(credit_port,credit_value);\n";
$actor_update_credit =$actor_update_credit."	
	#ifdef ORCC_DEBUG_EN
	printf(\"Wrong ${actor} Credit port \%u\\n\",credit_port);
	#endif
	return 0;
}
";		
$actor_h=$actor_h."void ${actor}_init_actor(schedinfo_t *);\n";	
$all_init_actor=$all_init_actor."\t${actor}_init_actor(&si);\n";	
$actor_init=$actor_init."

	${actor}_initialize(si);

}
";	

$actor_h=$actor_h."void ${actor}_run_actor(schedinfo_t *);\n";	
$all_run_actor=$all_run_actor."\t\t${actor}_run_actor(&si);\n";	
#$all_run_actor=$all_run_actor.$actor_local_connect if(defined $actor_local_connect);

my $t = (length  $crdit_update > 10  )? "unsigned int tmp1,tmp2,credit_num,credit_send_buff;" : ""; 

my $actor_run="
void ${actor}_run_actor (schedinfo_t * si) { 
	
	//unsigned int credit_send_buff;
	
	//run schedular
	
	
$schedul
 	
	//check if input ports have credit update to send
	$t
	$crdit_update  
		
	//check if output port has data to send
	$transfer_str 
	
	#if (ORCC_SENT_DONT_INT_EN == 0)  
		if(${ni_name}_any_sent_done_isr_is_asserted()) sent_packet_done_function();	
	#endif	
	
	#if (ORCC_SAVE_DONT_INT_EN == 0)			
		if(${ni_name}_any_save_done_isr_is_asserted()) check_packet_function();
	#endif
	
	#if (ORCC_GOT_PCK_INT_EN == 0)		
		if(${ni_name}_any_got_pck_isr_is_asserted()) got_packet_function();		
	#endif
	
	#if (ORCC_GOT_ERR_INT_EN == 0)
	if(${ni_name}_any_err_isr_is_asserted()) error_handling_function();
	#endif
				
}
";


	
	

   my $r;
  
   add_colored_info($tview,"actor name: $actor\n",'green');
   
   
  
   #copy orcc lib files
  
   my $orcc_lib_dir = get_project_dir()."/mpsoc/src_c/orcc/lib";
   opendir(DIR,"$orcc_lib_dir") or $r= "$!\n";
   if(defined $r) {
    	add_colored_info($tview,"cannot open directory: $r",'red');
		return;
   } 
   foreach my $name (readdir(DIR))
   {
   	 # add_colored_info($tview,"copy ($orcc_lib_dir/$name,$target_dir/sw/tile${actor_tile_id}/);\n   ",'red');
   	  copy ("$orcc_lib_dir/$name","$target_orccdir/");    
   }
   
   
   
  
   
  
   
  #print $fe "orcc/$fname.c ";
  #$main_include=$main_include."#include \"orcc/$fname.c\"\n";
   $main_include=$main_include."#include \"orcc/$fname.h\"\n";
  
  $src_lib="$src_lib orcc/$fname.c";
   
   print $fc " // Generated from $actor_file\n";
   my $defines="";
   my $pval = 	$self->object_get_attribute("map_param","add_debug");
   $defines .= ($pval eq '1\'b1')? "#define ORCC_DEBUG_EN\n" : "";
   $pval = 	$self->object_get_attribute("map_param","sent_int");
   $defines .= ($pval eq '1\'b1')? "#define ORCC_SENT_DONT_INT_EN  1\n" : "#define ORCC_SENT_DONT_INT_EN  0\n";
   $pval = 	$self->object_get_attribute("map_param","receive_int");
   $defines .= ($pval eq '1\'b1')? "#define ORCC_SAVE_DONT_INT_EN  1\n" : "#define ORCC_SAVE_DONT_INT_EN  0\n";
   $pval = 	$self->object_get_attribute("map_param","receive_int"); 
   $defines .= ($pval eq '1\'b1')? "#define ORCC_GOT_PCK_INT_EN  1\n" : "#define ORCC_GOT_PCK_INT_EN  0\n";
   $pval = 	$self->object_get_attribute("map_param","got_err_int"); 
   $defines .= ($pval eq '1\'b1')? "#define ORCC_GOT_ERR_INT_EN  1\n" : "#define ORCC_GOT_ERR_INT_EN  0\n";
      
   
   
   print $fc "  
#include <stddef.h>    
#include \"../$soc_name.h\" 
#include \"orcc_lib.h\"
#include \"../../phy_addr.h\"
#include \"$fname.h\"


extern volatile unsigned char oport_array [${ni_name}_NUM_VCs];

";
  

   
  my $origen_def="";
  my $origen_fuctions=""; 
  
   
	#read actor file name and remove unnecessarily codes. comment every files start with #include and extern
	open my $fh, "<", $actor_file or $r = "$!\n";
    if(defined $r) {
    	add_colored_info($tview,"Could not open $actor_file: $r",'red');
		return;
    } 
	while (my $line = <$fh>) {
	    chomp $line;
	    #search for fifo size inside the file	    
	    if( $line =~ /^\s*#define\s+SIZE_\w+/){
	    	 #example: #define SIZE_operand_1 32
	    	 my $text = $line;
	    	 $text =~ s/\s+/ /g; # remove extra spaces
	    	 $text =~ s/^\s+//; #ltrim
	    	 my  ($fifo_name,$size) = sscanf("#define SIZE_%s %u",$text);
	    	 $actor_h = $actor_h."#define SIZE_${actor}_$fifo_name $size\n";
	    	 $fifos{"${actor}_$fifo_name"}{'size'}=$size;
	    }	
	    
	    
	    $line = '//'.$line if( $line =~ /^\s*#include/); # comment every line start with #include
	    if( $line =~ /^\s*extern\s+/){
	    	 my $extern=0;
	    	 $line =~ s/\s+/ /g; # remove extra spaces
	    	 $line =~ s/^\s+//; #ltrim
	    	    	 
	    	 #fifo
	    	 my  ($type,$fifo_name) = sscanf("extern fifo_%s_t *%s;",$line);
	    	 if(defined $type){
	    	 	$extern=1;
	    	 	if (defined $fifos{$fifo_name}){
	    	 		#add fifo definition:
	    	 		my $size = $fifos{$fifo_name}{'size'};
	    	 		#if(!defined $size ){
	    	 			$size = "$fifo_name";
	    	 			#$size=~ s/^\s*${actor}_//g;
	    	 			$size = "SIZE_$size";
	    	 		#}
	    	 		
	    	 		my $fnum  = $fifos{"$fifo_name"}{'fifo_num'};
	    	 		my $ch_num= $fifos{"$fifo_name"}{'chanel_num'};
	    	 		$ch_num =1  if(!defined $ch_num);
	    	 		
	    	 		my $src_fifo_name= $self->object_get_attribute("locally_connected","$fifo_name");
	    	 		#printf "$src_fifo_name locally connected $fifo_name\n";
	    	 		
	    	 		unless (defined $src_fifo_name){#check if destintion port is not localy connected 
	    	 		   
	    	 			$main_fifo_def=$main_fifo_def . "DECLARE_FIFO(${type}, $size, $fnum, $ch_num);\n";	    	 			
	    	 		}
	    	 		$main_fifo_assign=$main_fifo_assign . "fifo_${type}_t *$fifo_name = &fifo_$fnum;\n"; 
	    	 		$main_fifo_rst_ptr.="\t${fifo_name}->write_ind=0;\n";
	    	 		for (my $c=0; $c<$ch_num; $c++){
	    	 			$main_fifo_rst_ptr.="\t${fifo_name}->read_inds[$c]=0;\n" 
	    	 		}
	    	 		
	    	 		$origen_fuctions= $origen_fuctions . "$line \n";
	    	 		
	    	 		#$main_fifo_rst_ptr.="\t printf(\"${fifo_name}_addr=%u\\n\", &${fifo_name}->contents[0]);\n";  	 		
	    	 		
	    	 		my $shift =
	    	 			($type eq "i8"  || $type eq "u8")  ? 0 :
	    	 			($type eq "i16" || $type eq "u16") ? 1 :
	    	 			($type eq "i32" || $type eq "u32") ? 2 :
	    	 			($type eq "i64" || $type eq "u64") ? 3 : "undef_type check orcc.pl";
	    	 			 
	    	 		$origen_def=$origen_def. "#define ${fifo_name}_size_shift  $shift \n";
	    	 		
	    	 		
	    	 		
	    	 	}else{
	    	 		print Dumper(\%fifos);
	    	 		add_colored_info($tview,"Could not find $fifo_name in csv file\n",'red');	 	 		
	    	 			return;
	    	 	}		    	 	
	    	 }
	    	 
	    	 #connection_t
	    	 my  ($connect_name) = sscanf("extern connection_t %s;",$line);
	    	 if(defined $connect_name ){
	    	   $extern=1;
	    	   $main_def=$main_def . " connection_t $connect_name = {0, 0, 0, 0};// We dont need connection as they are done in hardware. just define to prevent error\n";
	    	   $origen_fuctions= $origen_fuctions . "$line \n";	
	    	 }
	    	 
	    	 
	    	 #actor_t
	    	 my  ($actor_name) = sscanf("extern actor_t %s;",$line);
	    	 if(defined $actor_name ){
	    	 	$extern=1;
	    	 	if (defined $fifos{"$actor_name"}{'file'}){
	    	 	#	print "===============================================================\n";
	    	 	#add actor definition
	    	 	#search in network.c file for actor definition
	    	 		my $csv=$fifos{"$actor_name"}{'file'};	
	    	 		my ($fname,$path,$suffix) = fileparse("$csv",qr"\..[^.]*$");	
	    	 		my $net= "$path/${fname}.c";
	    	 		
	    	 	    my @lines = get_line_have_string($net,"actor_t $actor_name",$tview);
	    	 	    if(defined $lines[0]){
	    	 	    	
	    	 	    	#print $fd "void ${actor_name}_initialize(schedinfo_t *);\n";
						#print $fd "void ${actor_name}_scheduler (schedinfo_t *);\n";	    	 	    	
	    	 	    	#print $fd "$lines[0]\n";
	    	 	    	$origen_fuctions= $origen_fuctions . "$line \n";	
	    	 	    	$actors_str=$actors_str."$lines[0]\n"  if($actor_name eq $actor);
	    	 	    }
	    	 	     	
	    	 	}
	    	 	
	    	 	
	    	 }
	    	 
	    	 $line= "//$line\n" ; # comment every files start with extern
	    	add_colored_info($tview,"The Auto generator does not know how to define this extern definition:\n $line \n",'red') if($extern == 0);
	    	$origen_fuctions = $origen_fuctions.  "$line\n";
	    }#extern
	    elsif( $line =~ /^\s?#define\s+/){
	    	$origen_def=$origen_def.  "$line\n";
	    }else{	
        	$origen_fuctions = $origen_fuctions.  "$line\n";
	    }

  }
		


print $fc "			
$origen_def

$Hw_fifo_define 


$origen_fuctions	

$actor_got_pck_func

$actor_update_credit

$actor_check_pck_func

$actor_sent_pck_done_func
	


$actor_run



$actor_init

";		
		

			close($fc);

			$actor_h.="$defines
	unsigned int  transfer_manage (unsigned int, unsigned int, unsigned int, unsigned char, unsigned int, unsigned int, unsigned int,  unsigned int, unsigned int, unsigned int, unsigned char, unsigned int *, unsigned int *);
	void got_packet_function(void);
	void check_packet_function (void);
	void sent_packet_done_function (void);	
	void error_handling_function (void);	
#endif
";
			open my $fp, ">$target_actor_header" or $r = "$!\n";
			if(defined $r) {
		    	add_colored_info($tview,"Could not open $target_actor_header to write: $r",'red');
				return;
			}
			print $fp $actor_h;
			close($fp);
			 


	}  
	
	
	
	
	
	my $got_pck_func= "	
void got_packet_function(void){
	unsigned int i ;
	unsigned char iport;
	for (i=0;i<${ni_name}_NUM_VCs;i++){
		if((${ni_name}_got_packet(i)) && (iport_array[i]==255) && ni_receive_is_free(i) ) {
		
			iport =${ni_name}_RECEIVE_PRECAP_DATA_REG(i); 
			iport_array[i]=iport;	
			if(iport==0){ //a credit update packet is recived;
				${ni_name}_receive (i, (unsigned int)& credit_buff[i] , 4, 0);	
			}else{
$all_got_packet_function
			}			
			${ni_name}_ack_got_pck_isr(i); 
		}//If ${ni_name} got packet
	}//for	
}// got_packet_function

";	
		
		


	my $sent_packet_done_function = "
 	
void sent_packet_done_function (void){
	unsigned char oport;
	unsigned int i;
	for (i=0;i<${ni_name}_NUM_VCs;i++){
		if(${ni_name}_packet_is_sent(i)) {
			oport= oport_array[i];
			if(oport==0){ // a credit update packet has sent out
				
			}else{	
$all_sent_packet_done_function
			}
			oport_array[i]=255;
			${ni_name}_ack_send_done_isr(i); 			
		}//If ${ni_name}_packet_is_sent
	}//for		
}//sent_packet_done_function	
	
";


	
	my $check_pck_func ="	
	
void check_packet_function (void){
	unsigned char iport;
	unsigned int i ,size ;
	unsigned int credit_value,credit_port;
	#ifdef ORCC_DEBUG_EN
	struct SRC_INFOS  src_info;
	#endif
	for (i=0;i<${ni_name}_NUM_VCs;i++){
		if(${ni_name}_packet_is_saved(i)) {
			
			size=${ni_name}_RECEIVE_DATA_SIZE_REG(i); //size in byte
			iport= iport_array[i];
			
			#ifdef ORCC_DEBUG_EN
			src_info=get_src_info(i);
			if(iport != src_info.r) printf (\"Error: iport missmatch \%u != \%u \\n\",iport, src_info.r );			  
			#endif
			
			iport_array[i]=255;
			
			if(iport==0){ // a credit update packet has been received
				credit_port  = credit_buff[i] >> 16; //output port num
				credit_value = (credit_buff[i] & 0xFFFF); // credit value in word
$all_update_credit
			}else{	
$all_check_packet_function
			}
			${ni_name}_ack_save_done_isr(i); 
		}//If ${ni_name}_packet_is_saved
	}//for	
}// check_packet_function
				
";	
	
my $ni_isr='
	
/*
transfer_manage
	w: initial weight
	v: Virtual chanel number
	class_num: message class number
	dest_port: destination queue number
	queue_pointer: address in byte
	queue_size: queue size in byte
	start_index: start index byte number
	end_index:  end index byte number
	dest_phy_addr
	credit: Number of byte available in destination queue
*/



unsigned int  transfer_manage (unsigned int w, unsigned int v, unsigned int class_num, unsigned char dest_port, unsigned int queue_pointer,unsigned int queue_size,
unsigned int start_index,  unsigned int send_data_size_in_byte, unsigned int dest_phy_addr,unsigned int credit, unsigned char port_num, unsigned int * sent_dat_size, unsigned int * dest_credit_size){
    

	unsigned int start_addr_pointer;
	unsigned int data_size=send_data_size_in_byte;
';
	
$ni_isr=$ni_isr."
    if (${ni_name}_send_is_busy(v)) return 0 ; // if VC is busy sending previous packet do nothing
    
";

$ni_isr=$ni_isr.'
	if(credit==0) return 0;
    if(data_size==0) return 0;
    start_addr_pointer = queue_pointer + start_index;
    if(data_size > credit) data_size =  credit; // we dont want to send more data than the receiver credit
    if((start_index + data_size) > queue_size) data_size =  queue_size-start_index; // we only send data until end of the queue. The rest will be sent in next round starting from beginning of the queue   
	if(data_size==0) return 0;
';

$ni_isr=$ni_isr."	
	oport_array[v]=  port_num; // port_num and data size should be saved before calling transfer function.
	* sent_dat_size =  data_size;
	* dest_credit_size -= data_size;
	${ni_name}_transfer (w, v, class_num, dest_port , start_addr_pointer, data_size, dest_phy_addr);
    return 1;   
}	
	
	
	
	

	
	
void error_handling_function(){
	unsigned int i;
	for (i=0;i<${ni_name}_NUM_VCs;i++){
		if(${ni_name}_got_buff_ovf(i)) {
			printf (\"VC%u:The receiver allocated buffer size is smaller than the received packet size in core\%u\\n\",i,COREID);
			${ni_name}_ack_buff_ovf_isr(i);
		}
		if(${ni_name}_got_send_dsize_err(i)) {
			 printf (\"VC%u:The send data size is not set in core\%u\\n\",i,COREID);
			 ${ni_name}_ack_send_dsize_err_isr(i); 
		}
		if(${ni_name}_got_burst_size_err(i)){
 			 printf (\"VC%u:The burst size is not set in core\%u\\n\",i,COREID);
			 ${ni_name}_ack_burst_size_err_isr(i);
		}
		if(${ni_name}_got_invalid_send_req(i)){
			 printf( \"VC%u:A new send request is received while the DMA is still busy sending previous packet in core\%u\\n\",i,COREID);
			 ${ni_name}_ack_invalid_send_req_isr(i);
		}
		if(${ni_name}_got_crc_mismatch(i)){
			printf( \"VC%u:CRC miss-matched in core\%u\\n\",i,COREID);
			${ni_name}_ack_crc_mismatch_isr(i);
		}		  
	}//for
}//error_handle		
	

         
	
	
void ${ni_name}_isr(void){
	//place your interrupt code here
	#if (ORCC_GOT_ERR_INT_EN == 1)
	if(${ni_name}_any_err_isr_is_asserted()  ){
		// An error ocure 
		error_handling_function();	
	}
	#endif
	
	#if (ORCC_SENT_DONT_INT_EN == 1) 
	if( ${ni_name}_any_sent_done_isr_is_asserted()  ){
		//check which VC has finished sending the packet. 
		sent_packet_done_function();		
	}
	#endif
	
	#if (ORCC_GOT_PCK_INT_EN == 1 || ORCC_SAVE_DONT_INT_EN ==1)		
	// regardless of ORCC_SAVE_DONT_INT_EN we need to check if the fifo pointer has been updated with last packet data size before sending save command for new packet to NI. 
	if( ${ni_name}_any_save_done_isr_is_asserted()){
		//check which VC has finished saving the packet. This function must be called before got_packet_function
		check_packet_function();		
	}	
	#endif
	
	#if (ORCC_GOT_PCK_INT_EN == 1)		
	if(${ni_name}_any_got_pck_isr_is_asserted() ){
		//check which VC got packet
		got_packet_function();		
	}
	#endif
	
	
	
	return;
}
	
	";	
	
	
my $v_val= $self->object_get_attribute('noc_param','V');		
my $opr ='';
for (my $i=0;$i<$v_val; $i++){
	$opr = $opr."\toport_array[$i]=255;\n"; 
	$opr = $opr."\tiport_array[$i]=255;\n"; 
}	
	
$main_fifo_rst_ptr.=
"$opr
}\n";	
	
	
my $main="	
int main(){
	schedinfo_t si;	
	reset_all_fifo_ptr();	
$all_init_actor	
	general_int_init();
	general_int_add(${ni_name}_INT_PIN, ${ni_name}_isr, 0); //${ni_name}_INT_PIN
	// Enable ${ni_name} interrupt (its connected to interrupt pin 0)
	general_int_enable(${ni_name}_INT_PIN);
	general_cpu_int_en();
	// hw interrupt enable function:
	// ${ni_name}_initial (burst_size,  errors_int_en,  send_int_en,  save_int_en,  got_pck_int_en)
	${ni_name}_initial (16,ORCC_GOT_ERR_INT_EN,ORCC_SENT_DONT_INT_EN,ORCC_SAVE_DONT_INT_EN,ORCC_GOT_PCK_INT_EN); 
	
	delay(100);
	while(1){
$all_run_actor
	}	
	return 0;
}		
			
";		
	
my $log2=log2($max_dst_port_num +1);	
	
print $fd "	
$main_include

#define MAX_DST_PORT_NUM  $max_dst_port_num 

// make sure that the HDATA_PRECAPw widh is >= log2(MAX_DST_PORT_NUM) 	
#if ( $log2 > ${ni_name}_HDATA_PRECAPw )
	#error \" The value of HDATA_PRECAPw should be defined at least $log2. Open the processing tile generator and increase the NI HDATA_PRECAPw value >= $log2\"
#endif

//make dure Byte_En is asserted in NI 
#if (${ni_name}_BYTE_EN == 0)
	#error \" The NI NI BYTE_EN parameter should be set as one for correct data comminication between cores. \"
#endif


// a simple delay function

void delay ( unsigned int num ){
	
	while (num>0){ 
		num--;
		nop(); // asm volatile (\"nop\");
	}
	return;

}


$actors_str

$main_fifo_def

$main_fifo_assign

$main_fifo_rst_ptr

$main_def




$got_pck_func 

$check_pck_func  

$sent_packet_done_function     

$ni_isr

$main

";
 
  
  
  
  close($fd);
  
 
  
save_file($src_lib_file,$src_lib);




 add_colored_info($tview,"$main_c file has been created successfully from @actors_file_names file \n",'blue');	
		
	}	#actor
	
	
	#done 
	message_dialog("The source files have been generated successfully");
		#print Dumper (\$self);
} #end sub



sub get_line_have_string{
	my ($file,$str,$tview)=@_;
	my $r;
	my @matches;
	open my $fh, "<", $file or $r = "$!\n";
    if(defined $r) {
    	add_colored_info($tview,"Could not open $file: $r",'red');
		return;
    } 
    while (my $line = <$fh>) {
	    chomp $line;
	    $line =~ s/\s+/ /g; # remove extra spaces
	    $line =~ s/^\s+//; #ltrim
	    if ($line =~ /$str/){
	    	push(@matches,$line);
	    }    
    	
    }
	return @matches;
}	

sub get_destport_constant_list{
	my ($self,$category)=@_;
	my %destport_const;
	#1- Get list of all actors
	my @actors= get_all_tasks($self,$category);
	foreach my $actor (@actors){
	
		my $i=1;
		#2- for each actor get the list of all input ports
		my @sinkers= get_all_dest_traces_of_actr($self,$actor,$category);
		#3- number each source port of this actor
		foreach my $sink (@sinkers){
			
			my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var,$src_port,$dst_port,$buff_size,$chanel,$vc,$class
				)=get_trace($self,$category,$sink);
			
			$destport_const{$actor}{$dst_port}= $i;
			#print "destport_const{$actor}{$dst_port}= $i;\n";
			$i++;
		}
	}	
	return %destport_const;
}




sub get_srcport_constant_list{
	my ($self,$category)=@_;
	my %srcport_const;
	#1- Get list of all actors
	my @actors= get_all_tasks($self,$category);
	#print "@actors\n**************************************************";
	foreach my $actor (@actors){
	
		my $i=1;
		#2- for each actor get the list of all output ports
		my @injectors= get_all_source_traces_of_actr($self,$actor,$category);
		#3- number each source port of this actor
		foreach my $inject (@injectors){
			
			my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var,$src_port,$dst_port,$buff_size,$chanel,$vc,$class
				)=get_trace($self,$category,$inject);
			
			$srcport_const{$actor}{$src_port}{$chanel}= $i;					
			$i++;
		}
	}	
	return %srcport_const;
}





sub get_all_dest_traces_of_actr{
	my ($self,$actor,$category)=@_;
	my @traces =get_trace_list($self,$category);
	my @sources;
	foreach my $p (@traces){
		my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var)=get_trace($self,$category,$p);
		push (@sources,$p) if($dst eq $actor);
	}
	return  @sources;	
}

sub get_all_source_traces_of_actr{
	my ($self,$actor,$category)=@_;
	my @traces =get_trace_list($self,$category);
	my @dests;
	foreach my $p (@traces){
		my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var)=get_trace($self,$category,$p);
		push (@dests,$p) if($src eq $actor);
	}
	return  @dests;	
}	

sub get_actr_file_name {
	my ($self,$actor,$category)=@_;
	my @traces =get_trace_list($self,$category);
	foreach my $p (@traces){
		my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var)=get_trace($self,$category,$p);
		if($src eq $actor || $dst eq $actor){
			#the actor supposed to be located next to CSV file and have the same file name as actor name
			my ($fname,$path,$suffix) = fileparse("$file_name",qr"\..[^.]*$");	
			#my ($net,$num,$name)=split(':',$actor);
			return "$path/${actor}.c"; 
		}
	}
	return undef;
}

















1;
