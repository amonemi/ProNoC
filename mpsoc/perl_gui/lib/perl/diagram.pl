#!/usr/bin/perl -w
use strict;
use warnings;
use soc;
require "widget.pl"; 
require "emulator.pl";
use File::Copy;

#use GraphViz;


sub get_dot_file{
	my $soc= shift;
	my $soc_name=$soc->object_get_attribute('soc_name');
	my $remove_clk = $soc->object_get_attribute("diagrame","show_clk");
	my $remove_reset = $soc->object_get_attribute("diagrame","show_reset");
	my $remove_unused = $soc->object_get_attribute("diagrame","show_unused");

	my $dotfile=
"digraph G {
	graph [rankdir = LR , splines=polyline, overlap = false]; 
	node[shape=record];
";

	my @all_instances=$soc->soc_get_all_instances();
	#print "@all_instances\n";
	my $graph_connect= '';
	my $n=0;
	#my %socket_color;
	foreach my $instance_id (@all_instances){
		my $first=1;
		my $instance_name=$soc->soc_get_instance_name($instance_id);
		$dotfile="$dotfile \n\t$instance_id \[label=\"{  ";
		
		my @sockets= $soc->soc_get_all_sockets_of_an_instance($instance_id);
		@sockets = remove_scolar_from_array(\@sockets,'clk') if ($remove_clk);
		@sockets = remove_scolar_from_array(\@sockets,'reset') if ($remove_reset);
		

		foreach my $socket (@sockets){

			my @nums=$soc->soc_list_socket_nums($instance_id,$socket);
			foreach my $num (@nums){
				my $name= $soc->soc_get_socket_name ($instance_id,$socket,$num);
				my  ($s_type,$s_value,$s_connection_num)=$soc->soc_get_socket_of_instance($instance_id,$socket);
				my $v=$soc->soc_get_module_param_value($instance_id,$s_value);
				$v=1 if ( length( $v || '' ) ==0);
				#for(my $i=$v-1; $i>=0; $i--) {
				for(my $i=0; $i<$v; $i++) {
					#$socket_color{socket_${socket}\_$i}=$n;
					#$n = ($n<30)? $n+1 : 0;
					my ($ref1,$ref2)= $soc->soc_get_modules_plug_connected_to_socket($instance_id,$socket,$i);
					my %connected_plugs=%$ref1;
					my %connected_plug_nums=%$ref2;
					if(%connected_plugs || $remove_unused==0){ 
						$dotfile= ($first)? "$dotfile\{<socket_${socket}\_$i>$name\_$i" : "$dotfile |<socket_${socket}_${i}>$name\_${i}";
						$first=0;
					}
				}
				
			}
		}
		
		
		
		
		$dotfile=($first)? "$dotfile $instance_name"  : "$dotfile}|$instance_name";
		$first=1;
		my @plugs= $soc->soc_get_all_plugs_of_an_instance($instance_id);
		@plugs = remove_scolar_from_array(\@plugs,'clk') if ($remove_clk);
		@plugs = remove_scolar_from_array(\@plugs,'reset') if ($remove_reset);

		my %plug_order;
		my @noconnect;
		foreach my $plug (@plugs){
			
			my @nums=$soc->soc_list_plug_nums($instance_id,$plug);
			foreach my $num (@nums){
				my ($addr,$base,$end,$name,$connect_id,$connect_socket,$connect_socket_num)=$soc->soc_get_plug($instance_id,$plug,$num);
				
				if(defined $connect_socket || $remove_unused==0){ 
					#$dotfile= ($first)?  "$dotfile |{<plug_${plug}_${num}>$name" :  "$dotfile|<plug_${plug}_${num}>$name";
					if(defined $connect_id && defined $connect_socket){
						my @sockets= $soc->soc_get_all_sockets_of_an_instance($connect_id);
						my $order_val=0;
						my $s1=get_pos($connect_id, @all_instances);
						my $s2=get_pos($connect_socket,  @sockets);
						$order_val=$s1*1000000+$s2*10000+$connect_socket_num;
						$plug_order{$order_val}=  "<plug_${plug}_${num}>$name";
					}else {push (@noconnect,"<plug_${plug}_${num}>$name");}
				}
				

				#my $connect_name=$soc->soc_get_instance_name($connect_id);
				#my $color = get_color_hex_string($n);
				#$n = ($n<30)? $n+1 : 0;
				
				$graph_connect="$graph_connect $instance_id:plug_${plug}_${num} ->  $connect_id:socket_${connect_socket}_${connect_socket_num} [  dir=none]\n" if(defined $connect_socket);
				
			}
		}
		foreach my $p (sort {$a<=>$b} keys %plug_order){
					my $k=$plug_order{$p};
					#print "$instance_name   : $k=\$plug_order{$p}\n";
					$dotfile= ($first) ?   "$dotfile |{ ${k}": "$dotfile |${k}";
					$first=0;

				}

		foreach my $k (@noconnect){
			$dotfile= ($first) ?   "$dotfile |{ ${k}": "$dotfile |${k}";
			$first=0;
		}

		$dotfile=  "$dotfile} }\"];";

		
	
	}
	$dotfile="$dotfile\n\n$graph_connect";
	$dotfile="$dotfile\n\n}\n";


	return $dotfile;


}





