#! /usr/bin/perl -w
use constant::boolean;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use mpsoc;
use soc;
use ip;
use interface;
use POSIX 'strtol';
use File::Path;
use File::Copy;
use Cwd 'abs_path';
use Glib::Event;
use Event; # any order


require "widget.pl"; 
require "mpsoc_verilog_gen.pl";
require "hdr_file_gen.pl";
require "readme_gen.pl";
require "soc_gen.pl";
require "topology.pl";
require "diagram.pl";
require "orcc.pl";

my %noc_param_comment;

sub initial_default_param{
    my $mpsoc=shift;
    my @socs=$mpsoc->mpsoc_get_soc_list();
    foreach my $soc_name (@socs){
        my %param_value;
        my $top=$mpsoc->mpsoc_get_soc($soc_name);
        my @insts=$top->top_get_all_instances();
        my @exceptions=get_NI_instance_list($top);
        @insts=get_diff_array(\@insts,\@exceptions);
        foreach my $inst (@insts){
            my @params=$top->top_get_parameter_list($inst);
            foreach my $p (@params){    
                my  ($default,$type,$content,$info,$global_param,$redefine)=$top->top_get_parameter($inst,$p);
                $param_value{$p}=$default;
            }
        }
        $top->top_add_default_soc_param(\%param_value);
    }
    
}

#############
#    get_soc_lists
############

sub get_soc_list {
    my ($mpsoc,$info)=@_;    
    my $path=$mpsoc->object_get_attribute('setting','soc_path');        
    $path =~ s/ /\\ /g;
    my @socs;
    my @files = glob "$path/*.SOC";
    for my $p (@files){
       my ($soc,$r,$err) = regen_object($p);
        # Read       
         if ($r){        
            add_info($info,"**Error reading  $p file: $err\n");
                 next; 
        } 
        my $top=$soc->soc_get_top();
        if (defined $top){
            my @instance_list=$top->top_get_all_instances();
            #check if the soc has ni port
            foreach my $instanc(@instance_list){
                my $category=$top->top_get_def_of_instance($instanc,'category');
                if($category eq 'NoC') 
                {
                    my $name=$soc->object_get_attribute('soc_name');            
                    #get old tile parameter setting 
                    my $old_top = $mpsoc->mpsoc_get_soc($name);
                    copy_back_custom_soc_param($top,$old_top) if(defined $old_top);
                    $mpsoc->mpsoc_add_soc($name,$top);
                    #print" $name\n";
                }        
            }            
        
        }        
    }# files
    
    # initial  default soc parameter
    initial_default_param($mpsoc);    
    return $mpsoc->mpsoc_get_soc_list;
}

sub copy_back_custom_soc_param{
    my ($new,$old)=@_;
    my @tiles = $old->top_get_custom_tile_list();
    foreach my $tile (@tiles){
        my %l =$old->top_get_custom_soc_param($tile);
        $new->top_add_custom_soc_param (\%l,$tile);
    }
     
}    

sub get_NI_instance_list {
    my $top=shift;
    my @nis;
    return if (!defined $top);
    my @instance_list=$top->top_get_all_instances();
    #check if the soc has ni port
    foreach my $instanc(@instance_list){
            my $category=$top->top_get_def_of_instance($instanc,'category');
             push(@nis,$instanc) if($category eq 'NoC') ;
    }
    return @nis;
}

####################
# get_conflict_decision
###########################


sub get_conflict_decision{
    my ($mpsoc,$name,$inserted,$conflicts,$msg)=@_;
    $msg="\tThe inserted tile number(s) have been mapped previously to \n\t\t\"$msg\".\n\tDo you want to remove the conflicted tiles number(s) in newly \n\tinserted range or remove them from the previous ones? ";
    
    my $wind=def_popwin_size(10,30,"warning",'percent');
    my $label= gen_label_in_left($msg);    
    my $table=def_table(2,6,FALSE);
    $table->attach_defaults ($label , 0, 6, 0,1);
    $wind->add($table);

    my $b1= def_button("Remove Previous");
    my $b2= def_button("Remove Current");
    my $b3= def_button("Cancel");
    
    $table->attach ($b1 , 0, 1, 1,2,'fill','fill',2,2);
    $table->attach ($b2 , 3, 4, 1,2,'fill','fill',2,2);
    $table->attach ($b3 , 5, 6, 1,2,'fill','fill',2,2);


    $wind->show_all();
    
    $b1->signal_connect( "clicked"=> sub{ #Remove Previous
        my @socs=$mpsoc->mpsoc_get_soc_list();        
        foreach my $p (@socs){
            if($p ne $name){
                my @taken_tiles=$mpsoc->mpsoc_get_soc_tiles_num($p);
                my @diff=get_diff_array(\@taken_tiles,$inserted);
                $mpsoc->mpsoc_add_soc_tiles_num($p,\@diff) if(scalar @diff  );
                $mpsoc->mpsoc_add_soc_tiles_num($p,undef) if(scalar @diff ==0 );
            }
        }
        $mpsoc->mpsoc_add_soc_tiles_num($name,$inserted) if(defined $inserted  );
        #set_gui_status($mpsoc,"ref",1);        
        $wind->destroy();        
        get_soc_parameter_setting($mpsoc,$name, $inserted)if(defined $inserted  );
            
    });
    
    $b2->signal_connect( "clicked"=> sub{#Remove Current
        my @new= get_diff_array($inserted,$conflicts);    
        $mpsoc->mpsoc_add_soc_tiles_num($name,\@new) if(scalar @new  );
        $mpsoc->mpsoc_add_soc_tiles_num($name,undef) if(scalar @new ==0 );
        #set_gui_status($mpsoc,"ref",1);        
        $wind->destroy(); 
        get_soc_parameter_setting($mpsoc,$name, \@new) if(scalar @new  );       
        
    });
    
    $b3->signal_connect( "clicked"=> sub{
        $wind->destroy();        
        
    });        
}    


#############
#    check_inserted_ip_nums
##########
sub check_inserted_ip_nums{
    my  ($mpsoc,$name,$str)=@_;
    my @all_num=();
    $str= remove_all_white_spaces ($str);
    
    if($str !~ /^[0-9.:,]+$/){ message_dialog ("The Ip numbers contains invalid character" ); return; }
    my @chunks=split(/\s*,\s*/,$str);
    foreach my $p (@chunks){
        my @range=split(':',$p);
        my $size= scalar @range;
        if($size==1){ # its a number
            if ( grep( /^$range[0]$/, @all_num ) ) { message_dialog ("Multiple definition for IP number $range[0]" ); return; }
            push(@all_num,$range[0]);
        }elsif($size ==2){# its a range
            my($min,$max)=@range;
            if($min>$max) {message_dialog ("invalid range: [$p]",'error' ); return;} 
            for (my $i=$min; $i<=$max; $i++){
                if ( grep( /^$i$/, @all_num ) ) { message_dialog ("Multiple definition for IP number $i in $p" ); return; }
                push(@all_num,$i);
                
            }
            
        }else{message_dialog ("invalid range: [$p]" ); return; }    
        
    }
    #check if range does not exceed the tile numbers
    my ($NE, $NR, $RAw, $EAw, $Fw)=get_topology_info($mpsoc);
    my $max_tile_num=$NE;
    
    my @f=sort { $a <=> $b }  @all_num;
    my @l;
    foreach my $num (@f){
        push(@l,$num) if($num<$max_tile_num);            
        
    }
    @all_num=@l;
    
    #check if any ip number exists in the rest
    my $conflicts_msg;
    my @conflicts;
    
    
    my @socs=$mpsoc->mpsoc_get_soc_list();
    foreach my $p (@socs){
        if($p ne $name){
            my @taken_tiles=$mpsoc->mpsoc_get_soc_tiles_num($p);
            my @c=get_common_array(\@all_num,\@taken_tiles);
            if (scalar @c) {
                my $str=join(',', @c);
                $conflicts_msg = (defined $conflicts_msg)? "$conflicts_msg\n\t\t $str->$p" : "$str->$p";
                @conflicts= (defined $conflicts_msg)? (@conflicts,@c): @c;
            }
        }#if
    }
    if (defined $conflicts_msg) {
       get_conflict_decision($mpsoc,$name,\@all_num,\@conflicts,$conflicts_msg);
       
        
    }else {
        #save the entered ips
        if( scalar @all_num>0){ 
            $mpsoc->mpsoc_add_soc_tiles_num($name,\@all_num);
            return \@all_num;
        }
        else {
            $mpsoc->mpsoc_add_soc_tiles_num($name,undef);
            return undef;
        }
        #set_gui_status($mpsoc,"ref",1);
    }
    return undef;
}


#################
# get_soc_parameter_setting
################




sub get_soc_parameter_setting{
    my ($mpsoc,$soc_name,$tiles_ref)=@_;
    my @tiles = @{$tiles_ref} if defined ($tiles_ref);
    my $string = join (',',@tiles );
    my $window =  def_popwin_size(40,40,"Parameter setting for $soc_name mapped to tile( $string ) ",'percent');
    my $table = get_soc_parameter_setting_table($mpsoc,$soc_name,$window,$tiles_ref);
    $window->add($table);
    $window->show_all;
}


sub get_soc_parameter_setting_table{
    my ($mpsoc,$soc_name,$window,$tiles_ref)=@_;
    my @tiles;
    @tiles = @{$tiles_ref} if defined ($tiles_ref);
   # my $window =  def_popwin_size(40,40,"Parameter setting for $soc_name mapped to tile(@tiles) ",'percent');
    my $table = def_table(10, 7, FALSE);
    
    my $scrolled_win = add_widget_to_scrolled_win($table);
    my $row=0;
    my $column=0;
    my $top=$mpsoc->mpsoc_get_soc($soc_name);
    
    #read soc parameters
    my %param_value=(scalar @tiles ==1 ) ? $top->top_get_custom_soc_param($tiles[0])  : $top->top_get_default_soc_param();
    $mpsoc->object_add_attribute('current_tile_param',undef,\%param_value);
     
    my @insts=$top->top_get_all_instances();
    my @exceptions=get_NI_instance_list($top);
    @insts=get_diff_array(\@insts,\@exceptions);
    foreach my $inst (@insts){
        my @params=$top->top_get_parameter_list($inst);
        foreach my $p (@params){    
            my  ($default,$type,$content,$info,$global_param,$redefine)=$top->top_get_parameter($inst,$p);
            my $show = ($type ne "Fixed");
            $default= $param_value{$p} if(defined $param_value{$p});
            ($row,$column)=add_param_widget($mpsoc,$p,$p, $default,$type,$content,$info, $table,$row,$column,$show,'current_tile_param',undef,undef,'vertical');
        }
           
            
  #          if ($type eq "Entry"){
  #              my $entry=gen_entry($param_value{$p});
  #              $table->attach_defaults ($entry, 3, 6, $row, $row+1);
  #              $entry-> signal_connect("changed" => sub{$param_value{$p}=$entry->get_text();});
  #          }
  #          elsif ($type eq "Combo-box"){
  #              my @combo_list=split(/\s*,\s*/,$content);
  #              my $pos=get_item_pos($param_value{$p}, @combo_list) if(defined $param_value{$p});
  #              my $combo=gen_combo(\@combo_list, $pos);
  #              $table->attach_defaults ($combo, 3, 6, $row, $row+1);
  #              $combo-> signal_connect("changed" => sub{$param_value{$p}=$combo->get_active_text();});
  #              
  #          }
  #          elsif     ($type eq "Spin-button"){ 
  #                my ($min,$max,$step)=split(/\s*,\s*/,$content);
  #                $param_value{$p}=~ s/\D//g;
  #                $min=~ s/\D//g;
  #                $max=~ s/\D//g;    
  #                $step=~ s/\D//g;
  #                my $spin=gen_spin($min,$max,$step);
  #                $spin->set_value($param_value{$p});
  #                $table->attach_defaults ($spin, 3, 4, $row, $row+1);
  #                $spin-> signal_connect("value_changed" => sub{$param_value{$p}=$spin->get_value_as_int();});
  #       
  #       # $box=def_label_spin_help_box ($param,$info, $value,$min,$max,$step, 2);
  #          }
  #          my $label =gen_label_in_center($p);
  #          $table->attach_defaults ($label, 0, 3, $row, $row+1);
  #          if (defined $info){
  #          my $info_button=def_image_button('icons/help.png');
  #          $table->attach_defaults ($info_button, 6, 7, $row, $row+1);    
  #          $info_button->signal_connect('clicked'=>sub{
  #              message_dialog($info);
  #              
  #          });
  #          
  #      }       
  #      $row++;
  #                      
  #      
  #      }
    }
    
    my $ok = def_image_button('icons/select.png','OK');
    my $okbox=def_hbox(TRUE,0);
    $okbox->pack_start($ok, FALSE, FALSE,0);
    
    
    my $mtable = def_table(10, 1, TRUE);

    $mtable->attach_defaults($scrolled_win,0,1,0,9);
    $mtable->attach_defaults($okbox,0,1,9,10);
    
   
    
    $ok-> signal_connect("clicked" => sub{ 
        $window->destroy if(defined $window);
        #save new values 
        my $ref=$mpsoc->object_get_attribute('current_tile_param');
        %param_value=%{$ref};
             
       # if(!defined $tile ) {
        #    $top->top_add_default_soc_param(\%param_value);
        #    $mpsoc->object_add_attribute('soc_param',"default",\%param_value);      
       # }
       # else {
           foreach my $tile (@tiles){
            $top->top_add_custom_soc_param(\%param_value,$tile);
            $mpsoc->object_add_attribute('soc_param',"custom_${soc_name}",\%param_value);            
        }
        $mpsoc->object_add_attribute('current_tile_param',undef,undef);
        set_gui_status($mpsoc,"refresh_soc",1);
             
        
        });  
    $mtable->show_all();    
    return  $mtable;    
}

################
#    tile_set_widget
################

sub tile_set_widget{
    my ($mpsoc,$soc_name,$num,$table,$show,$row)=@_;
    #my $label=gen_label_in_left($soc);
    my @all_num= $mpsoc->mpsoc_get_soc_tiles_num($soc_name);
    my $init=compress_nums(@all_num);
    my $entry;
    if (defined $init){$entry=gen_entry($init) ;}
    else              {$entry=gen_entry();}
    my $set= def_image_button('icons/right.png');
    my $remove= def_image_button('icons/cancel.png');
    #my $setting= def_image_button('icons/setting.png','setting');
                
                
    my $button = def_colored_button($soc_name,$num);    
    $button->signal_connect("clicked"=> sub{
       # get_soc_parameter_setting($mpsoc,$soc_name,undef);        
    });        
    
    $set->signal_connect("clicked"=> sub{
        my $data=$entry->get_text();
        my $r=check_inserted_ip_nums($mpsoc,$soc_name,$data);
        if(defined $r){
            my @all_num = @{$r};
            get_soc_parameter_setting($mpsoc,$soc_name,\@all_num);
        }        
    });
    
    $remove->signal_connect("clicked"=> sub{
        $mpsoc->mpsoc_remove_soc($soc_name);
        set_gui_status($mpsoc,"ref",1);
    });

    
if($show){
    $table->attach ( $button, 0, 1, $row,$row+1,'fill','fill',2,2);
    $table->attach ( $remove, 1, 2, $row,$row+1,'fill','shrink',2,2);
    $table->attach ( $entry , 2, 3, $row,$row+1,'fill','shrink',2,2);    
    $table->attach ( $set, 3, 4, $row,$row+1,'fill','shrink',2,2);
    

        
    $row++;
}        
    
    return $row;    
    
    
}        




##################
#    defualt_tilles_setting
###################

