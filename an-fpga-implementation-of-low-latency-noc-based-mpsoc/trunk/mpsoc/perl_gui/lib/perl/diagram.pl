#!/usr/bin/perl -w
use Glib qw/TRUE FALSE/;
use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use soc;
require "widget.pl"; 
require "emulator.pl";
use File::Copy;




sub get_dot_file{
	my $self= shift;
	my $self_name=$self->object_get_attribute('soc_name');
	my $remove_clk = $self->object_get_attribute("tile_diagram","show_clk");
	my $remove_reset = $self->object_get_attribute("tile_diagram","show_reset");
	my $remove_unused = $self->object_get_attribute("tile_diagram","show_unused");

	my $dotfile=
"digraph G {
	graph [rankdir = LR , splines=polyline, overlap = false]; 
	node[shape=record];
";

	my @all_instances=$self->soc_get_all_instances();
	#print "@all_instances\n";
	my $graph_connect= '';
	my $n=0;
	#my %socket_color;
	foreach my $instance_id (@all_instances){
		my $first=1;
		my $instance_name=$self->soc_get_instance_name($instance_id);
		$dotfile="$dotfile \n\t$instance_id \[label=\"{  ";
		
		my @sockets= $self->soc_get_all_sockets_of_an_instance($instance_id);
		@sockets = remove_scolar_from_array(\@sockets,'clk') if ($remove_clk);
		@sockets = remove_scolar_from_array(\@sockets,'reset') if ($remove_reset);
		

		foreach my $socket (@sockets){

			my @nums=$self->soc_list_socket_nums($instance_id,$socket);
			foreach my $num (@nums){
				my $name= $self->soc_get_socket_name ($instance_id,$socket,$num);
				my  ($s_type,$s_value,$s_connection_num)=$self->soc_get_socket_of_instance($instance_id,$socket);
				my $v=$self->soc_get_module_param_value($instance_id,$s_value);
				$v=1 if ( length( $v || '' ) ==0);
				#for(my $i=$v-1; $i>=0; $i--) {
				for(my $i=0; $i<$v; $i++) {
					#$socket_color{socket_${socket}\_$i}=$n;
					#$n = ($n<30)? $n+1 : 0;
					my ($ref1,$ref2)= $self->soc_get_modules_plug_connected_to_socket($instance_id,$socket,$i);
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
		my @plugs= $self->soc_get_all_plugs_of_an_instance($instance_id);
		@plugs = remove_scolar_from_array(\@plugs,'clk') if ($remove_clk);
		@plugs = remove_scolar_from_array(\@plugs,'reset') if ($remove_reset);

		my %plug_order;
		my @noconnect;
		foreach my $plug (@plugs){
			
			my @nums=$self->soc_list_plug_nums($instance_id,$plug);
			foreach my $num (@nums){
				my ($addr,$base,$end,$name,$connect_id,$connect_socket,$connect_socket_num)=$self->soc_get_plug($instance_id,$plug,$num);
				
				if(defined $connect_socket || $remove_unused==0){ 
					#$dotfile= ($first)?  "$dotfile |{<plug_${plug}_${num}>$name" :  "$dotfile|<plug_${plug}_${num}>$name";
					if(defined $connect_id && defined $connect_socket){
						my @sockets= $self->soc_get_all_sockets_of_an_instance($connect_id);
						my $order_val=0;
						my $s1=get_pos($connect_id, @all_instances);
						my $s2=get_pos($connect_socket,  @sockets);
						$order_val=$s1*1000000+$s2*10000+$connect_socket_num;
						$plug_order{$order_val}=  "<plug_${plug}_${num}>$name";
					}else {push (@noconnect,"<plug_${plug}_${num}>$name");}
				}
				

				#my $connect_name=$self->soc_get_instance_name($connect_id);
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
	my $self= shift;

	my $table=def_table(20,20,FALSE);
	
	my $window=def_popwin_size(80,80,"Processing Tile functional block diagram",'percent');	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);	
	$scrolled_win->set_policy( "automatic", "automatic" );
	
	$window->add ($table);
	
	my $plus = def_image_button('icons/plus.png',undef,TRUE);
	my $minues = def_image_button('icons/minus.png',undef,TRUE);
	my $unused = gen_check_box_object ($self,"tile_diagram","show_unused",0,undef,undef);
	my $save = def_image_button('icons/save.png',undef,TRUE);
	my $clk = gen_check_box_object ($self,"tile_diagram","show_clk",0,undef,undef);
	my $reset = gen_check_box_object ($self,"tile_diagram","show_reset",0,undef,undef);
	#my $save = def_image_button('icons/save.png',undef,TRUE);

	my $scale=$self->object_get_attribute("tile_diagram","scale");
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
		$self->object_add_attribute("tile_diagram","scale", $scale );
		show_diagram ($self,$scrolled_win,$table,"tile_diagram");
	});	
	$minues  -> signal_connect("clicked" => sub{ 
		$scale*=.9  if ($scale >0.1); ;
		$self->object_add_attribute("tile_diagram","scale", $scale );
		show_diagram ($self,$scrolled_win,$table,"tile_diagram");
	});
	$save-> signal_connect("clicked" => sub{ 
			save_diagram_as ($self);
		});	
	$unused-> signal_connect("toggled" => sub{
		if(gen_diagram($self,'tile')){
			show_diagram ($self,$scrolled_win,$table,"tile_diagram");
		}

	});
	$clk-> signal_connect("toggled" => sub{
		if(gen_diagram($self,'tile')){
			show_diagram ($self,$scrolled_win,$table,"tile_diagram");
	}

	});
	$reset-> signal_connect("toggled" => sub{
		if(gen_diagram($self,'tile')){
			show_diagram ($self,$scrolled_win,$table,"tile_diagram");
		}

	});
	
	if(gen_diagram($self,'tile')){
		show_diagram ($self,$scrolled_win,$table,"tile_diagram");
	}
	$window->show_all();
}


sub show_topology_diagram {
	my $self= shift;

	my $table=def_table(20,20,FALSE);
	
	my $window=def_popwin_size(80,80,"NoC-based MCSoC topology block diagram",'percent');	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);	
	$scrolled_win->set_policy( "automatic", "automatic" );
	
	$window->add ($table);
	
	my $plus = def_image_button('icons/plus.png',undef,TRUE);
	my $minues = def_image_button('icons/minus.png',undef,TRUE);
	my $save = def_image_button('icons/save.png',undef,TRUE);
	
	my $scale=$self->object_get_attribute("tile_diagram","scale");
	$scale= 1 if (!defined $scale);
		
		
		
	
	my $col=0;
	$table->attach ($plus ,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach ($minues,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach ($save,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
	#$table->attach (gen_label_in_left("     Remove unconnected Interfaces"),  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
	#$table->attach (gen_label_in_left("     Remove Clk Interfaces"),  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
	#$table->attach (gen_label_in_left("     Remove Reset Interfaces"),  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
	while ($col<20){		
		my $tmp=gen_label_in_left('');
		$table->attach_defaults ($tmp, $col,  $col+1,0,1);$col++;
	}
	
	$plus  -> signal_connect("clicked" => sub{ 
		$scale*=1.1 if ($scale <10);
		$self->object_add_attribute("topology_diagram","scale", $scale );
		show_diagram ($self,$scrolled_win,$table,"topology_diagram");
	});	
	$minues  -> signal_connect("clicked" => sub{ 
		$scale*=.9  if ($scale >0.1); ;
		$self->object_add_attribute("topology_diagram","scale", $scale );
		show_diagram ($self,$scrolled_win,$table,"topology_diagram");
	});
	$save-> signal_connect("clicked" => sub{ 
			save_diagram_as ($self);
		});	
	
	
	if(gen_diagram($self,'topology')){
		show_diagram ($self,$scrolled_win,$table,"topology_diagram");
	}
	$window->show_all();
}





sub gen_diagram {
	my ($self,$type)=@_;
	
	my $dotfile;
	$dotfile=   get_dot_file($self) if ($type eq 'tile');
	$dotfile=   get_topology_dot_file($self) if ($type eq 'topology');
	$dotfile=   generate_custom_topology_dot_file($self) if ($type eq 'custom_topology');	
	$dotfile=   generate_trace_dot_file($self) if ($type eq 'trace');	
	$dotfile=   generate_map_dot_file($self) if ($type eq 'map');										
	
	my $tmp_dir  = "$ENV{'PRONOC_WORK'}/tmp";
	#mkpath("$tmp_dir/",1,01777);
	#open(FILE,  ">$tmp_dir/diagram.txt") || die "Can not open: $!";
	#print FILE $dotfile;
	#close(FILE) || die "Error closing file: $!";
	
	#unlink "$tmp_dir/diagram.png";

	my $cmd;
	#$cmd=  "dot  $tmp_dir/diagram.txt | neato -n  -Tpng -o $tmp_dir/diagram.png" if ($type eq 'tile' || $type eq 'trace'  );
	#$cmd = "dot  $tmp_dir/diagram.txt -Kfdp -n -Tpng -o $tmp_dir/diagram.png" if ( $type eq 'map' || $type eq 'topology' || $type eq 'custom_topology' );	
 	$cmd=  " dot   | neato -n  -Tpng -o $tmp_dir/diagram.png" if ($type eq 'tile' || $type eq 'trace'  );
	$cmd = " dot   -Kfdp -n -Tpng -o $tmp_dir/diagram.png" if ( $type eq 'map' || $type eq 'topology' || $type eq 'custom_topology' );	
    $cmd = "echo \'$dotfile\' | $cmd";

	my ($stdout,$exit,$stderr)= run_cmd_in_back_ground_get_stdout ($cmd);

	if ( length( $stderr || '' ) !=0)  {
		message_dialog("$stderr\nHave you installed graphviz? If not run \n \t \"sudo apt-get install graphviz\" \n in terminal");
		return 0 unless (-f "$tmp_dir/diagram.png");
	}
		return  1;
}



sub show_diagram {
	my ($self,$scrolled_win,$table, $name)=@_;

	$scrolled_win->destroy;
	$scrolled_win = new Gtk2::ScrolledWindow (undef, undef);	
	$scrolled_win->set_policy( "automatic", "automatic" );
	$table->attach_defaults ($scrolled_win, 0, 20, 1, 20); #,'fill','shrink',2,2);		
	my $scale=$self->object_get_attribute($name,"scale");
	$scale= 1 if (!defined $scale);
	my $tmp_dir  = "$ENV{'PRONOC_WORK'}/tmp";
	my $diagram=open_image("$tmp_dir/diagram.png",70*$scale,70*$scale,'percent');
	
	$scrolled_win->add_with_viewport($diagram);
	$scrolled_win->show_all();	
		
		


}


sub save_diagram_as {
	my $self= shift;
	
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
			
			$self->object_add_attribute("graph_save","name",$file);
			$self->object_add_attribute("graph_save","extension",$ext);
			my $tmp  = "$ENV{'PRONOC_WORK'}/tmp/diagram.png";
			copy ($tmp,$file);


					
	      		 }
	     		$dialog->destroy;
}



sub generate_trace_dot_file{
	my $self=shift;
	my $dotfile=
"digraph G {
	graph [rankdir = LR , splines=polyline, overlap = false]; 
	
";
	
#add nodes
	#my @tasks=get_all_tasks($self);
	#foreach my $p (@tasks){
	#	$dotfile=$dotfile."\"$p\" [label=\"{   $p} }\"];\n"; 		
	#}	
	
#add connections

	my @traces= $self->get_trace_list();
	foreach my $p (@traces) {	
		my ($src,$dst, $Mbytes, $file_id, $file_name)=$self->get_trace($p);
		$dotfile=$dotfile."\"$src\" -> \"$dst\"  [label=\"$Mbytes\" ];\n";	
	}
	
	$dotfile=$dotfile."\n}\n";
	return $dotfile;
	
}



sub generate_map_dot_file{
	my $self=shift;
	my $dotfile=
"digraph G {
	graph [rankdir = LR ,splines=spline,  overlap = false]; 
	node[shape=record];
	
	";
	

	
#add nodes
	my $nx=$self->object_get_attribute('noc_param','T1');
	my $ny=$self->object_get_attribute('noc_param','T2');
	my $nc= $nx * $ny;
	my @tasks=get_all_tasks($self);
	
	my @mappedtasks;
	
	
	for(my $y=0; $y<$ny; $y++){ 
		
		
				for(my $x=0; $x<$nx; $x++){
					my $id=$y*$nx+$x;
					my $task=get_task_assigned_to_tile($self,$x,$y);
					push(@mappedtasks,$task) if (defined $task); 
					
					$task= "_" if (!defined $task); 
					my $n = ($ny==1)?   "tile(${x})" : "tile${id}(${x}_$y)" ;
					my $m = ($ny==1)?   "tile(${x})" : "tile(${x}_$y)" ;
					my $node = "\"$m\"";					
					my $label =   "\"<S$task> $n|<R$task> $task\"" ;
					my $xx=$x*1.5;
					my $yy=($ny-$y-1)*1.5;
					
					$dotfile=$dotfile."
$node\[
	label = $label
    pos = \"$xx,$yy!\"
];";					
					
					
									
				}
				
	}					
	

	$dotfile=$dotfile."\n\n";
	
	#add connections
	my @traces= $self->get_trace_list();
	foreach my $p (@traces){
		my ($src,$dst, $Mbytes, $file_id, $file_name)=$self->get_trace($p);
				
		my $src_tile= $self->object_get_attribute("MAP_TILE","$src");
		my $dst_tile= $self->object_get_attribute("MAP_TILE","$dst");
		
		next if ( $src_tile eq "-" ||  $dst_tile eq "-" ) ;
		
		
		
		$dotfile=$dotfile." \"$src_tile\" :  \"S$src\" ->  \"$dst_tile\" : \"R$dst\"  ;\n";
	
	
	}



	
	$dotfile=$dotfile."\n}\n";
	return $dotfile;
	
}





sub show_trace_diagram {
	my ($self,$type)=@_;

	my $table=def_table(20,20,FALSE);
	
	my $window=def_popwin_size(80,80,"Processing Tile functional block diagram",'percent');	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);	
	$scrolled_win->set_policy( "automatic", "automatic" );
	
	$window->add ($table);
	
	my $plus = def_image_button('icons/plus.png',undef,TRUE);
	my $minues = def_image_button('icons/minus.png',undef,TRUE);
	my $save = def_image_button('icons/save.png',undef,TRUE);
	

	my $scale=$self->object_get_attribute("${type}_diagram","scale");
	$scale= 1 if (!defined $scale);
		
		
		
	
	my $col=0;
	$table->attach ($plus ,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach ($minues,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
	$table->attach ($save,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
	
	while ($col<20){
		

		
		my $tmp=gen_label_in_left('');
		$table->attach_defaults ($tmp, $col,  $col+1,0,1);$col++;
	}
	
	$plus  -> signal_connect("clicked" => sub{ 
		$scale*=1.1 if ($scale <10);
		$self->object_add_attribute("${type}_diagram","scale", $scale );
		show_diagram ($self,$scrolled_win,$table, "${type}_diagram");
	});	
	$minues  -> signal_connect("clicked" => sub{ 
		$scale*=.9  if ($scale >0.1); ;
		$self->object_add_attribute("${type}_diagram","scale", $scale );
		show_diagram ($self,$scrolled_win,$table, "${type}_diagram");
	});
	$save-> signal_connect("clicked" => sub{ 
			save_diagram_as ($self);
		});	
	



	if(gen_diagram($self,$type)){
		show_diagram ($self,$scrolled_win,$table, "${type}_diagram");
	}
	$window->show_all();

	


}	






sub node_connection{
	my ($sn,$sx,$sy,$sp,$dn,$dx,$dy,$dp)=@_;
	my $spp = (defined $sp) ? ":\"p$sp\"" : " ";
	my $dpp = (defined $dp) ? ":\"p$dp\"" : " ";
	my $sname = (defined $sy) ? "\"$sn${sx}_${sy}\"" : "\"$sn${sx}\"";
	my $dname = (defined $dy) ? "\"$dn${dx}_${dy}\"" : "\"$dn${dx}\"";
	
	my $t= "$sname  $spp -> $dname  $dpp [  dir=none];\n"; 
	return $t;	
}

sub node_connection2{
	my ($sn,$sx,$sp,$dn,$dx,$dy,$dp)=@_;
	my $spp = (defined $sp) ? ":\"p$sp\"" : " ";
	my $dpp = (defined $dp) ? ":\"p$dp\"" : " ";
	my $sname =   "\"$sn${sx}\"";
	my $dname =  "\"$dn${dx}\"";
	
	my $t= "$sname  $spp -> $dname  $dpp [  dir=none];\n"; 
	return $t;	
}


sub generate_mesh_dot_file_old{
	my $self=shift;
	my $dotfile=
"digraph G {
	graph [rankdir = LR , splines = true, overlap = true]; 
	
	
	
	node[shape=record];
	
	";
		
#five_port_router [
#	label="{ |2| } | {3|R0|1} | { |4|0}"
#	shape=record
#	color=blue
#	style=filled
#	fillcolor=blue
#];	
	
#add nodes
	my $nx=$self->object_get_attribute('noc_param','T1');
	my $ny=$self->object_get_attribute('noc_param','T2');
	my $nc= $nx * $ny;
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	my $btrace= ($topology eq '"TORUS"' || $topology eq '"RING"');
	my $oned = ($topology eq '"RING"' || $topology eq '"LINE"');	
	for(my $y=0; $y<$ny; $y++){ 		
				for(my $x=0; $x<$nx; $x++){
					my $id=$y*$nx+$x;
					
									
					my $n =    "R${id}" ;
					my $node = "${x}_$y";					
					my $label =  ($oned)?
					 "\{ |<p2>| \} | \{<p3>2|$n|<p1>1\} | \{ |<p4>|<p0>0\}"
					:  "\{ |<p2>2| \} | \{<p3>3|$n|<p1>1\} | \{ |<p4>4|<p0>0\}";
					my $xx=$x*2.5;
					my $yy=($ny-$y-1)*2.5+1;
					my $tx=$xx+0.75;
					my $ty=$yy-1;
					$dotfile=$dotfile."
\"R$node\"\[
	label = \"$label\"
    pos = \"$xx,$yy!\"
    shape=record
	color=blue
	style=filled
	fillcolor=blue
];

T$node\[
	label = \"Tile_$id($node)\"
    pos = \"$tx,$ty!\"
    shape=record
	color=orange
	style=filled
	fillcolor=orange
];";					

;									
		}
				
	}					
	

	$dotfile=$dotfile."\n\n";
	
	#add connections
	for(my $y=0; $y<$ny; $y++){ 		
		for(my $x=0; $x<$nx; $x++){
			 $dotfile=$dotfile.node_connection('R',$x,$y,1,'R',($x+1),$y,3) if($x <$nx-1);	
			 $dotfile=$dotfile.node_connection('R',$x,$y,1,'R',0,$y,3) if($x == ($nx-1) && $btrace);
			 $dotfile=$dotfile.node_connection('R',$x,$y,2,'R',$x,($y-1),4)if($y>0) ; 
             $dotfile=$dotfile.node_connection('R',$x,$y,2,'R',$x,($ny-1),4)   if($y ==0 && $btrace && !$oned);
             $dotfile=$dotfile.node_connection('R',$x,$y,0,'T',$x,$y);
                
              
	
	}}



	
	$dotfile=$dotfile."\n}\n";
	return $dotfile;
	
}


##################################
#
##################################


sub generate_mesh_dot_file{
	my $self=shift;
	my $dotfile=
"digraph G {
	graph [rankdir = RL , splines = true, overlap = true]; 
		
	
	node[shape=record];
	
	";
		
#five_port_router [
#	label="{ |2| } | {3|R0|1} | { |4|0}"
#	shape=record
#	color=blue
#	style=filled
#	fillcolor=blue
#];	
	
#add nodes
	my $nx=$self->object_get_attribute('noc_param','T1');
	my $ny=$self->object_get_attribute('noc_param','T2');
	my $nz=$self->object_get_attribute('noc_param','T3');
	my $NE = $nx*$ny*$nz;
	my $NR = $nx*$ny; 	
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
		
	
	my $btrace= ($topology eq '"TORUS"' || $topology eq '"RING"');
	my $oned = ($topology eq '"RING"' || $topology eq '"LINE"');
	
	#generate endpoints
	for(my $y=0; $y<$ny; $y++){ 		
				for(my $x=0; $x<$nx; $x++){
					for(my $z=0; $z<$nz; $z++){
						my $id=($y*$nx+$x)*$nz+$z;						
						my $offsetx = ($z==0 || $z==3) ? 1.05 : -1.05; 
						my $offsety = ($z==0 || $z==1) ? -0.85 : +0.85; 
						my $tx=$x*3+$offsetx;
						my $ty=($ny-$y-1)*2.5+1+$offsety;

$dotfile=$dotfile."

T$id\[
	label = \"T${id}\"
    pos = \"$tx,$ty!\"
    shape=record
	color=orange
	style=filled
	fillcolor=orange
];";								
	
	}}}
	
#generate routers	
	for(my $y=0; $y<$ny; $y++){ 		
				for(my $x=0; $x<$nx; $x++){
					my $e0 = '0';
					my $e1 = ($nz>1)? ( ($oned)? '3':'5') : ' ';
					my $e2 = ($nz>2)? ( ($oned)? '4':'6') : ' ';
					my $e3 = ($nz>3)? ( ($oned)? '5':'7') : ' ';
					
					my $id=$y*$nx+$x;									
					my $n = "R${id}";								
					my $label =  ($oned)?
					 "\{<p7>$e2 |<p2> |<p8>$e3 \} | \{<p3>2|$n|<p1>1\} | \{<p6>$e1 |<p4> |<p5>$e0\}"
					:"\{<p7>$e2 |<p2>2|<p8>$e3 \} | \{<p3>3|$n|<p1>1\} | \{<p6>$e1 |<p4>4|<p5>$e0\}";
					my $xx=$x*3;
					my $yy=($ny-$y-1)*2.5+1;
					


$dotfile=$dotfile."
\"$n\"\[
	label = \"$label\"
    pos = \"$xx,$yy!\"
    shape=record
	color=blue
	style=filled
	fillcolor=blue
];

";					

				}}							
	

	$dotfile=$dotfile."\n\n";
	
	#add connections
	for(my $y=0; $y<$ny; $y++){ 		
		for(my $x=0; $x<$nx; $x++){
			 
			 $dotfile=$dotfile.node_connection('R',get_router_num($self,$x,$y),undef,1,'R',get_router_num($self,($x+1),$y),undef,3) if($x <$nx-1);	
			 $dotfile=$dotfile.node_connection('R',get_router_num($self,$x,$y),undef,1,'R',get_router_num($self,0,$y),undef,3) if($x == ($nx-1) && $btrace);
			 $dotfile=$dotfile.node_connection('R',get_router_num($self,$x,$y),undef,2,'R',get_router_num($self,$x,($y-1)),undef,4)if($y>0) ; 
             $dotfile=$dotfile.node_connection('R',get_router_num($self,$x,$y),undef,2,'R',get_router_num($self,$x,($ny-1)),undef,4) if($y ==0 && $btrace && !$oned);
          #   $dotfile=$dotfile.node_connection('R',$x,$y,0,'T',$x,$y);               
    }}

	for(my $id=0; $id<$NE; $id++){ 
		my $rid=int($id/$nz);
		my $p =  $id%$nz+5;
		$dotfile=$dotfile.node_connection('R',$rid,undef,$p,'T',$id,undef);               
	
	}
	
	$dotfile=$dotfile."\n}\n";
	return $dotfile;



}



sub generate_fattree_dot_file{
	my $self=shift;
		
	my $dotfile=
"digraph G {
	graph [rankdir = LR , splines = true, overlap = true]; 	
	node[shape=record];	
	";
		
#add nodes
	my $k=$self->object_get_attribute('noc_param','T1');
	my $nl=$self->object_get_attribute('noc_param','T2');
	my @bp;
	my @hp;
	for(my $p=0; $p<$k; $p++) {push (@bp,"<p$p>$p");}
	for(my $p=$k; $p<2*$k; $p++) {push (@hp,"<p$p>$p");}
	my $bp= join("|",@bp);
	my $hp= join("|",@hp);
	my $NC= powi( $k,$nl  ); #total endpoints
	my $NL= $NC/$k ; #number of nodes in  each layer 


#add endpoints
for(my $i=0; $i<$NC; $i++){
	my $x=$i%$k;
	my $y=int($i/$k); 		

$dotfile=$dotfile."T$i\[
	label = \"T$i\"
    pos = \"$i,0!\"
    shape=house
    margin=0
	color=orange
	style=filled
	fillcolor=orange
];
";
	}

	#add roots
	for(my $pos=0; $pos<$NL; $pos++){ 
		my $x=($k)*$pos+($k/2)-0.5;	
		my $y=	1.5*($nl-1)+1;	
		my $r=$pos;
		my $lable = "\{R$r\}|\{$bp\}";
	$dotfile=$dotfile."
\"R$r\"\[
	label=\"$lable\"
    pos = \"$x,$y!\"
    shape=record
	color=blue
	style=filled
	fillcolor=blue
];	
";
	}

	#add leaves
	for(my $l=1; $l<$nl; $l++){ 
	for(my $pos=0; $pos<$NL; $pos++){ 
	my $x=($k)*$pos+($k/2)-0.5;	
	my $y=	1.5*($nl-$l-1)+1;	
	my $r=$NL*$l+$pos;
	my $lable = "\{$hp\}|\{R$r\}|\{$bp\}";
	 $dotfile=$dotfile."
\"R$r\"\[
	label=\"$lable\"
    pos = \"$x,$y!\"
    shape=record
	color=blue
	style=filled
	fillcolor=blue
];	
";
		}
	}	



	#connect all down input channels
	my $n=$nl;
	my $nPos = powi( $k, $n-1);
	my $chan_per_direction = ($k * powi( $k , $n-1 )); #up or down
	my $chan_per_level = 2*($k * powi( $k , $n-1 )); #up+down
	
	for (my $level = 0; $level<$n-1; $level++){
	    #input channel are numbered interleavely, the interleaev depends on level
	    my $routers_per_neighborhood = powi($k,$n-1-($level)); 
	    my $routers_per_branch = powi($k,$n-1-($level+1)); 
	    my $level_offset = $routers_per_neighborhood*$k;
	    for ( my $pos = 0; $pos < $nPos; ++$pos ) {
			my $neighborhood = int($pos/$routers_per_neighborhood);
			my $neighborhood_pos = $pos % $routers_per_neighborhood;
			for ( my $port = 0; $port < $k; ++$port ) {
				my $link = 
					(($level+1)*$chan_per_level - $chan_per_direction)  #which levellevel
		  			+$neighborhood*$level_offset   #region in level
		  			+$port*$routers_per_branch*$k  #sub region in region
		 			+($neighborhood_pos)%$routers_per_branch*$k  #router in subregion
		 			+($neighborhood_pos)/$routers_per_branch; #port on router
	
	#int link = (level*chan_per_level - chan_per_direction) + pos*k + port ;
				my $connect_l= int(($link+$chan_per_direction)/$chan_per_level);
				my $tmp=(($link+$chan_per_direction) % $chan_per_level);
				my $connect_pos= int($tmp/$k);
				my $connect_port= ($tmp%$k)+$k;
				my $id1=$NL*$level+$pos;
				my $connect_id=$NL*$connect_l+$connect_pos;
				$dotfile=$dotfile.node_connection('R',$id1,undef,$port,'R',$connect_id,undef,$connect_port);	
			}
	    }
	}

	#add endpoints connection
	for(my $i=0; $i<$NC; $i++){ 
		my $r= $NL*($nl-1)+int($i/$k);
		 $dotfile=$dotfile.node_connection('T',$i,undef,undef,'R',$r,undef,$i%($k));	
	
	}
	$dotfile=$dotfile."\n}\n";
	return $dotfile;
}




sub generate_tree_dot_file{
	my $self=shift;
		
	my $dotfile=
"digraph G {
	graph [rankdir = LR , splines = true, overlap = true]; 	
	node[shape=record];	
	";
		

	my $k=$self->object_get_attribute('noc_param','T1');
	my $nl=$self->object_get_attribute('noc_param','T2');
	#generate routres port interface
	my @bp;
	my @hp;
	for(my $p=0; $p<$k; $p++) {
		push (@bp,"<n$p>") if(($k%2)==0 && $p==$k/2);#if k is odd number add one empty space in the middle
		push (@bp,"<p$p>$p");
		
	}
	for(my $p=$k; $p<2*$k; $p++) {
		if($p==$k+int(($k-1)/2)){
			push (@hp,"<n$p>") if(($k%2)==0);#if k is odd number add one empty space in the middle
			push (@hp,"<p$k>$k");
		}else{
			push (@hp,"<n$p>"); 
		}
	}	
	my $bp= join("|",@bp);
	my $hp= join("|",@hp);
	my ($NE,$NR)=get_topology_info($self);
	


	#add endpoints
	for(my $i=0; $i<$NE; $i++){
		$dotfile=$dotfile."T$i\[
	label = \"T$i\"
    pos = \"$i,0!\"
    shape=house
    margin=0
	color=orange
	style=filled
	fillcolor=orange
];
";
	}

	#add roots
	my $lable = "\{R0\}|\{$bp\}";
	my $x=(($NE-1)/2);
	my $y=	1.5*($nl-1)+1;
	$dotfile=$dotfile."
\"R0\"\[
	label=\"$lable\"
    pos = \"$x,$y!\"
    shape=record
	color=blue
	style=filled
	fillcolor=blue
];	
";
	
	#add leaves
	my $t=1;
	
	for(my $l=$nl-1; $l>0; $l--){ 
		my $NL = powi($k,$l);
		$t*=$k;
		for(my $pos=0; $pos<$NL; $pos++){ 			
			my $x= 	$t*$pos + ($t-1)/2 ;
			my $y=	1.5*($nl-$l)-.5;
			my $r=sum_powi($k,$l)+$pos;
	my $lable = "\{$hp\}|\{R$r\}|\{$bp\}";
	 $dotfile=$dotfile."
\"R$r\"\[
	label=\"$lable\"
    pos = \"$x,$y!\"
    shape=record
	color=blue
	style=filled
	fillcolor=blue
];	
";
		}
	}	
	
	#add leave connections
	for(my $l=$nl-1; $l>0; $l--){ 
		my $NL = powi($k,$l);
		for(my $pos=0; $pos<$NL; $pos++){ 
			my $id1=sum_powi($k,$l)+$pos;
			my $id2=sum_powi($k,$l-1)+int($pos/$k);
			$dotfile=$dotfile.node_connection('R',$id1,undef,$k,'R',$id2,undef,$pos % $k);	
		}
	}
	
	#add endpoints connection
	for(my $i=0; $i<$NE; $i++){ 
		 my $r= sum_powi($k,$nl-1)+int($i/$k);
		 $dotfile=$dotfile.node_connection('T',$i,undef,undef,'R',$r,undef,$i%($k));	
	
	}
	
	

	$dotfile=$dotfile."\n}\n";
	return $dotfile;
}


sub get_topology_dot_file{
	my $self=shift;
	my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
	return generate_mesh_dot_file ($self) if($topology eq '"RING"' || $topology eq '"LINE"' || $topology eq '"MESH"' || $topology eq '"TORUS"' );
	return generate_fattree_dot_file ($self) if($topology eq '"FATTREE"');
	return generate_tree_dot_file($self);
}












return 1;
