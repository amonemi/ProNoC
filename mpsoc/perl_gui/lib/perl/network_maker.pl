#!/usr/bin/perl
use strict;
use warnings;
use constant::boolean;

use Cwd 'abs_path';
use base 'Class::Accessor::Fast';
require "widget.pl"; 
require "diagram.pl";
require "topology_verilog_gen.pl";

use String::Scanf; # imports sscanf()

use FindBin;
use lib $FindBin::Bin;
use tsort;

use File::Basename;
use Cwd 'abs_path';

__PACKAGE__->mk_accessors(qw{
	window
	sourceview		
});

my $NAME = 'Network_maker';
exit network_maker_main() unless caller;


sub network_maker_main {
	my $app = __PACKAGE__->new();
	
	my @parameters = (
	{param_name=> "V ", value=>2},    
    {param_name=> "B ", value=>4},    
    {param_name=> "C ", value=>2},     
    {param_name=> "Fpay ", value=>32},
    {param_name=> "MUX_TYPE", value=>'"ONE_HOT"'},    
    {param_name=> "VC_REALLOCATION_TYPE ", value=>'"NONATOMIC"'},
    {param_name=> "COMBINATION_TYPE", value=>'"COMB_NONSPEC"'},
    {param_name=> "FIRST_ARBITER_EXT_P_EN ", value=>1},  
    {param_name=> "CONGESTION_INDEX ", value=>7},
    {param_name=> "DEBUG_EN", value=>0},
    {param_name=> "AVC_ATOMIC_EN", value=>0},
    {param_name=> "ADD_PIPREG_AFTER_CROSSBAR", value=>0},
    {param_name=> "CVw", value=>"(C==0)? V : C * V"},
    {param_name=> "CLASS_SETTING ", value=>"{CVw{1\'b1}}"}, 
    {param_name=> "SSA_EN", value=>'"NO"'},
    {param_name=> "SWA_ARBITER_TYPE ", value=>'"RRA"'}, 
    {param_name=> "WEIGHTw ", value=>7},  
    {param_name=> "MIN_PCK_SIZE", value=>2},
    {param_name=> "BYTE_EN", value=>0}
); 

my @ports =(
	{name=> "flit_in_all", type=>"input", width=>"PFw", connect=>"flit_out_all",  pwidth=>"Fw", pname=> "flit_in", pconnect=>"flit_out", endp=>"yes"},
	{name=> "flit_in_wr_all", type=>"input", width=>"P", connect=>"flit_out_wr_all",  pwidth=>1, pname=> "flit_in_wr", pconnect=>"flit_out_wr",endp=>"yes"},
	{name=> "congestion_in_all", type=>"input", width=>"CONG_ALw", connect=>"congestion_out_all",  pwidth=>"CONGw", pname=> "congestion_in", pconnect=>"congestion_out",endp=>"no"},
	{name=> "credit_out_all", type=>"output", width=>"PV", connect=>"credit_in_all",  pwidth=>"V" ,pname=> "credit_out", pconnect=>"credit_in",endp=>"yes"}
);

  
  $app->object_add_attribute ('Verilog','Router_param',\@parameters);
  $app->object_add_attribute ('Verilog','Router_ports',\@ports);
 
  

	
	my $table=$app->build_network_maker_gui();
	return $table;
}