sub defualt_tilles_setting {
    my ($mpsoc,$table,$show,$row,$info)=@_;
        
    #title    
    my $separator1 = gen_Hsep();
    my $separator2 = gen_Hsep();
    my $title2=gen_label_in_center("Tile Configuration");
    my $box1=def_vbox(FALSE, 1);
    $box1->pack_start( $separator1, FALSE, FALSE, 3);
    $box1->pack_start( $title2, FALSE, FALSE, 3);
    $box1->pack_start( $separator2, FALSE, FALSE, 3);
    if($show){$table->attach_defaults ($box1 ,0,4, $row,$row+1);$row++;}
     
    
    my $label = gen_label_in_left("Tiles path:");
    my $entry = gen_entry();
    my $browse= def_image_button("icons/browse.png");
    my $file= $mpsoc->object_get_attribute('setting','soc_path');
    if(defined $file){$entry->set_text($file);}
    
    
    $browse->signal_connect("clicked"=> sub{
        my $entry_ref=$_[1];
        my $file;
        my $dialog = gen_folder_dialog('Select tile directory');
        if ( "ok" eq $dialog->run ) {
            $file = $dialog->get_filename;
            $$entry_ref->set_text($file);
            $mpsoc->object_add_attribute('setting','soc_path',$file);
            $mpsoc->mpsoc_remove_all_soc();
            set_gui_status($mpsoc,"ref",1);            
            #check_input_file($file,$socgen,$info);
                    #print "file = $file\n";
        }
        $dialog->destroy;

    } , \$entry);
        
    
    $entry->signal_connect("activate"=>sub{
        my $file_name=$entry->get_text();
        $mpsoc->object_add_attribute('setting','soc_path',$file_name);
        $mpsoc->mpsoc_remove_all_soc();    
        set_gui_status($mpsoc,"ref",1);    
        #check_input_file($file_name,$socgen,$info);
    });
        
    
    
    if($show){
        my $tmp=gen_label_in_left(" "); 
        $table->attach  ($label, 0, 1 , $row,$row+1,'fill','shrink',2,2);
        $table->attach ($tmp, 1, 2 , $row,$row+1,'fill','shrink',2,2);        
        $table->attach ($entry, 2, 3 , $row,$row+1,'fill','shrink',2,2);
        $table->attach ($browse, 3, 4, $row,$row+1,'fill','shrink',2,2);
        $row++;
    }
    
    
    
    my @socs=$mpsoc->mpsoc_get_soc_list();
    if( scalar @socs == 0){        
        @socs=get_soc_list($mpsoc,$info); 
                
    }
    @socs=$mpsoc->mpsoc_get_soc_list();
   
    
    
    my $lab1=gen_label_in_center(' Tile name');
    
    my $lab2=gen_label_help('Define the tile numbers that each IP is mapped to.
you can add individual numbers or ranges as follow 
    e.g. individual numbers: 5,6,7,8,9,10
    e.g. range: 5:10 
    ', ' Tile numbers ');
    if($show){
        $table->attach_defaults ($lab1 ,0,1, $row,$row+1);
        $table->attach_defaults ($lab2 ,2,3, $row,$row+1);$row++;
    }    
    
    my $soc_num=0;
    foreach my $soc_name (@socs){    
        $row=tile_set_widget ($mpsoc,$soc_name,$soc_num,$table,$show,$row);    
        $soc_num++;        
        
    }    
    return $row;
    
}




#######################
#   noc_config
######################


sub noc_topology_setting_gui {
    my ($mpsoc,$table,$txview,$row,$show_noc,$noc_id)=@_;
    my $noc_param="noc_param$noc_id";
    my $coltmp=0;
    #  topology
    my  $label='Topology';
    my  $param='TOPOLOGY';
    my  $default='"MESH"';
    my  $content='"MESH","FMESH","TORUS","RING","LINE","FATTREE","TREE","STAR","CUSTOM"';
    my  $type='Combo-box';
    my  $info="Specifies the NoC topology. 
    Options include $content"; 
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_param,1);
            
    my $topology=$mpsoc->object_get_attribute($noc_param,'TOPOLOGY');

    if($topology ne '"CUSTOM"' ){
    #topology T1 parameter
        $label= 
            ($topology eq '"FATTREE"' || $topology eq '"TREE"')? 'K' :
            ($topology eq '"STAR"')? "Total Endpoint number" : 'Routers per row';
        $param= 'T1';
        $default= '2';
        $content=
        ($topology eq '"MESH"'  || $topology eq '"TORUS"') ? '2,16,1':
        ($topology eq '"FMESH"')? '1,16,1':
        ($topology eq '"FATTREE"' || $topology eq '"TREE"' )? '2,6,1':'2,64,1';
        $info= ($topology eq '"FATTREE"' || $topology eq '"TREE"' )? 'number of last level individual router`s endpoints.' :'Number of NoC routers in row (X dimension)';
        $type= 'Spin-button'; 
        $noc_param_comment{$param}="$info";            
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_param,1);

    
    #Topology T2 parameter
    if($topology eq '"MESH"' || $topology eq '"FMESH"' || $topology eq '"TORUS"' || $topology eq '"FATTREE"' || $topology eq '"TREE"' ) {
        $label= ($topology eq '"FATTREE"' || $topology eq '"TREE"')?  'L' :'Routers per column';
        $param= 'T2';
        $default='2';
        $content=  ($topology eq '"FMESH"')? '1,16,1': '2,16,1';
        $info= ($topology eq '"FATTREE"' || $topology eq '"TREE"')? 'Fattree layer number (The height of FT)':'Number of NoC routers in column (Y dimension)';
        $type= 'Spin-button'; 
        $noc_param_comment{$param}="$info";            
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_param,1);
    } else {
        $mpsoc->object_add_attribute($noc_param,'T2',1);        
    }
    
    #Topology T3 parameter
    if($topology eq '"MESH"' || $topology eq '"FMESH"' || $topology eq '"TORUS"' || $topology eq '"RING"' || $topology eq '"LINE"') {
        $label="Router's endpoint number";
        $param= 'T3';
        $default='1';
        $content='1,4,1';
        $info= "Number of endpoints per router. In $topology topology, each router
        can have up to 4 endpoint processing tile.";
        $type= 'Spin-button'; 
        $noc_param_comment{$param}="$info";            
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_param,1);
    }
    
    
    }else{#its a custom Topology
        ($row,$coltmp)=config_custom_topology_gui($mpsoc,$table,$txview,$row,$noc_id);
    }
    return ($row,$coltmp);

}



sub noc_config{
    my ($mpsoc,$table,$txview,$noc_id)=@_;   
    $noc_id = "" if(!defined $noc_id);    
    my $noc_param="noc_param$noc_id";
    my $noc_type="noc_type$noc_id"; 

    #title    
    my $row=0;
    my $title=gen_label_in_center("NoC Configuration");
    $table->attach ($title , 0, 4,  $row, $row+1,'expand','shrink',2,2); $row++;
    add_Hsep_to_table ($table,0,4,$row); $row++;

    my $label;
    my $param;
    my $default;
    my $type;
    my $content;
    my $info;

    

    #parameter start
    my $b1;
    my $show_noc=$mpsoc->object_get_attribute('setting','show_noc_setting');
    if(!defined $show_noc){
        $show_noc=1;
        $mpsoc->object_add_attribute('setting','show_noc_setting',$show_noc);
        
    }
    if($show_noc == 0){    
        $b1= def_image_button("icons/down.png","NoC Parameters");
        $label=gen_label_in_center(' ');
        $table->attach  ( $label , 2, 3, $row,$row+1 ,'fill','shrink',2,2);
        $table->attach  ( $b1 , 0, 2, $row,$row+1,'fill','shrink',2,2);
        $row++;    
    }
    
    my $coltmp=0;
    
    #Router type
    $label='Router Type';
    $param='ROUTER_TYPE';
    $default='"VC_BASED"';
    $content='"INPUT_QUEUED","VC_BASED"';
    $type='Combo-box';
    $info="    Input-queued: simple router with low performance and does not support fully adaptive routing.
    VC-based routers offer higher performance, fully adaptive routing  and traffic isolation for different packet classes."; 
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_type,1);
    my $router_type=$mpsoc->object_get_attribute($noc_type,"ROUTER_TYPE");
    
    
    ($row,$coltmp) =noc_topology_setting_gui($mpsoc,$table,$txview,$row,$show_noc,$noc_id);
    my $topology=$mpsoc->object_get_attribute($noc_param,'TOPOLOGY');  
    
    #VC number per port
    if($router_type eq '"VC_BASED"'){    
        my $v=$mpsoc->object_get_attribute($noc_param,'V');
        if(defined $v){ $mpsoc->object_add_attribute($noc_param,'V',2) if($v eq 1);}
        $label='VC number per port';
        $param='V';
        $default='2';
        $type='Spin-button';
        $content='2,16,1';
        $info='Number of Virtual chanel per each router port';
        $noc_param_comment{$param}="$info";
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_param,1);
    } else {
        $noc_param_comment{'V'}="Number of Virtual chanel per each router port. V is equal to 1 means there is no VC.";
        $mpsoc->object_add_attribute($noc_param,'V',1);
        $mpsoc->object_add_attribute($noc_param,'C',0);        
    }
    
    #buffer width per VC
    $label=($router_type eq '"VC_BASED"')? 'Buffer flits per VC': "Buffer flits";
    $param='B';
    $default='4';                                  
    $content='2,256,1';
    $type='Spin-button';
    $info=($router_type eq '"VC_BASED"')?  'Buffer queue size per VC in flits' : 'Buffer queue size in flits';
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_param,undef);
    
    
    #Local port buffer width per VC
    $label=($router_type eq '"VC_BASED"')? 'Local port Buffer flits per VC': "Local Port Buffer flits";
    $param='LB';
    $default='4';                                  
    $content='2,256,1';
    $type='Spin-button';
    $info = "Buffer width for local router ports connected to endpoints. 
    May differ from B, which is for neighboring router ports. 
    Applicable to MESH, FMESH, TORUS, LINE, and RING topologies. 
    In FMESH, LB does not affect extra endpoints on edge routers.";
    $noc_param_comment{$param}="$info";
    if ($topology eq '"MESH"' || $topology eq '"FMESH"' || $topology eq '"TORUS"' || $topology eq '"RING"' || $topology eq '"LINE"'){
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_param,undef);
    }else{
        $mpsoc->object_add_attribute($noc_param,'LB','B');
    }    
    
    #packet payload width
    $label='Payload width';
    $param='Fpay';
    $default='32';       
    $content='32,256,32';
    $type='Spin-button';
    $info="The packet payload width in bits"; 
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info,$table,$row,undef,$show_noc,$noc_param,undef);

if($topology ne '"CUSTOM"' ){
    #routing algorithm
    $label='Routing Algorithm';
    $param="ROUTE_NAME";
    $type="Combo-box";
    if($router_type eq '"VC_BASED"'){
        $content=($topology eq '"MESH"' || $topology eq '"FMESH"')?  '"XY","WEST_FIRST","NORTH_LAST","NEGETIVE_FIRST","ODD_EVEN","DUATO"' :
                 ($topology eq '"TORUS"')? '"TRANC_XY","TRANC_WEST_FIRST","TRANC_NORTH_LAST","TRANC_NEGETIVE_FIRST","TRANC_DUATO"':
                 ($topology eq '"RING"')? '"TRANC_XY"' :
                 ($topology eq '"LINE"')?  '"XY"':
                 ($topology eq '"FATTREE"')? '"NCA_RND_UP","NCA_STRAIGHT_UP","NCA_DST_UP"':
                 ($topology eq '"TREE"')? '"NCA"' : '"UNKNOWN"';   
    }else{
        $content=($topology eq '"MESH"' || $topology eq '"FMESH"')?  '"XY","WEST_FIRST","NORTH_LAST","NEGETIVE_FIRST","ODD_EVEN"' :
                 ($topology eq '"TORUS"')? '"TRANC_XY","TRANC_WEST_FIRST","TRANC_NORTH_LAST","TRANC_NEGETIVE_FIRST"':
                 ($topology eq '"RING"')? '"TRANC_XY"' : 
                 ($topology eq '"LINE"')?  '"XY"':
                 ($topology eq '"FATTREE"')? '"NCA_RND_UP","NCA_STRAIGHT_UP","NCA_DST_UP"' : 
                 ($topology eq '"TREE"')? '"NCA"' : '"UNKNOWN"';    
    }
    $default=($topology eq '"MESH"' || $topology eq '"FMESH"' || $topology eq '"LINE"' )? '"XY"':
             ($topology eq '"TORUS"'|| $topology eq '"RING"')?  '"TRANC_XY"' : 
             ($topology eq '"FATTREE"')? '"NCA_STRAIGHT_UP"' :
             ($topology eq '"TREE"')? '"NCA"' : '"UNKNOWN"';

    my $info_mesh="Select the routing algorithm: XY(DoR) , partially adaptive (Turn models). Fully adaptive (Duato) "; 
    my $info_fat="Nearest common ancestor (NCA) where the up port is selected randomly (RND), 
    based on destination endpoint address (DST) or it is the top port that is located in front 
    of the port which has received the packet (STRAIGHT) "; 
    
    $info=($topology eq '"FATTREE"')? $info_fat : 
          ($topology eq '"TREE"') ? "Nearest common ancestor": $info_mesh;
    $noc_param_comment{$param}="$info
    options are $content";
    my $show_routing =($topology eq '"STAR"' )? 0 : $show_noc;
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_routing,$noc_param,1);
}

    #PCK_TYPE
    $label='Packet type'; 
    $param='PCK_TYPE';
    $default='"MULTI_FLIT"';
    $content='"MULTI_FLIT","SINGLE_FLIT"';
    $type="Combo-box";
    $info="Packet type.
    - SINGLE_FLIT: All packets are single-flit sized.
    - MULTI_FLIT: Packets can be single-flit, two-flit, or multi-flit sized:
        a) Single-flit: Head and tail flags set on one flit.
        b) Two-flit: Separate header and tail flits.
        c) Multi-flit: Header, one or more body flits, and a tail flit.";
    $noc_param_comment{$param}="$info";

    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_param,1);
    
    my $pck_type=$mpsoc->object_get_attribute($noc_param,'PCK_TYPE');  

    if($pck_type eq '"MULTI_FLIT"'){

        #MIN_PCK_SIZE 
        # 2 //minimum packet size in flits. The minimum value is 1. 
        $label='Minimum packet size'; 
        $param='MIN_PCK_SIZE';
        $default='2';
        $content='1,65535,1';
        $type='Spin-button';
        $info="Minimum packet size in flits.
    - For atomic VC reallocation, any value ≥1 is valid.
    - For non-atomic VC reallocation, this value defines buffer behavior.
    Note: Setting a value smaller than received packet size may cause crashes."; 
        $noc_param_comment{$param}="$info";
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_param,undef);
    }else{
        $mpsoc->object_add_attribute($noc_param,'MIN_PCK_SIZE',1);   
    }

    # BYTE_EN
    $label='Byte Enable';
    $param='BYTE_EN';
    $default= 0;
    $info='0 - Disable, 1 - Enable. 
    Adds a Byte Enable (BE) field to the header flit, indicating the location of 
    the last valid byte in the tail flit. This is required when the data unit being 
    sent is smaller than the Fpay value.'; 
    $content='0,1';
    $type="Combo-box";
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_param);
    
    #CAST_TYPE
    $label='Casting Type';
    $param='CAST_TYPE';
    $default= '"UNICAST"';
    $content='"UNICAST","MULTICAST_PARTIAL","MULTICAST_FULL","BROADCAST_PARTIAL","BROADCAST_FULL"';
    $info="Specifies NoC communication type.
    - UNICAST: A packet targets a single destination.
    - MULTICAST/BROADCAST: A single packet targets multiple/all destinations.
    Options: FULL (all nodes) or PARTIAL (defined by MCAST_ENDP_LIST).
    Select one of $content"; 
    
    $type="Combo-box";
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$show_noc,$noc_param,1);
    
    my $cast_type=$mpsoc->object_get_attribute($noc_param,'CAST_TYPE');  
    my ($NE, $NR, $RAw, $EAw, $Fw, $MAX_P) = get_topology_info($mpsoc,$noc_id);
    
    my $cast = $mpsoc->object_get_attribute($noc_param,"MCAST_ENDP_LIST");    
    if(!defined $cast){
        my $h=0;
        my $n="";
        for (my $i=0; $i<$NE; $i++){
            $h+= (1<<$i%4);     
            if(($i+1) % 4==0){
                $n="$h".$n if($h<10);
                $n=chr($h-10+97).$n if($h>9);
                $h=0;
            }
        }    
        $n="$h".$n if($h!=0);
        $n="'h".$n;  
        $mpsoc->object_add_attribute($noc_param,"MCAST_ENDP_LIST",$n);
        $mpsoc->object_add_attribute_order($noc_param,"MCAST_ENDP_LIST");
    #    $mpsoc->object_add_attribute($noc_param,"MCAST_PRTLw",$NE);
    #    $mpsoc->object_add_attribute_order($noc_param,"MCAST_PRTLw");
        $cast=$n;
    }
    
    if($cast_type eq '"MULTICAST_PARTIAL"' || $cast_type eq '"BROADCAST_PARTIAL"') {
        #$table->attach  ( gen_label_help($info,"Muticast Node list"),0 , 2, $row,$row+1,'fill','shrink',2,2);    
        $info='A one-hot encoded value where each asserted bit indicates that the corresponding destination ID 
    can be targeted in multicast or broadcast packets. Destinations represented by bits set to zero are restricted 
    to receiving only unicast packets.'; 
        $noc_param_comment{$param}="$info";
        my $b1= def_image_button("icons/setting.png","Set");
        my $bb= def_pack_hbox(FALSE,0,gen_label_in_left("$cast"),$b1);
        my $label=gen_label_in_left("Muticast Node list");
        my $inf_bt= (defined $info)? gen_button_message ($info,"icons/help.png"):gen_label_in_left(" ");
        attach_widget_to_table ($table,$row,$label,$inf_bt,$bb,0);
        
        
        # $table->attach  ( $bb , 2, 3, $row,$row+1,'fill','shrink',2,2);
        $row++;  
        
        $b1->signal_connect("clicked" => sub{ 
            set_multicast_list($mpsoc,$noc_id);        
        });        
    }    
    
    my $adv_set= $show_noc;
    #SSA
    $label='SSA Enable'; 
    $param='SSA_EN';
    $default='"NO"';
    $content='"YES","NO"';
    $type='Combo-box';
    $info="Enable single cycle latency on packets traversing in the same direction using 
    static straight allocator (SSA)"; 
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param,undef);
    
    #SMART
    $label='Max Straight Bypass'; 
    $param='SMART_MAX';
    $default='0';
    $content="0,1,2,3,4,5,6,7,8,9";
    $type='Combo-box';
    $info="Maximum number of routers a packet can bypass in a straight direction
    in a single cycle (0 = no bypass)"; 
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param,undef);

    #Fully and partially adaptive routing setting
    my $route=$mpsoc->object_get_attribute($noc_param,"ROUTE_NAME");
    $label="Congestion index";    
    $param="CONGESTION_INDEX";
    $type="Spin-button";
    $content="0,12,1";
    $info="Congestion index determines how congestion information is collected 
    from neighboring routers. Please refer to the usere manual for more information";
    $noc_param_comment{$param}="$info";
    $default=3;
    if($topology ne '"CUSTOM"' && $route ne '"XY"' && $route ne '"TRANC_XY"' ){
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param,undef);
    } else {
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,0,$noc_param,undef);
    }
    
    #Fully adaptive routing setting
    my $v=$mpsoc->object_get_attribute($noc_param,"V");
    $label="Select Escap VC";    
    $param="ESCAP_VC_MASK";
    $type="Check-box";
    $content=$v;
    $default="$v\'b";
    for (my $i=1; $i<=$v-1; $i++){$default=  "${default}0";}
    $default=  "${default}1";
    $info="Select the escap VC for fully adaptive routing.";
    $noc_param_comment{$param}="$info";
    if( $route eq '"TRANC_DUATO"' or $route eq '"DUATO"'  ){
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set, $noc_param,undef);
    }
    else{
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,0, $noc_param,undef);
    }
        
    # VC reallocation type
    $label=($router_type eq '"VC_BASED"')? 'VC reallocation type': 'Queue reallocation type';    
    $param='VC_REALLOCATION_TYPE';
    $info="VC reallocation policy.
    - ATOMIC: Only empty VCs can be reallocated.
    - NONATOMIC: Non-empty VCs with completed packets can accept new packets.";
    $default='"NONATOMIC"';  
    $content='"ATOMIC","NONATOMIC"';
    $type='Combo-box';
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param,undef);                                           


    #vc/sw allocator type
    $label = 'VC/SW combination type';
    $param='COMBINATION_TYPE';
    $default='"COMB_NONSPEC"';
    $content='"COMB_SPEC1","COMB_SPEC2","COMB_NONSPEC"';
    $type='Combo-box';
    $info="Specifies the joint VC/Switch allocator type as either speculative or non-speculative. 
