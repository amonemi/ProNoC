#!/usr/bin/perl -w
use constant::boolean;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use soc;
require "widget.pl"; 
require "emulator.pl";
use File::Copy;
use Chart::Gnuplot;


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
                my $v=(defined $s_value) ? $self->soc_get_module_param_value($instance_id,$s_value) : 1;
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
    my $scrolled_win = add_widget_to_scrolled_win();
    $window->add ($table);
    my $plus = def_image_button('icons/plus.png',undef,TRUE);
    my $minues = def_image_button('icons/minus.png',undef,TRUE);
    my $unused = gen_check_box_object ($self,"tile_diagram","show_unused",0,undef,undef);
    my $save = def_image_button('icons/save.png',undef,TRUE);
    my $clk = gen_check_box_object ($self,"tile_diagram","show_clk",0,undef,undef);
    my $reset = gen_check_box_object ($self,"tile_diagram","show_reset",0,undef,undef);
    my $dot_file = def_image_button('icons/add-notes.png',undef,TRUE);    
    set_tip($dot_file, "Show dot file.");
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
    $table->attach ($dot_file,  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
    while ($col<20){
        my $tmp=gen_label_in_left('');
        $table->attach_defaults ($tmp, $col,  $col+1,0,1);$col++;
    }
    $table->attach_defaults ($scrolled_win, 0, 20, 1, 20); #,'fill','shrink',2,2);    
    $plus  -> signal_connect("clicked" => sub{ 
        $scale*=1.1 if ($scale <10);
        $self->object_add_attribute("tile_diagram","scale", $scale );
        gen_show_diagram($self,$scrolled_win,'tile',"tile_diagram");    
    });    
    $minues  -> signal_connect("clicked" => sub{ 
        $scale*=.9  if ($scale >0.1); ;
        $self->object_add_attribute("tile_diagram","scale", $scale );
        gen_show_diagram($self,$scrolled_win,'tile',"tile_diagram");    
    });
    $save-> signal_connect("clicked" => sub{ 
            save_inline_diagram_as ($self);
            show_tile_diagram($self);
            $window->destroy;
        });    
    $unused-> signal_connect("toggled" => sub{
        gen_show_diagram($self,$scrolled_win,'tile',"tile_diagram");    
    });
    $clk-> signal_connect("toggled" => sub{
        gen_show_diagram($self,$scrolled_win,'tile',"tile_diagram");    
    });
    $reset-> signal_connect("toggled" => sub{
        
        gen_show_diagram($self,$scrolled_win,'tile',"tile_diagram");        
    });
    $dot_file-> signal_connect("clicked" => sub{ 
            my $dotfile = get_dot_file_text($self,'tile');    
            show_text_in_scrolled_win($self,$scrolled_win, $dotfile);            
    });
    gen_show_diagram($self,$scrolled_win,'tile',"tile_diagram");    
    $window->show_all();
}