sub custom_topology_diagram {
	my $self= shift;
	
	
	
	my $table=def_table(20,20,FALSE);
	my $scrolled_win = add_widget_to_scrolled_win();	
	
	
	my ($col,$row)=(0,0);
	
	
	
	
	my $plus = def_image_button('icons/plus.png',undef,TRUE);
	my $minues = def_image_button('icons/minus.png',undef,TRUE);
	my $save = def_image_button('icons/save.png',undef,TRUE);
	my $dot_file = def_image_button('icons/add-notes.png',undef,TRUE);	
	set_tip($dot_file, "Show dot file.");
	
	my $scale=$self->object_get_attribute("tile_diagram","scale");
	$scale= 1 if (!defined $scale);	
	
	my $state=$self->object_get_attribute("tile_diagram","auto_draw");
	if (!defined $state){
		$state='ON' ;
		$self->object_add_attribute("tile_diagram","auto_draw",$state);
	}		
	my $auto= ($state eq 'ON')? def_colored_button('ON',17): def_colored_button('OFF',4);
	
	
	my $gtype=$self->object_get_attribute("tile_diagram","gtype");
	if (!defined $gtype){
		$gtype='comp' ;
		$self->object_add_attribute("tile_diagram","gtype",$gtype);
	}		
	my $graph_type= ($gtype eq 'comp')? def_colored_button('comp',17): def_colored_button('simple',4);
	
	
	
	
	
	
	$table->attach (gen_label_in_center  ("Auto Draw") ,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $row++;
	$table->attach ($auto ,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $row++;
	$table->attach ($graph_type ,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $row++;
	$table->attach ($plus ,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $row++;
	$table->attach ($minues,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $row++;
	$table->attach ($save,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $row++;
	$table->attach ($dot_file,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $row++;
	
	$table->attach_defaults ($scrolled_win, 1, 20, 0, 20); #,'fill','shrink',2,2);
	
 	($col,$row)=(1,0);
	while ($row<20){		
		my $tmp=gen_label_in_left('');
		$table->attach_defaults ($tmp, $col,  $col+1,$row,$row+1);$row++;
	}
	
	$plus  -> signal_connect("clicked" => sub{ 
		$scale*=1.1 if ($scale <10);
		$self->object_add_attribute("topology_diagram","scale", $scale );
		show_custom_topology_diagram ($self,$scrolled_win,"topology_diagram");
	});	
	$minues  -> signal_connect("clicked" => sub{ 
		$scale*=.9  if ($scale >0.1); ;
		$self->object_add_attribute("topology_diagram","scale", $scale );
		show_custom_topology_diagram ($self,$scrolled_win,"topology_diagram");
	});
	$save-> signal_connect("clicked" => sub{ 
			save_inline_diagram_as ($self);
		});	
	
	$dot_file-> signal_connect("clicked" => sub{ 
			my $dotfile = generate_custom_topology_dot_file($self);
			show_text_in_scrolled_win($self,$scrolled_win, $dotfile);		
	});
	
	
	$auto -> signal_connect("clicked" => sub{ 
			my $state=$self->object_get_attribute("tile_diagram","auto_draw");
			
			
			my $new = ($state eq "ON")? "OFF" : "ON";
			$self->object_add_attribute("tile_diagram","auto_draw",$new);	
			set_gui_status($self,"ref",1);		
		});	
	
	$graph_type-> signal_connect("clicked" => sub{ 
			my $state=$self->object_get_attribute("tile_diagram","gtype");
			
			
			my $new = ($state eq "simple")? "comp" : "simple";
			$self->object_add_attribute("tile_diagram","gtype",$new);	
			set_gui_status($self,"ref",1);		
		});	
	
	if ($state eq 'ON'){
		show_custom_topology_diagram ($self,$scrolled_win,"topology_diagram");
	}
	
	return add_widget_to_scrolled_win ($table);
	
}





sub gen_right_paned {
	my ($self,$info) =@_;
	my $page_num=$self->object_get_attribute ("process_notebook","currentpage");
	
	return route_info_window($self,$info) if($page_num==3);
	return custom_topology_diagram ($self,$info);
	
}




sub endp_node_dot_comp {
	my ($T,$instance)=@_;
	
	
	return 
	"
	$T\[
	label = \"$instance\"
    shape=house
    margin=0
	color=orange
	style=filled
	fillcolor=orange
];
";	
}

sub router_node_dot_comp{
	my ($Pnum,$R,$instance)=@_;	
	$Pnum=1 if(!defined $Pnum);
	my $label =
		($Pnum==2)? "                        \{<p1>1|$instance|<p0>0\}":
		($Pnum==3)? "\{     |<p2>2|     \} | \{<p1>1|$instance|<p0>0\} ":
		($Pnum==4)? "\{     |<p3>3|     \} | \{<p2>2|$instance|<p0>0\} | \{  <p1>1\}":
		($Pnum==5)? "\{     |<p3>3|     \} | \{<p2>2|$instance|<p4>4\} | \{ |<p1>1|<p0>0\}":
		($Pnum==6)? "\{<p3>3|<p4>4|     \} | \{<p2>2|$instance|<p5>5\} | \{ |<p1>1|<p0>0\}":
		($Pnum==7)? "\{<p4>4|<p5>5|     \} | \{<p3>3|$instance|<p6>6\} | \{<p2>2 |<p1>1|<p0>0\}":
		($Pnum==8)? "\{<p4>4|<p5>5|<p6>6\} | \{<p3>3|$instance|<p7>7\} | \{<p2>2 |<p1>1|<p0>0\}":
		($Pnum==9)? "\{<p5>5|<p6>6|<p7>7\} | \{<p4>4|$instance|<p8>8\} | \{<p3>3 |<p2>2|<p1>1|<p0>0\}":
		($Pnum==10)? "\{<p5>5|<p6>6|<p7>7|<p8>8\} | \{<p4>4|$instance|<p9>9\} | \{<p3>3 |<p2>2|<p1>1|<p0>0\}":
		($Pnum==11)? "\{<p6>6|<p7>7|<p8>8|<p9>9\}| \{<p5>5| | |<p10>10\}  | \{<p4>4|$instance| \} | \{<p3>3 |<p2>2|<p1>1|<p0>0\}":
		($Pnum==12)? "\{<p6>6|<p7>7|<p8>8|<p9>9\}| \{<p5>5| | |<p10>10\}  | \{<p4>4|$instance|<p11>11\} | \{<p3>3 |<p2>2|<p1>1|<p0>0\}":
		  "\{ |<p2>2| \} | \{<p3>3|$instance|<p1>1\} | \{ |<p4>4|<p0>0\}";	
	
	
	return 
	"$R\[
	label = \"$label\"
    shape=record
	color=blue
	style=filled
	fillcolor=blue
];
";

}

sub router_node_dot_sim{
	my ($Pnum,$R,$instance)=@_;	
	$Pnum=1 if(!defined $Pnum);
	my $label =	 "$instance";
		
	
	return 
	"$R\[
	label = \"$label\"
    shape=circle
	color=blue
	style=filled
	fillcolor=blue
];
";

}


sub endp_node_dot_sim {
	my ($T,$instance)=@_;
	
	
	return 
	"
	$T\[
	label = \"$instance\"
    shape=circle
    margin=0
	color=orange
	style=filled
	fillcolor=orange
];
";	
}












sub generate_custom_topology_dot_file{
	my $self=shift;
	
	my $gtype=$self->object_get_attribute("tile_diagram","gtype");
	$gtype = "simple" if (!defined $gtype);
		
	my $dotfile=
"digraph G {
	graph [layout = twopi, rankdir = RL , splines = true, overlap = false]; 	
	node[shape=record];	
	";	
	#Add endpoints
	my @nodes=get_list_of_all_endpoints($self);
	my $i=0;
	foreach my $p (@nodes){
		my $instance= $self->object_get_attribute("$p","NAME");
		$instance = "T$i" if(!defined $instance);
		$dotfile.= ($gtype eq 'simple')? endp_node_dot_sim($p,$instance) : endp_node_dot_comp($p,$instance);		
		$i++;
	}
	
	
	
	#add routers
	@nodes=get_list_of_all_routers($self);
	$i=0;
	foreach my $p (@nodes){
		my $instance= $self->object_get_attribute("$p","NAME");
		$instance = "R$i" if(!defined $instance);
		my $pnum=$self->object_get_attribute("$p",'PNUM');
		$dotfile.=($gtype eq 'simple')? router_node_dot_sim($pnum,$p,$instance): router_node_dot_comp($pnum,$p,$instance);	
		$i++;
	}
		
	
	#add connections
	my @all_nodes=get_list_of_all_nodes($self);
	my @draw;
	foreach my $p (@all_nodes){
   	   	my $pnum=$self->object_get_attribute("$p",'PNUM');
   	   #	my $inst=$self->object_get_attribute("$p",'NAME');
   	   	my $type = $self->object_get_attribute("$p",'TYPE');   	   
   	   	$pnum = 0 if(!defined $pnum);
   	   	for (my $i=0;$i<$pnum; $i++){ 
   	   		my $src_port = "Port[${i}]";
   	   		my $connect = $self->{$p}{'PCONNECT'}{$src_port};
			
			if (defined $connect) { 
				my $pos = get_scolar_pos($connect,@draw);
				if ( !defined $pos ){
				
				
				my ($node,$pnode)=split(/\s*,\s*/,$connect);
				# check if $node exist
				if ( defined get_scolar_pos($node, @all_nodes)){
				 
	   	   		    my ($cp)= sscanf("Port[%u]","$pnode");
	   	   		    # my $cinst=$self->object_get_attribute("$node",'NAME');
	   	   		    my $ctype = $self->object_get_attribute("$node",'TYPE');
	   	   		  
	   	   		  
	   	   		  
	   	   		  	my ($t2, $t1);
	   	   		  	
	   	   		  	if ($gtype eq 'simple'){
	   	   		  		$t2 =  "\"$p\""; 
	   	   		  		$t1 =  "\"$node\"";
	   	   		  	} else {
	   	   		  		$t2 = ($type eq "ENDP" )? "\"$p\"" : "\"$p\" : \"p$i\"";
	   	   		  	    $t1 = ($ctype eq "ENDP" )? "\"$node\"" : "\"$node\" : \"p$cp\"";
	   	   		  		
	   	   		  	}
	   	   			my $t= "$t1 -> $t2 [ dir=none];\n"; 
	   	   			$dotfile=$dotfile."$t";
				}
   	   			push(@draw,$connect);
   	   			push(@draw,"$p,$src_port");
   	   			#print "@draw\n";
   	   		}
   	   		
	
   	   	}}
	}
	$dotfile=$dotfile."\n}\n";
	#print  $dotfile;
	return $dotfile;
}

sub get_connection_port_num_between_two_nodes{
	my ($self,$n1,$n2)=@_;
	my $PNUM=$self->object_get_attribute($n1,"PNUM");
	
	for (my $p1=0; $p1<$PNUM; $p1++){
		my $connect=$self->{$n1}{"PCONNECT"}{"Port[$p1]"};
		next if(!defined $connect);
		my ($node,$pnode)=split(/\s*,\s*/,$connect);
		my ($p2)= sscanf("Port[%u]","$pnode");
		return ($p1,$p2) if($node eq $n2 );		
	}
	return undef;
}


sub show_custom_topology_diagram {
	my ($self,$scrolled_win, $name)=@_;
	
	my $state=$self->object_get_attribute("tile_diagram","auto_draw");
	if( $state eq "ON") {
		my $dotfile = generate_custom_topology_dot_file($self);
		generate_and_show_graph_using_graphviz($self,$scrolled_win,$dotfile,$name);
	}
	else {
		my @list = $scrolled_win->get_children();
		foreach my $l (@list){ 
			$scrolled_win->remove($l);			
		}
	}
	
	return;
}





sub take_node_num_page{
	my ($self)=@_;		
	my $table= def_table(2,10,FALSE);
	my $row=0;
	my $col=4;
	$table->attach (def_label('Network Element'),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col+=2;
	$table->attach (def_label('Number'),$col,$col+1,$row,$row+1,'fill','shrink',2,2);
	$row++;$col=0;
	
	$table->attach (def_icon('icons/e.png'),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
	($row,$col)=add_param_widget ($self,"# Endpoints","NUM", 0,'Spin-button','0,1024,1',undef, $table,$row,$col,1,'ENDP',10,'redraw');$col=0;
	for ( my $i=2;$i<=12; $i++){
		$table->attach (def_icon('icons/r.png'),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col++;
		($row,$col)=add_param_widget ($self,"# $i-Port Routers","NUM", 0,'Spin-button','0,1024,1',undef, $table,$row,$col,1,"ROUTER${i}",10,'redraw');$col=0;		
	}	
	return $table;
}



sub take_instance_page{
	my ($self)=@_;		
	my $table= def_table(2,10,FALSE);
	
	initial_node_info($self);
	
	my $row=0;
	my $col=0;
	
	
	$table->attach (def_label(' Network Element '),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col+=2;
	$table->attach (def_label(' Instance name '),$col,$col+1,$row,$row+1,'fill','shrink',2,2);
	$row++;$col=0;
	
	
	my $EN= $self->object_get_attribute('ENDP','NUM');
	$EN = 0 if(!defined $EN);
	for (my $i=0;$i<$EN; $i++){	
		
		 my $d=get_default_instance_name($self,"ENDP_$i");	                            
		($row,$col)=add_param_widget ($self,"Endpoint $i","NAME",$d ,'Entry',undef,"router instance name", $table,$row,$col,1,"ENDP_$i",10,'redraw');$col=0;
		
	}	
	
	#routers
	my $Rnum=0;
	for ( my $i=2;$i<=12; $i++){
		my $n= $self->object_get_attribute("ROUTER${i}","NUM");
		$n=0 if(!defined $n);
		 for ( my $j=0;$j<$n; $j++){
		 	my $d=get_default_instance_name($self,"ROUTER${i}_$j");
		 	($row,$col)=add_param_widget ($self,"Router $Rnum","NAME", "$d",'Entry',undef,"router instance name", $table,$row,$col,1,"ROUTER${i}_$j",10,'redraw');$col=0;
					 
			 $Rnum++;
		 }
	}	
	return $table;
	
}

sub initial_node_info {
	my ($self)=@_;		
	
	my $EN= $self->object_get_attribute('ENDP','NUM');
	$EN = 0 if(!defined $EN);
	for (my $i=0;$i<$EN; $i++){	
		 $self->object_add_attribute("ENDP_$i",'PNUM',1);
		 $self->object_add_attribute("ENDP_$i",'TYPE',"ENDP");
		 my $inst=$self->object_get_attribute("ENDP_$i",'NAME');
		 if(!defined $inst){
		 	$inst=get_default_instance_name ($self,"ENDP_$i");
		 	$self->object_add_attribute("ENDP_$i",'NAME',$inst);
		 }
	}	
	
	#routers
	my $Rnum=0;
	for ( my $i=2;$i<=12; $i++){
		my $n= $self->object_get_attribute("ROUTER${i}","NUM");
		$n=0 if(!defined $n);
		 for ( my $j=0;$j<$n; $j++){
		 	 $self->object_add_attribute("ROUTER${i}_$j",'PNUM',${i});
			 $self->object_add_attribute("ROUTER${i}_$j",'RNUM',$Rnum);
			 $self->object_add_attribute("ROUTER${i}_$j",'TYPE',"ROUTER");
			 my $inst=$self->object_get_attribute("ROUTER${i}_$j",'NAME');
			 if(!defined $inst){
			 	$inst=get_default_instance_name ($self,"ROUTER${i}_$j");
			 	$self->object_add_attribute("ROUTER${i}_$j",'NAME',$inst);
			 }
		 	 $Rnum++;
		 }
	}	
	
}




sub get_default_instance_name {
	my ($self,$name)=@_;
	my $type = $self->object_get_attribute($name,'TYPE');
	my @nodes =($type eq 'ENDP')? get_list_of_all_endpoints($self):get_list_of_all_routers($self);
		
	my @R=("--");
	foreach my $p (@nodes){
		my $n= $self->object_get_attribute("$p","NAME");
		push( @R, $n) if(defined $n);			
	}	
	
	my $i=0;
	my $inst = 	($type eq 'ENDP')? "T$i": "R$i";
	my $pos= get_scolar_pos($inst,@R);
	while (defined $pos){
		$i++;	
		$inst = 	($type eq 'ENDP')? "T$i": "R$i";
		$pos= get_scolar_pos($inst,@R);				
	}
		
	
	return 	$inst;	
}	
	
	


sub get_list_of_all_routers {
	my ($self)=@_;	
	my @R;
	for ( my $i=2;$i<=12; $i++){
		 my $n= $self->object_get_attribute("ROUTER${i}","NUM");
		 $n=0 if(!defined $n);
		 for ( my $j=0;$j<$n; $j++){
		 	push( @R, "ROUTER${i}_$j");		 	
		 }
	}	
	return @R;
}

sub get_list_of_all_endpoints {
	my ($self)=@_;	
	my @E;
	my $EN= $self->object_get_attribute('ENDP','NUM');
	$EN = 0 if(!defined $EN);
	for (my $i=0;$i<$EN; $i++){	
		push( @E, "ENDP_$i");		
	}
	return @E;
}

sub get_list_of_all_nodes {
	my ($self)=@_;	
	my @R=get_list_of_all_routers($self);
    my @E=get_list_of_all_endpoints($self);
    my @all_nodes= (@E,@R);
	return @all_nodes;
}	

sub remove_connected_port{
	my ($self,$node,$port,$info)=@_;
	my @all_nodes=get_list_of_all_nodes($self);
	foreach my $p (@all_nodes){
   	   	my $pnum=$self->object_get_attribute("$p",'PNUM');
   	   	my $inst=$self->object_get_attribute("$p",'NAME');
   	   
   	   	$pnum = 0 if(!defined $pnum);
   	   	for (my $i=0;$i<$pnum; $i++){ 
   	   		my $src_port = "Port[${i}]";
   	   		if(defined $self->{$p}{'PCONNECT'}{$src_port}){ if ($self->{$p}{'PCONNECT'}{$src_port} eq "$node,$port"){
   	   			delete $self->{$p}{'PCONNECT'}{$src_port};
   	   			my $con_inst=$self->object_get_attribute("$node",'NAME');
   	   			add_info($info,"** $inst  $src_port is disconnected from $con_inst $port \n") if (defined $info);
   	   		
   	   		}}
   	   	} 
	}	   	 	
}	


sub get_instance_to_node_name {
	my $self=shift;
	my @all_nodes=get_list_of_all_nodes($self);
    my %par;
    foreach my $p (@all_nodes){
   	   	my $inst=$self->object_get_attribute("$p",'NAME');
   	   	$par{$inst}= $p;
    }
    return %par;	
}


##############
#	create_tree 
##############
sub create_tree_view {
   my ($self,$source,$src_port,$info)=@_;  
   my $window = def_popwin_size(30,85,"Select Connection Element and Port",'percent');
     

   my ($model,$tree_view,$column) =create_tree_model_network_maker();
      
   my @all_nodes=get_list_of_all_nodes($self);
 
   unshift(@all_nodes,"-");
   my %par;
 
   foreach my $p (@all_nodes){
   	    my @childs;
   	   	my $pnum=$self->object_get_attribute("$p",'PNUM');
   	   	my $inst=$self->object_get_attribute("$p",'NAME');
   	   	
   	   	$pnum = 0 if(!defined $pnum);
   	   	$inst = "-" if(!defined $inst);
   	   	
   	   	$par{$inst}= $p;
   	   	for (my $i=0;$i<$pnum; $i++){ 
   	   		#donot add the source port itself to connection list
   	   		if(($source ne $p)|| ($src_port ne "Port[${i}]")){
   				push(@childs, "Port[${i}]");
   	   		}
   	   	}  	
		my $iter = $model->append (undef);
	    $model->set ($iter, 0, $inst, 1, $inst || '', 2, 0 || '', 3,   FALSE);
		foreach my $v ( @childs){
			 my $child_iter = $model->append ($iter);
			 $model->set ($child_iter, 0, $v, 1, $inst|| '', 2, $v || '', 3,   FALSE);
		}	
   }
	
  
   $tree_view->append_column ($column);
   
   
   
   $tree_view->signal_connect (row_activated => sub{

		my ($tree_view, $path, $column) = @_;
		my $model = $tree_view->get_model;
		my $iter = $model->get_iter ($path);
		my $parent = $model->get ($iter, 1);
		my $child = $model->get ($iter, 2);
		
		if ($child){ 
			   	my $node=$par{$parent};
			   	connect_nodes ($self,$node,$child,$source,$src_port,$info);
		  		
		  		
		  		
		  
		  		set_gui_status($self,'ref',1);		
		  		$window->destroy;
		  		
				#add parent child
			}
		elsif($parent ){
			
			my $node=$par{$parent};
			if ($node eq "-"){
				remove_connected_port($self,$source,$src_port);
				delete $self->{$source}{'PCONNECT'}{$src_port};
			}
			
			
			
			set_gui_status($self,'ref',1);		
		  	$window->destroy;
		  		
			
		}
	
  
	#add parent child

	});

  #$tree_view->expand_all;

  my $scrolled_window = add_widget_to_scrolled_win($tree_view);

  my $hbox = def_hbox (FALSE, 0);
  $hbox->pack_start ( $scrolled_window, TRUE, TRUE, 0);
  $window ->add($hbox);
  $window->show_all;
}

sub connect_nodes {
	my ($self,$node1,$src_port1,$node2,$src_port2,$info)=@_;
	
		
		
	#add_colored_info($info,"$node1,$src_port1,$node2,$src_port2;\n","red") if (defined $info);	
	
	#check if the selected port has been connected to another port before and remove the connection
	remove_connected_port($self,$node1,$src_port1,$info);
	remove_connected_port($self,$node2,$src_port2,$info);
		  		
	$self->{$node1}{'PCONNECT'}{$src_port1}="$node2,$src_port2";
	$self->{$node2}{'PCONNECT'}{$src_port2}="$node1,$src_port1";
	
}

sub remove_all_connection {
	my ($self)=@_;
	my @all_nodes=get_list_of_all_nodes($self);
	foreach  my $node  (@all_nodes ){
		$self->{$node}{'PCONNECT'}=undef;	
	}	
	set_gui_status($self,"ref",1);
}

sub list_node_all_port{
	my ($self,$node)=@_;
	my @l;
	my $pnum =  $self->object_get_attribute($node,'PNUM');
	for (my $i=0;$i<$pnum; $i++){
		push(@l,"Port[${i}]");
	}
	return @l;
}



sub list_node_connected_port {
	my ($self,$node)=@_;
	my $r = $self->{$node}{'PCONNECT'};
	my %c =(defined $r)? %{$r} : undef;
	return sort keys %c;
}

sub list_node_unconnected_port {
	my ($self,$node)=@_;
	my @p = list_node_all_port($self,$node);
	my @cp = list_node_connected_port ($self,$node);
	#@p - @cp;
    my @np =get_diff_array(\@p,\@cp);
	return @np;
}


sub connection_page{
	my ($self,$info)=@_;		
	my $table= def_table(2,10,FALSE);
	my $row=0;
	my $col=0;
	
	initial_node_info($self);
	
	
	
	my $eq = def_table(1,8,TRUE);
	
	my $label = gen_label_help("Eg: R[i]P[0]->T[i]P[0];i[0,10,1]","Equation:");
	my $entry = gen_entry();
	my $open= def_image_button("icons/enter.png",undef,TRUE);
	$eq->attach ($label,0,2,  $row, $row+1,'fill','fill',2,2);
	$eq->attach_defaults ($entry,2, 9,  $row, $row+1);
	$eq->attach ($open,9, 10,  $row, $row+1,'fill','shrink',2,2);
	$table->attach ($eq,0, 20,  $row, $row+1,'expand','fill',2,2);$row++;	
	
	$open->signal_connect("clicked" => sub {
				evaluate_eqation($self,$entry->get_text(),$info);
				
	});
	
	$row++;
	
	
	
	add_Hsep_to_table($table,0, 20,  $row);$row++;	
	my $savr=$row;$row++;	
	
	my $maxp=1;	
	
	my @all_nodes=get_list_of_all_nodes($self);
		
	foreach  my $p  (@all_nodes ){	
		my $inst=$self->object_get_attribute("$p",'NAME');
		my $pnum=$self->object_get_attribute("$p",'PNUM');
   	   	$maxp=	$pnum if($pnum > $maxp );  	   		
   	   
   	   	
   	   	
		my $label =gen_label_in_left("$inst:");
		attach_widget_to_table ($table,$row,undef,undef,$label,$col);  $col+=4;
		
		for (my $i=0;$i<$pnum; $i++){ 
			my $pname= "Port[${i}]";
			my $connect = $self->{$p}{'PCONNECT'}{$pname};
			my $button =  def_button(" -> ");
			if (defined $connect) { 
				my ($node,$pnode)=split(/\s*,\s*/,$connect);
		    	my $e=$self->object_get_attribute("$node",'NAME');
				$button = def_button("$e->$pnode") if(defined $e);
			}
			$button->signal_connect("clicked" => sub {
				create_tree_view($self,$p,$pname,$info);
				
			});
			attach_widget_to_table ($table,$row,undef,undef,$button,$col);  $col+=4;
		}   
		$col=0;
			                            
		#($row,$col)=add_param_widget ($self,"$instance","CNNT", undef,"Combo-box",$list,"router instance name", $table,$row,$col,1,"ENDP_$i",1,'ref','horizontal');
		# my $connect_r= $self->object_get_attribute("ENDP_$i","CNNT");
		# if( defined $connect_r){
		# 	print "cponnection is $R{$connect_r}\n";
		# 	my $conr= $R{$connect_r};
		# 	my $p=0;
		# 	($row,$col)=add_param_widget ($self,"P$p","P_$p", undef,"Combo-box",$list,undef, $table,$row,$col,1,"ENDP_$i",1,'ref','horizontal');
		 	
		 	
		 	
		# }
		 $row++;$col=0;
		
	}	
	
	#routers
    for ( my $i=2;$i<=12; $i++){
		 my $n= $self->object_get_attribute("ROUTER${i}","NUM");
		 $n=0 if(!defined $n);
		 for ( my $j=0;$j<$n; $j++){
			my $pnum=	 $self->object_get_attribute("ROUTER${i}_$j",'PNUM');
			 for ( my $p=0;$p<$pnum; $p++){
			 	#	($row,$col)=add_param_widget ($self,"P$p","P_$p", undef,"Combo-box",$list,undef, $table,$row,$col,1,"ROUTER${i}_$j",1,'ref','horizontal');
		 	
			 }
			  $row++;$col=0;
			
		 }
	}	
	
	
	
	
	#add lables
	$row=$savr;$col=0;
	$table->attach (def_label(' Network Element '),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col+=4;
	for (my $i=0;$i<$maxp; $i++){ 
		$table->attach (def_label(" P$i "),$col,$col+1,$row,$row+1,'fill','shrink',2,2);$col+=4;
		
	}
	return $table;
	
}


sub evaluate_eqation{
	my ($self,$exp,$info)=@_;

	my @str=split /;/, $exp; 
	my $eq_exp;
	
	my $f=0;
	my %vname;
	my %vars;
	
	my %nodes_name=get_instance_to_node_name($self);
	
	foreach my $p (@str) {
		
		if($f==0){
			$eq_exp= $p;
					
		}	
		else{
			my ($v, $start, $end, $step) = sscanf("%s[%d,%d,%d]", $p);
			print "($v, $start, $end, $step)\n";
			my @a;
			for (my $i=$start; $i<$end;$i++){
				push (@a,$i);
			} 
			$vars{$f}=\@a;
			$vname{$f}=$v;
			
		}
		$f++;
	
	}
	
	
	my %vars2;
	my $v1=$vname{1};
	foreach my $i (@{$vars{1}}){
		$vars2{$v1}=$i;
		my $v2=$vname{2};
		if (defined $v2) {
			foreach my $j (@{$vars{2}}){
				$vars2{$v2}=$j;
				my $v3=$vname{3};
				if (defined $v3) {
					foreach my $k (@{$vars{3}}){
						$vars2{$v3}=$k;
						eval_exp($self,$eq_exp,\%vars2,\%nodes_name,$info);	
					}
						
				}
				else {eval_exp($self,$eq_exp,\%vars2,\%nodes_name,$info)};	
			
			
			}
		}
		else {eval_exp($self,$eq_exp,\%vars2,\%nodes_name,$info)};	
		
	}

set_gui_status($self,'ref',1);	
}




sub eval_exp {
	my ($self,$exp,$ref,$ref2,$info)=@_;
	my  %vars = %{$ref};
	my %nodes_name =%{$ref2};
    foreach my $p (sort keys %vars){
    	
    	chomp $exp;    	
		($exp=$exp)=~ s/\b$p\b/$vars{$p}/g; 
    	   	
    	
    }
    
    my ($s1, $n1, $p1,$s2, $n2, $p2 ) = sscanf("%s[%s]P[%s]->%s[%s]P[%s]", $exp);


$n1 = eval $n1;
$p1 = eval $p1;

$n2 = eval $n2;
$p2 = eval $p2;


my $string= "$s1 [$n1] P [$p1] -> $s2 [$n2] P [$p2]\n";

my $node1=$nodes_name{$s1.$n1};
my $node2=$nodes_name{$s2.$n2};

if(!defined $node1 ){
		add_colored_info($info,"No instance is named as \"$s1$n1\";\n","red") if (defined $info);
		return;
	}
	if( !defined $node2 ){
		add_colored_info($info,"No instance is named as \"$s2$n2\";\n","red") if (defined $info);
		return;
	}	


 connect_nodes ($self,$node1,"Port[$p1]",$node2,"Port[$p2]",$info);


add_info($info,"$string") if (defined $info);

		
}	
	
###########
# connection_page_auto
##########	
	
sub connection_page_auto{
	my ($self,$info)=@_;		
	my $table= def_table(2,10,FALSE);
	my $row=0;
	my $col=0;
	
	initial_node_info($self);
	
	my $help1 =  "Define the minimum number of endpoints that can be connected to a single router. Routers in the topology will have either at least a minum endpoint number or they will have no endpoints at all.";
	my $help2 =  "Define the manimum number of endpoints that can be connected to a single router."; 
	my $help3 =  undef; 
	
	
	
	my @widgets = (
	{ label=>"Minimum Endp per Router",        param_name=>'MIN_ENDP_PER_ROUTER',   type=>"Spin-button",     default_val=>1, content=>"1,1024,1", info=>$help1, param_parent=>'connection_auto', ref_delay=> undef},
	{ label=>"Maximum Endp per Router",        param_name=>'MAX_ENDP_PER_ROUTER',   type=>"Spin-button",     default_val=>1, content=>"1,1024,1", info=>$help2, param_parent=>'connection_auto', ref_delay=> undef},
	{ label=>"Endp per Router distribution",   param_name=>'ENDP_PER_ROUTER_DIST',   type=>"Combo-box",     default_val=>"uniform", content=>"uniform,random", info=>$help3, param_parent=>'connection_auto', ref_delay=> undef},
	{ label=>"Topology Dimention",             param_name=>'DIMENTION',   type=>"Combo-box",     default_val=>"2D", content=>"2D,3D", info=>undef, param_parent=>'connection_auto', ref_delay=> undef},
	
		);	
	
	

	foreach my $d (@widgets) {
		my $w;
		($row,$col,$w)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay},undef,"vertical");
		
	}#foreach
	
	
	
	
	my $auto = def_image_button('icons/gen.png','Auto Connect');
	$table->attach ($auto,1, 2,  $row, $row+1,'fill','fill',2,2);
	$auto-> signal_connect("clicked" => sub{
			auto_connect($self,$info);	
	});
	
	my $clean = def_image_button('icons/clear.png','Remove All Connection');
	$table->attach ($clean,0,1 ,  $row, $row+1,'fill','fill',2,2);
	$clean-> signal_connect("clicked" => sub{
			remove_all_connection($self); 
	});
	
	
	
	return $table;	
}

sub get_new_val_based_on_dist {
	my ($total_router,$total_endp, $router_Pnum,$min_endp,$max_endp,$dist_endp)=@_;

	if($dist_endp eq "uniform"){
		my $a = int($total_endp/$total_router);
		return $a if($a >= $min_endp && $a <$router_Pnum ); 
		return $min_endp if($a < $min_endp  );       
		return $router_Pnum -1 if($a >= $router_Pnum ) ;                                
	}		
	#random distribution	
	my $a = int(rand($max_endp - $min_endp +1)) + $min_endp;
	return $a if($a >= $min_endp && $a <$router_Pnum ); 
	return $min_endp if($a < $min_endp  );       
	return $router_Pnum -1 if($a >= $router_Pnum) ;	
}


sub assign_endp_num_based_on_dist {
	my ($self,$routers_ref,$total_endp, $min_endp,$max_endp,$dist_endp,$info)=@_;
	my @routers = @{$routers_ref};
	my %assigned;
	my $total_router = scalar @routers;
	my $valid=1;
	while ($total_endp > 0 && $valid ==1){
		$valid =0;
		foreach my $r (reverse @routers) {
			my $router_Pnum=$self->object_get_attribute("$r",'PNUM');
			my $val  = $assigned{$r};
			if (!defined $val) {
				$val=0;
				$assigned{$r}=0;
			}
			if ($min_endp >=$router_Pnum || $total_endp ==0 ){
				
			} else{      
		    	my $new =get_new_val_based_on_dist ($total_router,$total_endp, $router_Pnum,$min_endp,$max_endp,$dist_endp);
				$new =$val + $total_endp  if(($new - $val) > $total_endp);
				if  ($new<$min_endp){
					
				}
				elsif ($new > $val){
					$assigned{$r} = $new;
					$total_endp-=($new - $val);
					$valid = 1;				
				} elsif ($val < $router_Pnum-2 && $val +1 <=$max_endp ){
					$assigned{$r} = $val +1;
					$total_endp-=1;
					$valid = 1;				
				}
			}#else
		}#for		
		
	}#while
	  
	if ($total_endp > 0) {
		add_colored_info($info, "Error: Unable to assign all endpoits to routers using requested configuration. Total of $total_endp endpoints left unconnected\n",'red');
		return (\%assigned,0);
	}
	
	return (\%assigned,1);

}

#list the manhatan distance of all nodes in dimention ($xd,$yd,$zd) to the node located in ($xm,$ym,$zm)
sub list_manhatan_distance {
	my ($xd,$yd,$zd,$xm,$ym,$zm)=@_;
	my %manhatan;
	for( my $x=0; $x<$xd;$x++){
		for( my $y=0; $y<$yd;$y++){
			for( my $z=0; $z<$zd;$z++){
				$manhatan{"$x,$y,$z"} = abs($x-$xm) + abs($y-$ym) + abs($z-$zm);
			}
		}
	} 
	return %manhatan;
}



sub auto_connect {
	my ($self,$info)=@_;
	show_colored_info($info, "Start auto connecting Nodes\n",'blue');
	add_info($info, "Step 1: Connect endpoints to the routers:\n");
	
	                                     
	my $min_endp  = $self->object_get_attribute('connection_auto','MIN_ENDP_PER_ROUTER');                     
	my $max_endp  = $self->object_get_attribute('connection_auto','MAX_ENDP_PER_ROUTER');    
	my $dist_endp = $self->object_get_attribute('connection_auto','ENDP_PER_ROUTER_DIST');
	my $dimention = $self->object_get_attribute('connection_auto','DIMENTION');
	
	 
	#check min and max is correct
	if($min_endp > $max_endp ){
		add_colored_info($info, "Error: Invalid Min & Max range for endpoint router numbr per router. MAX_ENDP_PER_ROUTER shuld >= MIN_ENDP_PER_ROUTER\n",'red');
	}                                     
	
	initial_node_info($self);
	
	my @all_endpoints=get_list_of_all_endpoints($self);
	my @routers=get_list_of_all_routers($self);
	
	#connect endpoints
	my ($ref,$result)  = assign_endp_num_based_on_dist ($self,\@routers,scalar @all_endpoints, $min_endp,$max_endp,$dist_endp,$info);
	my %assign = %{$ref};
	my %router_free_port;
	foreach my $r (reverse @routers) {		
		$router_free_port{$r}=$self->object_get_attribute("$r",'PNUM');
		my $num = $assign{$r};
		for (my $p=0; $p<$num;$p++){
			my $e = pop (@all_endpoints);
			connect_nodes ($self,$r,"Port[$p]",$e,"Port[0]",$info);
			my $rinst=$self->object_get_attribute("$r",'NAME');
			my $einst=$self->object_get_attribute("$e",'NAME');
			add_info($info,"\t connect $rinst-Port[$p] -> $einst-Port[0]\n",$info);
			$router_free_port{$r}=$router_free_port{$r}-1;
		}		
	}
	
	#get dimention 
	my $routers_num =scalar @routers;
	my ($xd,$yd,$zd)=(1,1,1);
	($xd,$yd)= network_dim_cal ($routers_num) if ($dimention eq '2D');
	($xd,$yd,$zd)=network_3dim_cal ($routers_num) if ($dimention eq '3D');
	add_info($info, "Step 2: Map $routers_num routers in (x=$xd , y=$yd , z=$zd) dimention. Routers with higher number of free ports located in center:\n");
	
	#obtain routers location 
	#center loc
	my $xmid =int($xd/2); 
	my $ymid =int($yd/2);
	my $zmid =int($zd/2);
	
	#sort location based on manhatan distanc from the center
	my %manhatan = list_manhatan_distance ($xd,$yd,$zd,$xmid,$ymid,$zmid);
	my @sort_locs = (sort { $manhatan{$a} <=> $manhatan{$b} } keys %manhatan);
	
	#sort routers based on avilable ports
	my @sort_routers = (sort { $router_free_port{$b} <=> $router_free_port{$a} } keys %router_free_port);
	
	#assign sorted routers to sorted locations 
	my %locations;
	foreach my $r (@sort_routers){
    	my $loc = shift @sort_locs;
    	my $inst=$self->object_get_attribute("$r",'NAME');
    	add_info($info, "\t $inst with $router_free_port{$r} free port placed in $loc location\n");
    	$self->object_add_attribute("$r",'LOC_ASIC',$loc);
    	$locations{$loc}=$r;    	
	}
	
	#start from the center and connect each router to the N nearest router
	add_info($info,"Step3 : start from the center and connect each router to the N nearest router\n",$info);
	foreach my $r (@sort_routers){
		
		my $avb_P_num =$router_free_port{$r};
		my @up = list_node_unconnected_port($self,$r);
		my @cp = list_node_connected_port ($self,$r);
		my $loc = $self->object_get_attribute("$r",'LOC_ASIC');
		my ($xc,$yc,$zc)=split(',',$loc);
		my %manhatan = list_manhatan_distance ($xd,$yd,$zd,$xc,$yc,$zc);
		my @sort_locs = (sort { $manhatan{$a} <=> $manhatan{$b} } keys %manhatan);
		
		while (scalar @up && scalar @sort_locs){
			#select one unconnected port from current router
			my $p = shift @up;
			my $cr;
			my $cp;
			while (scalar @sort_locs && !defined $cp){			
				#select the nearest router to current one
				my $cl =shift @sort_locs;
				$cr=$locations{$cl};
				next if(!defined $cr);
				next if ($cr eq $r); #thes two routers are identical
				#check if they are not connected
				my $line =get_connection_port_num_between_two_nodes($self,$r,$cr);
				next if (defined $line); #these two routers are already connected
				my @up_cr = list_node_unconnected_port($self,$cr);	
				next if (scalar @up_cr == 0); # the target router has no free port
				$cp=$up_cr[0];
			}
			last if(!defined $cp);
			my $rinst=$self->object_get_attribute("$r",'NAME');
			my $einst=$self->object_get_attribute("$cr",'NAME');
			add_info($info,"\t connect $rinst-$p -> $einst-$cp\n",$info);
			connect_nodes ($self,$r,"$p",$cr,"$cp",$info);
		}	
		
	}	
	
	
	
	
	
	
	set_gui_status($self,"ref",1);
	
	  
	
	
	
}

sub routing_page_auto{
	my ($self,$info)=@_;		
	my $table= def_table(2,10,FALSE);
	my $row=0;
	my $col=0;
	
	
	$self->object_add_attribute('routing','type','turn_model');
	
	
	
	my $auto = def_image_button('icons/gen.png','AutoGenerate');
	#$table->attach ($auto,0, 1,  $row, $row+1,'fill','fill',2,2);
	my $clear = def_image_button('icons/clear.png','Clear');
	#$table->attach ($clear,2,3 ,  $row, $row+1,'fill','fill',2,2);$row++;
	
	my $box= def_pack_hbox( FALSE, 0 , $auto,$clear);
	$table->attach ($box,0,5 ,  $row, $row+1,'fill','fill',2,2);$row++;
	
	$auto-> signal_connect("clicked" => sub{
			auto_route($self,$info);	
	});
	
	$clear-> signal_connect("clicked" => sub{
			clean_route($self,$info);	
	});
	
	my $manual = get_route_manual ($self,$info);
	
	my $mtable= def_table(2,2,FALSE);
	
	$mtable->attach_defaults ($table  , 0, 1, 0,1);
	$mtable->attach_defaults ($manual  , 0, 1, 1,2);
	
	return $mtable;
}

sub update_acycle_model {
	my ($self,$alg_name,$info)=@_; 
	my $tmp_dir  = "$ENV{'PRONOC_WORK'}/tmp";
	my $model_file = "$tmp_dir/$alg_name.alg";	
	my ($pp,$r,$err) = regen_object($model_file);
	if ($r){        
		add_colored_info($info,"**Error: cannot open $model_file file: $err\n",'red');
		$self->object_add_attribute('routing_auto','acyclic_turns_model',undef);
		return;
	} else {
		add_info($info,"Use $alg_name algorithm for obtaing acyclic paths\n");
	}

	my @acyclic_turns = @{$pp};			
	$self->object_add_attribute('routing_auto','acyclic_turns_model',\@acyclic_turns);
			
}			


sub routing_page_manual{
	my ($self,$info)=@_;		
	my $table= def_table(2,10,FALSE);
	my $row=0;
	my $col=0;
	
	$self->object_add_attribute('routing','type','minimal');
	
	initial_node_info($self);
	my $help1 =  "Define the offset path value that is the maximum difference between the lentght of all paths which are extracted for any specefic source-destination endpoints pair. Define this valuse as zero for Minimal-path (MIN) routing algorithms.";  
	my $help2 =  "Define the maximum number of routers (path length) paths which should be extracted for any specefic source-destination endpoints pair."; 
	my $help3 =  "Define how to extract paths between two endpoints: all-paths: extract all paths between two specific endpoints that match the offset size and maximum size parameters. Cycle-free: only paths which do not generate a cyclic dependency in routing graph are extracted.";
	
	
	my @widgets = (
	{ label=>"Route path offset size ",        param_name=>'OFFSET',   type=>"Spin-button",     default_val=>1, content=>"0,1024,1", info=>$help1, param_parent=>'routing_auto', ref_delay=>"1",ref_state=> undef},
	{ label=>"Route path maximum size",        param_name=>'MAX_LENGTH',   type=>"Spin-button",     default_val=>1000, content=>"1,1024,1", info=>$help2, param_parent=>'routing_auto', ref_delay=>"1",ref_state=> undef},
	{ label=>"Route paths select",        param_name=>'PATH_SELECT',   type=>"Combo-box",     default_val=>"Cycle-free paths", content=>"all-paths,Cycle-free paths", info=>$help3, param_parent=>'routing_auto', ref_delay=>"1",ref_state=> undef },
	
	);	
	
		
	foreach my $d (@widgets) {
		my $w;
		($row,$col,$w)=add_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,$col,1, $d->{param_parent}, $d->{ref_delay},$d->{ref_state},"vertical");
		
	}#foreach
	my $offset = $self->object_get_attribute('routing_auto','OFFSET');
	my $max_len = $self->object_get_attribute('routing_auto','MAX_LENGTH');	
	
	my $auto = def_image_button('icons/gen.png','AutoGenerate');
	
	my $path_select= $self->object_get_attribute("routing_auto",'PATH_SELECT');
	if($path_select eq "Cycle-free paths") {
		my %algorithms;
		my $ref  =$self->object_get_attribute('routing_auto','acyclic_algorithms');
		%algorithms = %{$ref} if defined $ref;
		my @algs = sort { $algorithms{$a} <=> $algorithms{$b} } keys(%algorithms);
		my ($content,$default);
		foreach my $alg (@algs){
			$content.="$alg  --  $algorithms{$alg},";
			$default= "$alg  --  $algorithms{$alg};";
						
		}
		if (!defined $content){
			$content='-';
			$default='-';
			
		}
		
		my $alg;
		($row,$col,$alg)=add_param_widget ($self,"cycle-remove algorithm:" , "CYCLE_FREE_ALG",$default , "Combo-box", $content, undef, $table,$row,$col,1,'routing_auto', undef,undef,"vertical");
		
		$alg->signal_connect("changed" => sub{
			my $comb_text = $alg->get_active_text();
			my ($alg_name,$line) = split (/\s+--\s+/,$comb_text);
			update_acycle_model ($self,$alg_name,$info);
			#print "bbbb:@acyclic_turns\n";	
		});
		
		$auto-> signal_connect("clicked" => sub{
			auto_route($self,$info);	
		});
		
		
	}
	
	
	
	
	my $clear = def_image_button('icons/clear.png','Clear');
	my $gen_cycle_free = def_image_button('icons/turn.png','Generate Cycle-free Paths');
	
	if($path_select eq 'Cycle-free paths') {
		$table->attach ($gen_cycle_free,0,2 ,  $row, $row+1,'fill','fill',2,2);$row++;
		$table->attach ($auto,2, 3,  $row, $row+1,'fill','fill',2,2);
		
	}
	$table->attach ($clear,0,2 ,  $row, $row+1,'fill','fill',2,2);$row++;		
	
	
	$clear-> signal_connect("clicked" => sub{
			clean_route($self,$info);	
	});
	
	$gen_cycle_free -> signal_connect("clicked" => sub{
			gen_aciclic_turn_graph($self,$info);
			my %algorithms;
			my $ref  =$self->object_get_attribute('routing_auto','acyclic_algorithms');
			%algorithms = %{$ref} if defined $ref;
			my @algs = sort { $algorithms{$a} <=> $algorithms{$b} } keys(%algorithms);
			update_acycle_model ($self,$algs[0],$info);
			set_gui_status($self,'ref',1);		
	});
	
	my $manual = get_route_manual ($self,$info);
	
	my $mtable= def_table(2,2,FALSE);
	
	$mtable->attach_defaults ($table  , 0, 1, 0,1);
	$mtable->attach_defaults ($manual  , 0, 1, 1,2);
	
	return $mtable;
}




sub get_route_manual {
	my ($self,$info)=@_;	
	
	my $row=0;
	my $col=0;
		
	my $table= def_table(2,10,FALSE);
	
	add_Hsep_to_table ($table,0, 200,  $row);$row++;
	
	my $refresh = def_image_button('icons/refresh.png','Refresh');
	$table->attach ($refresh,0,5 ,  $row, $row+1,'fill','fill',2,2);$row++;
		

	$table->attach (gen_colored_label('Not selected',17),5,10,$row,$row+1,'fill','shrink',2,2);	
	$table->attach (gen_colored_label('Selected',0),10,15,$row,$row+1,'fill','shrink',2,2);	
	$table->attach (gen_colored_label('Not Existed',11),15,20,$row,$row+1,'fill','shrink',2,2);	
	$row++;	
	
	$table->attach (def_label(' source -> destination '),10,15,$row,$row+1,'fill','shrink',2,2);	
    $row++;	
	
		
	my @all_endpoints=get_list_of_all_endpoints($self);
		
	foreach  my $src  (@all_endpoints ){	
		foreach  my $dst  (@all_endpoints ){	
			my $src_inst=$self->object_get_attribute("$src",'NAME');
			my $dst_inst=$self->object_get_attribute("$dst",'NAME');
		   	my $select = $self->object_get_attribute('Route',"${src}::$dst");
		   	
		  	#my ($paths_to_dst,$ports_to_dst); #= get_all_paths_between_two_endps($self,$src, $dst);
		  	#my $color =(scalar @{$paths_to_dst}==0)? 11 :  (defined $select)? 0 : 17;		   		   	
		   	#my $button = ($src_inst ne $dst_inst )?  def_colored_button("${src_inst}->$dst_inst",$color): gen_label_in_center(' - ');	
		   	
		   	my $color = (defined $select)? 0 :17;		   		   	
		   	my $button = ($src_inst ne $dst_inst )?  def_colored_button("${src_inst}->$dst_inst",$color): gen_label_in_center(' - ');	
		   
		   	
		   	attach_widget_to_table ($table,$row,undef,undef,$button,$col);  $col+=4;	
		   	
		   	
		   	
		   	$button->signal_connect("clicked" => sub {
		   		$self->object_add_attribute("SELECT_PATH","src",$src);
		   		$self->object_add_attribute("SELECT_PATH","dst",$dst);		   		
		   		set_gui_status($self,"redraw",1);
				
			}) if($src_inst ne $dst_inst );	
		   		
   	   
		}$row++;$col=0;
	} 
	
	
	$refresh->signal_connect("clicked" => sub{
			refresh_route_manual($self,$info);	
	});
			
	return $table;
}


sub refresh_route_manual {
	my ($self,$info)=@_;
	my @all_endpoints=get_list_of_all_endpoints($self);
	
	my $path_select= $self->object_get_attribute("routing_auto",'PATH_SELECT');
	my @acyclic_turns;	


	if ($path_select ne "all-paths"){
		 my $ref = $self->object_get_attribute('routing_auto','acyclic_turns_model'); 
		 if(defined $ref) {
		 	@acyclic_turns = @{$ref};
		 }else{
		 	add_colored_info($info,"Info:No acyclic route model is selected\n",'green');
		 		 	
		 }	
	}
		
	foreach  my $src  (@all_endpoints ){	
		foreach  my $dst  (@all_endpoints ){	
			my $src_inst=$self->object_get_attribute("$src",'NAME');
			my $dst_inst=$self->object_get_attribute("$dst",'NAME');
		   	my $select = $self->object_get_attribute('Route',"${src}::$dst");
		   	
		   	my ($ref1,$ref2)= ($path_select eq "all-paths")? get_all_paths_between_two_endps($self,$src, $dst) : get_all_paths_between_two_endps_using_accyclic_turn($self,$src, $dst,\@acyclic_turns) ;
			my @paths = @{$ref1};
			if (defined $select){
				#check if select exist in @paths
				my $match=0;
			
				foreach  my $p (@paths ){
					my @a1 = @{$p};
					my @a2 = @{$select};
					my $st1=join('->',@a1);
					my $st2=join('->',@a2);
					if($st1 eq $st2){
						$match=1;
					}
				}#foreach
				#remove it from the selected path
				if ($match ==0){
					my $selp;
					foreach my $q ( @{$select}){
						my $inst=$self->object_get_attribute("$q",'NAME');
						$selp= (defined $selp)? $selp."->$inst" : $inst;
					}
					
					add_info ($info,"$selp does not exist in path list anymore and it has been removed\n"); 
					$self->object_add_attribute('Route',"${src}::$dst",undef);
				}#if 
			}#if 
		}#foreach
	}#foreach	   	
		   	
	
	set_gui_status($self,"ref",1);
	
}		


sub route_info_window{
	my ($self,$info)= @_;	
	my $w1 = show_paths_between_two_endps($self,$info);
	my $w2 = routing_summary($self,$info);
	my $h1=gen_hpaned($w1,.30,$w2);		
	return $h1;	
}



sub add_route_edge_to_graph{
	my ($gref,$anodes_ref)=@_;
	my %graph=%{$gref};
	my @a_nodes= @{$anodes_ref};
	
	my $old_r;	
	foreach my $r (@a_nodes){
		
		if(defined $old_r){
			        push(@{$graph{$old_r}},$r);										
		}
		$old_r=$r;
	}	
	
	return %graph;	
}

sub get_adjacent_node_in_a_path{
	my $ref=shift;
	my @result;
	my @path=@{$ref};
	my $old_r;	
	foreach my $r (@path){	
		push (@result,"${old_r}::$r") if(defined $old_r);
		$old_r=$r;
	}	
	return @result;
	
}

sub get_adjacent_router_in_a_path{
	
	my $ref=shift;
	my @result;
	my @path=@{$ref};
	shift @path; #remove source node from the path
	pop @path; #remove the destination node from the path
	
	
	my $old_r;	
	foreach my $r (@path){	
		push (@result,"${old_r}::$r") if(defined $old_r);
		$old_r=$r;
	}	
	return @result;
	
}


sub get_route_info{
	my ($self)=@_;
	my %R_num;
	my %L_num;
	my @all_endpoints=get_list_of_all_endpoints($self);
	foreach  my $r  (@all_endpoints ){
		#$R_num{$r} =0;
	}
	my @nodes=get_list_of_all_routers($self);
	foreach my $p (@nodes){
		$R_num{$p} =0;
	}	
	foreach  my $src  (@all_endpoints ){	
		foreach  my $dst  (@all_endpoints ){	
			my $path = $self->object_get_attribute('Route',"${src}::$dst");
			if (defined $path){				
				#router counting
				my @p=@{$path};
				shift @p; #remove source node from the path
				pop @p; #remove the destination node from the path
				foreach my $r (@p){				
					$R_num{$r} ++;					
				}
				#path counting
				@p= 	get_adjacent_router_in_a_path($path);
				foreach my $r (@p){				
					$L_num{$r} ++;	
							
				}
			
			
			}			
		}
	}
	
	my @Rkeys = sort { $R_num{$a} <=> $R_num{$b} } keys(%R_num);
	my @Lkeys = sort { $L_num{$a} <=> $L_num{$b} } keys(%L_num);
	my $sample="sample0";
	foreach  my $r  (@nodes ){
		my $inst=$self->object_get_attribute("$r",'NAME');
		update_result ($self,$sample,"router_all_paths_result",'-',$inst,$R_num{$r});
	}
	
	my $max_r = (defined $Rkeys[-1]) ? $R_num{$Rkeys[-1]} : 0;
	my $min_r = (defined $Rkeys[ 0]) ? $R_num{$Rkeys[ 0]} : 0;
	my $max_l = (defined $Lkeys[-1]) ? $L_num{$Lkeys[-1]} : 0;
	my $min_l = (defined $Lkeys[ 0]) ? $L_num{$Lkeys[ 0]} : 0;
	my @l = sort  values (%L_num);
	my $std_l=stdev(\@l);	
	
	$self->object_add_attribute ($sample,"link_all_paths_result",undef);
	
	my $nn=0;
	my $min_l_name="-";
	my $max_l_name="-";
	my $siz = $#Lkeys;
	foreach  my $r  (@Lkeys ){
		my ($n1,$n2)=split(/::/,$r);
		my $inst1=$self->object_get_attribute("$n1",'NAME');
		my $inst2=$self->object_get_attribute("$n2",'NAME');
		my $inst = "$inst1-$inst2"; 
		update_result ($self,$sample,"link_all_paths_result",'-',$inst,$L_num{$r});
		$min_l_name= $inst if($nn==0);
		$max_l_name= $inst if($nn==$siz-1);
		$nn++;
	}
	
			
		
	my $max_r_name= (defined $Rkeys[-1])? $self->object_get_attribute("$Rkeys[-1]",'NAME') : "-";
	my $min_r_name= (defined $Rkeys[0]) ? $self->object_get_attribute("$Rkeys[0]",'NAME') : "-";	
	
	$max_r_name= "-" if (!defined $max_r_name); 
	$min_r_name= "-" if (!defined $min_r_name); 	
    
		   
	return ($max_r,$min_r,$max_l,$min_l,$std_l,$max_r_name,$min_r_name,$max_l_name,$min_l_name);	
}	


sub routing_summary{
	my ($self,$info)= @_;		
	
	my $sc_win = gen_scr_win_with_adjst($self,'map_info');
	#my $table= def_table(10,10,FALSE);
	
	
	my $row=0;
	my $col=0;
	my ($max_r,$min_r,$max_l,$min_l,$std_l,$max_r_name,$min_r_name,$max_l_name,$min_l_name)=get_route_info($self);
	
	
	my @data = (
   {0 => "The Maximum number that a router is used in routing",  1 =>"$max_r", 2 =>"$max_r_name"}, # The maximum number that a router is located in all paths between all source-destination pair in this routing algorithm.
   {0 => "The Minimum number that a router is used in routing",  1 =>"$min_r", 2 =>"$min_r_name" },  
   {0 => "The Maximum number that a link is used in routing ",  1 =>"$max_l", 2 =>"$max_l_name"}, # The maximum number that a node-2-node link is located in all paths between all source-destination pair in this routing algorithm.
   {0 => "The Minimum number that a link is used in routing",  1=>"$min_l", 2 =>"$min_l_name" },  
   {0 => "Link usage  standard deviation ",  1 =>"$std_l" } 
  );
	
	  
 
	my @clmn_type = ('Glib::String',  # => G_TYPE_STRING
                                    'Glib::String',
                                    'Glib::String'); # you get the idea

	my @clmns = ("Routing Summary", " ", " ");

	my $list=	gen_list_store (\@data,\@clmn_type,\@clmns);


	add_widget_to_scrolled_win($list,$sc_win);
	
	my $charts =  gen_routing_charts($self,$info);
	
	my $v1=gen_vpaned($sc_win,.25,$charts);
	
	$sc_win->show_all;
	
	return $v1;	
	
}


sub gen_routing_charts{
	
	my ($self,$info)=@_;
	
	my @pages =(
	{page_name=>" # Routers in all Paths", page_num=>0},
	{page_name=>" # Links in all Paths ", page_num=>1}	
);



my @charts = (
	{ type=>"3D_bar", page_num=>0, graph_name=> "# Router in all Paths", result_name => "router_all_paths_result", X_Title=> 'Router Name', Y_Title=>'The total number that a router is used in the routing', Z_Title=>undef},
	{ type=>"3D_bar", page_num=>1, graph_name=> "# Links in all paths", result_name => "link_all_paths_result", X_Title=> 'Connection Link', Y_Title=>'The total number that a link is used in the routing', Z_Title=>undef},
  	#{ type=>"2D_line", page_num=>0, graph_name=> "SD latency", result_name => "sd_latency_result", X_Title=> 'Desired Avg. Injected Load Per Router (flits/clock (%))', Y_Title=>'Latency Standard Deviation (clock)', Z_Title=>undef},
	#{ type=>"3D_bar",  page_num=>1, graph_name=> "Received", result_name => "packet_rsvd_result", X_Title=>'Core ID' , Y_Title=>'Received Packets Per Router', Z_Title=>undef},
	#{ type=>"3D_bar",  page_num=>1, graph_name=> "Sent", result_name => "packet_sent_result", X_Title=>'Core ID' , Y_Title=>'Sent Packets Per Router', Z_Title=>undef},
	
	);
	
	
	my $chart   =gen_multiple_charts  ($self,\@pages,\@charts,.3);
    return $chart;
	
}




sub show_paths_between_two_endps{
	my ($self,$info)= @_;
	my $table=def_table(20,20,FALSE);
		
	my $row-=0;
	my $col=0;
	
	my $src = $self->object_get_attribute("SELECT_PATH","src");
	my $dst = $self->object_get_attribute("SELECT_PATH","dst");
	
	my @acyclic_turns;
	my $path_select= $self->object_get_attribute("routing_auto",'PATH_SELECT');
	if ($path_select ne "all-paths"){
		 my $ref = $self->object_get_attribute('routing_auto','acyclic_turns_model'); 
		 if(defined $ref) {
		 	@acyclic_turns = @{$ref};
		 }else{
		 	add_colored_info($info,"Info:No acyclic route model is selected\n",'green');
		 		 	
		 }	
	}
	
	
	
	
	
	if(defined $src && defined $dst ){
		my $s= $self->object_get_attribute("$src","NAME");
		my $d= $self->object_get_attribute("$dst","NAME");		
		$table->attach (def_label("Select path between $s to $d" ),$col,$col+10,$row,$row+1,'fill','shrink',2,2);
		add_info($info,"get list of all paths between $s to $d \n") if (defined $info);
		$row=1;
		my ($ref1,$ref2)= ($path_select eq "all-paths") ?  get_all_paths_between_two_endps($self,$src, $dst):
		get_all_paths_between_two_endps_using_accyclic_turn($self,$src, $dst,\@acyclic_turns);
		
		
		my @paths = @{$ref1};
		my @ports= @{$ref2};
		my $n=0;
		my $select = $self->object_get_attribute('Route',"${src}::$dst");
		foreach my $p (@paths){
			my $scal;
			my $selp;
			my $path_num=$n;
			my $path=$p;
			foreach my $q ( @{$p}){
				my $inst=$self->object_get_attribute("$q",'NAME');
				$scal= (defined $scal)? $scal."->$inst" : $inst;
			}
			
			foreach my $q ( @{$select}){
				my $inst=$self->object_get_attribute("$q",'NAME');
				$selp= (defined $selp)? $selp."->$inst" : $inst;
			}
			
				
			my $check= gen_checkbutton();
			#print "if($select eq $path)";
			if(defined $select && defined $scal && defined $selp) {if($selp eq $scal) {$check->set_active(TRUE);}}
			else {$check->set_active(FALSE);}
			
			$check-> signal_connect("toggled" => sub{
				if($check->get_active()) {
					 
					$self->object_add_attribute('Route',"${src}::$dst",$path);
				}
				else {
					 
					$self->object_add_attribute('Route',"${src}::$dst",undef);
				}
				set_gui_status($self,"ref",1);
			});
			
			
			my $label =gen_label_in_left("$scal");
			$table->attach ($check ,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $col++;
			$table->attach ($label ,  $col, $col+1,$row,$row+1,'shrink','shrink',2,2); $row++;$col=0;
			
			$n++;	
		}
		
		
	}
	
	return add_widget_to_scrolled_win($table);
	
}



##########
#	save
##########
sub save_network {
	my ($self)=@_;
	# read topology  name
	my $name=$self->object_get_attribute('save_as');	
	#print $name;
	my $s= (!defined $name)? 0 : (length($name)==0)? 0 :1;	
	if ($s == 0){
		message_dialog("Please set the topology name!");
		return 0;
	}
	# Write object file
	my $fname = "$name.NWM";
	open(FILE,  ">lib/netwmaker/$fname") || die "Can not open: $!";
	print FILE perl_file_header("$fname");
	print FILE Data::Dumper->Dump([\%$self],["nwmaker"]);
	close(FILE) || die "Error closing file: $!";
	message_dialog("Current network maker state is saved as lib/netwmaker/$fname!");
	return 1;
}

sub get_all_endp_ids{
	my $self=shift;
	my %e=  $self->object_get_attribute("E");
	my @list = sort keys %e;
	return @list;
	
}



#############
#    load
#############

sub load_net_maker{
    my ($self,$info)=@_;
    my $file;
	my $dialog =  gen_file_dialog (undef, 'NWM');
   
    
    my $dir = Cwd::getcwd();
    $dialog->set_current_folder ("$dir/lib/netwmaker")    ;
   
    if ( "ok" eq $dialog->run ) {
        $file = $dialog->get_filename;
        my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
        if($suffix eq '.NWM'){
            my ($pp,$r,$err) = regen_object($file );
            if ($r){        
                add_info($info,"**Error: cannot open $file file: $err\n");
                 $dialog->destroy;
                return;
            } 
            

            clone_obj($self,$pp);

                    
        }                    
     }
     $dialog->destroy;
     set_gui_status($self,"ref",1)
}







sub get_all_paths_between_two_endps{
	my ($self,$src, $dst)=@_;
	my @proceed_nodes;
	my @head_nodes;
	
	my $offset = $self->object_get_attribute('routing_auto','OFFSET');
	my $max_len = $self->object_get_attribute('routing_auto','MAX_LENGTH');	
	
	push (@head_nodes,$src);
	push (@proceed_nodes,$src);
	
	my @paths;
	my @ports;
	my @paths_to_dst;
	my @ports_to_dst;
	
	my @first_path=($src);
	my @first_port=(0);
	$paths[0]=\@first_path;
	$ports[0]=\@first_port;
	
	# select one path
	my $n=0;
	my $min_dist=1000000;
	do{	
		my @current_path= @{$paths[$n]};
		my @current_port= @{$ports[$n]};
		# get head node
		my $head_node = 	$current_path[-1];
		if(defined $head_node){
			# get connected nodes for all ports 
			#print "hn=$head_node\n";
			my $pnum =  $self->object_get_attribute($head_node,'PNUM');
			
			for (my $i=0;$i<$pnum; $i++){
				my @new_path=@current_path;
				my @new_ports=@current_port;
				my $src_port = "Port[${i}]";
		   	   	my $connect = $self->{$head_node}{'PCONNECT'}{$src_port};	
				if(defined $connect){
					my ($node,$pnode)=split(/\s*,\s*/,$connect);
					#add connected nodes to head_nodes if they are not in path before
					if(!defined get_scolar_pos($node,@new_path)){
						my $size=scalar @new_path;
						#if ($min_dist > $size){
						if( ($min_dist+$offset) > $size &&   $max_len>=$size){
							
							
							push (@new_path,$node);
							push (@new_ports,$pnode);
							push (@paths,\@new_path);
							push (@ports,\@new_ports);						 
							if($node eq $dst){
								push(@paths_to_dst,\@new_path);
								push(@ports_to_dst,\@new_ports); 
								$min_dist=$size+1 if ($min_dist > $size);
							} 
						}
					} #if
				}
			}#for
		}	
		$n++;
	}while( defined $paths[$n]);
	
	#print "\@paths_to_dst". Dumper(@paths_to_dst). "\n \@ports_to_dst". Dumper(@ports_to_dst) . "\n" ;
	
	return (\@paths_to_dst,\@ports_to_dst);

}

sub get_path_from_turns {
	my ($self,$ref)=@_;
	my @new_turn = @{$ref} if(defined $ref);
	my @path_nodes;
	my @path_ports;
	my $st2;
	foreach my $code (@new_turn){
		my $pn2  =  $code & 0xF;
		$code >>=4;
		my $rn2  = $code & 0xFFF;
		$code >>=12;
		my $pn1 =$code & 0xF;
		$code >>=4;
		my $rn1=$code;	
		my $st1 = ($pn1==1)? "ENDP_${rn1}" : "ROUTER${pn1}_${rn1}";
		$st2 = ($pn2==1)? "ENDP_${rn2}"    : "ROUTER${pn2}_${rn2}";
		push(@path_nodes,$st1);		
	}
	push(@path_nodes,$st2);	
	
	@path_ports=(0);
	for (my $i=0; $i<scalar @path_nodes-1; $i++){
		my ($p1,$p2) =get_connection_port_num_between_two_nodes($self,$path_nodes[$i],$path_nodes[$i+1]);
		push(@path_ports,"Port[$p2]");
	}
	
	return (\@path_nodes,\@path_ports);
		
}

sub get_all_paths_between_two_endps_using_accyclic_turn{
	my ($self,$src, $dst,$ref)=@_;
	my @proceed_turns;
	my @head_turns;
	my @accyclic_turn= @{$ref};
	
	my $offset = $self->object_get_attribute('routing_auto','OFFSET');
	my $max_len = $self->object_get_attribute('routing_auto','MAX_LENGTH');	
	
	my @paths_to_dst;
	my @ports_to_dst;
	
	my %graph;
	
	foreach my $str (@accyclic_turn){
		my ($s1,$s2) = split /\s/, $str;
		push(@{$graph{$s1}},$s2);			
	}	

	my $start_turns;
	my $ended_turns;
	my $src_port = "Port[0]";
	my $connect = $self->{$src}{'PCONNECT'}{$src_port};	
	if(defined $connect){
		my ($node,$pnode)=split(/\s*,\s*/,$connect);
		$start_turns = 	get_turn_code("${src}::${node}");
	}
	
	$connect = $self->{$dst}{'PCONNECT'}{$src_port};	
	if(defined $connect){
		my ($node,$pnode)=split(/\s*,\s*/,$connect);
		$ended_turns = 	get_turn_code("${node}::${dst}");
	}
	
	push (@head_turns,$start_turns);
    push (@proceed_turns,$start_turns);

	
	
	
	
	my @turns;
	my @ports;
	my @turns_to_dst;
	my @first_turn=($start_turns);
	
	$turns[0]=\@first_turn;
	
	
	# select one path
	my $n=0;
	my $min_dist=1000000;
	do{	
		my @current_turn= @{$turns[$n]};
		# get head node
		my $head_turn = 	$current_turn[-1];
		if(defined $head_turn){
			#get all turns 
			my @all_fwd_turns = @{$graph{$head_turn}} if (defined $graph{$head_turn});	
					
			foreach my $fwd_turn (@all_fwd_turns){
				my @new_turn=@current_turn;
				#add new turn to head_turns if they are not in turns before
				if(!defined get_scolar_pos($fwd_turn,@new_turn)){	
					my $size=scalar @new_turn;	
					#if ($min_dist > $size){
					if( ($min_dist+$offset) > $size &&   $max_len>=$size){
						push (@new_turn,$fwd_turn);
						push (@turns,\@new_turn);
						if($fwd_turn eq $ended_turns){
							push(@turns_to_dst,\@new_turn);	
							my ($path_ref,$port_ref) = get_path_from_turns($self,\@new_turn); 				
							push(@paths_to_dst,$path_ref);
							push(@ports_to_dst,$port_ref);
							$min_dist=$size+1 if ($min_dist > $size);
						} #if
						
					}#if
				}#if
			}#foreach
		}#if
	$n++;
	}while( defined $turns[$n]);			
					
		
					
	#print "\@paths_to_dst". Dumper(@paths_to_dst). "\n \@ports_to_dst". Dumper(@ports_to_dst) . "\n" ;
	
	
	return (\@paths_to_dst,\@ports_to_dst);
	
}




sub get_turn_code {
	my $turn =shift;
	my ($pn1,$rn1,$pn2,$rn2)= sscanf( "ROUTER%u_%u::ROUTER%u_%u",$turn);
	if(defined $rn1){
		return ( ($rn1 << 20)+ ($pn1 << 16) +  ($rn2 << 4) +  $pn2);
	}
	($rn1,$pn2,$rn2)= sscanf( "ENDP_%u::ROUTER%u_%u",$turn);
	if(defined $rn1){
		return ( ($rn1 << 20)+ (1 << 16) +  ($rn2 << 4) +  $pn2);
	}	
	($pn1,$rn1,$rn2)= sscanf( "ROUTER%u_%u::ENDP_%u",$turn);
	return ( ($rn1 << 20)+ ($pn1 << 16) +  ($rn2 << 4) +  1);
}

sub get_turn_str {
	my $code =shift;
	my $pn2  =  $code & 0xF;
	$code >>=4;
	my $rn2  = $code & 0xFFF;
	$code >>=12;
	my $pn1 =$code & 0xF;
	$code >>=4;
	my $rn1=$code;	
	my $st1 = ($pn1==1)? "ENDP_${rn1}" : "ROUTER${pn1}_${rn1}";
	my $st2 = ($pn2==1)? "ENDP_${rn2}" : "ROUTER${pn2}_${rn2}";
	
	return   "${st1}::${st2}";
}

sub get_turn_involved_routrs{
	my ($s1,$s2,$info)=@_;
	my ($r1,$ra2) = split /::/, $s1;
	my ($rb2,$r3) = split /::/, $s2;
	add_colored_info($info,"Error in turn format. $s1 -> $s2 : $ra2 should be equal with $rb2 ",'red') if($ra2 ne $rb2);
	return ($r1,$ra2,$r3);	
}

sub get_path_edges_graph_file{
	my ($ref1,$ref2) = @_;	
	my @a_nodes = @{$ref1};
	my %graph   = %{$ref2};
	
	my $old_r;	
	foreach my $r (@a_nodes){
		
		if(defined $old_r){
			my $str1 = "$old_r $r";
			my $n1  = get_turn_code($old_r);
			my $n2  = get_turn_code($r); 
			my $str2 = "$n1 $n2";
			$graph{$str2}=$str1;			
		}
		$old_r=$r;
	}
	return %graph;
}	




sub get_forbiden_turns_old {
#sub gen_aciclic_turn_graph {	
	my ($self,$info)=@_;
	my @forbiden_turn;
	add_info($info,"Calculate forbidden turns to avoid deadlock \n");
	#step 1: get the list of all  minimal paths between all source and destination pairs
	my $graph='';
	my $graph_coded='';
	my @all_endpoints=get_list_of_all_endpoints($self);
	
	my %edge_graph;
	foreach  my $src  (@all_endpoints ){	
		foreach  my $dst  (@all_endpoints ){
			if($src ne $dst){	
				my ($paths_to_dst,$ports_to_dst) = get_all_paths_between_two_endps($self,$src, $dst);
				foreach my $path (@{$paths_to_dst}) {
					if (defined $path){
						#path counting
						my @a_nodes= 	get_adjacent_node_in_a_path($path);#get_adjacent_router_in_a_path($path);
						print "@a_nodes = \@a_nodes \n";
						%edge_graph = get_path_edges_graph_file (\@a_nodes,\%edge_graph);
						#$graph  =$graph. $str1;
						#$graph_coded = $graph_coded . $str2;
					}#defined path	
				}#foreach	
			}#if			
		}#froeach				
			
	}#froeach	
	
	foreach my $p (sort keys %edge_graph){
		$graph_coded  .="$p\n";
		$graph .= "$edge_graph{$p}\n";
	}
			
	my $tmp_dir  = "$ENV{'PRONOC_WORK'}/tmp";
	save_file ("$tmp_dir/paths_graph.edges",$graph);
	save_file ("$tmp_dir/paths_graph_coded.edges",$graph_coded);
	
	
	#remove old files 
	my @files = File::Find::Rule->file()
                            ->name( 'paths_graph_coded_removed*.edges')
                            ->in( "$tmp_dir" );	
	foreach my $f (@files){
		unlink  $f if (-f "$f");		
	}			
	
	# run remove_cycle_edges_by_dfs on coded graph 
	my $remover_dire = get_project_dir()."/mpsoc/remove_cycle/";
	my $cmd  =  "cd $remover_dire; 
	python  break_cycles.py  -g $tmp_dir/paths_graph_coded.edges;
	python remove_cycle_edges_by_dfs.py -g $tmp_dir/paths_graph_coded.edges; 
	python remove_cycle_edges_by_minimum_feedback_arc_set_greedy.py  -g $tmp_dir/paths_graph_coded.edges";	
	#sort paths_graph_coded.edges | uniq > newfile.db
	
	my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
	if(length $stderr>1){			
		add_colored_info($info,"$stderr\n",'red');
	}else {
		add_info($info,"$stdout\n");
	}	
	# find the files with the list edges removal
	@files = File::Find::Rule->file()
                         ->name( 'paths_graph_coded_removed*.edges')
                         ->in( "$tmp_dir" );	
	
	                       
	my $line_num;
	my $out;
	foreach my $f (@files){
		my $n =count_file_line_num ($f);
		$line_num = $n if(! defined $line_num);
		if($n <= $line_num){
			$out = $f;
			$line_num=$n; 
		}		
	}			
		
			
	# check if the output file is generated 
	if (-f $out ){
		add_colored_info($info,"$out file has been selected as it has the minimum number of edge removal of $line_num \n",'blue');
		
	} else {
		add_colored_info($info,"could not find a paths_graph_coded_removed*.edges file.  Please make sure $cmd has been run successfully\n",'red');
		return;
		
	}
	
	
	
	
	my $r;
	open my $fh, "<", $out or $r = "$!\n";
    if(defined $r) {
    	add_colored_info($info,"Could not open $out: $r",'red');
		return;
    } 
    
    add_colored_info($info,"List of forbidden turns: \n",'blue');
    
	while (my $line = <$fh>) {
    	chomp $line;
    	$line=~ s/^\s+|\s+$//g; 
    	my ($s1,$s2) = split /\s/, $line;
        $s1  = get_turn_str($s1);  
  		$s2  = get_turn_str($s2);
  		my @turn = get_turn_involved_routrs($s1,$s2);
  		my $str = get_path_instance_string($self,\@turn);
  		my $string=join('->',@turn);
  		push (@forbiden_turn, $string);
  		add_info($info,"$str\n");  

  }
  return @forbiden_turn;
  
}


sub gen_turn_graph{
	my $self=shift;
	my %edge_graph;
	my @all_nodes=get_list_of_all_nodes($self);
	foreach  my $node1  (@all_nodes ){	
		my $pnum1=$self->object_get_attribute("$node1",'PNUM');
		for (my $i=0;$i<$pnum1; $i++){ 
   	   		my $port1 = "Port[${i}]";
   	   		my $connect1 = $self->{$node1}{'PCONNECT'}{$port1};
			if (defined $connect1) {
				my ($node2,$Rport2)=split(/\s*,\s*/,$connect1);
				my $pnum2=$self->object_get_attribute("$node2",'PNUM');
				for (my $j=0;$j<$pnum2; $j++){ 
					my $port2 = "Port[${j}]";
					my $connect2 = $self->{$node2}{'PCONNECT'}{$port2};
					if (defined $connect2) {
						my ($node3,$Rport3)=split(/\s*,\s*/,$connect2);
						if($node1 ne $node3){
							my @a_nodes= 	("${node1}::${node2}","${node2}::${node3}");
							%edge_graph = get_path_edges_graph_file (\@a_nodes,\%edge_graph);
						}
					
					}#if	
				}#for		
			}#if
		}#for	 
	}	
	return %edge_graph;
}

sub gen_aciclic_turn_graph {
	
	my ($self,$info)=@_;
	
	#my @forbiden_turn;
	
	add_info($info,"Generate an acyclic turn graph to avoid deadlock \n");
	#step 1: get the list of turn in topology. A turn is a path that include three nodes.
	my $graph='';
	my $graph_coded='';
	
	my %edge_graph =gen_turn_graph($self);
	
		
	foreach my $p (sort keys %edge_graph){
		$graph_coded  .="$p\n";
		$graph .= "$edge_graph{$p}\n";
	}
			
	my $tmp_dir  = "$ENV{'PRONOC_WORK'}/tmp";
	save_file ("$tmp_dir/paths_graph.edges",$graph);
	save_file ("$tmp_dir/paths_graph_coded.edges",$graph_coded);
	
	
	#remove old files 
	my @files = File::Find::Rule->file()
                            ->name( 'paths_graph_coded_removed*.edges')
                            ->in( "$tmp_dir" );	
	foreach my $f (@files){
		unlink  $f if (-f "$f");		
	}			
	
	# run remove_cycle_edges_by_dfs on coded graph 
	my $remover_dire = get_project_dir()."/mpsoc/remove_cycle/";
	my $cmd  =  "cd $remover_dire; 
	python  break_cycles.py  -g $tmp_dir/paths_graph_coded.edges;
	python remove_cycle_edges_by_dfs.py -g $tmp_dir/paths_graph_coded.edges; 
	python remove_cycle_edges_by_minimum_feedback_arc_set_greedy.py  -g $tmp_dir/paths_graph_coded.edges";	
	#sort paths_graph_coded.edges | uniq > newfile.db
	
	my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
	if(length $stderr>1){			
		add_colored_info($info,"$stderr\n",'red');
	}else {
		add_info($info,"$stdout\n");
	}	
	# find the files with the list edges removal
	@files = File::Find::Rule->file()
                         ->name( 'paths_graph_coded_removed*.edges')
                         ->in( "$tmp_dir" );		                       
	my $line_num;
	my $out;
	my %all_outs;
	foreach my $f (@files){
		
		my $n =count_file_line_num ($f);
		$all_outs{$f}=$n;
		
	}			
	
	my @graph_array=sort keys %edge_graph;
	my @acyclic_turns;
	my @removed_edge;
	my $result=0;
	
	my %algorithms;
	
	foreach my $file  (sort {$all_outs{$a} <=> $all_outs{$b}} keys %all_outs) {
		$line_num = $all_outs{$file};
		$out=$file;
		add_info($info,"check if $file file $line_num edges removal results in a connected graph\n");
		
		@removed_edge=();			
		open(FILE,$file);
		if (tell FILE ){
			add_colored_info($info,"Cannot open $file to read: $!\n",'red');
			return;
		}
    	while (my $line = <FILE>) {
    		chomp($line);
    	   	$line=~ s/^\s+|\s+$//g; 
	   		push(@removed_edge,$line);
		}
    	close FILE;
		
		@acyclic_turns = get_diff_array ( \@graph_array , \@removed_edge );
		
		
				
		$result = check_diff_graph_be_connected ($self,\@acyclic_turns,$info);
		if($result == 1){			
			my $alg = capture_string_between ('paths_graph_coded_removed_by_',$file,".edges");
			$algorithms{$alg}=$line_num;
			#save @acyclic_turns for this algorithm
			open(F,  ">$tmp_dir/$alg.alg") || die "Can not creat: $!";
    		print F perl_file_header("$alg.alg");
    		print F Data::Dumper->Dump([\@acyclic_turns],['turn']);
    		close(F ) || die "Error closing file: $!";			
		}
			
		 
	}

	$self->object_add_attribute('routing_auto','acyclic_algorithms',\%algorithms);
	

    if (scalar (keys %algorithms) == 0){
		add_colored_info($info,"Unable to find any directed acyclic graph for routing\n",'red');
		return;
    }
	
	return;
	#add_colored_info($info,"$out file has been selected as it has the minimum number of edge removal of $line_num and its connected\n",'blue');
		
	
	    
    #add_colored_info($info,"List of forbidden turns: \n",'blue');
    
	foreach my $line (@removed_edge) {
    	chomp $line;
    	my ($s1,$s2) = split /\s/, $line;
        $s1  = get_turn_str($s1);  
  		$s2  = get_turn_str($s2);
  		my @turn = get_turn_involved_routrs($s1,$s2);
  		my $str = get_path_instance_string($self,\@turn);
  		my $string=join('->',@turn);
  #		push (@forbiden_turn, $string);
  		add_info($info,"$str\n");  

  	}
  	
 # $self->object_add_attribute('routing_auto','acyclic_turns',\@acyclic_turns);
  	
#  return @forbiden_turn;
  
}



sub check_diff_graph_be_connected {
	my ($self,$ref,$info)=@_;
	my @diff = @{$ref};
	my %all_turns;
	my %graph;
	
	foreach my $str (@diff){
		my ($s1,$s2) = split /\s/, $str;
		$all_turns{$s1}=1;
		$all_turns{$s2}=1;
		push(@{$graph{$s1}},$s2);
			
	}
	
	my @all_endpoints=get_list_of_all_endpoints($self);
	my @start_turns;
	my @ended_turns;
	foreach my $endp (@all_endpoints){
				
				my $src_port = "Port[0]";
		   	   	my $connect = $self->{$endp}{'PCONNECT'}{$src_port};	
				if(defined $connect){
					my ($node,$pnode)=split(/\s*,\s*/,$connect);
					push (@start_turns, 	get_turn_code("${endp}::${node}"));
					push (@ended_turns, 	get_turn_code("${node}::${endp}"));
				}
	}
	
	my $k=0;
	foreach my $s (@start_turns){# we should see all @ended_turns
	
		my @seen_turns=($s,$ended_turns[$k]);# put connect to itself connection as seen node.  
		$k++;
		my @next_turns =@{$graph{$s}};
		
		while (scalar @next_turns>0){
		
		
			#print "\@next_nodes = @next_nodes\n";
			#print "\@seen_nodes = @seen_nodes\n";
			my $n = pop (@next_turns);
			#print "\$n  = $n \n";
			my @nn;
			@nn = @{$graph{$n}} if (defined $graph{$n}); 		
			#print "\@nn  = @nn \n";
			push (@seen_turns, $n);
			@diff = get_diff_array ( \@nn , \@seen_turns );
			#print "\@diff  = @diff \n";
			push (@next_turns,@diff);
				
		}
		
		my @sep = get_diff_array (\@ended_turns,\@seen_turns);
		
		if( scalar @sep > 0) {
			my $s1  = get_turn_str($s);
			my ($a1,$a2) = split ('::',$s1); 
			my $n1=$self->object_get_attribute("$a1",'NAME');
			
			$s1  = get_turn_str($sep[0]);
			my($a3,$a4) = split ('::',$s1); 
			my $n2=$self->object_get_attribute("$a4",'NAME');
				
			add_info($info,"\t $n1 is not connected to $n2. \n");  
			return 0;
		}
	
			
	}
	
		
	add_info($info,"\t All endpoints are connected in chanel dpenedency graph. \n");  
	return 1;

}


	
sub get_path_instance_string {
	my ($self,$path_ref)=@_;
	my @path = @{$path_ref};
	my @path_inst;
	foreach my $p (@path){
		push (@path_inst, $self->object_get_attribute("$p",'NAME'));	
		
	}
	my $string=join('->',@path_inst);
	return $string;
}	


sub remove_cycle_paths {
	my ($self,$info,$paths_ref, $fturn_ref)=@_;	
	my @free_paths;
	my @paths= @{$paths_ref};
	my @fturns= @{$fturn_ref};
	my $remove;
	
	
	
	foreach my $path (@paths) {
		my @p = @$path;
		my $turn;
		my $string=join('->',@p);
		#print "$string\n";	
		$remove=0;
		foreach my $t (@fturns){
			 if ($string =~ /$t-/){
			 	$remove=1;
			 	$turn=$t;
			 	last;
			 }
			 
		}
		push (@free_paths,$path) if($remove == 0);
		if($remove == 1){
			my @ft = split /->/, $turn; 
			add_info($info,"path ".get_path_instance_string($self,$path)." is removed due to turn ".get_path_instance_string($self,\@ft)."\n") 
		}
	}	
	return @free_paths;	
}	
	
	
	
	
	



sub auto_route {
	my ($self,$info)=@_;
	my %Psize;
	my $alg = $self->object_get_attribute('routing_auto', 'CYCLE_FREE_ALG'); 	
	my ($alg_name,$line) = split (/\s+--\s+/,$alg);
	
	if(!defined $line){
		add_colored_info($info,"No acyclic turn model is selected. click on Generate Cycle-free and make sure it runs successfully!\n",'red');
        return; 
	}
	my $tmp_dir  = "$ENV{'PRONOC_WORK'}/tmp";
	my $model_file = "$tmp_dir/$alg_name.alg";	
	my ($pp,$r,$err) = regen_object($model_file);
    if ($r){        
    	add_colored_info($info,"**Error: cannot open $model_file file: $err\n",'red');
   		return;
    } else {
    	add_info($info,"Use $alg_name algorithm for obtaing acyclic paths\n");
    }
	
	my @acyclic_turns = @{$pp};
	my %rusage = get_router_usage ($self,\@acyclic_turns);
	
	
	#step 1: calculate all minimal paths between all source and destination pairs
	add_info($info,"Calculate all  paths between all source and destination pairs\n");
	my @all_endpoints=get_list_of_all_endpoints($self);
	foreach  my $src  (@all_endpoints ){	
		foreach  my $dst  (@all_endpoints ){
			if($src ne $dst){	
				my ($paths_to_dst,$ports_to_dst) =  get_all_paths_between_two_endps_using_accyclic_turn($self,$src, $dst,\@acyclic_turns);
				my @cyle_free_paths= @{$paths_to_dst} if (defined $paths_to_dst);
				my $size = scalar  @cyle_free_paths;
				$Psize{"${src}::$dst"} = $size;
			}
		}
	}
	#step 2: Remove cyclic paths between all source and destination pairs
	
	
	
	
	
	
	#step 3 sort source destination based on the number of paths
	my @keys = sort { $Psize{$a} <=> $Psize{$b} } keys(%Psize);
	for my $key ( @keys) {
		my $size=$Psize{$key};
		#print "size = $size\n";
		next if(defined $self->object_get_attribute('Route',$key));
		
       # print "($key)->($Psize{$key})\n";
        my ($src , $dst)=split ('::',$key);
        my ($paths_to_dst,$ports_to_dst) = get_all_paths_between_two_endps_using_accyclic_turn($self,$src, $dst,\@acyclic_turns);
        #my @cyle_free_paths=remove_cycle_paths($self,$info,$paths_to_dst, \@forbiden_turn);
        my @cyle_free_paths= @{$paths_to_dst} if (defined $paths_to_dst);
        my @sort_paths=sort_paths_based_on_router_usage($self,\@cyle_free_paths,\%rusage);
       
      # my @sort_paths=sort_paths_based_on_link_usage($self,\@cyle_free_paths);
      

        
        my $path;
        my $n=0;
        foreach my $p (@sort_paths ){
        	if(check_cyclick_loop($self,$p)==0){
        		$path=$p;
        		#my @rrr=($p);
        		#remove_cycle_paths($self,$info,\@rrr, \@forbiden_turn);
        		
        		last;
        	}  else {
        		print "***Error  something goes wrong in acyclic turns model  ****************************\n";
        	}
        	$n++;      	
        }
        if(!defined $path){
        	#extract path from acyclic turn graph. This graph is connected so there must be atleast a path between each endpoint pairs there. however this path does not match the offset or size lentgh
        	
        	
        	set_gui_status($self,"ref",1);
        	add_colored_info($info,"Failed to find an acyclic routing paths for $key nodes!\n",'red');
        	return FALSE ;
        	
        }
        
        $self->object_add_attribute('Route',$key,$path);
		
	}
	
	set_gui_status($self,"ref",1);
	add_colored_info($info,"The routeing function table is generated successfully!\n",'blue');
	return TRUE;
}	


sub clean_route {
	my ($self,$info)=@_;
	 
	my @all_endpoints=get_list_of_all_endpoints($self);
	foreach  my $src  (@all_endpoints ){	
		foreach  my $dst  (@all_endpoints ){						
        $self->object_add_attribute('Route',"${src}::$dst",undef);
		
	}}
	
	set_gui_status($self,"ref",1);
	add_colored_info($info,"The Routing function table is cleared!\n",'blue');
	return TRUE;
}	



sub average{
        my($data) = @_;
        if (not @$data) {
               return 0;
        }
        my $total = 0;
        foreach (@$data) {
                $total += $_;
        }
        my $average = $total / @$data;
        return $average;
}
sub stdev{
        my($data) = @_;
        if(@$data == 1){
                return 0;
        }
        my $average = &average($data);
        my $sqtotal = 0;
        foreach(@$data) {
                $sqtotal += ($average-$_) ** 2;
        }
        my $std = ($sqtotal / (@$data-1)) ** 0.5;
        return $std;
}

sub clone_hash{
	my $ref=shift;
	my %hash=%{$ref};
	my %copy;
	foreach my $p (keys %hash){
		if (defined $hash{$p}){	$copy{$p} =  $hash{$p};}
	}
	return %copy;
}


sub sort_paths_based_on_router_usage{
	my ($self,$paths_to_dst,$usage)=@_;
	my %scored;
	my %usage_r= %{$usage};
	#get list of 30% high congested ruters 
	my @A = sort { $usage_r{$b} <=> $usage_r{$a} } keys %usage_r;
	#my $t = (scalar @A)*.3; # %30 
	my %congested;
	foreach my $a ( @A){		
		$congested{$a}=$usage_r{$a};# if(scalar(keys %congested)<$t);
	}
	
	my $i=0;
	foreach my $path (@{$paths_to_dst}) {
		my $val = 0;
		my $num=0;			
		for my $r (@{$path}){
			if(defined $congested{$r}){
				$val+=$congested{$r}**1.5;# pow of 3/2 to give higher weight to more congested routers
				$num++;
			}			
		}
		$scored{$i}=($num==0)? 0 : $val/$num;	#average weight of congested routers
		$i++;
	}
	
	my @order = sort { $scored{$a} <=> $scored{$b} } keys %scored;
	my @sorted;
	
	
	
	$i=0;
	foreach my $a ( @order){
		$sorted[$i]=${$paths_to_dst}[$a];
		$i++;
		#print "\$max{$a}=$max{$a},"
	}
	
	#print "\n";
	
	return @sorted;		
}	


sub sort_paths_based_on_link_usage{
	my ($self,$paths_to_dst)=@_;
	
	my %L_num;
	my %max;
	my @all_endpoints=get_list_of_all_endpoints($self);
	#get link count
	foreach  my $src  (@all_endpoints ){	
		foreach  my $dst  (@all_endpoints ){	
			my $path = $self->object_get_attribute('Route',"${src}::$dst");
			if (defined $path){
				#path counting
				my @p= 	get_adjacent_router_in_a_path($path);
				
				foreach my $r (@p){				
					$L_num{$r} ++;						
				}	
			
			}			
		}
	}
	#get std_devision of link  for each path if added   
	my $i=0;
	foreach my $path (@{$paths_to_dst}) {
		my %copy = clone_hash(\%L_num);
		my @p=get_adjacent_router_in_a_path($path);	
		foreach my $r (@p){				
					$copy{$r} ++;						
		}				
		my @l = sort  values (%copy);
		my $std=stdev(\@l);		
		$max{$i}=$std*100;
		$i++;	
	}
	
	
	my @order = sort { $max{$a} <=> $max{$b} } keys(%max);
	
	#print "*********** @order ************"; 
	my @sorted;
	$i=0;
	foreach my $a ( @order){
		$sorted[$i]=${$paths_to_dst}[$a];
		$i++;
		#print "\$max{$a}=$max{$a},"
	}
	
	#print "\n";
	
	return @sorted;
	
	
}


sub get_router_usage{
	my ($self,$acycle_turn_ref)=@_;
	
	my @all_endpoints=get_list_of_all_endpoints($self);
	my %router_cnt;
	#get router counts
	foreach  my $src  (@all_endpoints ){	
		foreach  my $dst  (@all_endpoints ){	
			#get list of all path between a source and destination nodes
			 my ($paths_to_dst,$ports_to_dst)= get_all_paths_between_two_endps_using_accyclic_turn($self,$src, $dst,$acycle_turn_ref);
			
			my @paths = @{$paths_to_dst};					
			foreach my $path (@paths){
				shift @{$path}; #remove source node from the path
				pop @{$path}; #remove the destination node from the path	
				foreach my $q ( @{$path}){
				 	$router_cnt{"$q"} = ( defined $router_cnt{"$q"})? $router_cnt{"$q"}+1 : 1;
				}
			}		
		}
	}
	
	return %router_cnt;
	
}


sub check_cyclick_loop{
	my ($self,$paths_to_dst)=@_;
	
	
	my %graph;
	my @all_endpoints=get_list_of_all_endpoints($self);
	# create routing dependency graph
	
	foreach  my $src  (@all_endpoints ){	
		foreach  my $dst  (@all_endpoints ){	
			my $path = $self->object_get_attribute('Route',"${src}::$dst");
			if (defined $path){
				#path counting
				my @p= 	get_adjacent_node_in_a_path($path);
				%graph=add_route_edge_to_graph(\%graph,\@p);
			
			}			
		}
	}
	
	my @p= 	get_adjacent_node_in_a_path($paths_to_dst);
	%graph=add_route_edge_to_graph(\%graph,\@p);
	
	my $result = Algorithm::TSort::cicle_detect( Algorithm::TSort::Graph( ADJ => \%graph ), keys %graph ); 
	
	#print Data::Dumper->Dump([\%graph],["link"]);
	#print "result=$result\n";
	
	
	
	
	
	
	
	return  $result;
	
	
}

sub generate_topology{
	my ($self,$info)=@_;
	my $name=$self->object_get_attribute('save_as');
    my $error = check_verilog_identifier_syntax($name);
    if ( defined $error ){
        #message_dialog("The \"$name\" is given with an unacceptable formatting. The mpsoc name will be used as top level verilog module name so it must follow Verilog identifier declaration formatting:\n $error");
        my $message = "The \"$name\" is given with an unacceptable formatting. The topology name will be used as top level Verilog module name so it must follow Verilog identifier declaration formatting:\n $error";
        add_colored_info($info, $message,'red' );
        return 0;
    }
    my $rname=$self->object_get_attribute('routing_name');
    $error = check_verilog_identifier_syntax($rname);
    if ( defined $error ){
        #message_dialog("The \"$rname\" is given with an unacceptable formatting. The mpsoc name will be used as top level verilog module name so it must follow Verilog identifier declaration formatting:\n $error");
        $rname='Undefined' if(!defined $rname);
        my $message = "The \"$name\" is given with an unacceptable formatting. The routing name will be used as routing Verilog module name so it must follow Verilog identifier declaration formatting:\n $error";
        add_colored_info($info, $message,'red' );
        return 0;
    }
    
    
    
    
	#make destination dir
	my $dir =get_project_dir()."/mpsoc/rtl/src_topology/$name";
	mkpath("$dir",1,01777) unless (-d $dir) ;  
    mkpath("$dir/../common",1,01777) unless (-d "$dir/../common") ;  
    
	#save topology image file
	$self->object_add_attribute("graph_save","name","$dir/$name");
	$self->object_add_attribute("graph_save","extension",'png');
	$self->object_add_attribute("graph_save","enable",1);
	
	show_custom_topology_diagram ($self,undef,"topology_diagram");
	
	
	
	#generate topology top module verilog file
	generate_topology_top_v($self,$info,$dir);
	generate_topology_top_genvar_v($self,$info,$dir);
	generate_routing_v($self,$info,$dir);
	#generate_connection_v($self,$info,$dir);
	add_routing_instance_v($self,$info,$dir);
	add_noc_instance_v($self,$info,$dir);
	add_noc_custom_h($self,$info,$dir);
	save_topology_parameter_object_file($self,$info);	
	
	#create the file list
	my $txt="+incdir+./\n";
	my @files = File::Find::Rule->file()
                            ->name( '*.v','*.sv')
                            ->in( "$dir/../" );	
    foreach my $f (@files){
    	my $d = basename(dirname(abs_path($f)));
    	my $n = basename($f);
    	$txt.="./$d/$n\n";    	
    }
	save_file("$dir/../custom_flist.f",$txt);
	
	
}


sub save_topology_parameter_object_file{
	my ($self,$info)=@_;	
	my $name=$self->object_get_attribute('save_as');
	my $rname=$self->object_get_attribute('routing_name');
	my $dir =get_project_dir()."/mpsoc/rtl/src_topology";
	my $file="$dir/param.obj";
	
	my %param;
	
	if(-f $file){
		 my ($pp,$r,$err) = regen_object($file );
            if ($r){        
                add_info($info,"**Error: cannot open $file file: $err\n");
                return;
            } 
		
		%param=%{$pp};		
	}
	
	
	my @ends=get_list_of_all_endpoints($self);
    my @routers=get_list_of_all_routers($self);
    
    my $MAX_P=0;
    my %router_ps;
    foreach my $p (@routers){
    	my $Pnum=$self->object_get_attribute("$p",'PNUM');
    	$MAX_P =$Pnum  if($Pnum>$MAX_P ); 
    	$router_ps{$Pnum}=(defined $router_ps{$Pnum})? $router_ps{$Pnum}+1 : '1';   	
    }	

    my $NE= scalar @ends;
    my $NR= scalar @routers;
	
	
	$param{"\"$name\""}{'T1'}=$NE;
	$param{"\"$name\""}{'T2'}=$NR;
	$param{"\"$name\""}{'T3'}=$MAX_P;
	my $routs = $param{"\"$name\""}{'ROUTE_NAME'};
	my $new="\"$rname\"";
	if(!defined $routs){
		$param{"\"$name\""}{'ROUTE_NAME'}=$new;
	}
	else {	
		my @r=split(/\s*,\s*/,$routs);
		unless( grep (/^$new$/,@r)){
			$param{"\"$name\""}{'ROUTE_NAME'}= $routs.",$new" ;
		}
	}
	
	$param{"\"$name\""}{'ROUTER_Ps'}= \%router_ps;
	
	
	my @er_addr;
	foreach my $end (@ends){
		my $connect = $self->{$end}{'PCONNECT'}{'Port[0]'};
		my ($Rname,$Rport)=split(/\s*,\s*/,$connect);
		my $R = get_scolar_pos($Rname,@routers);
		push(@er_addr,$R);			
	}
	$param{"\"$name\""}{'er_addr'}= \@er_addr;
	
	
	
	
    open(FILE,  ">$file") || die "Can not open: $!";
    print FILE perl_file_header("$file");
    print FILE Data::Dumper->Dump([\%param],['Topology']);
    close(FILE) || die "Error closing file: $!";
	
}


sub get_path_route_widgets {
	my 	($self,$info)=@_;

	my 		$w1 = show_paths_between_two_endps($self,$info);
	my		$w2 = routing_summary($self,$info);
    my $h=gen_hpaned($w1,.15,$w2);
    $h -> pack1($w1, TRUE, TRUE); 
	$h -> pack2($w2, TRUE, TRUE); 
	return $h;
}


sub load_nwm{
	my ($self,$info)=@_;
	load_net_maker($self,$info);
	my $n=0;
    my $sample="sample$n";
	$n++;
	$self->object_add_attribute("id",undef,$n);
	$self->object_add_attribute("active_setting",undef,undef);
	$self->object_add_attribute_order("samples",$sample);
	$self->object_add_attribute($sample,"color",1);
	add_color_to_gd($self);	
}

sub build_network_maker_gui {
	my ($self) = @_;
	set_gui_status($self,"ideal",0);
	$self->object_add_attribute ("process_notebook","currentpage",0);
	my $main_table= def_table(2,10,FALSE);
	
    my ($infobox,$info)= create_txview();
	
	
	my $notebook = gen_notebook();
	$notebook->set_tab_pos ('left');
	$notebook->set_scrollable(TRUE);
	
	
	
	my $page0=take_node_num_page($self);
	my $page1=take_instance_page($self);
	my $page2=connection_page_auto($self,$info);
	my $page3=connection_page($self,$info);
	my $page4=routing_page_manual($self,$info);
	
	my $page0_win = add_widget_to_scrolled_win($page0);
	my $page1_win = add_widget_to_scrolled_win($page1);
	my $page2_win = add_widget_to_scrolled_win($page2);
	my $page3_win = add_widget_to_scrolled_win($page3);
	my $page4_win = add_widget_to_scrolled_win($page4);

	
	$notebook->append_page ($page0_win,gen_label_in_center  (" Nodes #"));
	$notebook->append_page ($page1_win,gen_label_in_center  ("Instance"));
	$notebook->append_page ($page2_win,gen_label_in_center  ("Connection Auto"));
	$notebook->append_page ($page3_win,gen_label_in_center  ("Connection Manual"));
	$notebook->append_page ($page4_win,gen_label_in_center  ("Route Select"));

	
	$notebook->signal_connect( 'switch-page'=> sub{ # rebulid the current page		
		$self->object_add_attribute ("process_notebook","currentpage",$_[2]);	#save the new pagenumber
		set_gui_status($self,"ref",1);	
	});	
	
		
	my $draw=custom_topology_diagram($self);
	my $h1=gen_hpaned($notebook,.35,$draw);
	
	
	my $v2=gen_vpaned($h1,.65,$infobox);
	my $pronoc_dir	  = get_project_dir(); #mpsoc dir addr
	my $target_dir= "$pronoc_dir/mpsoc/rtl/src_topology/";
    my ($entrybox,$entry ) =gen_save_load_widget (
        $self, #the object 
        "Topology name",#the label shown for setting configuration
        'save_as',#the key name for saveing the setting configuration in object 
        'Custom NoC Topology',#the label full name show in tool tips
        $target_dir,#Where the generted RTL files are loacted. Undef if not aplicaple
        'soc',#check the given name match the SoC or mpsoc name rules
        'lib/netwmaker',#where the current configuration seting file is saved
        'NWM',#the extenstion given for configuration seting file
		\&load_nwm,#refrence to load function
		$info
        );


	my $generate = def_image_button('icons/gen.png','Generate');
	my ($entrybox2,$entry2) = def_h_labeled_entry('Routing Alg. name:',undef);
	
	$entry2->signal_connect( 'changed'=> sub{
		my $name=$entry2->get_text();
		$self->object_add_attribute ("routing_name",undef,$name);	
	});	

	$main_table->attach_defaults ($v2  , 0, 12, 0,24);	
	$main_table->attach ($entrybox,2, 4, 24,25,'expand','shrink',2,2);
	$main_table->attach ($entrybox2,4, 6, 24,25,'expand','shrink',2,2);	
	$main_table->attach ($generate, 6, 9, 24,25,'expand','shrink',2,2);

	my $sc_win = add_widget_to_scrolled_win($main_table);	
	
	#setting for graphs
	my $n=0;
    my $sample="sample$n";
	$n++;
	$self->object_add_attribute("id",undef,$n);
	$self->object_add_attribute("active_setting",undef,undef);
	$self->object_add_attribute_order("samples",$sample);
	$self->object_add_attribute($sample,"color",1);
	add_color_to_gd($self);
	
	$generate->signal_connect("clicked" => sub{ 
		generate_topology($self,$info);
	
	});	
		
	
	
	#check soc status every 0.5 second. refresh device table if there is any changes 
	Glib::Timeout->add (100, sub{ 
	   
		my ($state,$timeout)= get_gui_status($self);
		
		if ($timeout>0){
			$timeout--;
			set_gui_status($self,$state,$timeout);	
			return TRUE;
			
		}
		if($state eq "ideal"){
			return TRUE;
			 
		}
		
		if($state eq "ref" || $state eq "redraw"){
			
			my $page_num=$self->object_get_attribute ("process_notebook","currentpage");
			if($state eq "ref"){
				if($page_num==0){
					$page0->destroy;
					$page0=take_node_num_page($self);
					add_widget_to_scrolled_win($page0,$page0_win);
					$page0_win->show_all;
					
				}
				if($page_num==1){
					$page1->destroy;
					$page1=take_instance_page($self);
					add_widget_to_scrolled_win($page1,$page1_win);
					$page1_win->show_all;
				}
				if($page_num==2){
					$page2->destroy;
					$page2=connection_page_auto($self,$info);
					add_widget_to_scrolled_win($page2,$page2_win);
					$page2_win->show_all;
				}
				if($page_num==3){
					$page3->destroy;
					$page3=connection_page($self,$info);
					add_widget_to_scrolled_win($page3,$page3_win);
					$page3_win->show_all;
				}
				if($page_num==4){
					$page4->destroy;
					$page4=routing_page_manual($self,$info);
					add_widget_to_scrolled_win($page4,$page4_win);
					$page4_win->show_all;
				}
						
			}			
			
			if($page_num==4  ){
				$draw->destroy;
				$draw = get_path_route_widgets($self,$info);
				$h1 -> pack2($draw, TRUE, TRUE);       	
				
				
			}else{
				
				$draw->destroy;
				$draw=custom_topology_diagram($self);
				$h1 -> pack2($draw, TRUE, TRUE);    
			}			
			my $saved_name=$self->object_get_attribute('save_as');
		    $entry->set_text($saved_name)if(defined $saved_name);
		    
		    $saved_name = $self->object_get_attribute('routing_name');
		    $entry2->set_text($saved_name) if(defined $saved_name);
		    
			set_gui_status($self,"ideal",0);
			$main_table->show_all();	
			
			return TRUE;
			 
		}	
		
		#refresh GUI
			
		
		$main_table->show_all();			
		set_gui_status($self,"ideal",0);
		
		return TRUE;
		
	} );

	return $sc_win;	
}
