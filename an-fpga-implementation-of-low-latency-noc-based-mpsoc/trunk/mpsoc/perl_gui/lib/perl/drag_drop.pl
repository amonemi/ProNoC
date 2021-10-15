#! /usr/bin/perl -w

use strict;
use constant::boolean;


use FindBin;
use lib $FindBin::Bin;
require "widget.pl";
use POSIX qw(ceil floor);


#Declare our columns
use constant C_MARKUP               => 0;
use constant C_PIXBUF               => 1;


#Declare our IDENDTIFIER ID's
use constant ID_ICONVIEW            => 48;






sub drag_and_drop_page {
	my ($self,$tview,$name,$items_ref, $ctrl_box)=@_;
    my $vbox = def_vbox(FALSE,5);
	my $group_num=$self->object_get_attribute($name,'group_num');
	update_group_item_list($self,$group_num,$name,$items_ref);
	my $ref_source = $self->object_get_attribute("$name",'ungrouped');
    my $lb=$self->object_get_attribute($name,'lable');
    my ($win,$list_store)=create_iconview($self,"$lb",'NO', $ref_source,$name,'ungrouped',undef);
    my $table = def_table($group_num%8,$group_num/8,FALSE);
    my $dim_y = floor(sqrt($group_num));
  	my $gname=$self->object_get_attribute("$name",'group_name_root');	
	my $editable =$self->object_get_attribute("$name",'group_name_editble');	  	
  	my $limit=$self->object_get_attribute($name,'map_limit');
  	for (my $i=0; $i<$group_num;$i++){
  		
  			my $ref_grp = $self->object_get_attribute("$name","$gname($i)");  			
  			
    		my ($gwin,$list_store)=create_iconview($self,"$gname($i)",$editable,$ref_grp,$name,"$gname($i)",$limit );
    		my $y= int($i/$dim_y);
    		my $x= $i % $dim_y;    		
	        $table->attach_defaults ($gwin, $x, $x+1 , $y, $y+1);
    }
   my $sw = add_widget_to_scrolled_win($table);
   
   my  $v_paned=gen_vpaned($win,.2,$sw);
   my  $h_paned= (defined $ctrl_box)? gen_hpaned_adj($self,$v_paned,.5,$ctrl_box, "drag.$name") : $v_paned;   

$vbox->add($h_paned);
$vbox->show_all();
return $vbox;
}

sub get_item_group_name{
	my ($self,$name,$item)=@_;
	#print "($self,$name,$item)\n";
	my $group_num=$self->object_get_attribute("$name",'group_num');
	my $gname=$self->object_get_attribute("$name",'group_name_root');
	for(my $i=0;$i<$group_num;$i=$i+1){
		my $gref = $self->object_get_attribute("$name","$gname($i)");
		next if(! defined $gref);
		return $self->object_get_attribute("$name","$gname($i)".'_name') if( check_scolar_exist_in_array($item,$gref ));
	}	
	return $item;
}

sub get_items_in_a_group{
	my ($self,$name,$group_name)=@_;
	my $group_num=$self->object_get_attribute("$name",'group_num');
	my $gname=$self->object_get_attribute("$name",'group_name_root');
	for(my $i=0;$i<$group_num;$i=$i+1){
		my $current_name= $self->object_get_attribute("$name","$gname($i)".'_name');
		return  $self->object_get_attribute("$name","$gname($i)") if($current_name eq $group_name );
	}	
	return undef;	
}


sub update_group_item_list{
	my ($self,$group_num,$name,$items_ref)=@_;
	#get the list of current items
	my @items = (defined $items_ref) ? @{$items_ref}:();
	my @items_grouped;
	my $gname=$self->object_get_attribute("$name",'group_name_root');
	#update groaped_list
	for(my $i=0;$i<$group_num;$i=$i+1){
		my $gref = $self->object_get_attribute("$name","$gname($i)");
		next if(! defined $gref);
		my @grouped =  @{$gref};
		@grouped=get_common_array(\@grouped,\@items);		
		$self->object_add_attribute("$name","$gname($i)",\@grouped);		
		push (@items_grouped,@grouped);
	}	
	#@items_ungroaped= @items - @items_groaped
	my @items_ungrouped= get_diff_array(\@items ,\@items_grouped);
	$self->object_add_attribute("$name",'ungrouped',\@items_ungrouped);	
}