sub gen_show_diagram{
    my ($self,$scrolled_win,$type,$name)=@_;
    my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
    if ($type eq 'topology' && $topology eq '"CUSTOM"'){
        my $name=$self->object_get_attribute('noc_param','CUSTOM_TOPOLOGY_NAME');
        $name=~s/["]//gs;                
        my $image=  get_project_dir()."/mpsoc/rtl/src_topology/$name/$name.png";
        my $tmp  = "$ENV{'PRONOC_WORK'}/tmp/diagram.png";
        unlink $tmp; 
        return 0 unless (-f "$image");
        copy ($image,$tmp);
        return 0 unless (-f "$tmp");
        show_diagram ($self,$scrolled_win,$name);
        return 1;
    }
    my $dotfile = get_dot_file_text($self,$type);    
    generate_and_show_graph_using_graphviz ($self,$scrolled_win,$dotfile, $name);    
}


sub show_topology_diagram {
    my ($self)= @_;
    my $table=def_table(20,20,FALSE);
    my $window=def_popwin_size(80,80,"NoC-based MPSoC topology block diagram",'percent');    
    my $scrolled_win = add_widget_to_scrolled_win();
    my $notebook = gen_notebook();
    $notebook->set_tab_pos ('top');
    $notebook->set_scrollable(TRUE);
    $window->add($notebook);
    my @data;    
    my $ref =$self->object_get_attribute('noc_param');
    if(defined $ref){
        my %param=%{$ref};
        foreach my $p (sort keys %param){
            push (@data, {0 => "$p", 1 =>"$param{$p}"});
        }        
    }
    
    # create list store
    my @clmn_type =  ('Glib::String',  'Glib::String'); 
    my @clmns = (" Parameter Name   ", " Value ");
    my $page2=add_widget_to_scrolled_win(gen_list_store (\@data,\@clmn_type,\@clmns));
    $notebook->append_page ($table,gen_label_with_mnemonic ("Topology diagram")) ;
    $notebook->append_page ($page2,gen_label_with_mnemonic ("NoC parameters")) ;
    my $plus = def_image_button('icons/plus.png',undef,TRUE);
    my $minues = def_image_button('icons/minus.png',undef,TRUE);
    my $save = def_image_button('icons/save.png',undef,TRUE);
    my $dot_file = def_image_button('icons/add-notes.png',undef,TRUE);        
    set_tip($dot_file, "Show dot file.");
    
    my $gtype=$self->object_get_attribute("tile_diagram","gtype");
    if (!defined $gtype){
        $gtype='comp' ;
        $self->object_add_attribute("tile_diagram","gtype",$gtype);
    }        
    my $graph_type= ($gtype eq 'comp')? def_colored_button('comp',17): def_colored_button('simple',4);
    my $box=def_hbox(FALSE,0);
    $box->pack_start( $graph_type, FALSE, FALSE, 0);
    my $scale=$self->object_get_attribute("tile_diagram","scale");
    $scale= 1 if (!defined $scale);
    
    my $col=0;
    $table->attach ($plus ,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
    $table->attach ($minues,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
    $table->attach ($save,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
    $table->attach ($dot_file,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
    $table->attach ($box,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
    #$table->attach (gen_label_in_left("     Remove unconnected Interfaces"),  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
    #$table->attach (gen_label_in_left("     Remove Clk Interfaces"),  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
    #$table->attach (gen_label_in_left("     Remove Reset Interfaces"),  $col,  $col+1,0,1,'shrink','shrink',2,2); $col++;
    while ($col<20){        
        my $tmp=gen_label_in_left('');
        $table->attach_defaults ($tmp, $col,  $col+1,0,1);$col++;
    }
    
    $table->attach_defaults ($scrolled_win, 0, 20, 1, 20); #,'fill','shrink',2,2);    
    $plus  -> signal_connect("clicked" => sub{ 
        $scale*=1.1 if ($scale <10);
        $self->object_add_attribute("topology_diagram","scale", $scale );
        gen_show_diagram($self,$scrolled_win,'topology',"topology_diagram");    
        
    });    
    $minues  -> signal_connect("clicked" => sub{ 
        $scale*=.9  if ($scale >0.1);
        $self->object_add_attribute("topology_diagram","scale", $scale );
        gen_show_diagram($self,$scrolled_win,'topology',"topology_diagram");    
    });
    $save-> signal_connect("clicked" => sub{ 
            save_inline_diagram_as ($self);            
            show_topology_diagram($self);
            $window->destroy;
    });    
    
    $dot_file-> signal_connect("clicked" => sub{ 
            my $dot_file=get_dot_file_text($self,'topology');
            show_text_in_scrolled_win($self,$scrolled_win, $dot_file);            
    });
    
    $graph_type-> signal_connect("clicked" => sub{ 
            my $gtype=$self->object_get_attribute("tile_diagram","gtype");            
            my $new = ($gtype eq "simple")? "comp" : "simple";
            $self->object_add_attribute("tile_diagram","gtype",$new);    
            $graph_type= ($new eq 'comp')? def_colored_button('comp',17): def_colored_button('simple',4);
            show_topology_diagram($self);
            $window->destroy;            
    });    
    gen_show_diagram($self,$scrolled_win,'topology',"topology_diagram");    
    $window->show_all();
    $notebook->set_current_page (0);
}


sub get_dot_file_text {
    my ($self,$type)=@_;
    my $dotfile;
    $dotfile=   get_dot_file($self) if ($type eq 'tile');
    $dotfile=   get_topology_dot_file($self) if ($type eq 'topology');
    $dotfile=   generate_custom_topology_dot_file($self) if ($type eq 'custom_topology');    
    $dotfile=   generate_trace_dot_file($self) if ($type eq 'trace');
    $dotfile=   generate_merge_actor_dot_file    ($self) if ($type eq 'merge-actor');
    $dotfile=   generate_map_dot_file($self) if ($type eq 'map');
    return $dotfile;    
}


sub gen_diagram {
    my ($self,$type)=@_;
    my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
    if ($type eq 'topology' && $topology eq '"CUSTOM"'){
        my $name=$self->object_get_attribute('noc_param','CUSTOM_TOPOLOGY_NAME');
        $name=~s/["]//gs;                
        my $image=  get_project_dir()."/mpsoc/rtl/src_topology/$name/$name.png";
        my $tmp  = "$ENV{'PRONOC_WORK'}/tmp/diagram.png";
        unlink $tmp; 
        return 0 unless (-f "$image");
        copy ($image,$tmp);
        return 0 unless (-f "$tmp");
        return 1;
    }
    my $dotfile = get_dot_file_text(@_);                                    
    my $tmp_dir  = "$ENV{'PRONOC_WORK'}/tmp";
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
    my ($self,$scrolled_win,$name,$image_name)=@_;    
    $image_name="diagram.png" if (!defined $image_name);
    my @list = $scrolled_win->get_children();
    foreach my $l (@list){ 
        $scrolled_win->remove($l);            
    }
    my $scale=$self->object_get_attribute($name,"scale");
    $scale= 1 if (!defined $scale);
    my $tmp_dir  = "$ENV{'PRONOC_WORK'}/tmp";
    my $diagram=open_image("$tmp_dir/$image_name",70*$scale,70*$scale,'percent');
    add_widget_to_scrolled_win($diagram,$scrolled_win);
    $scrolled_win->show_all();    
}

sub show_text_in_scrolled_win {
    my ($self,$scrolled_win, $text)=@_;
    my @list = $scrolled_win->get_children();
    foreach my $l (@list){ 
        $scrolled_win->remove($l);            
    }
    my ($u,$tview)=create_txview();
    show_info($tview, $text);
    add_widget_to_scrolled_win($u,$scrolled_win);
    $scrolled_win->show_all();        
}

sub save_diagram_as {
    my $self= shift;
    my $file;
    my $title ='Save as';
    my @extensions=('png');
    my $open_in=undef;
    my $dialog = save_file_dialog  ( 'Save file',@extensions);
    $dialog->set_current_folder ($open_in) if(defined  $open_in); 
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

sub save_inline_diagram_as {
    my $self= shift;
    my $file;
    my $title ='Save as';
    my @extensions=('png','jpeg');
    my $open_in=undef;
    my $dialog = save_file_dialog  ('Save file',@extensions);
    $dialog->set_current_folder ($open_in) if(defined  $open_in);
    if ( "ok" eq $dialog->run ) {
        $file = $dialog->get_filename;
        my $ext = $dialog->get_filter;
        $ext=$ext->get_name;
        my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
        $file = ($suffix eq ".$ext" )? $file : "$file.$ext";
        $self->object_add_attribute("graph_save","name","$path/$name");
        $self->object_add_attribute("graph_save","extension",$ext);
        $self->object_add_attribute("graph_save","enable",1);
        set_gui_status($self,"ref",5);
    }
    $dialog->destroy;
}



sub generate_trace_dot_file{
    my $self=shift;
    my $dotfile=
"digraph G {
    graph [ layout = neato, rankdir = LR , splines=polyline, overlap = false]; 
    
";
#add connections
    my @traces= get_trace_list($self,'raw');
    foreach my $p (@traces) {    
        my ($src,$dst, $Mbytes, $file_id, $file_name)=get_trace($self,'raw',$p);
        $dotfile=$dotfile."\"$src\" -> \"$dst\"  [label=\"$Mbytes\" ];\n";    
    }
    $dotfile=$dotfile."\n}\n";
    return $dotfile;
}


sub generate_map_dot_file{
    my $self=shift;
    my $dotfile=
"digraph G {
    graph [layout = neato, rankdir = LR ,splines=spline,  overlap = false]; 
    node[shape=record];
    
    ";
    
#add nodes    
    my @tasks=get_all_tasks($self,"merge");
    my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info($self);    
    my %pos=get_endp_pos($self);    
    my @mappedtasks;    
    for(my $i=0; $i<$NE; $i++){ 
        my $task=get_task_assigned_to_tile($self,$i);
        push(@mappedtasks,$task) if (defined $task); 
        $task= "_" if (!defined $task); 
        my $n =    "tile($i)" ;
        my $m =    "tile($i)" ;
        my $node = "\"$m\"";                    
        my $label =   "\"<S$task> $n|<R$task> $task\"" ;
        $dotfile=$dotfile."
$node\[
    label = $label
    pos = $pos{$i}
];";
    }
    $dotfile=$dotfile."\n\n";
    #add connections
    my @traces= get_trace_list($self,'merge');
    my %src_dst;
    foreach my $p (@traces){
        my ($src,$dst, $Mbytes, $file_id, $file_name)=get_trace($self,'merge',$p);        
        my $src_tile=get_task_give_tile($self,"$src");
        my $dst_tile=get_task_give_tile($self,"$dst");        
        next if ($src_dst{"${src_tile}_$dst_tile"}); #make sure there will be only one arow betwenn each source destination tile
        next if ( $src_tile eq "-" ||  $dst_tile eq "-" );            
        $dotfile=$dotfile." \"$src_tile\" :  \"S$src\" ->  \"$dst_tile\" : \"R$dst\"  ;\n" if((defined $src_tile )&& (defined $dst_tile));
        $src_dst{"${src_tile}_$dst_tile"}=1;
    }
    $dotfile=$dotfile."\n}\n";
    return $dotfile;
}


sub show_trace_diagram {
    my ($self,$type)=@_;
    my $table=def_table(20,20,FALSE);
    my $window=def_popwin_size(80,80,"Trace Diagram",'percent');    
    my $scrolled_win =add_widget_to_scrolled_win();
    $window->add ($table);
    my $plus = def_image_button('icons/plus.png',undef,TRUE);
    my $minues = def_image_button('icons/minus.png',undef,TRUE);
    my $save = def_image_button('icons/save.png',undef,TRUE);
    my $dot_file = def_image_button('icons/add-notes.png',undef,TRUE);    
    set_tip($dot_file, "Show dot file.");
    my $scale=$self->object_get_attribute("${type}_diagram","scale");
    $scale= 1 if (!defined $scale);
    my $col=0;
    $table->attach ($plus ,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
    $table->attach ($minues,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
    $table->attach ($save,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
    $table->attach ($dot_file,  $col, $col+1,0,1,'shrink','shrink',2,2); $col++;
    $table->attach_defaults ($scrolled_win, 0, 20, 1, 20); #,'fill','shrink',2,2);    
    
    while ($col<20){    
        my $tmp=gen_label_in_left('');
        $table->attach_defaults ($tmp, $col,  $col+1,0,1);$col++;
    }
    
    $plus  -> signal_connect("clicked" => sub{ 
        $scale*=1.1 if ($scale <10);
        $self->object_add_attribute("${type}_diagram","scale", $scale );
        my $dotfile = get_dot_file_text($self,$type);
        generate_and_show_graph_using_graphviz ($self,$scrolled_win,$dotfile, "${type}_diagram");
    });    
    $minues  -> signal_connect("clicked" => sub{ 
        $scale*=.9  if ($scale >0.1); ;
        $self->object_add_attribute("${type}_diagram","scale", $scale );
        gen_show_diagram ($self,$scrolled_win,$type,"${type}_diagram");
    });
    $save-> signal_connect("clicked" => sub{ 
            save_inline_diagram_as ($self);
            show_trace_diagram($self,$type);
            $window->destroy;
        });    
    
    $dot_file-> signal_connect("clicked" => sub{ 
        my $dotfile = get_dot_file_text($self,$type);    
        show_text_in_scrolled_win($self,$scrolled_win, $dotfile);        
            
    });
    gen_show_diagram ($self,$scrolled_win,$type,"${type}_diagram");
    $window->show_all();
}

sub node_connection{
    my ($sn,$sx,$sy,$sp,$dn,$dx,$dy,$dp,$gtype)=@_;
    $gtype="comp" if(!defined $gtype);
    
    my $spp = (defined $sp  && $gtype eq "comp" ) ? ":\"p$sp\"" : " ";
    my $dpp = (defined $dp  && $gtype eq "comp" ) ? ":\"p$dp\"" : " ";
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


##################################
#
#################################
sub generate_heat_map_table{
    my ($d)=@_ ;
    return (def_table (1, 1, FALSE),def_table (1, 1, FALSE)) if (!defined $d);
    my %data=%{$d};
    my @xs = (sort {$a<=>$b} keys %data);
    my $max=0;
    #for(my $y=0; $y<$dim; $y++){         
    #    for(my $x=0; $x<$dim; $x++){    
        foreach my $y (@xs){
            foreach my $x (@xs){
            #$data{$x}{$y}=int(rand(50000));
            #$data{$x}{$y}=$y*64+$x;
            $max = $data{$x}{$y} if( $max < $data{$x}{$y});
        }
    }
    my $width_max = length int $max;
    my $table = def_table (1, 1, FALSE);
    #for(my $y=0; $y<$dim; $y++){ 
    foreach my $y (@xs){
        my $l=gen_label_in_center("$y");
        $table->attach ($l,    $y+1,$y+2,0,1,'expand','shrink',2,2);      
    }
    #for(my $x=0; $x<$dim; $x++){
    foreach my $x (@xs){
        my $l=gen_label_in_center("$x");
        $table->attach ($l,    0,1,$x+1,$x+2,'expand','shrink',2,2);      
    }
    #for(my $y=0; $y<$dim; $y++){         
    #    for(my $x=0; $x<$dim; $x++){
    foreach my $y (@xs){
        foreach my $x (@xs){
            my $d=$data{$x}{$y}; 
            my $c = int (((5*$d))/($max+1));
            my $v = length int $d;
            until ($v >= $width_max){
                $d="  ".$d;
                $v++;
            }   
            my $l =gen_colored_label( "   " ,32+$c);    
            set_tip($l,"E[$x]->E[$y]=$d");
            $table->attach ($l, $y+1,$y+2,$x+1,$x+2,'expand','shrink',2,2);            
        }
    }   
    my $scale = def_table (1, 1, FALSE);
    my $v=gen_label_in_center("0");    
    $scale->attach ($v, 1,2,0,1,'expand','shrink',2,2); 
    for (my $i=0; $i<5; $i++){
        my $l =gen_colored_label( "   " ,32+$i);
        my $val =int( (2*$i+1)*$max/10); 
        my $v=gen_label_in_center($val);    
        $scale->attach ($v, 0,1,$i+1,$i+2,'expand','shrink',2,2);           
        $scale->attach ($l, 1,2,$i+1,$i+2,'expand','shrink',2,2); 
        $scale->attach (gen_label_in_center("$max"), 1,2,$i+2,$i+3,'expand','shrink',2,2) if($i==4);
    }
    return ($table,$scale);
}

sub generate_heat_map_img_file{
    my ($d,$image_file,$title)=@_ ;
    return  if (!defined $d);
    my %hash=%{$d};        
    my @data;
    my @xs = (sort {$a<=>$b} keys %hash);
    foreach my $y (@xs){
        my @b;
        push (@data ,\@b) if ($y!=0);   
        foreach my $x (@xs){
            my @a=($x,$y, $hash{$x}{$y});
            push (@data ,\@a); 
        }
    }
    my $length = @xs;
    $length+=1;
    my $chart = Chart::Gnuplot->new(
        bg         => 'white',
        view       => 'map',
        palette    => 'defined (0 0 0 1, 1 1 1 0, 2 1 0 0)',
        output     => "$image_file",
        title      => "$title",
        xlabel     => 'Endp-ID',
        ylabel     => 'Endp-ID',
        xrange       => [-1, $length],
        size       => 'ratio -1',
        xtics      => {
            labels   => \@xs,
        },
        ytics      => {
            labels   => \@xs,
        },
        mxtics => '2',
        mytics => '2',
        border => undef,
        grid   => 'front mxtics mytics lw 1.5 lt -1 lc rgb \'white\'',
    );
    my $dataSet = Chart::Gnuplot::DataSet->new(
        points => \@data,
        view   => 'map',
        type   => 'matrix',
        using  => "1:2:3 with image",     
    );
    $chart->plot2d($dataSet);
}


sub generate_heat_map_dot_file{
    my ($data,$dim)=@_ ;
    my $dotfile=
"digraph G {
    graph [layout = neato, rankdir = RL , splines = true, overlap = true]; 
    node[shape=record];    
    ";
    for(my $y=0; $y<$dim; $y++){         
        for(my $x=0; $x<$dim; $x++){
            my $tx=$x*2+0.5;
            my $ty=($dim-$y-1)*2+0.5;        
            my $w=2;
            $tx/=2;
            $ty/=2;        
            $w/=2;
            $dotfile.="
                    \"t${x}_$y\"[
    label = \"8822255\"
    pos = \"$tx,$ty!\"
    width =$w
    height=$w  
    style=filled
    fontsize=\"12\"
    fillcolor=orange
    
];
"
        }
    }
    $dotfile=$dotfile."\n}\n";
    return $dotfile;
}


sub generate_mesh_dot_file{
    my $self=shift;
    my $gtype=$self->object_get_attribute("tile_diagram","gtype");    
    my $dotfile=
"digraph G {
    graph [layout = neato, rankdir = RL , splines = true, overlap = true]; 
        
    
    node[shape=record];
    
    ";
    
#five_port_router [
#    label="{ |2| } | {3|R0|1} | { |4|0}"
#    shape=record
#    color=blue
#    style=filled
#    fillcolor=blue
#];    
    
#add nodes
    my $nx=$self->object_get_attribute('noc_param','T1');
    my $ny=$self->object_get_attribute('noc_param','T2');
    my $nz=$self->object_get_attribute('noc_param','T3');
    my ($NE, $NR, $RAw, $EAw, $Fw)  = get_topology_info($self);
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
                        $dotfile.=get_record_endp_dot_file("T$id","T$id", "$tx,$ty!");    
    }}}
    
    if($topology eq '"FMESH"' ) {
        my $tmp = $ny*$nx*$nz;
        for(my $x=0; $x<$nx; $x++){ 
            #top edges
            my $id=$tmp + $x;
            my $tx=$x*3;    
            my $ty=($ny)*2.5-.5;                
            $dotfile.=get_record_endp_dot_file("T$id","T$id", "$tx,$ty!");
            get_connected_router_id_to_endp($self,$id);
            #down edges
            $id= $tmp + $nx +$x;
            $tx=$x*3;    
            $ty=-.5;                
            $dotfile.=get_record_endp_dot_file("T$id","T$id", "$tx,$ty!");
        }
        for(my $y=0; $y<$ny; $y++){ 
            #right edges
            my $id= $tmp + 2*$nx +$y;
            my $tx=-1.5;        
            my $ty=($ny-$y-1)*2.5+1;
            $dotfile.=get_record_endp_dot_file("T$id","T$id", "$tx,$ty!");
            #left edges
            $id= $tmp + 2*$nx+$ny +$y;
            $tx=$nx*3-1.5;
            $ty=($ny-$y-1)*2.5+1;
            $dotfile.=get_record_endp_dot_file("T$id","T$id", "$tx,$ty!");
        }
    }
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
            $dotfile.=get_router_dot_file($n,$label,"$xx,$yy!",$gtype);
        }
    }
    $dotfile=$dotfile."\n\n";
    #add connections
    for(my $y=0; $y<$ny; $y++){         
        for(my $x=0; $x<$nx; $x++){
            $dotfile=$dotfile.node_connection('R',get_router_num($self,$x,$y),undef,1,'R',get_router_num($self,($x+1),$y),undef,3,$gtype) if($x <$nx-1);    
            $dotfile=$dotfile.node_connection('R',get_router_num($self,$x,$y),undef,1,'R',get_router_num($self,0,$y),undef,3,$gtype) if($x == ($nx-1) && $btrace);
            $dotfile=$dotfile.node_connection('R',get_router_num($self,$x,$y),undef,2,'R',get_router_num($self,$x,($y-1)),undef,4,$gtype)if($y>0) ; 
            $dotfile=$dotfile.node_connection('R',get_router_num($self,$x,$y),undef,2,'R',get_router_num($self,$x,($ny-1)),undef,4,$gtype) if($y ==0 && $btrace && !$oned);
            #   $dotfile=$dotfile.node_connection('R',$x,$y,0,'T',$x,$y);               
        }
    }
    if($topology eq '"FMESH"' ) {
        for(my $id=0; $id<$NE; $id++){ 
            my $rid= get_connected_router_id_to_endp($self,$id);
            my $tmp = $nx*$ny*$nz;
            my $p = ($id<$tmp)? $id%$nz+5 :
                    ($id<$tmp+$nx)? 2 :
                    ($id<$tmp+2*$nx)? 4 :
                    ($id<$tmp+2*$nx+$ny)? 3:1;
            $dotfile=$dotfile.node_connection('R',$rid,undef,$p,'T',$id,undef,undef,$gtype);               
        }
    }else{
        for(my $id=0; $id<$NE; $id++){ 
            my $rid=int($id/$nz);
            my $p =  $id%$nz+5;
            $dotfile=$dotfile.node_connection('R',$rid,undef,$p,'T',$id,undef,undef,$gtype);               
        }
    }
    $dotfile=$dotfile."\n}\n";
    return $dotfile;
}


sub get_endp_pos {
    my $self=shift;
    my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
    my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info($self);
    my %pos;
    if($topology eq '"FATTREE"' || $topology eq '"TREE"'){
        for(my $i=0; $i<$NE; $i++){
                $pos{$i} = "\"$i,0!\"";
        }
        return %pos;
    }
    #($topology eq '"TORUS"' || $topology eq '"RING"' || $topology eq '"RING"' || $topology eq '"LINE"');    
    my $nx=$self->object_get_attribute('noc_param','T1');
    my $ny=$self->object_get_attribute('noc_param','T2');
    my $nz=$self->object_get_attribute('noc_param','T3');        
    #generate endpoints
    for(my $y=0; $y<$ny; $y++){         
        for(my $x=0; $x<$nx; $x++){
            for(my $z=0; $z<$nz; $z++){
                my $id=($y*$nx+$x)*$nz+$z;                        
                my $offsetx = ($z==0 || $z==3) ? 1.05 : -1.05; 
                my $offsety = ($z==0 || $z==1) ? -0.85 : +0.85; 
                my $tx=$x*3+$offsetx;
                my $ty=($ny-$y-1)*2.5+1+$offsety;
                $pos{$id} = "\"$tx,$ty!\"";
            }
        }
    }
    return %pos;
}

sub get_record_endp_dot_file {
    my ($name,$label,$pos)=@_;
return "$name\[
    label = \"$label\"
    pos = \"$pos\"
    shape=record
    color=orange
    style=filled
    fillcolor=orange
];
";
}

sub get_router_dot_file {
    my ($name,$label,$pos,$type)=@_;
    return ($type eq 'comp')? "\"$name\"\[
    label=\"$label\"
    pos = \"$pos\"
    shape=record
    color=blue
    style=filled
    fillcolor=blue
];
"
: 
"\"$name\"\[
    label=\"$name\"
    pos = \"$pos\"
    shape=circle
    color=blue
    style=filled
    fillcolor=blue
];
";
}

sub generate_fattree_dot_file{
    my $self=shift;
    my $gtype=$self->object_get_attribute("tile_diagram","gtype");    
    my $dotfile=
"digraph G {
    graph [layout = neato, rankdir = LR , splines = true, overlap = true];     
    node[shape=record];    
    ";
#add nodes
    my ($NE, $NR, $RAw, $EAw, $Fw)=get_topology_info($self);
    my $k=$self->object_get_attribute('noc_param','T1');
    my $nl=$self->object_get_attribute('noc_param','T2');
    my @bp;
    my @hp;
    for(my $p=0; $p<$k; $p++) {push (@bp,"<p$p>$p");}
    for(my $p=$k; $p<2*$k; $p++) {push (@hp,"<p$p>$p");}
    my $bp= join("|",@bp);
    my $hp= join("|",@hp);
    #my $NC= powi( $k,$nl  ); #total endpoints
    my $NL= $NE/$k ; #number of nodes in  each layer 
    #add endpoints
    for(my $i=0; $i<$NE; $i++){
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
        my $y=    1.5*($nl-1)+1;    
        my $r=$pos;
        my $label = "\{R$r\}|\{$bp\}";
        $dotfile.=get_router_dot_file("R$r",$label,"$x,$y!",$gtype);
    }
    #add leaves
    for(my $l=1; $l<$nl; $l++){ 
        for(my $pos=0; $pos<$NL; $pos++){ 
            my $x=($k)*$pos+($k/2)-0.5;    
            my $y=    1.5*($nl-$l-1)+1;    
            my $r=$NL*$l+$pos;
            my $label = "\{$hp\}|\{R$r\}|\{$bp\}";
            $dotfile.=get_router_dot_file("R$r",$label,"$x,$y!",$gtype);
        }
    }
    #connect all down input chanels
    my $n=$nl;
    my $nPos = powi( $k, $n-1);
    my $chan_per_direction = ($k * powi( $k , $n-1 )); #up or down
    my $chan_per_level = 2*($k * powi( $k , $n-1 )); #up+down
    for (my $level = 0; $level<$n-1; $level++){
        #input chanel are numbered interleavely, the interleaev depends on level
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
                $dotfile=$dotfile.node_connection('R',$id1,undef,$port,'R',$connect_id,undef,$connect_port,$gtype);    
            }
        }
    }
    #add endpoints connection
    for(my $i=0; $i<$NE; $i++){ 
        my $r= $NL*($nl-1)+int($i/$k);
        $dotfile=$dotfile.node_connection('T',$i,undef,undef,'R',$r,undef,$i%($k),$gtype);    
    }
    $dotfile=$dotfile."\n}\n";
    return $dotfile;
}

sub generate_star_dot_file{
    my $self=shift;
    my $dotfile=
"digraph G {
    graph [layout = neato, fontsize=3, rankdir = LR , splines = true, overlap = false];     
    node[shape=record];    
    ";
    my $pnum=$self->object_get_attribute('noc_param','T1');
    $dotfile.=router_node_dot_sim($pnum,"R","R");    
    for(my $p=0; $p<$pnum; $p++) {
        $dotfile.=endp_node_dot_sim ("T$p","T$p");
        $dotfile.="R -> T$p [dir=none];\n";
        $dotfile.='#'.node_connection('T',$p,undef,undef,'R',0,undef,$p);
    }
    $dotfile.="\n}\n";
    return $dotfile;
}


sub generate_tree_dot_file{
    my $self=shift;
    my $gtype=$self->object_get_attribute("tile_diagram","gtype");    
    my $dotfile=
"digraph G {
    graph [layout = neato, rankdir = LR , splines = true, overlap = true];     
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
    #    my ($NE,$NR)=get_topology_info($self);
    my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info($self);
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
    my $label = "\{R0\}|\{$bp\}";
    my $x=(($NE-1)/2);
    my $y=    1.5*($nl-1)+1;
    $dotfile.=get_router_dot_file("R0",$label,"$x,$y!",$gtype);
    #add leaves
    my $t=1;
    for(my $l=$nl-1; $l>0; $l--){ 
        my $NL = powi($k,$l);
        $t*=$k;
        for(my $pos=0; $pos<$NL; $pos++){             
            my $x=     $t*$pos + ($t-1)/2 ;
            my $y=    1.5*($nl-$l)-.5;
            my $r=sum_powi($k,$l)+$pos;
            my $label = "\{$hp\}|\{R$r\}|\{$bp\}";
            $dotfile.=get_router_dot_file("R$r",$label,"$x,$y!",$gtype);
        }
    }
    #add leave connections
    for(my $l=$nl-1; $l>0; $l--){ 
        my $NL = powi($k,$l);
        for(my $pos=0; $pos<$NL; $pos++){ 
            my $id1=sum_powi($k,$l)+$pos;
            my $id2=sum_powi($k,$l-1)+int($pos/$k);
            $dotfile=$dotfile.node_connection('R',$id1,undef,$k,'R',$id2,undef,$pos % $k,$gtype);    
        }
    }
    #add endpoints connection
    for(my $i=0; $i<$NE; $i++){ 
        my $r= sum_powi($k,$nl-1)+int($i/$k);
        $dotfile=$dotfile.node_connection('T',$i,undef,undef,'R',$r,undef,$i%($k),$gtype);    
    }
    $dotfile=$dotfile."\n}\n";
    return $dotfile;
}


sub get_topology_dot_file{
    my $self=shift;
    my $topology=$self->object_get_attribute('noc_param','TOPOLOGY');
    return generate_mesh_dot_file ($self) if($topology eq '"RING"' || $topology eq '"LINE"' || $topology eq '"MESH"'|| $topology eq '"FMESH"' || $topology eq '"TORUS"' );
    return generate_fattree_dot_file ($self) if($topology eq '"FATTREE"');
    return generate_tree_dot_file($self) if($topology eq '"TREE"');
    return generate_star_dot_file($self) if($topology eq '"STAR"');
}


sub generate_merge_actor_dot_file{
    my $self=shift;
    my $dotfile=
"digraph G {
    graph [ layout = neato, rankdir = LR , splines=polyline, overlap = false]; 
    
";
#add connections
    my @traces= get_trace_list($self,'merge');
    my %src_dst;
    my %dests= get_destport_constant_list ($self,'merge');
    my %srcs = get_srcport_constant_list  ($self,'merge');
    foreach my $p (@traces){
        my ($src,$dst, $Mbytes, $file_id, $file_name,$init_weight,$min_pck, $max_pck,  $burst, $injct_rate, $injct_rate_var,$src_port,$dst_port,$buff_size,$chanel,$vc,$class)
                =get_trace($self,'merge',$p);
        $dotfile=$dotfile."\"$src\" -> \"$dst\"  [label=\"$srcs{$src}{$src_port}{$chanel}->$dests{$dst}{$dst_port}\" ];\n";    
    }
    $dotfile=$dotfile."\n}\n";
    return $dotfile;
}
return 1;