Options are: 
    - SPEC: Speculative allocation.
    - NONSPEC: Non-speculative allocation.";   
    $noc_param_comment{$param}="$info";
    if ($router_type eq '"VC_BASED"'){                 
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param,undef);                   
    } else{
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,0,$noc_param,undef);  
    }
    
    # Crossbar mux type 
    $label='Crossbar mux type';
    $param='MUX_TYPE';
    $default='"BINARY"';
    $content='"ONE_HOT","BINARY"';
    $type='Combo-box';
    $info="Crossbar multiplexer type";
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param,undef);             
    
    #class   
    if($router_type eq '"VC_BASED"'){
        $label='class number';
        $param='C';
        $default= 0;
        $info='Number of message classes. Each specific class can use different set of VC'; 
        $content='0,16,1';
        $type='Spin-button';
        ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param,5);                             
        

        my $class=$mpsoc->object_get_attribute($noc_param,"C");
        my $v=$mpsoc->object_get_attribute($noc_param,"V");
        $default= "$v\'b";
        for (my $i=1; $i<=$v; $i++){
            $default=  "${default}1";
        }    
        #print "\$default=$default\n";
        for (my $i=0; $i<=$class-1; $i++){
        
            $label="Class $i Permitted VCs";    
            $param="Cn_$i";
            $type="Check-box";
            $content=$v;
            $info="Select the permitted VCs which the message class $i can be sent via them.";
            ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,'class_param',undef);
        }
    
    }#($router_type eq '"VC_BASED"')
    
    #simulation debuge enable     
    $label='Debug enable';
    $param='DEBUG_EN';
    $info= "Add extra Verilog code for debugging NoC for simulation";
    $default='0';
    $content='0,1';
    $type='Combo-box';
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param);  
    
    #pipeline reg    
    $label="Add pipeline reg after crossbar";    
    $param="ADD_PIPREG_AFTER_CROSSBAR";
    $type="Check-box";
    $content=1;
    $default="1\'b0";
    $info="If is enabled it adds a pipeline register at the output port of the router.";
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param);

    #FIRST_ARBITER_EXT_P_EN
    $label='Swich allocator first level 
arbiters external priority enable';
    $param='FIRST_ARBITER_EXT_P_EN';
    $default= 1;
    $info='Enables switch allocator\'s input priority registers 
    only when a request gets grants from both input and output arbiters.'; 
    $content='0,1';
    $type="Combo-box";
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info,$table,$row,undef,$adv_set,$noc_param);     
    
    #Arbiter type
    $label='SW allocator arbitration type'; 
    $param='SWA_ARBITER_TYPE';
    $default='"RRA"';
    $content='"RRA","WRRA"'; 
    $type='Combo-box';
    $info="Switch allocator arbitration type.
    - RRA: Round Robin Arbiter (local fairness only).
    - WRRA: Weighted Round Robin Arbiter (global fairness based on contention).
"; 
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param,1);
    
    my $arbiter=$mpsoc->object_get_attribute($noc_param,"SWA_ARBITER_TYPE");
    my $wrra_show = ($arbiter ne  '"RRA"' && $adv_set == 1 )? 1 : 0;
    # weight width
    $label='Weight width';
    $param='WEIGHTw';
    $default='4';
    $content='2,7,1';
    $info= 'Maximum weight width';
    $noc_param_comment{$param}="$info";
    $type= 'Spin-button';  
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$wrra_show,$noc_param,undef);  
    
    
    
    $label='Self loop enable'; 
    $param='SELF_LOOP_EN';
    $default='"NO"';
    $content='"NO","YES"';
    $type='Combo-box';
    $info="Allows a router input port to send packets to its own output port, 
    enabling self-communication for tiles."; 
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param,1);
    
    #WRRA_CONFIG_INDEX
    $label='Weight configuration index';
    $param='WRRA_CONFIG_INDEX';
    $default='0';
    $content='0,7,1';
    $info= 'WRRA_CONFIG_INDEX:

';
    $type= 'Spin-button';  
    #($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,$wrra_show,$noc_param,undef);  
    
    #HETERO_VC
    $label='Heterogeneous VC En'; 
    $param='HETERO_VC';
    $default='0';
    $content='0,1,2';
    $type='Combo-box';
    $info="Configures the VC (Virtual Channel) distribution across routers and ports in the NoC.
    0 : Uniform VC distribution. All routers in the NoC have an equal number of VCs.
    1 : Router-specific VC distribution. All ports in a specific router have the same number of VCs, 
    but different routers in the NoC can have different numbers of VCs.
    2 : Fully heterogeneous VC distribution. Each port in any router can have a unique number of VCs."; 
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,$adv_set,$noc_param,1);
    $noc_param_comment{$param}="$info";


    #VC_CONFIG_TABLE
    my $hetero_en=$mpsoc->object_get_attribute($noc_param,'HETERO_VC');
    $label='Heterogeneous VC setting'; 
    $param='int VC_CONFIG_TABLE [MAX_ROUTER][MAX_PORT]';
    $default='\'{\'{0}}';
    $content='0,1,2';
    $type='Combo-box';
    $info='Defines how a heterogeneous number of VCs are distributed in the NoC.
    - HETERO_VC= 0: Uniform VC configuration. All routers and ports have 
        the same number of VCs, and this parameter is not used.
    - HETERO_VC= 1,2 : Specifies the VC count in a 2D parameter array, where:
        * The first dimension represents the router ID.
        * The second dimension represents the port number.
    - For HETERO_VC = 1: All ports within a router have the same number of VCs, 
        so only the first element of each row is considered valid.
    - For HETERO_VC = 2: Each port in every router can have a unique VC count.';
    $noc_param_comment{$param}="$info";
    if($hetero_en eq '0'){
        $mpsoc->object_add_attribute($noc_param,"MAX_ROUTER",1);
        $mpsoc->object_add_attribute($noc_param,"MAX_PORT",1);
        $mpsoc->object_add_attribute($noc_param,$param,$default);
        
    }elsif($hetero_en eq '1'){
        $mpsoc->object_add_attribute($noc_param,"MAX_ROUTER",$NR);
        $mpsoc->object_add_attribute($noc_param,"MAX_PORT",1);        
        $row=hetero_vc_widget($mpsoc,$row,$NR,1,$label,$info,$table,$noc_id,$param,$v);
    }else{
        $mpsoc->object_add_attribute($noc_param,"MAX_ROUTER",$NR);
        $mpsoc->object_add_attribute($noc_param,"MAX_PORT",$MAX_P);
        $row=hetero_vc_widget($mpsoc,$row,$NR,$MAX_P,$label,$info,$table,$noc_id,$param,$v);
    }


    $mpsoc->object_add_attribute_order($noc_param,"MAX_ROUTER");
    $mpsoc->object_add_attribute_order($noc_param,"MAX_PORT");
    $mpsoc->object_add_attribute_order($noc_param,$param);

    if($show_noc == 1){    
        $b1= def_image_button("icons/up.png","NoC Parameters");
        $table->attach  ( $b1 , 0, 2, $row,$row+1,'fill','shrink',2,2);
        $row++;    
    }
    $b1->signal_connect("clicked" => sub{ 
        $show_noc=($show_noc==1)?0:1;
        $mpsoc->object_add_attribute('setting','show_noc_setting',$show_noc);
        set_gui_status($mpsoc,"ref",1);
    });
    

    #other fixed parameters       
    
    # AVC_ATOMIC_EN
    $label='AVC_ATOMIC_EN';
    $param='AVC_ATOMIC_EN';
    $default= 0;
    $info='AVC_ATOMIC_EN'; 
    $content='0,1';
    $type="Combo-box";
    $noc_param_comment{$param}="$info";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,0,$noc_param);
    
    
    $mpsoc->object_add_attribute('noc_param_comments',undef,\%noc_param_comment);
    
    return $row;
}

sub hetero_vc_widget{
    my ($mpsoc,$row,$nr,$np,$label_text,$info,$table,$noc_id,$param,$v)=@_;
    my $b1= def_image_button("icons/setting.png","Set");
    my $label=gen_label_in_left($label_text);
    my $inf_bt= (defined $info)? gen_button_message ($info,"icons/help.png"):gen_label_in_left(" ");
    attach_widget_to_table ($table,$row,$label,$inf_bt,$b1,0);
    $row++;  
    update_vc_list($mpsoc,$noc_id,$nr,$np,$v,$param,$info);
    $b1->signal_connect("clicked" => sub{ 
            set_hetero_vc_list($mpsoc,$noc_id,$nr,$np,$param,$v,$info);        
    });
    return $row;
}

sub set_hetero_vc_list{
    my($mpsoc,$noc_id,$nr,$np,$param,$v,$info)=@_;    
    my $noc_param="noc_param$noc_id";
    my $vc_param="vc_param$noc_id";
    my $title=($np==1)? "Specify number of VCs in each router" : "Specify number of VCs in each router port";
    my $window = def_popwin_size(50,40,$title,'percent');
    my $table= def_table(10,10,FALSE);
    my $row=0;
    my $col=0;
    my $init = $mpsoc->object_get_attribute($noc_param,$param);

    my $label = "$param=";
    my ($Ebox,$entry) = def_h_labeled_entry ($label);    
    $entry->set_sensitive (FALSE);
    $entry->set_text("$init");
    my $content="1";
    for(my $r=2;$r<=$v;$r++){ $content.=",$r" }
    for(my $p=0;$p<$np;$p++){
        if  ($p==0){
            my $label= gen_label_in_center("R/P");
            $table->attach ($label , $col, $col+4, $row,$row+1,'fill','shrink',2,2);$col+=4;	
        }
        my $label= gen_label_in_center("P$p");
        $table->attach ($label , $col, $col+4, $row,$row+1,'fill','shrink',2,2);$col+=4;    
    }
    $row++;$col=0;
    for(my $r=0;$r<$nr;$r++){
        my $label= gen_label_in_center("R$r");
        $table->attach ($label , $col, $col+4, $row,$row+1,'fill','shrink',2,2);$col+=4;

        for(my $p=0;$p<$np;$p++){
            my $w;
            ($row,$col,$w)=add_param_widget ($mpsoc,undef,"R$r-P$p", $v,"Combo-box",$content,undef, $table,$row,$col,1,$vc_param,undef,undef,"horizental");
            set_tip($w,"R$r-P$p");
        } 
        $row++;
        $col=0;
    }
    #$table->attach ($Ebox , $row, 10, $row,$row+1,'fill','shrink',2,2);$row++;
    
    my $main_table=def_table(10,10,FALSE);
    my $ok = def_image_button('icons/select.png','OK');    
    $main_table->attach_defaults ($table  , 0, 12, 0,11);
    $main_table->attach ($ok,5, 6, 11,12,'shrink','shrink',0,0);
    $ok->signal_connect('clicked', sub {
        update_vc_list($mpsoc,$noc_id,$nr,$np,$v,$param,$info);
        set_gui_status($mpsoc,"ref",1);    
        $window->destroy;
    });   
    my $scrolled_win = gen_scr_win_with_adjst($mpsoc,'gen_multicast');
    add_widget_to_scrolled_win($main_table,$scrolled_win);
    $window->add($scrolled_win);
    $window->show_all();
}

sub update_vc_list{
    my ($mpsoc,$noc_id,$nr,$np,$v,$param_in)=@_;
    my $noc_param="noc_param$noc_id";
    my $vc_param="vc_param$noc_id";
    my $out="'{\n\t//";
    for(my $p=0;$p<$np;$p++){$out.="P$p ";};
    for(my $r=0;$r<$nr;$r++){
        $out.="\n\t\'{";
        for(my $p=0;$p<$np;$p++){
            my $param   ="R$r-P$p";
            my $val=$mpsoc->object_get_attribute($vc_param,$param) //$v;
            $out.=($p <$np-1 )? "$val, " : "$val";           
        }
         $out.=($r<$nr-1)? "}, // R$r" : "}  // R$r"
    }
    $out.="\n\t}";
    $mpsoc->object_add_attribute($noc_param,$param_in,$out)
}