sub create_iconview {
#---------------------------------------------------
#Creates an Iconview in a ScrolledWindow. This -----
#Iconview has the ability to drag items off it  -----
#---------------------------------------------------
	my ($self,$label,$editable,$ref,$name,$param,$limit)=@_;
    my $icon_string= undef;
    my $tree_model = create_iconview_model($self,$name,$ref);

    my $icon_view = gen_iconview($tree_model,C_MARKUP,C_PIXBUF);

    #Enable the IconView as a drag source
	
    add_drag_source($icon_view,'STRING',[],ID_ICONVIEW);
    add_drop_source($icon_view,$tree_model,$name,$param,$self,$limit);

    #This is a nice to have. It changes the drag icon to that of the
    #icon which are now selected and dragged (single selection mode)
	my $saved;

    $icon_view->signal_connect('drag-begin' => sub { 
        $icon_view->selected_foreach ( sub{
                my $iter =$tree_model->get_iter($_[1]);
				$saved=$iter;
                #set the text and pixbuf
                my $icon_pixbuf = $tree_model->get_value($iter,C_PIXBUF);
				drag_set_icon_pixbuf($icon_view,$icon_pixbuf);
				$icon_view->show_all();
        } );
    });

    #set up the data which needs to be fed to the drag destination (drop)
    $icon_view->signal_connect ('drag-data-get' => sub { 
		return if(! defined $saved);
		$icon_string = $tree_model->get_value($saved,C_MARKUP);		
		#print "\$icon_string=$icon_string\n";
		my $no_markup = $icon_string;
        $no_markup =~ s/<[^>]*>//g;
		
		
		my $gref = $self->object_get_attribute("$name",$param);		
		$tree_model->remove($saved);
		source_drag_data_get(@_,$icon_string); 
		my @array=remove_scolar_from_array($gref,$no_markup );
		$self->object_add_attribute("$name",$param,\@array);
		set_gui_status($self,"drag-data-get",0);
		
	} );
    
    #Standard scrolledwindow to allow growth
    my $sw = add_widget_to_scrolled_win($icon_view);
    $sw->set_policy('never','automatic');
    $sw->set_border_width(6);
    my($width,$hight)=max_win_size();
	$sw->set_size_request($width/10,$hight/10);
    
   
    my $frame = gen_frame();
	$frame->set_shadow_type ('in');
	# Animation
	$frame->add ($sw);
	#$align->add ($frame);
	
	
	
	my $entry=gen_entry_object($self,$name,$param."_name",$label);
	$frame->set_label_widget ($entry) if($editable eq 'YES');
	$frame->set_label_widget (gen_label_in_center($label)) unless($editable eq 'YES');
    
    
    return ($frame,$tree_model);
}





sub target_drag_data_received {
#---------------------------------------------------
#Extract the data which was set up during the  -----
#'drag-data-get' event which fired just before -----
#the 'drag-data-received' event. Also checks which--
#source supplied the data, and handle accordingly----
#---------------------------------------------------

    my ($widget, $context, $x, $y, $data, $info, $time,$ref) = @_;

	my ($target,$name,$param,$self,$limit) = @{$ref};
    my @array;
	my $icon=$self->object_get_attribute($name,'trace_icon');
	my $pixbuf = get_icon_pixbuff ($icon );
    

   

        my $no_markup = $data->get_text;
		#print Dumper ($widget, $context, $x, $y, $data, $info, $time,$no_markup);

        $no_markup =~ s/<[^>]*>//g;       

	
       

        add_icon_to_tree($self,$name,$target,$no_markup) ;
        my $r=$self->object_get_attribute("$name","$param");
        
        @array = defined ($r)? @{$r}:();
        push (@array ,$no_markup);
        $self->object_add_attribute("$name","$param",\@array); 
      
        
        
        
   
# check if the maximum number of dropped item is received
$limit =655350 if(!defined $limit);
if( scalar @array >= $limit){    
    stop_drag_dest( $widget);
}    

	call_gtk_drag_finish($context, 0, 0, $time);
   # $context->finish (0, 0, $time);
}

sub source_drag_data_get {
#---------------------------------------------------
#This sets up the data of the drag source. It is ---
#required before the 'drag-data-received' event ----
#fires which can be used to extract this data ------
#---------------------------------------------------

    my ($widget, $context, $data, $info, $time,$string) = @_;

    $data->set_text($string,-1) if defined $string;
    $data->set_text("Unknown-event-name",-1) unless defined $string;
	
	

}




sub add_icon_to_tree{
	my ($self,$name,$list_store,$val)=@_;
	
    my $icon=$self->object_get_attribute($name,'trace_icon');
	my $pixbuf = get_icon_pixbuff ($icon );
	
	
        #if there was a valid icon in the iconset, add it
        if( defined $pixbuf ){

            my $iter = $list_store->append;
            $list_store->set (
                        $iter,
                        C_MARKUP, "<b>$val</b>",
                        C_PIXBUF, $pixbuf,
             );

        }

}




sub stop_drag_dest {
	my $widget=shift;
	$widget->drag_dest_unset ();
}


sub add_drop_source {
	my ($widget,$target,$name,$param,$self,$limit)=@_;	
	
	#Create a target table to receive drops
	add_drag_dest_set($widget, 'STRING',[],ID_ICONVIEW);

    #make this the drag destination (drop) for various drag sources
    my $r=$self->object_get_attribute("$name","$param");
    my    @array = defined ($r)? @{$r}:();
    
    # check if the maximum number of dropped item is received
	$limit =655350 if(!defined $limit);
	if( scalar @array >= $limit){    
	    stop_drag_dest( $widget);
	}    
    

    #do a callback as soon as drag data is received
    my @params=($target,$name,$param,$self,$limit);
    $widget->signal_connect ('drag-data-received' => \&target_drag_data_received,\@params );
    $widget->signal_connect ('drag-data-get' => sub {
		add_drag_dest_set($widget, 'STRING',[],ID_ICONVIEW);
    });
	
}