sub show_tile_diagram {
	my $soc= shift;

	my $table=def_table(20,20,FALSE);
	
	my $window=def_popwin_size(80,80,"Processing Tile functional block diagram",'percent');	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);	
	$scrolled_win->set_policy( "automatic", "automatic" );
	
	$window->add ($table);
	
	my $plus = def_image_button('icons/plus.png',undef,TRUE);
	my $minues = def_image_button('icons/minus.png',undef,TRUE);
	my $unused = gen_check_box_object ($soc,"diagrame","show_unused",0,undef,undef);
	my $save = def_image_button('icons/save.png',undef,TRUE);
	my $clk = gen_check_box_object ($soc,"diagrame","show_clk",0,undef,undef);
	my $reset = gen_check_box_object ($soc,"diagrame","show_reset",0,undef,undef);
	#my $save = def_image_button('icons/save.png',undef,TRUE);

	my $scale=$soc->object_get_attribute("diagrame","scale");
	$scale= 1 if (!defined $scale);
		
		
		
	
	my $col=0;
	$table->attach ($plus ,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach ($minues,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach ($save,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach (gen_label_in_left("     Remove unconnected Interfaces"),  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach ($unused,  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach (gen_label_in_left("     Remove Clk Interfaces"),  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach ($clk,  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach (gen_label_in_left("     Remove Reset Interfaces"),  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach ($reset,  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
	while ($col<20){
		
		my $tmp=gen_label_in_left('');
		$table->attach_defaults ($tmp, $col,  $col+1,0,1);$col++;
	}
	
	$plus  -> signal_connect("clicked" => sub{ 
		$scale*=1.1 if ($scale <10);
		$soc->object_add_attribute("diagrame","scale", $scale );
		show_diagram ($soc,$scrolled_win,$table);
	});	
	$minues  -> signal_connect("clicked" => sub{ 
		$scale*=.9  if ($scale >0.1); ;
		$soc->object_add_attribute("diagrame","scale", $scale );
		show_diagram ($soc,$scrolled_win,$table);
	});
	$save-> signal_connect("clicked" => sub{ 
			save_diagram_as ($soc);
		});	
	$unused-> signal_connect("toggled" => sub{
		if(gen_diagram($soc)){
			show_diagram ($soc,$scrolled_win,$table);
		}

	});
	$clk-> signal_connect("toggled" => sub{
		if(gen_diagram($soc)){
			show_diagram ($soc,$scrolled_win,$table);
	}

	});
	$reset-> signal_connect("toggled" => sub{
		if(gen_diagram($soc)){
			show_diagram ($soc,$scrolled_win,$table);
		}

	});



	
	if(gen_diagram($soc)){
		show_diagram ($soc,$scrolled_win,$table);
	}
	$window->show_all();

	



}



sub gen_diagram {
	my ($soc)=@_;

	

	my $dotfile= get_dot_file($soc);
	my $tmp_dir  = "$ENV{'PRONOC_WORK'}/tmp";
	mkpath("$tmp_dir/",1,01777);
	open(FILE,  ">$tmp_dir/diagram.txt") || die "Can not open: $!";
	print FILE $dotfile;
	close(FILE) || die "Error closing file: $!";

	my $cmd = "dot  $tmp_dir/diagram.txt | neato -n  -Tpng -o $tmp_dir/diagram.png";
 

	my ($stdout,$exit,$stderr)= run_cmd_in_back_ground_get_stdout ($cmd);

	 if ( length( $stderr || '' ) !=0)  {
		message_dialog("$stderr\nHave you installed graphviz? If not run \n \t \"sudo apt-get install graphviz\" \n in terminal");
		return 0;
	}
	else {
		#my $diagram=show_gif("$tmp_dir/diagram.png");
		
		
		return  1;
		
	}	


}



sub show_diagram {
	my ($soc,$scrolled_win,$table)=@_;

	$scrolled_win->destroy;
	$scrolled_win = new Gtk2::ScrolledWindow (undef, undef);	
	$scrolled_win->set_policy( "automatic", "automatic" );
	$table->attach_defaults ($scrolled_win, 0, 20, 1, 20); #,'fill','shrink',2,2);		
	my $scale=$soc->object_get_attribute("diagrame","scale");
	$scale= 1 if (!defined $scale);
	my $tmp_dir  = "$ENV{'PRONOC_WORK'}/tmp";
	my $diagram=open_image("$tmp_dir/diagram.png",70*$scale,70*$scale,'percent');
		$scrolled_win->add_with_viewport($diagram);
		$scrolled_win->show_all();	
		
		


}


sub save_diagram_as {
	my $soc= shift;
	
	my $file;
	my $title ='Save as';



	my @extensions=('png');
	my $open_in=undef;
	my $dialog = Gtk2::FileChooserDialog->new(
            	'Save file', undef,
            	'save',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);
	# if(defined $extension){
		
		foreach my $ext (@extensions){
			my $filter = Gtk2::FileFilter->new();
			$filter->set_name($ext);
			$filter->add_pattern("*.$ext");
			$dialog->add_filter ($filter);
		}
		
	# }
	  if(defined  $open_in){
		$dialog->set_current_folder ($open_in); 
		# print "$open_in\n";
		 
	}
		
	if ( "ok" eq $dialog->run ) {
	    		$file = $dialog->get_filename;
			my $ext = $dialog->get_filter;
			$ext=$ext->get_name;
			my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
			$file = ($suffix eq ".$ext" )? $file : "$file.$ext";
			
			$soc->object_add_attribute("graph_save","name",$file);
			$soc->object_add_attribute("graph_save","extension",$ext);
			my $tmp  = "$ENV{'PRONOC_WORK'}/tmp/diagram.png";
			copy ($tmp,$file);


					
	      		 }
	     		$dialog->destroy;
	       		


	 


}



return 1;