sub set_multicast_list{
    my($mpsoc,$noc_id)=@_;    
    my $noc_param="noc_param$noc_id";
    my $window = def_popwin_size(50,40,"Select nodes invlove in multicasting ",'percent');
    my $table= def_table(10,10,FALSE);
    my $row=0;
    my $col=0;
    
    my $init = $mpsoc->object_get_attribute($noc_param,"MCAST_ENDP_LIST");
    $init =~ s/'h//g;
    my @arr= reverse split (//, $init);
        
    
    my $label = "Multicast Node list (hex fromat)";    
    my ($Ebox,$entry) = def_h_labeled_entry ($label);    
    $entry->set_sensitive (FALSE);
        
    my @sel_options= ("Select","All","None","2n","3n","4n","2n+1","3n+1","3n+2","4n+1","4n+2","4n+3");
    my $combo= gen_combo(\@sel_options, 0);
    $table->attach ($combo , 0, 1, $row,$row+1,'fill','shrink',2,2);
    #get the number of endpoints
    my ($NE, $NR, $RAw, $EAw, $Fw) = get_topology_info($mpsoc,$noc_id);
    my @check;
    
    
    
    my $sel_val="Init";
    for (my $i=0; $i<$NE; $i++){
        if($i%10 == 0){    $row++;$col=0;}        
        my $box;
        my $l=$NE -$i-1;
        
        my $char = $arr[$l/4];
        $char=0 if (!defined $char);
        my $hex = hex($char);        
        my $bit = ($hex >> ($l%4)) & 1;
        ($box,$check[$l])=def_h_labeled_checkbutton("$l");
        $table->attach ($box , $col, $col+1, $row,$row+1,'fill','shrink',2,2);
        $col++;    
        
        if($bit==1){
            $check[$l]->set_active(TRUE);
        }
        
        $check[$l]-> signal_connect("toggled" => sub{                        
            get_multicast_val ($mpsoc,$entry,$NE,@check)if($sel_val eq "Select");
        });    
    }    
    $row++;
    $col=0;
    
    $sel_val="Select";
    get_multicast_val ($mpsoc,$entry,$NE,@check);
    
    $combo-> signal_connect("changed" => sub{
        $sel_val=$combo->get_active_text();        
        my $n=1;
        my $r=0;
        return if ($sel_val eq "Select");        
        if ($sel_val eq "None"){        
            for (my $i=0; $i<$NE; $i++){$check[$i]->set_active(FALSE)};
            get_multicast_val ($mpsoc,$entry,$NE,@check);
            $combo->set_active(0);
            return;
        }
        ($n,$r)=sscanf("%dn+%d",$sel_val);
        if(!defined $r){
            ($n,$r)=sscanf("%dn",$sel_val);
            $r=0;
            $n=1 if(!defined $n);
        }
        
        for (my $i=0; $i<$NE; $i++){
            if($i % $n == $r){  $check[$i]->set_active(TRUE);}
        }
        $combo->set_active(0);
        get_multicast_val ($mpsoc,$entry,$NE,@check);
        
    });
    
    
    
    $table->attach ($Ebox , 0, 10, $row,$row+1,'fill','shrink',2,2);$row++;
    
    my $main_table=def_table(10,10,FALSE);
    
    my $ok = def_image_button('icons/select.png','OK');    
    $main_table->attach_defaults ($table  , 0, 12, 0,11);
    $main_table->attach ($ok,5, 6, 11,12,'shrink','shrink',0,0);
    
    $ok->signal_connect('clicked', sub {
        my $s=get_multicast_val ($mpsoc,$entry,$NE,@check);
        my $n=$entry->get_text( );
        $mpsoc->object_add_attribute($noc_param,"MCAST_ENDP_LIST",$n);    
    #    $mpsoc->object_add_attribute($noc_param,"MCAST_PRTLw",$s);
        set_gui_status($mpsoc,"ref",1);    
        $window->destroy;
    });
    
    
    
    
    my $scrolled_win = gen_scr_win_with_adjst($mpsoc,'gen_multicast');
    add_widget_to_scrolled_win($main_table,$scrolled_win);
    $window->add($scrolled_win);
    $window->show_all();
}

sub get_multicast_val {
    my ($mpsoc,$entry,$NE,@check)=@_;
    my $n="";
    my $h=0;
    my $s=0;
    for (my $i=0; $i<$NE; $i++){
            if($check[$i]->get_active()){$h+= (1<<$i%4);$s++;} 
        if(($i+1) % 4==0){
            $n="$h".$n if($h<10);
            $n=chr($h-10+97).$n if($h>9);
            $h=0;
        }
    }
    
    $n="$h".$n if($NE%4!=0);
    $n="'h".$n;
    $entry->set_text("$n");
    return $s;
    
}
#############
# config_custom_topology_gui
############

sub config_custom_topology_gui{
    my($mpsoc,$table,$txview,$row,$noc_id)=@_;
my $noc_param="noc_param$noc_id";
my $coltmp=0;
#read param.obj file to load cutom topology info
    my $dir =get_project_dir()."/mpsoc/rtl/src_topology";
    my $file="$dir/param.obj";
    unless (-f $file){
        add_colored_info($txview,"No Custom topology find in $dir. You can define a Custom Topology using ProNoC Topology maker.\n",'red');
        return;        
    }    
    
    my %param;    
    my ($pp,$r,$err) = regen_object($file );
    if ($r){        
        add_colored_info($txview,"Error: cannot open $file file: $err\n",'red');
        return;  
    }         
    
    %param=%{$pp};
    my @topologies=sort keys %param;
            
    my $label='Topology_name';
    my $param='CUSTOM_TOPOLOGY_NAME';
    my $default=$topologies[0];
    my $content= join(",", @topologies);  
    my $type='Combo-box';
    my $info="Custom topology name"; 
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,1,$noc_param,1);
    
    my $topology_name=$mpsoc->object_get_attribute($noc_param,'CUSTOM_TOPOLOGY_NAME');                
    
    
    $label='Routing Algorithm';
    $param="ROUTE_NAME";
    $type="Combo-box";
    $content=$param{$topology_name}{'ROUTE_NAME'};             
    my @rr=split(/\s*,\s*/,$content);
    $default=$rr[0];
    $info="Select the routing algorithm";
    ($row,$coltmp)=add_param_widget ($mpsoc,$label,$param, $default,$type,$content,$info, $table,$row,undef,1,$noc_param,1);
    
    $mpsoc->object_add_attribute($noc_param,'T1',$param{$topology_name}{'T1'});    
    $mpsoc->object_add_attribute($noc_param,'T2',$param{$topology_name}{'T2'}); 
    $mpsoc->object_add_attribute($noc_param,'T3',$param{$topology_name}{'T3'});     
    $mpsoc->object_add_attribute('noc_connection','er_addr',$param{$topology_name}{'er_addr'});          
            
                
    return ($row,$coltmp);

}




#######################
#   get_config
######################

sub get_config{
    my ($mpsoc,$info)=@_;
    my $table=def_table(20,10,FALSE);#    my ($row,$col,$homogeneous)=@_;
   

    #noc_setting
    my $row=noc_config ($mpsoc,$table,$info);
    
        
    #tiles setting 
    my $tile_set;
    my $show=$mpsoc->object_get_attribute('setting','show_tile_setting');
    
    if($show == 0){    
        $tile_set= def_image_button("icons/down.png","Tiles setting");
        $table->attach ( $tile_set , 0, 2, $row,$row+1,'fill','shrink',2,2);
        $row++;
    
    }
    
    $row=defualt_tilles_setting($mpsoc,$table,$show,$row,$info);
    

    #end tile setting
    if($show == 1){    
        $tile_set= def_image_button("icons/up.png","Tiles setting");
        $table->attach ( $tile_set , 0, 2, $row,$row+1,'fill','shrink',2,2);
        $row++;
    }
    $tile_set->signal_connect("clicked" => sub{ 
        $show=($show==1)?0:1;
        $mpsoc->object_add_attribute('setting','show_tile_setting',$show);
        set_gui_status($mpsoc,"ref",1);


    });

    my $scrolled_win = gen_scr_win_with_adjst($mpsoc,'get_config_adj');
    add_widget_to_scrolled_win($table,$scrolled_win);
    return $scrolled_win;
}


#############
#  gen_all_tiles
###########

sub gen_all_tiles{
    my ($mpsoc,$info, $hw_dir,$sw_dir)=@_;
    my ($NE, $NR, $RAw, $EAw, $Fw)=get_topology_info($mpsoc);    
    my $mpsoc_name=$mpsoc->object_get_attribute('mpsoc_name');
    my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";   
    my @generated_tiles;
    for (my $tile_num=0;$tile_num<$NE;$tile_num++){
        #print "$tile_num\n";
        my ($soc_name,$num)= $mpsoc->mpsoc_get_tile_soc_name($tile_num);
        next if(!defined $soc_name);
        
        
        my $path=$mpsoc->object_get_attribute('setting','soc_path');    
        $path=~ s/ /\\ /g;
        my $p = "$path/$soc_name.SOC";
        my ($soc,$r,$err) = regen_object($p);
        if ($r){        
            show_info($info,"**Error reading  $p file: $err\n");
            next; 
        } 
        
        #update core id
        $soc->object_add_attribute('global_param','CORE_ID',$tile_num);
        #update NoC param
        #my %nocparam = %{$mpsoc->object_get_attribute('noc_param',undef)};
        my $nocparam =$mpsoc->object_get_attribute('noc_param',undef);
        my $top=$mpsoc->mpsoc_get_soc($soc_name);
        my @nis=get_NI_instance_list($top);
        $soc->soc_add_instance_param($nis[0] ,$nocparam );
        my %z;
        foreach my $p (sort keys %{$nocparam}){
            $z{$p}="Parameter";
        }        
        $soc->soc_add_instance_param_type($nis[0] ,\%z);
        #foreach my $p ( sort keys %nocparam ) {
            
        #    print "$p = $nocparam{$p} \n";
        #}

        my $sw_path     = "$sw_dir/tile$tile_num";
        #print "$sw_path\n";
        if( grep (/^$soc_name$/,@generated_tiles)){ # This soc is generated before only create the software file
            generate_soc($soc,$info,$target_dir,$hw_dir,$sw_path,0,0,undef,1);
        }else{
            generate_soc($soc,$info,$target_dir,$hw_dir,$sw_path,0,1,"merge",1);
            move ("$hw_dir/$soc_name.sv","$hw_dir/tiles/");
            my @tmp= ("$hw_dir/tiles/$soc_name.sv");
            add_to_project_file_list(\@tmp,"$hw_dir/tiles",$hw_dir);       
            
        }      
    }#$tile_num
    
    
}


################
#    generate_soc
#################

sub generate_soc_files{
    my ($mpsoc,$soc,$info)=@_;
    my $mpsoc_name=$mpsoc->object_get_attribute('mpsoc_name');
    my $soc_name=$soc->object_get_attribute('soc_name');
    
    # copy all files in project work directory
    my $dir = Cwd::getcwd();
    my $project_dir      = abs_path("$dir/../../");
    #make target dir
    my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";
    mkpath("$target_dir/src_verilog/lib/",1,0755);
    mkpath("$target_dir/src_verilog/tiles/",1,0755);
    mkpath("$target_dir/sw",1,0755);

    my ($file_v,$tmp)=soc_generate_verilog($soc,"$target_dir/sw",$info);
        
    # Write object file
    open(FILE,  ">lib/soc/$soc_name.SOC") || die "Can not open: $!";
    print FILE perl_file_header("$soc_name.SOC");
    print FILE Data::Dumper->Dump([\%$soc],['soc']);
    close(FILE) || die "Error closing file: $!";
        
    # Write verilog file
    open(FILE,  ">lib/verilog/$soc_name.sv") || die "Can not open: $!";
    print FILE $file_v;
    close(FILE) || die "Error closing file: $!";
            
     
            
    #copy hdl codes in src_verilog         
    my ($hdl_ref,$warnings)= get_all_files_list($soc,"hdl_files");
    my ($sim_ref,$warnings2)= get_all_files_list($soc,"hdl_files_ticked");
    #hdl_ref-sim_ref
    my @n= get_diff_array($hdl_ref,$sim_ref);
    $hdl_ref=\@n;
            
    foreach my $f(@{$hdl_ref}){    
        my $n="$project_dir$f";
         if (-f "$n") {
                 copy ("$n","$target_dir/src_verilog/lib");         
         }elsif(-f "$f" ){
                 copy ("$f","$target_dir/src_verilog/lib");                     
         }            
    }
    show_colored_info($info,$warnings,'green')             if(defined $warnings); 
    
    
    
    foreach my $f(@{$sim_ref}){    
         my $n="$project_dir$f";
         if (-f "$n") {
                 copy ("$n","$target_dir/src_sim");         
         }elsif(-f "$f" ){
                 copy ("$f","$target_dir/src_sim");                     
         }            
    }
    show_colored_info($info,$warnings2,'green')             if(defined $warnings2); 
    
    
    #save project hdl file/folder list
    my @new_file_ref;
    foreach my $f(@{$hdl_ref}){
            my ($name,$path,$suffix) = fileparse("$f",qr"\..[^.]*$");
            push(@new_file_ref,"$target_dir/src_verilog/lib/$name$suffix");
    }
    foreach my $f(@{$sim_ref}){
            my ($name,$path,$suffix) = fileparse("$f",qr"\..[^.]*$");
            push(@new_file_ref,"$target_dir/src_sim/$name$suffix");
    }
    open(FILE,  ">$target_dir/src_verilog/file_list") || die "Can not open: $!";
    print FILE Data::Dumper->Dump([\@new_file_ref],['files']);
    close(FILE) || die "Error closing file: $!";            
            
            
            
            
    move ("$dir/lib/verilog/$soc_name.sv","$target_dir/src_verilog/tiles/");     
    copy_noc_files($project_dir,"$target_dir/src_verilog/lib");
            
            
    # Write header file
    generate_header_file($soc,$project_dir,$target_dir,$target_dir,$dir);
    #use File::Copy::Recursive qw(dircopy);
    #dircopy("$dir/../src_processor/aeMB/compiler","$target_dir/sw/") or die("$!\n");
    my $msg="SoC \"$soc_name\" has been created successfully at $target_dir/ ";
    return $msg;    
}    


sub generate_mpsoc_lib_file {
    my ($mpsoc,$info) = @_;
    my $tmp = $mpsoc;
    my $name=$mpsoc->object_get_attribute('mpsoc_name');
    
    open(FILE,  ">lib/mpsoc/$name.MPSOC") || die "Can not open: $!";
    print FILE perl_file_header("$name.MPSOC");
    print FILE Data::Dumper->Dump([\%$tmp],['mpsoc']);
    close(FILE) || die "Error closing file: $!";
     
    #get_soc_list($mpsoc,$info); 
    
}    

sub check_mpsoc_name {
    my ($name,$info,$label)= @_;
    $label="MPSoC" if (!defined $label);
    my $error = check_verilog_identifier_syntax($name);
    if ( defined $error ){
        #message_dialog("The \"$name\" is given with an unacceptable formatting. The mpsoc name will be used as top level verilog module name so it must follow Verilog identifier declaration formatting:\n $error");
        my $message = "The \"$name\" is given with an unacceptable formatting. The $label name will be used as top level Verilog module name so it must follow Verilog identifier declaration formatting:\n $error";
        add_colored_info($info, $message,'red' );
        return 1;
    }
    my $size= (defined $name)? length($name) :0;
    if ($size ==0) {
        message_dialog("Please define the $label filed!");
        return 1;
    }
    return 0;    
}


################
#    generate_mpsoc
#################

sub generate_mpsoc{
    my ($mpsoc,$info,$show_sucess_msg)=@_;
    my $name=$mpsoc->object_get_attribute('mpsoc_name');
    return 0 if (check_mpsoc_name($name,$info));
     
    # make target dir
    my $dir = Cwd::getcwd();
    my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$name";
    my $hw_dir     = "$target_dir/src_verilog";
    my $sw_dir     = "$target_dir/sw";
    
    # rmtree ($hw_dir);
    mkpath("$hw_dir",1,01777);    
    mkpath("$hw_dir/lib/",1,0755);
    mkpath("$hw_dir/tiles",1,0755);
    mkpath("$sw_dir",1,0755);
     
    #remove old rtl files that were copied by ProNoC
    my ($old_file_ref,$r,$err) = regen_object("$hw_dir/file_list");
    if (defined $old_file_ref){        
        remove_file_and_folders($old_file_ref,$target_dir);
    }    
    unlink "$hw_dir/file_list";
    
    #generate/copy all tiles HDL/SW codes
    gen_all_tiles($mpsoc,$info, $hw_dir,$sw_dir );
    
    #copy clk setting hdl codes in src_verilog
    my $project_dir      = abs_path("$dir/../../");          
    my $sc_soc =get_source_set_top($mpsoc,'mpsoc');  
      my ($file_ref,$warnings)= get_all_files_list($sc_soc,"hdl_files");    
      my ($sim_ref,$warnings2)= get_all_files_list($sc_soc,"hdl_files_ticked");
    #file_ref-sim_ref
    my @n= get_diff_array($file_ref,$sim_ref);
    $file_ref=\@n;
      
    copy_file_and_folders($file_ref,$project_dir,"$hw_dir/lib");
    show_colored_info($info,$warnings,'green')             if(defined $warnings);            
    add_to_project_file_list($file_ref,"$hw_dir/lib/",$hw_dir);
             
    copy_file_and_folders($sim_ref,$project_dir,"$hw_dir/../src_sim");
    show_colored_info($info,$warnings2,'green')     if(defined $warnings2);            
    add_to_project_file_list($sim_ref,"$hw_dir/../src_sim",$hw_dir);
              
    
     
    #generate header file containig the tiles physical addresses
    gen_tiles_physical_addrsses_header_file($mpsoc,"$sw_dir/phy_addr.h");
        
    #copy all NoC HDL files    
    #my @files = glob( "$dir/../rtl/src_noc/*.v" );
    #copy_file_and_folders(\@files,$project_dir,"$hw_dir/lib/");  
    #add_to_project_file_list(\@files,"$hw_dir/lib/",$hw_dir);
    my ($file_v,$top_v, $noc_param_v)=mpsoc_generate_verilog($mpsoc,$sw_dir,$info);
    
    #if Topology is custom copy custom topology files
    my $topology=$mpsoc->object_get_attribute('noc_param','TOPOLOGY');
    if ($topology eq '"CUSTOM"'){ 
        my $Tname=$mpsoc->object_get_attribute('noc_param','CUSTOM_TOPOLOGY_NAME');
        $Tname=~s/["]//gs;     
        my $dir1=  get_project_dir()."/mpsoc/rtl/src_topology/$Tname";
        my $dir2=  get_project_dir()."/mpsoc/rtl/src_topology/common";
        my @files = File::Find::Rule->file()
                            ->name( '*.v','*.V')
                            ->in( "$dir1" );
        copy_file_and_folders (\@files,$project_dir,"$hw_dir/lib/");
        
        @files = File::Find::Rule->file()
                            ->name( '*.v','*.V')
                            ->in( "$dir2" );
                         
        copy_file_and_folders (\@files,$project_dir,"$hw_dir/lib/");    
    }
     
        
    # Write object file
    generate_mpsoc_lib_file($mpsoc,$info);
       
    # Write verilog file
    open(FILE,  ">$target_dir/src_verilog/$name.sv") || die "Can not open: $!";
    print FILE $file_v;
    close(FILE) || die "Error closing file: $!";
            
    my $l=autogen_warning().get_license_header("${name}_top.v");
    open(FILE,  ">$target_dir/src_verilog/${name}_top.v") || die "Can not open: $!";
    print FILE "$l\n$top_v";
    close(FILE) || die "Error closing file: $!";   
    
    gen_noc_localparam_v_file($mpsoc,"$target_dir/src_verilog/lib/src_noc");
    
   
     
    
         
    
  #  $l=autogen_warning().get_license_header("${name}_mp.v");
  #  open(FILE,  ">$target_dir/src_verilog/${name}_mp.v") || die "Can not open: $!";
  #  print FILE "$l\n$mp_v";
  #  close(FILE) || die "Error closing file: $!";   
        
    
    #generate makefile
    open(FILE,  ">$sw_dir/Makefile") || die "Can not open: $!";
    print FILE mpsoc_sw_make();
    close(FILE) || die "Error closing file: $!";
    
    my $m_chain = $mpsoc->object_get_attribute('JTAG','M_CHAIN');
    
    #generate prog_mem
    open(FILE,  ">$sw_dir/program.sh") || die "Can not open: $!";
    print FILE mpsoc_mem_prog($m_chain);
    close(FILE) || die "Error closing file: $!";
      
    my @ff= ("$target_dir/src_verilog/$name.sv","$target_dir/src_verilog/${name}_top.v");       
    add_to_project_file_list(\@ff,"$hw_dir/lib/",$hw_dir);   
    
    #write perl_object_file 
    mkpath("$target_dir/perl_lib/",1,01777);
    open(FILE,  ">$target_dir/perl_lib/$name.MPSOC") || die "Can not open: $!";
    print FILE perl_file_header("$name.MPSOC");
    print FILE Data::Dumper->Dump([\%$mpsoc],['mpsoc']);                 
    
    #regenerate linker var file
    create_linker_var_file($mpsoc);
      
         
    message_dialog("MPSoC \"$name\" has been created successfully at $target_dir/ " ) if($show_sucess_msg);
    return 1;    
}    

sub mpsoc_sw_make {
     my $make="TOPTARGETS := all clean
SUBDIRS := \$(wildcard */.)
\$(TOPTARGETS): \$(SUBDIRS)
\$(SUBDIRS):
\t\$(MAKE) -C \$@ \$(MAKECMDGOALS)

.PHONY: \$(TOPTARGETS) \$(SUBDIRS)    
";
    return $make;
}


sub mpsoc_mem_prog {
    my $chain=shift;
    
     my $string="#!/bin/bash


#JTAG_INTFC=\"\$PRONOC_WORK/toolchain/bin/JTAG_INTFC\"
source ./jtag_intfc.sh


#reset and disable cpus, then release the reset but keep the cpus disabled

\$JTAG_INTFC -t $chain  -n 127  -d  \"I:1,D:2:3,D:2:2,I:0\"

# jtag instruction 
#    0: bypass
#    1: getting data
# jtag data :
#     bit 0 is reset 
#    bit 1 is disable
# I:1  set jtag_enable  in active mode
# D:2:3 load jtag_enable data register with 0x3 reset=1 disable=1
# D:2:2 load jtag_enable data register with 0x2 reset=0 disable=1
# I:0  set jtag_enable  in bypass mode



#programe the memory
for i in \$(ls -d */); do 
    echo \"Enter \${i\%\%/}\"
    cd \${i\%\%/}
    bash write_memory.sh 
    cd ..
done
 
#Enable the cpu
\$JTAG_INTFC -t $chain -n 127  -d  \"I:1,D:2:0,I:0\"
# I:1  set jtag_enable  in active mode
# D:2:0 load jtag_enable data register with 0x0 reset=0 disable=0
# I:0  set jtag_enable  in bypass mode
";
    return $string;
}


sub get_tile_LIST{
    my ($mpsoc,$x,$y,$soc_num,$row,$table)=@_;
    my $instance_name=$mpsoc->mpsoc_get_instance_info($soc_num);    
    if(!defined $instance_name){
        $mpsoc->mpsoc_set_default_ip($soc_num);
        $instance_name=$mpsoc->mpsoc_get_instance_info($soc_num);    
    }

    #ipname
    my $col=0;
    my $label=gen_label_in_left("IP_$soc_num($x,$y)");
    $table->attach_defaults ( $label, $col, $col+1 , $row, $row+1);$col+=2;
    #instance name
    my $entry=gen_entry($instance_name);
    $table->attach_defaults ( $entry, $col, $col+1 , $row, $row+1);$col+=2;
    $entry->signal_connect( 'changed'=> sub{
        my $new_instance=$entry->get_text();
        $mpsoc->mpsoc_set_ip_inst_name($soc_num,$new_instance);
        set_gui_status($mpsoc,"ref",20);
        print "changed to  $new_instance\n ";    
    });

    #combo box
    my @list=('A','B');
    my $combo=gen_combo(\@list,0);
    $table->attach_defaults ( $combo, $col, $col+1 , $row, $row+1);$col+=2;
    #setting
    my $setting= def_image_button("icons/setting.png","Browse");
    $table->attach_defaults ( $setting, $col, $col+1 , $row, $row+1);$col+=2;
}

sub get_tile{
    my ($mpsoc,$tile)=@_;
    my ($soc_name,$num)= $mpsoc->mpsoc_get_tile_soc_name($tile);
    my $button;
    my $topology=$mpsoc->object_get_attribute('noc_param','TOPOLOGY');
    
    if( defined $soc_name){
        my $setting=$mpsoc->mpsoc_get_tile_param_setting($tile);
        $button=($setting eq 'Custom')? def_colored_button("Tile $tile*\n$soc_name",$num) :    def_colored_button("Tile $tile\n$soc_name",$num) ;
    }else {
        $button =def_colored_button("Tile $tile\n",50) if(! defined $soc_name);
    }
    
    $button->signal_connect("clicked" => sub{ 
       get_tile_setting ($mpsoc,$tile);
    });    
  
    #$button->show_all;
    return $button;
}

sub define_empty_param_setting {
    my ($mpsoc,$window)=@_;
    my $ok = def_image_button('icons/select.png','OK');
    my $okbox=def_hbox(TRUE,0);
    $okbox->pack_start($ok, FALSE, FALSE,0);
    $ok-> signal_connect("clicked" => sub{ 
             set_gui_status($mpsoc,"refresh_soc",1);
             $window->destroy;          
        
     });
     my $param_table = def_table(1, 1, TRUE);
     $param_table->attach_defaults($okbox,0,1,3,4);
     return $param_table;
    
    
}

sub get_tile_setting {
        my($mpsoc,$tile)=@_;
        my $window = def_popwin_size(50,40,"Parameter setting for Tile $tile ",'percent');
        my $table = def_table(6, 2, FALSE);
    
        my $scrolled_win = add_widget_to_scrolled_win($table);
        my $row=0;
        my ($soc_name,$g,$t)=$mpsoc->mpsoc_get_tile_soc_name($tile);
       
        my @socs=$mpsoc->mpsoc_get_soc_list();
        my @list=(' ',@socs);
        my $pos=(defined $soc_name)? get_scolar_pos($soc_name,@list): 0;
        my $combo=gen_combo(\@list, $pos);
        my $label=gen_label_in_left("  Processing tile name:");
        $table->attach($label,0,2,$row,$row+1,'shrink','shrink',2,2);
        $table->attach($combo,2,3,$row,$row+1,'shrink','shrink',2,2);$row++;
        add_Hsep_to_table($table,0,3,$row);$row++;
        $soc_name = ' ' if (!defined $soc_name);
        my $param_table =  ($soc_name eq ' ')? define_empty_param_setting($mpsoc,$window) :
               get_soc_parameter_setting_table($mpsoc,$soc_name,$window,[$tile]); 
     
         $table->attach_defaults($param_table,0,3,2,3);
         
         
         $combo->signal_connect('changed'=>sub{
            my $new_soc=$combo->get_active_text();
            if ($new_soc eq ' '){
                #unconnect tile
                $mpsoc->mpsoc_set_tile_free($tile);
                $param_table->destroy;
                $param_table=  define_empty_param_setting($mpsoc,$window); 
                $table->attach_defaults($param_table,0,3,2,3);
                $window->show_all;
            }else {
                $mpsoc->mpsoc_set_tile_soc_name($tile,$new_soc);
                $param_table->destroy;
                $param_table =  get_soc_parameter_setting_table($mpsoc,$new_soc,$window,[$tile]); 
                $table->attach_defaults($param_table,0,3,2,3);
                $window->show_all;
            }
        });
        $window->add($scrolled_win);
        $window->show_all;
}


##########
# gen_tiles
#########
sub gen_tiles{
    my ($mpsoc)=@_;
    my ($NE, $NR, $RAw, $EAw, $Fw)=get_topology_info($mpsoc);
    my $table;
    my $dim_y = floor(sqrt($NE));
       $table=def_table($NE%8,$NE/8,FALSE);#    my ($row,$col,$homogeneous)=@_;
       for (my $i=0; $i<$NE;$i++){
           my $tile=get_tile($mpsoc,$i);
           my $y= int($i/$dim_y);
           my $x= $i % $dim_y;            
        $table->attach_defaults ($tile, $x, $x+1 , $y, $y+1);
       }
       
       my $scrolled_win = gen_scr_win_with_adjst($mpsoc,'gen_tiles_adj');
    add_widget_to_scrolled_win($table,$scrolled_win);
    return $scrolled_win;   
}


sub get_elf_file_addr_range {
    my ($file,$tview)=@_;    
    #my $command=  "size  -A $file";
    my $command=  "nm  $file";
    #add_info($tview,"$command\n");
    my    ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($command);
    if(length $stderr>1){            
        add_colored_info($tview,"$stderr\n",'red');
        add_colored_info($tview,"$command was not run successfully!\n",'red');
        return ("Err","Err");
    }    
    if($exit){
        add_colored_info($tview,"$stdout\n",'red');
        add_colored_info($tview,"$command was not run successfully!\n",'red');
        return ("Err","Err");
    }
                            
    my @lines = split ("\n" ,$stdout);
    my $max_addr=0;
    my $sec_name;    

    foreach my $p (@lines ){
        $p =~ s/\s+/ /g; # remove extra spaces
        $p =~ s/^\s+//; #ltrim
        my ($addr,$type,$name)= sscanf("%x %s %s","$p");
        if(defined $addr && defined $name){
            if($max_addr < $addr) {
                $max_addr = $addr;
                $sec_name = $name;        
            }
        } 
    }
    return ($max_addr,$sec_name);    
}


sub show_reqired_brams{
    my ($self,$tview)=@_;
    my $win=def_popwin_size (50,50,"BRAM info", 'percent');
    my $sc_win = gen_scr_win_with_adjst($self,'liststore');
    my $table= def_table(10,10,FALSE);
    add_widget_to_scrolled_win($table,$sc_win);    
    my $row=0;
    my $col=0;        
    
    my  @clmns =('Tile#', 'Section located in Upper Bound Address (UBA) ','UBA in Bytes','UBA in Words','Minimum Memory Address Width');    
    my $target_dir;
    my @data;
    
    my $mpsoc_name=$self->object_get_attribute('mpsoc_name');
    if(defined $mpsoc_name){#it is an soc

        my ($NE, $NR, $RAw, $EAw, $Fw)=get_topology_info($self);    
   
        $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";       
       
        for (my $tile_num=0;$tile_num<$NE;$tile_num++){           
            my $ram_file     = "$target_dir/sw/tile$tile_num/image";            
            my ($size,$sec) = get_elf_file_addr_range($ram_file,$tview);
            my %clmn;
            $clmn{0}="tile$tile_num";
            $clmn{1}= "$sec";
            $clmn{2}="$size";
            my $w=$size/4;
            $clmn{3}="$w";
            $clmn{4}=ceil(log($w)/log(2));
            push(@data,\%clmn);
            
        }#$tile_num    
    } 
    else 
    {
        my $soc_name=$self->object_get_attribute('soc_name');
        $target_dir  = "$ENV{'PRONOC_WORK'}/SOC/$soc_name";
        my $ram_file     = "$target_dir/sw/image";                    
        my ($size,$sec) = get_elf_file_addr_range($ram_file,$tview);            
        my %clmn;
        $clmn{0}="$soc_name";
        $clmn{1}= "$sec";
        $clmn{2}="$size";
        my $w=$size/4;
        $clmn{3}="$w";
        $clmn{4}=ceil(log($w)/log(2));
        push(@data,\%clmn);        
    }    

    my @clmn_type = (#'Glib::Boolean', # => G_TYPE_BOOLEAN
                                    #'Glib::Uint',    # => G_TYPE_UINT
                                    'Glib::String',  # => G_TYPE_STRING
                                  'Glib::String',
                                   'Glib::String',
                                   'Glib::String',
                                   'Glib::String'); # you get the idea
    
    my $list=    gen_list_store (\@data,\@clmn_type,\@clmns);
    $table-> attach  ($list, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $row++; 
    
    $win->add($sc_win);
    $win->show_all();    
}

sub check_conflict {
    my ($self,$tile_num,$label)=@_;    
    
    my $r1 =$self->object_get_attribute("ROM$tile_num",'end'); 
    my $r2 =$self->object_get_attribute("RAM$tile_num",'start');
    
    if(defined $r1 && defined $r2){
        if(hex($r1)> hex($r2)){
            $label->set_markup("<span  foreground= 'red' ><b>RAM-ROM range Conflict</b></span>");
            
        }else {     
            $label->set_label(" ");
        
        }
    }else {
        $label->set_label(" ");
    
    }     
}


sub update_ram_rom_size {
    my ($self,$tile_num,$name,$label,$start,$end,$conflict)=@_;    
    my $s = $start->get_value();
    my $e = $end->get_value();

    $self->object_add_attribute($name.$tile_num,'start',$start->get_value());
    $self->object_add_attribute($name.$tile_num,'end',$end->get_value());
    if($e <= $s){
        #$label->set_label("Invalid range" );
        $label->set_markup("<span  foreground= 'red' ><b>Invalid range</b></span>");
        
    }else {
        $label->set_label( metric_conversion($e - $s) . "B");
    
    }
    
    check_conflict($self,$tile_num,$conflict);
    
    
    
}

sub get_tile_peripheral_patameter {
    my ($mpsoc,$tile_num,$peripheral,$param_name)=@_;  
    my ($soc_name,$n,$soc_num)=$mpsoc->mpsoc_get_tile_soc_name($tile_num);
    if(defined $soc_name) {
        my $top=$mpsoc->mpsoc_get_soc($soc_name);
        my @insts=$top->top_get_all_instances();
        foreach my $id (@insts){                    
            if ($id =~/$peripheral[0-9]/){
                my $name=$top->top_get_def_of_instance($id,'instance');
                
                my  %params;
                my $setting=$mpsoc->mpsoc_get_tile_param_setting($tile_num);
                #if ($setting eq 'Custom'){
                    %params= $top->top_get_custom_soc_param($tile_num);
                #}else{
                #    %params=$top->top_get_default_soc_param();
                #}
                return $params{"${name}_$param_name"};
            }    
        }
    }
    return undef;        
                            
}

sub get_soc_peripheral_parameter {
    my ($soc,$peripheral,$param_nam)=@_;    
    my @instances=$soc->soc_get_all_instances();
    foreach my $id (@instances){
        if ($id =~/$peripheral[0-9]/){    
            return $soc->soc_get_module_param_value ($id,$param_nam) if (defined $param_nam);        
        }
    }    
    return undef;
}


sub linker_initial_setting {
    my ($self,$tview)=@_;    
    my $mpsoc_name=$self->object_get_attribute('mpsoc_name');
    my $tnum;
    my $target_dir;
    if(defined $mpsoc_name){#it is an mpsoc

        my ($NE, $NR, $RAw, $EAw, $Fw)=get_topology_info($self);    
       
        $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";
        for (my $tile_num=0;$tile_num<$NE;$tile_num++){      
            
            my $v=get_tile_peripheral_patameter($self,$tile_num,"_ram","Aw");
            $v = 13 if (!defined $v);
            $self->object_add_attribute('MEM'.$tile_num,'width',$v);
            $self->object_add_attribute('MEM'.$tile_num,'percent',75);
            
            my $s =(1 << ($v+2)) ;
            my $p = 75;
            
            my $rom_start = 0;
            my $rom_end= int ( ($s*$p)/100);
            my $ram_start= int (($s*$p)/100);
            my $ram_end= $s;
            
            $self->object_add_attribute('ROM'.$tile_num,'start',$rom_start);
            $self->object_add_attribute('ROM'.$tile_num,'end',$rom_end);
            $self->object_add_attribute('RAM'.$tile_num,'start',$ram_start);
            $self->object_add_attribute('RAM'.$tile_num,'end',$ram_end);
            
        
        }    
        
               
    }
    else 
    {
        my $v=get_soc_peripheral_parameter ($self,"_ram","Aw");
        $v = 13 if (!defined $v);
        $self->object_add_attribute('MEM0','width',$v);
        $self->object_add_attribute('MEM0','percent',75);
        my $s =(1 << ($v+2)) ;
        my $p = 75;
            
        my $rom_start = 0;
        my $rom_end= int ( ($s*$p)/100);
        my $ram_start= int (($s*$p)/100);
        my $ram_end= $s;
            
        $self->object_add_attribute('ROM0','start',$rom_start);
        $self->object_add_attribute('ROM0','end',$rom_end);
        $self->object_add_attribute('RAM0','start',$ram_start);
        $self->object_add_attribute('RAM0','end',$ram_end);
    }  
    
    
}



sub linker_setting{
    my ($self,$tview)=@_;
    my $win=def_popwin_size (80,50,"BRAM info", 'percent');
    my $sc_win = gen_scr_win_with_adjst($self,'liststore');
    my $table= def_table(10,10,FALSE);
    
    
    my $row=0;
    my $col=0;        
    
    $table-> attach  (gen_label_in_center("Tile"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col+=1;
    $table-> attach  (gen_label_in_center("Memory Addr"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col+=1;
    $table-> attach  (gen_label_in_center("ROM/(ROM+RAM)"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col+=1;
    
    $table-> attach  (gen_label_in_center("ROM index addr (hex)"), $col, $col+2,  $row, $row+1,'shrink','shrink',2,2); $col+=3;
    $table-> attach  (gen_label_in_center("RAM index addr (hex)"), $col, $col+2,  $row, $row+1,'shrink','shrink',2,2); $col+=3;

    
    $col=0;$row++; 
    $table-> attach  (gen_label_in_center("#"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++;
    $table-> attach  (gen_label_in_center("Width"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++;
    $table-> attach  (gen_label_in_center("(%)"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++;
    
    $table-> attach  (gen_label_in_center("Beginning"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col+=1;
    $table-> attach  (gen_label_in_center("End"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++;
    $table-> attach  (gen_label_in_center("Size"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++;
    
    $table-> attach  (gen_label_in_center("Beginning"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col+=1;
    $table-> attach  (gen_label_in_center("End"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++;
    $table-> attach  (gen_label_in_center("Size"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++;
    
        
    $col=0;$row++;     
    
    my $target_dir;
    my @data;
    
    my $mpsoc_name=$self->object_get_attribute('mpsoc_name');
    my $tnum;
    if(defined $mpsoc_name){#it is an mpsoc

        my ($NE, $NR, $RAw, $EAw, $Fw)=get_topology_info($self);    
           $tnum=$NE;
        $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";       
    }
    else 
    {
        my $soc_name=$self->object_get_attribute('soc_name');
        $target_dir  = "$ENV{'PRONOC_WORK'}/SOC/$soc_name";
        $tnum=1;
    }   
    for (my $j=0;$j<$tnum;$j++){           
            my $tile_num=$j;
            my $conflict =gen_label_in_center(" ") ;
            
            $table-> attach  (gen_label_in_center("$tile_num"), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2);$col++; 
            my $ram_width = gen_spin(2,64,1);
            my $width = $self->object_get_attribute('MEM'.$tile_num,'width');
            if(!defined $width){
                linker_initial_setting ($self,$tview);
                $width = $self->object_get_attribute('MEM'.$tile_num,'width');
            }
            $ram_width->set_value($width);    
            my $size =gen_label_in_center(metric_conversion(1 << 15). "B") ;
            
            
            $table-> attach  (def_pack_hbox('FALSE',0,$ram_width,$size), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
            
            
            
            
            my $percent = gen_spin_float(6.25,93.75,6.25,2);
            my $p=$self->object_get_attribute('MEM'.$tile_num,'percent');
            $percent->set_value($p);
            
            my $enter= def_image_button("icons/enter.png"); 
            $table-> attach  (def_pack_hbox('FALSE',0,$percent,$enter), $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
            
            my $rom_start_v =$self->object_get_attribute('ROM'.$tile_num,'start');
            my $rom_end_v = $self->object_get_attribute('ROM'.$tile_num,'end');
            my $ram_start_v = $self->object_get_attribute('RAM'.$tile_num,'start');
            my $ram_end_v = $self->object_get_attribute('RAM'.$tile_num,'end');
            
            
            
            my $rom_start = HexSpin->new ( $rom_start_v, 0, 0xffffffff ,4);
            $rom_start->set_digits(8);
            $table-> attach  ($rom_start, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
            
            
            
            my $rom_end = HexSpin->new ( $rom_end_v, 0, 0xffffffff ,4);
            $rom_end->set_digits(8);
            $table-> attach  ($rom_end, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
            
            my $rom_size =gen_label_in_center(" ") ;
            $table-> attach  ($rom_size, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
            update_ram_rom_size($self,$tile_num,'ROM',$rom_size,$rom_start,$rom_end,$conflict);
            $rom_start->signal_connect ( 'changed', sub {update_ram_rom_size($self,$tile_num,'ROM',$rom_size,$rom_start,$rom_end,$conflict);});
            $rom_end->signal_connect ( 'changed', sub {update_ram_rom_size($self,$tile_num,'ROM',$rom_size,$rom_start,$rom_end,$conflict);});
        
            my $ram_start = HexSpin->new ( $ram_start_v, 0, 0xffffffff ,4);
            $ram_start->set_digits(8);
            $table-> attach  ($ram_start, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
            
            
            my $ram_end = HexSpin->new ( $ram_end_v, 0, 0xffffffff ,4);
            $ram_end->set_digits(8);
            $table-> attach  ($ram_end, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
        
            my $ram_size =gen_label_in_center(" ") ;
            $table-> attach  ($ram_size, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
            
            
            
            
            update_ram_rom_size($self,$tile_num,'RAM',$ram_size,$ram_start,$ram_end,$conflict);
            
            $ram_start->signal_connect ( 'changed', sub {update_ram_rom_size($self,$tile_num,'RAM',$ram_size,$ram_start,$ram_end,$conflict);});
            $ram_end->signal_connect ( 'changed', sub {update_ram_rom_size($self,$tile_num,'RAM',$ram_size,$ram_start,$ram_end,$conflict);});
        
            $ram_width->signal_connect("value_changed" => sub{
                my $w=$ram_width->get_value();
                $self->object_add_attribute('MEM'.$tile_num,'width',$w);
                $size->set_label (metric_conversion(1 << ($w+2)). "B") ;
                $size->show_all;
                $enter->clicked; 
            });    
            $percent->signal_connect("value_changed" => sub{
                $self->object_add_attribute('MEM'.$tile_num,'percent',$percent->get_value());
            });
            
            $table-> attach  ($conflict, $col, $col+1,  $row, $row+1,'shrink','shrink',2,2); $col++; 
        
           
        
            
            $enter-> signal_connect ( 'clicked' , sub {
                my $w=$ram_width->get_value();
                my $s =(1 << ($w+2));
                my $p = $percent->get_value();
                
                my $rom_start_v = 0;
                my $rom_end_v= int ( ($s*$p)/100);
                my $ram_start_v= int (($s*$p)/100);
                my $ram_end_v= $s;
                
                $rom_start->set_value($rom_start_v);
                $rom_end->set_value($rom_end_v);
                $ram_start->set_value($ram_start_v);
                $ram_end->set_value($ram_end_v);
                update_ram_rom_size($self,$tile_num,'ROM',$rom_size,$rom_start,$rom_end,$conflict);
                update_ram_rom_size($self,$tile_num,'RAM',$ram_size,$ram_start,$ram_end,$conflict);
                
            });
            
            $col=0; $row++; 
            
    }#$tile_num    
     
    my $main_table=def_table(10,10,FALSE);
      
    my $ok = def_image_button('icons/select.png','OK');    
    $main_table->attach_defaults ($table  , 0, 12, 0,11);
    $main_table->attach ($ok,5, 6, 11,12,'shrink','shrink',0,0);
    
    $ok->signal_connect('clicked', sub {
        for (my $t=0;$t<$tnum;$t++){      
            my $r0 =$self->object_get_attribute("ROM$t",'start');
            my $r1 =$self->object_get_attribute("ROM$t",'end'); 
            my $r2 =$self->object_get_attribute("RAM$t",'start');
            my $r3 =$self->object_get_attribute("RAM$t",'end'); 
            if(hex($r1) <hex($r0)  || hex($r3) <hex($r2)   ){
                 message_dialog("Please fix tile $t invalid range !");
                 return ;
                
            }
            
            if(hex($r1) > hex($r2)  ){
                 message_dialog("Please fix tile $t conflict range !");
                 return ;
                
            }
            
            
            
        }
        create_linker_var_file($self);    
        $win->destroy();
    
    
    });
    
    
    add_widget_to_scrolled_win($main_table,$sc_win);
    $win->add($sc_win);
    $win->show_all();    
    
}


sub create_linker_var_file{
    my ($self)=@_;
    my $mpsoc_name=$self->object_get_attribute('mpsoc_name');
    my $tnum;
    
    my $width = $self->object_get_attribute('MEM0','width');
    if(!defined $width){
        linker_initial_setting ($self);
    }
    
    if(defined $mpsoc_name){#it is an mpsoc
        my ($NE, $NR, $RAw, $EAw, $Fw)=get_topology_info($self);    
           $tnum=$NE;       
    }
    else 
    {
        
        $tnum=1;        
    }   
    
    for (my $t=0;$t<$tnum;$t++){       
        my $r0 =$self->object_get_attribute("ROM$t",'start');
        my $r1 =$self->object_get_attribute("ROM$t",'end'); 
        my $r2 =$self->object_get_attribute("RAM$t",'start');
        my $r3 =$self->object_get_attribute("RAM$t",'end'); 
                        
        my $file=sprintf("        
    
MEMORY
{    
    rom (rx)    : ORIGIN = 0x%x , LENGTH = 0x%x  /* %s B- Rom space  */
    ram (wrx)   : ORIGIN = 0x%x , LENGTH = 0x%x  /* %s B- Ram space  */
}        

            ",$r0,$r1 - $r0, metric_conversion($r1 - $r0),$r2,$r3- $r2,metric_conversion($r3 - $r2));
            
        if(defined $mpsoc_name){            
            save_file ("$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name/sw/tile$t/linkvar.ld",$file) if(-d "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name/sw/tile$t/"); 
        }else{
            my $soc_name=$self->object_get_attribute('soc_name');
            my $p1="$ENV{'PRONOC_WORK'}/SOC/$soc_name/sw/";
            mkpath("$p1",1,0755) unless (-d "$p1");        
            save_file ("$p1/linkvar.ld",$file) 
        }
    }
    
}


sub software_edit_mpsoc {
    my $self=shift;    
    my $name=$self->object_get_attribute('mpsoc_name');
    if (length($name)==0){
        message_dialog("Please define the MPSoC name!");
        return ;
    }
    my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$name";
    my $sw     = "$target_dir/sw";
    
    my $orcc_page=select_orcc_generated_srcs($self);
    my $orcc_lable=def_image_label('icons/orcc.png','Auto-generate Software using ORCC');
    my @pages=($orcc_page);
    my @pages_lables=($orcc_lable);
    my ($app,$table,$tview) = software_main($sw,undef,\@pages,\@pages_lables);    
    
    my $prog= def_image_button('icons/write.png','Program FPGA\'s BRAMs');
    my $linker = def_image_button('icons/setting.png','LD Linker',FALSE,1);
    my $make = def_image_button('icons/gen.png','_Compile',FALSE,1);
    my $ram = def_image_button('icons/info.png',"Required BRAMs\' size",FALSE,1);
            
    $table->attach ($ram,0, 1, 1,2,'shrink','shrink',0,0);
    $table->attach ($linker,4, 5, 1,2,'shrink','shrink',0,0);
    $table->attach ($make,5, 6, 1,2,'shrink','shrink',0,0);
    $table->attach ($prog,9, 10, 1,2,'shrink','shrink',0,0); 
    
    $ram -> signal_connect("clicked" => sub{
        show_reqired_brams($self,$tview);
    });
     
      my $load;
     
    $make -> signal_connect("clicked" => sub{
        $load->destroy   if(defined $load);
        $load= show_gif("icons/load.gif");
        $table->attach ($load,7, 8, 1,2,'shrink','shrink',0,0); 
        $load->show_all; 
        $app->ask_to_save_changes();
        add_info($tview,' ');
        unless (run_make_file($sw,$tview,'clean')){
            $load->destroy;    
            $load=def_icon("icons/cancel.png");
            $table->attach ($load,7, 8, 1,2,'shrink','shrink',0,0); 
            $load->show_all; 
            return;
        };
         unless (run_make_file($sw,$tview)){
             $load->destroy;    
             $load=def_icon("icons/cancel.png");
             $table->attach ($load,7, 8, 1,2,'shrink','shrink',0,0); 
             $load->show_all; 
             return;
         }
        $load->destroy; 
        $load=def_icon("icons/button_ok.png");
        $table->attach ($load,7, 8, 1,2,'shrink','shrink',0,0); 
        $load->show_all; 
        

    });
    
    #Programe the board 
    $prog-> signal_connect("clicked" => sub{ 
        my $error = 0;
        my $bash_file="$sw/program.sh";
        my $jtag_intfc="$sw/jtag_intfc.sh";
        
        add_info($tview,"Program the board using quartus_pgm and $bash_file file\n");
        #check if the programming file exists
        unless (-f $bash_file) {
            add_colored_info($tview,"\tThe $bash_file does not exists! \n", 'red');
            $error=1;
        }
        #check if the jtag_intfc.sh file exists
        unless (-f $jtag_intfc) {
            add_colored_info($tview,"\tThe $jtag_intfc does not exists!. Press the compile button and select your FPGA board first to generate $jtag_intfc file\n", 'red');
            $error=1;
        }
        
        return if($error);
        my $command = "cd $sw; bash program.sh";
        add_info($tview,"$command\n");
        my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($command);
        if(length $stderr>1){            
            add_colored_info($tview,"$stderr\n",'red');
            add_colored_info($tview,"Memory was not programmed successfully!\n",'red');
        }else {

            if($exit){
                add_colored_info($tview,"$stdout\n",'red');
                add_colored_info($tview,"Memory was not programmed successfully!\n",'red');
            }else{
                add_info($tview,"$stdout\n");
                add_colored_info($tview,"Memory is programmed successfully!\n",'blue');

            }
            
        }        
    });
    
    
    $linker -> signal_connect("clicked" => sub{
        linker_setting($self,$tview);
    });

}



#############
#    load_mpsoc
#############

sub load_mpsoc{
    my ($mpsoc,$info)=@_;
    my $file;
    my $dialog =  gen_file_dialog (undef, 'MPSOC');    
    my $dir = Cwd::getcwd();
    $dialog->set_current_folder ("$dir/lib/mpsoc")    ;
    my @newsocs=$mpsoc->mpsoc_get_soc_list();
    add_info($info,'');
    if ( "ok" eq $dialog->run ) {
        $file = $dialog->get_filename;
        my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
        if($suffix eq '.MPSOC'){
            my ($pp,$r,$err) = regen_object($file );
            if ($r){        
                add_info($info,"**Error: cannot open $file file: $err\n");
                $dialog->destroy;
                return;
            } 
            

            clone_obj($mpsoc,$pp);
            #read save mpsoc socs
            my @oldsocs=$mpsoc->mpsoc_get_soc_list();
            #add existing SoCs and add them to mpsoc
            
            my $error;
            #print "old: @oldsocs\n new @newsocs \n"; 
            foreach my $p (@oldsocs) {
                #print "$p\n";
                my @num= $mpsoc->mpsoc_get_soc_tiles_num($p);
                if (scalar @num && ( grep (/^$p$/,@newsocs)==0)){
                    my $m="Processing tile $p that has been used for ties  @num but is not located in library anymore\n";
                     $error = (defined $error ) ? "$error $m" : $m;
                } 
                $mpsoc->mpsoc_remove_soc ($p) if (grep (/^$p$/,@newsocs)==0); 
                     

            }
            @newsocs=get_soc_list($mpsoc,$info); # add all existing socs
            add_info($info,"**Error:  \n $error\n") if(defined $error);

            set_gui_status($mpsoc,"load_file",0);
                    
        }                    
     }
     $dialog->destroy;
}

#######
#    CLK setting
#######

sub clk_setting_win1{
    my ($self,$info,$type)=@_;

    my $window = def_popwin_size(80,80,"CLK setting",'percent');
   
    my $next=def_image_button('icons/right.png','Next');     
    my $mtable = def_table(10, 1, FALSE);
    #get the list of all tiles clk sources
    
    my @sources=('clk','reset');
    
    my $table = def_table(10, 7, FALSE);
    my $notebook = gen_notebook();
    $notebook->set_scrollable(TRUE);
    #$notebook->can_focus(FALSE);
    $notebook->set_tab_pos ('left'); 
    
    
    
    my($row,$column)=(0,0);
    
    my %all = ($type eq 'mpsoc') ? get_all_tiles_clk_sources_list($self): get_soc_clk_source_list($self) ;
    foreach my $s (@sources){
         my $spin;    
         ($row,$column,$spin)=  add_param_widget($self,"$s number","${s}_number", 1,'Spin-button',"1,1024,1","Define total number of ${s} input ports  mpsoc", $table,$row,$column,1,'SOURCE_SET',undef,undef,'horizontal');
         
         my $w=get_source_assignment_win($self,$s,$all{$s},$type);
         my $box=def_hbox(FALSE,0);
         $box->pack_start($w, TRUE, TRUE, 0);
         $notebook->append_page ($box,gen_label_in_center ($s)); 
         $spin->signal_connect("value_changed" => sub{
             $self->object_add_attribute('SOURCE_SET',"REDEFINE_TOP",1);    
             $w->destroy;
             $w=get_source_assignment_win($self,$s,$all{$s},$type);
             $box->pack_start($w, TRUE, TRUE, 0);
             $box->show_all; 
             
         });
        
    }    

    $mtable->attach_defaults($table,0,1,0,1);
    $mtable->attach_defaults( $notebook,0,1,1,20);
    $mtable->attach($next,0,1,20,21,'expand','fill',2,2);    
    $window->add ($mtable);
    $window->show_all();    
    $next-> signal_connect("clicked" => sub{             
        clk_setting_win2($self,$info,$type);
        $window->destroy;    
                    
    });    

}


sub update_wave_form {
    my ($period,$rise,$fall,$r_lab,$f_lab)=@_;
    my $p =$period->get_value();
    my $n =$rise->get_value();
    my $v= ($p * $n)/100;
    $r_lab->set_text("=$v ns");             
    $n =$fall->get_value();
    $v= ($p * $n)/100;
    $f_lab->set_text("=$v ns");    
}

sub get_source_assignment_win{
    my ($mpsoc,$s,$ports_ref,$type)=@_;
    my$row=0;
    my $column=0;
    my $num = $mpsoc->object_get_attribute('SOURCE_SET',"${s}_number");    
    my $table1 = def_table(20, 20, FALSE);
    my $win1=add_widget_to_scrolled_win($table1);
    my $win2;
    my $v2;
    
    #if($s eq 'clk'){
    #    my @labels=("clk name", 'Frequency MHz', 'Period ns', 'rise edge times ns', 'fall edge times ns');
    #    foreach my $l (@labels){
            #  $table1->attach  (gen_label_in_center($l),$column,$column+1,$row,$row+1,'fill','shrink',2,2);$column+=5;
    #    }
        #$row++;
        #$column=0;
    #}
    
    #get source signal names    
    my $loc =  'vertical';
    for(my $n=0;$n<$num; $n++ ){
        my $entry;
        my $enter= def_image_button("icons/enter.png");
        my $box=def_hbox(FALSE,0);
        $box->pack_start( $enter, FALSE, FALSE, 0);    

        ($row,$column,$entry)=  add_param_widget($mpsoc,"$n-","${s}_${n}_name", "${s}$n",'Entry',undef,undef, $table1,$row,$column,1,'SOURCE_SET',undef,undef,'horizontal');
        $table1->attach  ($box,$column,$column+1,$row,$row+1,'fill','shrink',2,2);$column++;
           
        $enter->signal_connect ("clicked"  => sub{
            $mpsoc->object_add_attribute('SOURCE_SET',"REDEFINE_TOP",1); 
            $win2->destroy;
            $win2= get_source_assignment_win2($mpsoc,$s,$ports_ref,$type);
            $v2-> pack2($win2, TRUE, TRUE);  
            $v2->show_all;            
        });
        
        
        if($s eq 'clk'){
            ($column,$row)=get_clk_constrain_widget($mpsoc,$table1,$column,$row, $s,$n);                 
        }
        
            
        
       # if((($n+1) % 4)==0){
              $column=0;
              $row++;
       #}          
    }    
         
       #source assigmnmet
    $win2= get_source_assignment_win2($mpsoc,$s,$ports_ref,$type);
    $v2=gen_vpaned($win1,.2,$win2);    
       return $v2;    
}


sub get_clk_constrain_widget {
    my ($self,$table,$column,$row, $s,$n)=@_;
    $table->attach (gen_Vsep() , $column,$column+1,$row,$row+1,'fill','fill',2,2);$column+=1;
    return ($column,$row);
    my $frequency;    
    ($row,$column,$frequency)=  add_param_widget($self,"Frequency(MHz)","${s}_${n}_mhz", 100,'Spin-button',"1,1024,0.01",undef, $table,$row,$column,1,'SOURCE_SET',undef,undef,'horizontal');
    $table->attach (gen_Vsep() , $column,$column+1,$row,$row+1,'fill','fill',2,2);$column+=1;
    my $period;
    ($row,$column,$period)=  add_param_widget($self,"Period(ns)","${s}_${n}_period", 10,'Spin-button',"0,1024,0.01",undef, $table,$row,$column,1,'SOURCE_SET',undef,undef,'horizontal');
    $table->attach (gen_Vsep() , $column,$column+1,$row,$row+1,'fill','fill',2,2);$column+=1;
    my $rise;    
    ($row,$column,$rise)=  add_param_widget($self,"rising edge(%)","${s}_${n}_rise", 0,'Spin-button',"0,100,0.1",undef, $table,$row,$column,1,'SOURCE_SET',undef,undef,'horizontal');
    my $r_lab=gen_label_in_center('=0 ns');
    $table->attach  ($r_lab,$column,$column+1,$row,$row+1,'fill','shrink',2,2);$column+=1;
    $table->attach (gen_Vsep() , $column,$column+1,$row,$row+1,'fill','fill',2,2);$column+=1;
    my $fall;    
    ($row,$column,$fall)=  add_param_widget($self,"falling edge(%)","${s}_${n}_fall", 50,'Spin-button',"0,100,0.1",undef, $table,$row,$column,1,'SOURCE_SET',undef,undef,'horizontal');
    my $f_lab=gen_label_in_center('=5 ns');
    $table->attach  ($f_lab,$column,$column+1,$row,$row+1,'fill','shrink',2,2);$column+=1;
    update_wave_form($period,$rise,$fall,$r_lab,$f_lab);
    $frequency-> signal_connect("value_changed" => sub{
         my $fr =$frequency->get_value();
        my $p = 1000/$fr;
         $period->set_value($p);
         update_wave_form($period,$rise,$fall,$r_lab,$f_lab);
    });    
    $period-> signal_connect("value_changed" => sub{
        my $p =$period->get_value();
        my $fr = 1000/$p;
        $frequency->set_value($fr);
        update_wave_form($period,$rise,$fall,$r_lab,$f_lab);
    });    
    $rise-> signal_connect("value_changed" => sub{
         update_wave_form($period,$rise,$fall,$r_lab,$f_lab);             
    });    
    $fall-> signal_connect("value_changed" => sub{
       update_wave_form($period,$rise,$fall,$r_lab,$f_lab);
    });    
    return ($column,$row);
}



sub get_source_assignment_win2{
    my ($mpsoc,$s,$ports_ref,$type)=@_;
    my $num = $mpsoc->object_get_attribute('SOURCE_SET',"${s}_number");
    my $table2 = def_table(10, 7, FALSE);
       my $win2=add_widget_to_scrolled_win($table2);
       my %ports = %{$ports_ref} if(defined $ports_ref);   
   
    my $contents;
    for(my $n=0;$n<$num; $n++ ){
           my $m=$mpsoc->object_get_attribute('SOURCE_SET',"${s}_${n}_name");
           $contents=(defined $contents)? "$contents,$m":$m;   
    }
    my $default=$mpsoc->object_get_attribute('SOURCE_SET',"${s}_0_name");    
    my $n=0;
    my($row,$column)=(0,0);
    if($type eq 'mpsoc' ) {
        add_param_widget($mpsoc,"    NoC $s","NoC_${s}", $default,'Combo-box',$contents,undef, $table2,$row,$column,1,'SOURCE_SET_CONNECT',undef,undef,'horizontal');
        ($row,$column)=(1,0);
    }    

    foreach my $p (sort keys %ports){
           my @array=@{$ports{$p}};
           foreach my $q (@array){
               my $param="${p}_$q"; 
               my $label="  ${p}_$q";                              
               ($row,$column)=  add_param_widget($mpsoc,$label,$param, $default,'Combo-box',$contents,undef, $table2,$row,$column,1,'SOURCE_SET_CONNECT',undef,undef,'horizontal');
               if((($n+1) % 4)==0){$column=0;$row++;}$n++;
           }        
    }
    return $win2;
    
}


sub get_all_tiles_clk_sources_list{
    my $mpsoc=shift;
    my ($NE, $NR, $RAw, $EAw, $Fw)= get_topology_info ($mpsoc); 
    my %all_sources;    
    for (my $tile_num=0;$tile_num<$NE;$tile_num++){
        my ($soc_name,$n,$soc_num)=$mpsoc->mpsoc_get_tile_soc_name($tile_num);
        next if(!defined $soc_name);     
        my $top=$mpsoc->mpsoc_get_soc($soc_name);
        my @intfcs=$top->top_get_intfc_list();
        
        my @sources=('clk','reset');
            
        foreach my $intfc (@intfcs){
            my($type,$name,$num)= split("[:\[ \\]]", $intfc);
            foreach my $s (@sources){
                if ($intfc =~ /plug:$s/){ 
                    my @ports=$top->top_get_intfc_ports_list($intfc);                
                    $all_sources{$s}{"T$tile_num"}=\@ports;
                }    
            }
        
        }
    }
        return  %all_sources;    
}



sub clk_setting_win2{
    my ($self,$info,$type)=@_;
        
    my $window = def_popwin_size(70,70,"CLK setting",'percent');
    my $table = def_table(10, 7, FALSE);
    my $scrolled_win=add_widget_to_scrolled_win($table);
    my $ok = def_image_button('icons/select.png','OK');    
    my $back = def_image_button('icons/left.png',undef);
    my $diagram  = def_image_button('icons/diagram.png','Diagram');    
    my $ip = ip->lib_new ();
    #print "get_top_ip(\$self,$type);\n";
    my $mpsoc_ip=get_top_ip($self,$type);
  
    $ip->add_ip($mpsoc_ip);            
    my $soc =get_source_set_top($self,$type);    
    my $infc = interface->interface_new(); 
           
    
    set_gui_status($soc,"ideal",0);
    # A tree view for holding a library
    my %tree_text;
    my @categories= ('Source');
    foreach my $p (@categories)
    {
           my @modules= $ip->get_modules($p);
           $tree_text{$p}=\@modules;    
    }
   
    my $tree_box = create_tree ($soc,'IP list', $info,\%tree_text,\&tmp,\&add_module_to_mpsoc);
    my  $device_win=show_active_dev($soc,$ip,$infc,$info); 
    my $h1=gen_hpaned($tree_box,.15,$device_win);
    $table->attach_defaults ($h1,0, 10, 0, 10);
    
    my $event =Event->timer (after => 1, interval => 1, cb => sub { 

my ($state,$timeout)= get_gui_status($soc);
            
    
            if ($timeout>0){
                $timeout--;
                set_gui_status($soc,$state,$timeout);                        
            }
            elsif( $state ne "ideal" ){
              
               #check if top is removed add it
                my @instances=$soc->soc_get_all_instances();
                my $redefine =1;
                foreach my $inst (@instances){
                    $redefine = 0 if ($inst eq 'TOP');
                }
                if($redefine == 1){
                    my $ip = ip->lib_new ();
                    #print "get_top_ip(\$self,$type);\n";
                    my $mpsoc_ip=get_top_ip($self,$type);
                    
                    $ip->add_ip($mpsoc_ip);    
                    $soc ->object_add_attribute('SOURCE_SET',"IP",$mpsoc_ip);        
                    $self->object_add_attribute('SOURCE_SET',"REDEFINE_TOP",0);  
                    add_mpsoc_to_device($soc,$ip); 
                    $self->object_add_attribute('SOURCE_SET',"SOC",$soc);                    
                }
                
                $device_win->destroy;
               
                $device_win=show_active_dev($soc,$ip,$infc,$info); 
                $h1 -> pack2($device_win, TRUE, TRUE);  
                $h1 -> show_all; 
                $table->show_all();    
                $device_win->show_all();
                 
                $self->object_add_attribute('SOURCE_SET',"SOC",$soc);       
                set_gui_status($soc,"ideal",0);
                 
            }    
            return TRUE;


 });
  
     my $mtable = def_table(10, 5, FALSE);
    $mtable->attach_defaults($scrolled_win,0,5,0,9);
    $mtable->attach($back,0,1,9,10,'expand','fill',2,2) if($type ne 'soc');
    $mtable->attach($diagram,2,4,9,10,'expand','fill',2,2);
    $mtable->attach($ok,4,5,9,10,'expand','fill',2,2);
    
    $window->add ($mtable);
    $window->show_all();
    $self->object_add_attribute('SOURCE_SET',"SOC",$soc);
    $back-> signal_connect("clicked" => sub{             
        $self->object_add_attribute('SOURCE_SET',"SOC",$soc);        
        clk_setting_win1($self,$info,$type);
        $window->destroy;
        $event->cancel;                
    });    
    
    $diagram-> signal_connect("clicked" => sub{ 
        show_tile_diagram ($soc);
    });
    
    $ok-> signal_connect("clicked" => sub{     
        set_gui_status($self,"ref",1);             
        $window->destroy;
        $event->cancel;                        
    });    
    
      
 
    
    
    
}

sub tmp{
    
}

sub add_module_to_mpsoc{
    my ($soc,$category,$module,$info)=@_;
    my $ip = ip->lib_new ();
    
    my ($instance_id,$id)= get_instance_id($soc,$category,$module);
    
    #add module instance
    my $result=$soc->soc_add_instance($instance_id,$category,$module,$ip);
    
    if($result == 0){
        my $info_text= "Failed to add \"$instance_id\" to SoC. $instance_id is already exist.";     
        show_info($info,$info_text); 
        return;
    }
    $soc->soc_add_instance_order($instance_id);
    # Add IP version 
    my $v=$ip->ip_get($category,$module,"version"); 
    $v = 0 if(!defined $v);
    #print "$v\n";
    $soc->object_add_attribute($instance_id,"version",$v);
    # Read default parameter from lib and add them to soc
    my %param_default= $ip->get_param_default($category,$module);
    
    my $rr=$soc->soc_add_instance_param($instance_id,\%param_default);
    if($rr == 0){
        my $info_text= "Failed to add default parameter to \"$instance_id\".  $instance_id does not exist.";     
        show_info($info,$info_text); 
        return;
    }
    my @r=$ip->ip_get_param_order($category,$module);
    $soc->soc_add_instance_param_order($instance_id,\@r);
    
    get_module_parameter($soc,$ip,$instance_id);
    undef $ip;
    set_gui_status($soc,"refresh_soc",0);    
} 




#$mpsoc,$top_ip,$sw_dir,$soc_name,$id,$soc_num,$txview
sub get_top_ip{
    my ($self,$type)=@_;    
    
    my $mpsoc_ip=ip_gen->ip_gen_new();
    $mpsoc_ip->ipgen_add("module_name",'TOP');
    $mpsoc_ip->ipgen_add("ip_name",'TOP');
    $mpsoc_ip->ipgen_add("category",'TOP');
    $mpsoc_ip->ipgen_add('GUI_REMOVE_SET','DISABLE');
    if($type eq 'mpsoc'){
        my @sources=('clk','reset');
        foreach my $s (@sources){
            my $num = $self->object_get_attribute('SOURCE_SET',"${s}_number");
            $num=1 if(!defined $num);
            $mpsoc_ip->ipgen_add_plug("$s",'num',$num);
            for (my $n=0; $n<$num; $n++ ){
                
                my $name=$self->object_get_attribute('SOURCE_SET',"${s}_${n}_name");
                $mpsoc_ip->ipgen_set_plug_name($s,$n,$name);            
                $mpsoc_ip->ipgen_add_port($name,undef,'input',"plug:${s}\[$n\]","${s}_i");    
                                
            }    
        }
    # add_mpsoc_ip_other_interfaces($mpsoc,$mpsoc_ip);    
    }
    else{
        my %sources = get_soc_clk_source_list($self);
        foreach my $s (sort keys %sources){
            my @ports = @{$sources{$s}} if (defined $sources{$s});
            my $num=scalar @ports;
            $mpsoc_ip->ipgen_add_plug("$s",'num',$num);
            my $n=0;    
            foreach my $p (@ports){
                $mpsoc_ip->ipgen_set_plug_name($s,$n,$p);
                $mpsoc_ip->ipgen_add_port($p,undef,'input',"plug:${s}\[$n\]","${s}_i");
                $n++;
            } 
        }
    }
    return $mpsoc_ip;            
}


sub add_mpsoc_ip_other_interfaces{
    my ($mpsoc,$mpsoc_ip)=@_;    
my ($NE, $NR, $RAw, $EAw, $Fw)= get_topology_info ($mpsoc); 
    my $processors_en=0;
    my %intfc_num;
    my @parameters_order;
    for (my $tile_num=0;$tile_num<$NE;$tile_num++){
            my ($soc_name,$n,$soc_num)=$mpsoc->mpsoc_get_tile_soc_name($tile_num);    
    
    
            my $top=$mpsoc->mpsoc_get_soc($soc_name);
            my @nis=get_NI_instance_list($top);
            my @noc_param=$top->top_get_parameter_list($nis[0]);
            my $inst_name=$top->top_get_def_of_instance($nis[0],'instance');
    
            #other parameters
            my %params=$top->top_get_default_soc_param();
    
            my @intfcs=$top->top_get_intfc_list();
            
            my $i=0;
        
            my $dir = Cwd::getcwd();
            my $mpsoc_name=$mpsoc->object_get_attribute('mpsoc_name');
            my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$mpsoc_name";
            my $soc_file="$target_dir/src_verilog/tiles/$soc_name.sv";
                    
            my $vdb =read_verilog_file($soc_file);
                
            my %soc_localparam = $vdb->get_modules_parameters($soc_name);
        
            
            foreach my $intfc (@intfcs){
        
                # Auto connected/not connected interface    
                if( $intfc eq 'socket:ni[0]' || ($intfc =~ /plug:clk\[/) ||  ( $intfc =~ /plug:reset\[/)|| ($intfc =~ /socket:RxD_sim\[/ )  || $intfc =~ /plug:enable\[/){
                    #do nothing
                }
                elsif( $intfc eq 'IO' ){
                    my @ports=$top->top_get_intfc_ports_list($intfc);
                    foreach my $p (@ports){
                        my ($io_port,$type,$new_range,$intfc_name,$intfc_port)=    get_top_port_io_info($top,$p,$tile_num,\%params,\%soc_localparam);
                        $mpsoc_ip->ipgen_add_port($io_port,$new_range,$type,'IO','IO');    
                        
                                
                    }            
                    
                }
    
                else {
                #other interface
                    my($if_type,$if_name,$if_num)= split("[:\[ \\]]", $intfc); 
                    print "my($if_type,$if_name,$if_num)= split(, $intfc); \n";
                    my $num = (defined $intfc_num{"$if_type:$if_name"})? $intfc_num{"$if_type:$if_name"}+1:0;
                    $intfc_num{"$if_type:$if_name"}=$num;
                    $mpsoc_ip->ipgen_add_plug("$if_name",'num',$num) if ($if_type eq 'plug');
                    $mpsoc_ip->ipgen_add_soket("$if_name",'num',$num) if ($if_type eq 'socket');
                                       
                    my @ports=$top->top_get_intfc_ports_list($intfc);
                    foreach my $p (@ports){
                        my ($io_port,$type,$new_range,$intfc_name,$intfc_port)=    get_top_port_io_info($top,$p,$tile_num,\%params,\%soc_localparam);
                        $mpsoc_ip->ipgen_add_port($io_port,$new_range,$type,"$if_type:$if_name\[$num\]",$intfc_port);    
                                    
                    }            
                }            
            }
            
            
        my $setting=$mpsoc->mpsoc_get_tile_param_setting($tile_num);
        #if ($setting eq 'Custom'){
             %params= $top->top_get_custom_soc_param($tile_num);
        #}else{
        #     %params=$top->top_get_default_soc_param();
        #}
        
        foreach my $p (sort keys %params){
            $params{$p}=add_instantc_name_to_parameters(\%params,"T$tile_num",$params{$p});    
            $params{$p}=add_instantc_name_to_parameters(\%soc_localparam,"T$tile_num",$params{$p});    
            my $pname="T${tile_num}_$p";
            $mpsoc_ip->    ipgen_add_parameter ($pname,$params{$p},'Fixed',undef,undef,'Localparam',1);    
            push (@parameters_order,$pname);
        
        }        
        foreach my $p (sort keys %soc_localparam){
            $soc_localparam{$p}=add_instantc_name_to_parameters(\%params,"T$tile_num",$soc_localparam{$p});        
            $soc_localparam{$p}=add_instantc_name_to_parameters(\%soc_localparam,"T$tile_num",$soc_localparam{$p});        
            my $pname="T${tile_num}_$p";
            $mpsoc_ip->    ipgen_add_parameter ($pname,$soc_localparam{$p},'Fixed',undef,undef,'Localparam',0);    
            push (@parameters_order,$pname);
            
        }
            
    
    
    }    
    #TODO get parameter order
    $mpsoc_ip->ipgen_add("parameters_order",\@parameters_order);     
    
}

sub get_source_set_top{
    my ($self,$type)=@_;
    my $soc =$self->object_get_attribute('SOURCE_SET',"SOC");
    my $redefine =$self->object_get_attribute('SOURCE_SET',"REDEFINE_TOP");
    $redefine=1 if(!defined $redefine);
    if(!defined $soc){
        $soc = soc->soc_new();         
        $soc->object_add_attribute('soc_name','TOP'); 
        $redefine=1;        
    }
    if($redefine==1){
        my $ip = ip->lib_new ();
        #print "get_top_ip(\$self,$type);\n";
        my $mpsoc_ip=get_top_ip($self,$type);
        
        $ip->add_ip($mpsoc_ip);    
        $soc ->object_add_attribute('SOURCE_SET',"IP",$mpsoc_ip);        
        $self->object_add_attribute('SOURCE_SET',"REDEFINE_TOP",0);  
        add_mpsoc_to_device($soc,$ip); 
        $self->object_add_attribute('SOURCE_SET',"SOC",$soc);
    }        
    return $soc;    
}


sub add_mpsoc_to_device{
    my ($soc,$ip)=@_;
    my $category='TOP';
    my $module='TOP';
    my ($instance_id,$id) =('TOP',1);
    
    #my ($instance_id,$id)= get_instance_id($soc,$category,$module);
    
    remove_instance_from_soc($soc,$instance_id);
    
    #add module instanance
    my $result=$soc->soc_add_instance($instance_id,$category,$module,$ip);
    
    if($result == 0){
        my $info_text= "Failed to add \"$instance_id\" to SoC. $instance_id is already exist.";     
    #    show_info($info,$info_text); 
        return;
    }
    $soc->soc_add_instance_order($instance_id);
    # Add IP version 
    my $v=$ip->ip_get($category,$module,"version"); 
    $v = 0 if(!defined $v);
    #print "$v\n";
    $soc->object_add_attribute($instance_id,"version",$v);
    # Read default parameter from lib and add them to soc
    my %param_default= $ip->get_param_default($category,$module);
    
    my $rr=$soc->soc_add_instance_param($instance_id,\%param_default);
    if($rr == 0){
        my $info_text= "Failed to add default parameter to \"$instance_id\".  $instance_id does not exist.";     
    #    show_info($info,$info_text); 
        return;
    }
    my @r=$ip->ip_get_param_order($category,$module);
    $soc->soc_add_instance_param_order($instance_id,\@r);
    
    #get_module_parameter($soc,$ip,$instance_id);
    undef $ip;
    set_gui_status($soc,"refresh_soc",0);    
} 

######
# ctrl
######

sub ctrl_box{
    my ($mpsoc,$info)=@_;
    my $table = def_table (1, 12, FALSE);     
    my $generate = def_image_button('icons/gen.png','_Generate RTL',FALSE,1);
    my $compile  = def_image_button('icons/gate.png','_Compile RTL',FALSE,1);
    my $software = def_image_button('icons/binary.png','_Software',FALSE,1);
    my $diagram  = def_image_button('icons/diagram.png','Diagram');
    my $clk=  def_image_button('icons/clk.png','CLK setting');
    my $row=0;
    my $target_dir= "$ENV{'PRONOC_WORK'}/MPSOC";
    my ($entrybox,$entry ) =gen_save_load_widget (
        $mpsoc, #the object 
        "MPSoC name",#the label shown for setting configuration
        'mpsoc_name',#the key name for saveing the setting configuration in object 
        'MPSoC',#the label full name show in tool tips
        $target_dir,#Where the generted RTL files are loacted. Undef if not aplicaple
        'mpsoc',#check the given name match the SoC or mpsoc name rules
        'lib/mpsoc',#where the current configuration seting file is saved
        'MPSOC',#the extenstion given for configuration seting file
        \&load_mpsoc,#refrence to load function
        $info
        );
    $table->attach ($entrybox,$row, $row+2, 0,1,'expand','shrink',2,2);$row+=2;
    $table->attach ($diagram, $row, $row+1, 0,1,'expand','shrink',2,2);$row++;
    $table->attach ($clk, $row, $row+1, 0,1,'expand','shrink',2,2);$row++;    
    $table->attach ($generate, $row, $row+1, 0,1,'expand','shrink',2,2);$row++;
    $table->attach ($software, $row, $row+1, 0,1,'expand','shrink',2,2);$row++;    
    $table->attach ($compile, $row, $row+1, 0,1,'expand','shrink',2,2);$row++;
    $generate-> signal_connect("clicked" => sub{ 
        generate_mpsoc($mpsoc,$info,1);
        set_gui_status($mpsoc,"refresh_soc",1);
    });
    $compile -> signal_connect("clicked" => sub{ 
        $mpsoc->object_add_attribute('compile','compilers',"QuartusII,Vivado,Verilator,Modelsim");
        my $name=$mpsoc->object_get_attribute('mpsoc_name');
        $name="" if (!defined $name);
        if (length($name)==0){
            message_dialog("Please define the MPSoC name!");
            return ;
        }
        my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$name";
        my $top_file     = "$target_dir/src_verilog/${name}_top.v";
        if (-f $top_file){  
            my $answer = yes_no_dialog ("Do you want to Regenearte the MPSoC RTL code too?");  
            generate_mpsoc($mpsoc,$info,0) if ($answer eq 'yes');
            select_compiler($mpsoc,$name,$top_file,$target_dir);
        } else {
            message_dialog("Cannot find $top_file file. Please run RTL Generator first!");
            return;
        }
    });
    $software -> signal_connect("clicked" => sub{
        my $name=$mpsoc->object_get_attribute('mpsoc_name');
        $name="" if (!defined $name);
        if (length($name)==0){
            message_dialog("Please define the MPSoC name!");
            return ;
        }
        my $target_dir  = "$ENV{'PRONOC_WORK'}/MPSOC/$name";
        my $sw_folder = "$target_dir/sw";
        unless (-d $sw_folder){  
            message_dialog("Cannot find $sw_folder. Please run RTL Generator first!");
            return;
        }
        software_edit_mpsoc($mpsoc);
    });
    $diagram-> signal_connect("clicked" => sub{ 
        show_topology_diagram ($mpsoc);
    });
    
    $clk-> signal_connect("clicked" => sub{ 
        clk_setting_win1($mpsoc,$info,'mpsoc');    
    });
    return $table;
}

sub gen_save_load_widget {
    my (
        $self, #the object 
        $label,#the label shown for setting configuration
        $param_name,#the key name for saveing the setting configuration in object 
        $full_name,#the label full name show in tool tips
        $target_dir,#Where the generted RTL files are loacted. Undef if not aplicaple
        $check,#check the given name match the SoC or mpsoc name rules
        $config_dir,#where the current configuration seting file is saved
        $extention,#the extenstion given for configuration seting file
        $load_func,
        $info
    )=@_;
    my $load = def_image_button('icons/load2.png');
    my $entry=gen_entry_object($self,$param_name,undef,undef,undef,undef);
    my $entrybox=gen_label_info("$label:",$entry);
    my $save  = def_image_button('icons/save.png');    
    my $open_dir  = def_image_button('icons/open-folder.png') if (defined $target_dir);
    set_tip($save, "Save current $full_name configuration setting");
    set_tip($load, "Load a saved $full_name configuration setting");
    set_tip($open_dir, "Open target $full_name folder") if (defined $target_dir);
    $entrybox->pack_start( $save, FALSE, FALSE, 0);
    $entrybox->pack_start( $load, FALSE, FALSE, 0);
    $entrybox->pack_start( $open_dir , FALSE, FALSE, 0) if (defined $target_dir);
    $open_dir-> signal_connect("clicked" => sub{         
        my $name=$self->object_get_attribute($param_name);
        $name="" if (!defined $name);
        if (length($name)==0){
            message_dialog("Please define the $label!");
            return ;
        }
        return if(check_mpsoc_name($name,$label) && $check=='mpsoc') ;
        return if(check_soc_name($name,$label) && $check=='soc') ;    
        unless (-d "$target_dir/$name"){
            message_dialog("Cannot find $target_dir/$name.\n Please run RTL Generator first!",'error');
            return;
        }
        system "xdg-open   $target_dir/$name";
    })  if (defined $target_dir);
    $save-> signal_connect("clicked" => sub{ 
        my $name=$self->object_get_attribute($param_name);    
        if (length($name)==0){
            message_dialog("Please define the $label!");
            return ;
        }
        return if(check_mpsoc_name($name,$label) && $check=='mpsoc') ;
        return if(check_soc_name($name,$label) && $check=='soc') ;    
        # Write object file
        my $config_file = "${config_dir}/${name}.$extention";
        open(FILE,  ">$config_file") || die "Can not open $config_file: $!";
        print FILE perl_file_header("${name}.$extention");
        print FILE Data::Dumper->Dump([\%$self],[$extention]);
        close(FILE) || die "Error closing file: $!";
        message_dialog("Current configuration  \"$name\" is saved as $config_file.");
    });
    $entry->signal_connect( 'changed'=> sub{
        my $name=$entry->get_text();
        $self->object_add_attribute ("save_as",undef,$name);
    });
    $load-> signal_connect("clicked" => sub{
        &$load_func($self,$info);
        set_gui_status($self,"ref",5);
    });
    return ($entrybox,$entry);
}

############
#    main
############
sub mpsocgen_main{
    my $infc = interface->interface_new(); 
    my $soc = ip->lib_new ();
    my $mpsoc= mpsoc->mpsoc_new();
    set_gui_status($mpsoc,"ideal",0);
    my $main_table = def_table (25, 12, FALSE);
    # The box which holds the info, warning, error ...  messages
    my ($infobox,$info)= create_txview();
    my $noc_conf_box=get_config ($mpsoc,$info);
    my $noc_tiles=gen_tiles($mpsoc);
    $main_table->set_row_spacings (4);
    $main_table->set_col_spacings (1);
    my $ctrl=ctrl_box($mpsoc,$info);
    my $h1=gen_hpaned($noc_conf_box,.3,$noc_tiles);
    my $v2=gen_vpaned($h1,.55,$infobox);
    my $row=0;
    $main_table->attach_defaults ($v2  , 0, 12, 0,24);
    #$main_table->attach_defaults ($ctrl,0, 12, 24,25);
    $main_table->attach ($ctrl,0, 12, 24,25, 'fill','fill',2,2);
    #check soc status every 0.5 second. refresh device table if there is any changes 
    Glib::Timeout->add (100, sub{ 
        my ($state,$timeout)= get_gui_status($mpsoc);
        if ($timeout>0){
            $timeout--;
            set_gui_status($mpsoc,$state,$timeout); 
        }elsif ($state eq 'save_project'){
            # Write object file
            my $name=$mpsoc->object_get_attribute('mpsoc_name');
            open(FILE,  ">lib/mpsoc/$name.MPSOC") || die "Can not open: $!";
            print FILE perl_file_header("$name.MPSOC");
            print FILE Data::Dumper->Dump([\%$mpsoc],[$name]);
            close(FILE) || die "Error closing file: $!";
            set_gui_status($mpsoc,"ideal",0);
        }
        elsif( $state ne "ideal" ){
            $noc_conf_box->destroy();
            $noc_conf_box=get_config ($mpsoc,$info);
            $noc_tiles->destroy();
            $noc_tiles=gen_tiles($mpsoc);
            $h1 -> pack1($noc_conf_box, TRUE, TRUE);
            $h1 -> pack2($noc_tiles, TRUE, TRUE);
            $v2-> pack1($h1, TRUE, TRUE);
            $h1->show_all;
            $ctrl->destroy;
            $ctrl=ctrl_box($mpsoc,$info);
            $main_table->attach ($ctrl,0, 12, 24,25,'fill','fill',2,2);
            $main_table->show_all();
            set_gui_status($mpsoc,"ideal",0);
        }
        return TRUE;
    } );
    my $sc_win = add_widget_to_scrolled_win($main_table);
    return $sc_win;
}

1
