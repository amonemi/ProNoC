use Glib qw/TRUE FALSE/;
#use Gtk2 '-init';
use strict;
use warnings;




use Gtk2::Pango;
#use Tk::Animation;

use String::Similarity;

 
sub find_the_most_similar_position{
	my ($item ,@list)=@_;
	my $most_similar_pos=0;
	my $lastsim=0;
	my $i=0;
	# convert item to lowercase
	$item = lc $item;
	foreach my $p(@list){
		my $similarity= similarity $item, $p;
		if ($similarity > $lastsim){
			$lastsim=$similarity;
			$most_similar_pos=$i;
		}
		$i++;
	}
	return $most_similar_pos;
}

##############
# combo box
#############
sub gen_combo{
	my ($combo_list, $combo_active_pos)= @_;
	my $combo = Gtk2::ComboBox->new_text;
	
	combo_set_names($combo,$combo_list);
	$combo->set_active($combo_active_pos) if(defined $combo_active_pos);
	
	#my $font = Gtk2::Pango::FontDescription->from_string('Tahoma 5');
	#$combo->modify_font($font);

	
	return $combo;	
}


sub combo_set_names {
	my ( $combo, $list_ref ) = @_;
	my @list=@{$list_ref};
	#print "$list[0]\n";
	for my $item (@list){$combo->append_text($item);}
}


sub gen_combo_help {
	my ($help, @combo_list, $pos)= @_;
	my $box = def_hbox(FALSE, 0);
	my $combo= gen_combo(@combo_list, $pos);
	my $button=def_image_button("icons/help.png");
		
	$button->signal_connect("clicked" => sub {message_dialog($help);});
			
	$box->pack_start( $combo, FALSE, FALSE, 3);
	$box->pack_start( $button, FALSE, FALSE, 3);
	$box->show_all;
	
	return ($box,$combo);
}

	
sub def_h_labeled_combo{
		my ($label_name,$combo_list,$combo_active_pos)=@_;
		my $box = def_hbox(TRUE,0);
		my $label= gen_label_in_left($label_name);	
		my $combo= gen_combo($combo_list, $combo_active_pos);
		$box->pack_start( $label, FALSE, FALSE, 3);
		$box->pack_start( $combo, FALSE, TRUE, 3);
		return ($box,$combo);
}	

sub def_h_labeled_combo_scaled{
		my ($label_name,$combo_list,$combo_active_pos,$lable_w,$comb_w)=@_;
		my $table= def_table(1,3,TRUE);
		my $label= gen_label_in_left($label_name);	
		my $combo= gen_combo($combo_list, $combo_active_pos);
		$table->attach_defaults ($label, 0, $lable_w, 0, 1);
		$table->attach_defaults ($combo, 1, $lable_w+$comb_w, 0, 1);

		


		return ($table,$combo);
}	


##############
# spin button
#############
sub gen_spin{
	my ($min,$max,$step)= @_;
	my $spin = Gtk2::SpinButton->new_with_range ($min, $max, $step);
	return $spin;	
}



sub gen_spin_help {
	my ($help, $min,$max,$step)= @_;
	my $box = def_hbox(FALSE, 0);
	my $spin= gen_spin($min,$max,$step);
	my $button=def_image_button("icons/help.png");
		
	$button->signal_connect("clicked" => sub {message_dialog($help);});
			
	$box->pack_start( $spin, FALSE, FALSE, 3);
	$box->pack_start( $button, FALSE, FALSE, 3);
	$box->show_all;
	
	return ($box,$spin);
}


#############
#  entry
#############
sub gen_entry{
	my ($initial) = @_;
	my $entry = Gtk2::Entry->new;
	if(defined $initial){ $entry->set_text($initial)};
	return $entry;
}


sub gen_entry_help{
	my ($help, $init)= @_;
	my $box = def_hbox(FALSE, 0);
	my $entry= gen_entry ($init);
	my $button=def_image_button("icons/help.png");
		
	$button->signal_connect("clicked" => sub {message_dialog($help);});
			
	$box->pack_start( $entry, FALSE, FALSE, 3);
	$box->pack_start( $button, FALSE, FALSE, 3);
	$box->show_all;
	
	return ($box,$entry);
}

sub def_h_labeled_entry{
	my ($label_name,$initial)=@_;
	my $box = def_hbox(TRUE,0);
	my $label= gen_label_in_left($label_name);	
	my $entry =gen_entry($initial);
	$box->pack_start( $label, FALSE, FALSE, 3);
	$box->pack_start( $entry, FALSE, FALSE, 3);
	return ($box,$entry);
	
}

sub def_h_labeled_entry_help{
	my ($help,$label_name,$initial)=@_;
	my $box = def_hbox(TRUE,0);
	my $label= gen_label_in_left($label_name);	
	my ($b,$entry) =gen_entry_help($help,$initial);
	$box->pack_start( $label, FALSE, FALSE, 3);
	$box->pack_start( $b, FALSE, FALSE, 3);
	return ($box,$entry);
	
}			

##############
# ComboBoxEntry
##############

sub gen_combo_entry{
	my ($list_ref,$pos)=@_;
	my @list=@{$list_ref};	

	my $combo_box_entry = Gtk2::ComboBoxEntry->new_text;
	foreach my $p (@list){
		$combo_box_entry->append_text($p);
	}
	$pos=0 if(! defined $pos ); 
	$combo_box_entry->set_active($pos);
	return $combo_box_entry;
}


sub def_h_labeled_combo_entry_help{
	my ($help,$label_name,$list_ref,$initial)=@_;
	my $box = def_hbox(TRUE,0);
	my $label= gen_label_in_left($list_ref);	
	my ($b,$entry) =gen_combo_entry($help,$initial);
	$box->pack_start( $label, FALSE, FALSE, 3);
	$box->pack_start( $b, FALSE, FALSE, 3);
	return ($box,$entry);
	
}		

###########
#
###########

sub def_h_labeled_checkbutton{
	my ($label_name,$status)=@_;
	my $box = def_hbox(TRUE,0);
	my $label= gen_label_in_left($label_name);	
	my $check= Gtk2::CheckButton->new;
	#if($status==1) $check->
	$box->pack_start( $label, FALSE, FALSE, 3);
	$box->pack_start( $check, FALSE, FALSE, 3);
	return ($box,$check);
	
}	




#############
#  label
############

sub gen_label_in_left{
	my ($data)=@_;
	my $label   = Gtk2::Label->new($data);
	$label->set_alignment( 0, 0.5 );
	#my $font = Gtk2::Pango::FontDescription->from_string('Tahoma 5');
	#$label->modify_font($font);
	return $label;
}


sub gen_label_in_center{
	my ($data)=@_;
	my $label   = Gtk2::Label->new($data);
	return $label;
}

sub def_label{
	my @data=@_;
	my $label   = Gtk2::Label->new(@data);
	$label->set_alignment( 0, 0.5 );
	return $label;

}


sub box_label{
	my( $homogeneous, $spacing, $name)=@_;
	my $box=def_hbox($homogeneous, $spacing);
	my $label= def_label($name);	
	$box->pack_start( $label, FALSE, FALSE, 3);
	return $box;
}


sub def_title_box{
	my( $homogeneous, $spacing, @labels)=@_;
	my $box=def_hbox($homogeneous, $spacing);
	foreach my $label (@labels){
		my $labelbox=box_label($homogeneous, $spacing, $label);
		$box->pack_start( $labelbox, FALSE, FALSE, 3);

	}
	return $box;
}	


sub gen_label_help {	
	my ($help, $label_name)= @_;
	my $box = def_hbox(FALSE, 0);
	my $label= gen_label_in_left($label_name);
	my $button=def_image_button("icons/help.png");
		
	$button->signal_connect("clicked" => sub {message_dialog($help);});
			
	$box->pack_start( $label, FALSE, FALSE, 0);
	$box->pack_start( $button, FALSE, FALSE, 0);
	$box->set_spacing (0);
	$box->show_all;
	
	return $box;


}



	
##############
# button
#############


sub button_box{
# create a new button
	my @label=@_;
	my $button = Gtk2::Button->new_from_stock(@label);
	my $box=def_hbox(TRUE,5);
	$box->pack_start($button,   FALSE, FALSE,0);
	
	return ($box,$button);

}
	

sub def_icon{
	my $image_file=shift;
	my $font_size=get_defualt_font_size();
	my $size=($font_size==10)? 25:
		     ($font_size==9 )? 22:
			 ($font_size==8 )? 18:
			 ($font_size==7 )? 15:12 ;
	my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_scale($image_file,$size,$size,FALSE);
 	
 			 
 	my $image = Gtk2::Image->new_from_pixbuf($pixbuf);
	return $image;

}


sub open_image{
	my ($image_file,$x,$y,$unit)=@_;
	if(defined $unit){
		my($width,$hight)=max_win_size();
		if($unit eq 'percent'){
			$x= ($x * $width)/100;
			$y= ($y * $hight)/100;
		} # else its pixels
			
	}
	my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_scale($image_file,$x,$y,TRUE);
 	my $image = Gtk2::Image->new_from_pixbuf($pixbuf);
	return $image;

}



sub def_image_button{
	my ($image_file, $label_text, $homogeneous)=@_;
	# create box for image and label 
	$homogeneous = FALSE if(!defined $homogeneous);
	my $box = def_hbox($homogeneous,0);
	my $image = def_icon($image_file) if(-f $image_file);
		
	
	# now on to the image stuff
	#my $image = Gtk2::Image->new_from_file($image_file);
	$box->pack_start($image, FALSE, FALSE, 0) if(-f $image_file);
	$box->set_border_width(0);
	$box->set_spacing (0);
	# Create a label for the button
	if(defined $label_text ) {
		my $label = Gtk2::Label->new("  $label_text");
		$box->pack_start($label, FALSE, FALSE, 0);
	}
	
	
	my $button = Gtk2::Button->new();
	$button->add($box);
	$button->set_border_width(0);
	$button->show_all;
	return $button;

}


sub def_image_label{
	my ($image_file, $label_text)=@_;
	# create box for image and label 
	my $box = def_hbox(FALSE,1);
	# now on to the image stuff
	my $image = def_icon($image_file);
	$box->pack_start($image, TRUE, FALSE, 0);
	# Create a label for the button
	if(defined $label_text ) {
		my $label = Gtk2::Label->new($label_text);
		$box->pack_start($label, TRUE, FALSE, 0);
	}	
		
	return $box;

}


sub gen_button_message {	
	my ($help, $image_file,$label_name)= @_;
	my $box = def_hbox(FALSE, 0);
	my $label= gen_label_in_center($label_name) if(defined $label_name);
	my $button=def_image_button($image_file);
		
	if(defined $help ){$button->signal_connect("clicked" => sub {message_dialog($help);});}
			
	$box->pack_start( $label, FALSE, FALSE, 0) if(defined $label_name);
	$box->pack_start( $button, FALSE, FALSE, 0);
	$box->set_border_width(0);
	$box->set_spacing (0);
	$box->show_all;
	
	return $box;


}


sub def_colored_button{
	my ($label_text,$color_num)=@_;
	# create box for image and label 
	my $box = def_hbox(FALSE,0);
	my $font_size=get_defualt_font_size();
	my $size=($font_size==10)? 25:
		     ($font_size==9 )? 22:
			 ($font_size==8 )? 18:
			 ($font_size==7 )? 15:12 ;
	$box->set_border_width(0);
	$box->set_spacing (0);
	# Create a label for the button
	if(defined $label_text ) {
		my $label = gen_label_in_center("$label_text");
		$box->pack_start($label, TRUE, TRUE, 0);
	}
	my @clr_code=get_color($color_num);
	my $color = Gtk2::Gdk::Color->new (@clr_code);
	
	my $button = Gtk2::Button->new();
	$button->modify_bg('normal',$color);
	$button->add($box);
	$button->set_border_width(0);
	$button->show_all;
	return $button;

}




sub show_gif{

	my $gif = shift;
	#my $mw=def_popwin_size(400,200,'hey');
	my $vbox = Gtk2::HBox->new (TRUE, 8);
    my $filename;
      eval {
##          $filename = demo_find_file ("floppybuddy.gif");
          $filename = main::demo_find_file ($gif);
      };
     
      
      my $image = Gtk2::Image->new_from_file ($gif);
    
     $vbox->set_border_width (4);
     my   $align = Gtk2::Alignment->new (0.5, 0.5, 0, 0);
     
	my $frame = Gtk2::Frame->new;
	$frame->set_shadow_type ('in');

     
      
 
      # Animation
     $frame->add ($image);
      $align->add ($frame);

     
     
	
     $vbox->pack_start ($align, FALSE, FALSE, 0);
  
      # $mw->add ($vbox);
      

      # Progressive
      
      
      
  
	#$mw->show_all();
  return $vbox;




}

############
#	message_dialog
############

sub message_dialog {
  my ($message,$type)=@_;
  $type = 'info' if (!defined $type);
  my $window;
  my $dialog = Gtk2::MessageDialog->new ($window,
				   [qw/modal destroy-with-parent/],
				   $type,
				   'ok',
				    $message);
  $dialog->run;
  $dialog->destroy;
 
}



sub set_tip{
	my ($widget,$tip)=@_;
	my $tooltips = Gtk2::Tooltips->new;
	$tooltips->set_tip($widget,$tip);
	
	
}


############
# window
###########

sub def_win {
	my @titel=shift;
	my $window = Gtk2::Window->new('toplevel');
	$window->set_title(@titel);
	$window->set_position("center");
	$window->set_default_size(100, 100);
	$window->set_border_width(20);
	$window->signal_connect (delete_event => sub { Gtk2->main_quit });
	return $window;
	
}	


sub def_win_size {
	my $x=shift;
	my $y=shift;
	my @titel=shift;
	my $window = Gtk2::Window->new('toplevel');
	$window->set_title(@titel);
	$window->set_position("center");
	$window->set_default_size($x, $y);
	$window->set_border_width(20);
	$window->signal_connect (delete_event => sub { Gtk2->main_quit });
	return $window;
	
}	


sub def_popwin_size {
	my ($x,$y,$titel,$unit)=@_;
	if(defined $unit){
		my($width,$hight)=max_win_size();
		if($unit eq 'percent'){
			$x= ($x * $width)/100;
			$y= ($y * $hight)/100;
		} # else its pixels
			
	}
	#my $window = Gtk2::Window->new('popup');
	my $window = Gtk2::Window->new('toplevel');
	$window->set_title($titel);
	$window->set_position("center");
	$window->set_default_size($x, $y);
	$window->set_border_width(20);
	$window->signal_connect (delete_event => sub { $window->destroy });
	return $window;
	
}	





sub def_scrolled_window_box{
			
	my $window =  def_popwin_size(@_);
	my $box=def_vbox(TRUE,5);
	my $scrolled_window = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_window->set_policy( "automatic", "automatic" );
	$scrolled_window->add_with_viewport($box);
	$window->add($scrolled_window);
	$window->show_all;
	$box->show_all;
	return ($box,$window);

}

sub max_win_size{
	my $screen =Gtk2::Gdk::Screen->get_default();
	my $hight = $screen->get_height(); 
	my $width = $screen->get_width(); 
	return ($width,$hight);
}


sub get_defualt_font_size{
	my($width,$hight)=max_win_size();
	#print "($width,$hight)\n";
	my $font_size=($width>=1600)? 10:
			      ($width>=1400)? 9:
				  ($width>=1200)? 9:
				  ($width>=1000)? 7:6;
	#print "$font_size\n";	
	return $font_size;
}


sub set_defualt_font_size{
	my $font_size=get_defualt_font_size();
	   
		Gtk2::Rc->parse_string(<<__);
			style "normal" { 
				font_name ="Verdana $font_size" 
			}
			widget "*" style "normal"
__

}

sub gen_scr_win_with_adjst {
	my ($self,$name)=@_;
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);	
	$scrolled_win->set_policy( "automatic", "automatic" );	
	$scrolled_win->signal_connect("destroy"=> sub{
	 	save_scrolled_win_adj($self,$scrolled_win, $name);
	 	
	 });
	 my $adjast=0;
	 $scrolled_win->signal_connect("size-allocate"=> sub{
	 	if($adjast==0){
	 		load_scrolled_win_adj($self,$scrolled_win, $name);
	 		$adjast=1;
	 	}
	 	
	 });	
	return $scrolled_win;
}


sub save_scrolled_win_adj {
	my ($self,$scrolled_win,$name)=@_;  	
	my $ha= $scrolled_win->get_hadjustment();
    my $va =$scrolled_win->get_vadjustment();
    return if(!defined $ha);
    return if(!defined $va);
    save_adj ($self,$ha,$name,"ha"); 
	save_adj ($self,$va,$name,"va"); 
}


sub load_scrolled_win_adj {
	my ($self,$scrolled_win,$name)=@_;  
	my $ha= $scrolled_win->get_hadjustment();
    my $va =$scrolled_win->get_vadjustment();
	my $h=load_adj ($self,$ha,$name,"ha"); 
	my $v=load_adj ($self,$va,$name,"va"); 
	#$ha->set_value($h) if(defined $h);
    #$va->set_value($v) if(defined $v);    
}
  
    
    
    
sub save_adj {
	my ($self,$adjustment,$at1,$at2)=@_;  	
	my $value = $adjustment->value;
	$self->object_add_attribute($at1,$at2,$value);
}


sub load_adj {
	my ($self,$adjustment,$at1,$at2)=@_;
	return if(!defined $at1);
    my $value=  $self->object_get_attribute($at1,$at2);
    return if(!defined $value);
    my $lower =  $adjustment->lower;
    my $upper = $adjustment->upper - $adjustment->page_size;
    $value=  ($value < $lower || $value > $upper ) ? 0 : $value; 
    
    $adjustment->set_value($value);   
}


##############
#	box
#############

sub def_hbox {
	my( $homogeneous, $spacing)=@_;
	my $box = Gtk2::HBox->new($homogeneous, $spacing);
	$box->set_border_width(2);
	return $box;
}

sub def_vbox {
	my $box = Gtk2::VBox->new(FALSE, 0);
	$box->set_border_width(2);
	return $box;
}

sub def_pack_hbox{
	my( $homogeneous, $spacing , @box_list)=@_;
	my $box=def_hbox($homogeneous, $spacing); 
	foreach my $subbox (@box_list){
		$box->pack_start( $subbox, FALSE, FALSE, 3);
	}
	return $box;	


}

sub def_pack_vbox{
	my( $homogeneous, $spacing , @box_list)=@_;
	my $box=def_vbox($homogeneous, $spacing); 
	foreach my $subbox (@box_list){
		$box->pack_start( $subbox, FALSE, FALSE, 3);
	}
	return $box;	

}


##########
# Paned
#########


sub gen_vpaned {
	my ($w1,$loc,$w2) = @_;
	my $vpaned = Gtk2::VPaned -> new;
	my($width,$hight)=max_win_size();

	
	$vpaned -> pack1($w1, TRUE, TRUE); 	
	$vpaned -> set_position ($hight*$loc);	
	$vpaned -> pack2($w2, TRUE, TRUE); 
	
	return $vpaned;
}


sub gen_hpaned {
	my ($w1,$loc,$w2) = @_;
	my $hpaned = Gtk2::HPaned -> new;
	my($width,$hight)=max_win_size();

	
	$hpaned -> pack1($w1, TRUE, TRUE); 	
	$hpaned -> set_position ($width*$loc);	
	$hpaned -> pack2($w2, TRUE, TRUE); 
	
	return $hpaned;
}

#############
# text_view 
############

sub create_text {
  my $scrolled_window = Gtk2::ScrolledWindow->new;
  $scrolled_window->set_policy ('automatic', 'automatic');
  $scrolled_window->set_shadow_type ('in');
  my $tview = Gtk2::TextView->new();
  $scrolled_window->add ($tview);
  $tview->show_all;
  # Make it a bit nicer for text.
  $tview->set_wrap_mode ('word');
  $tview->set_pixels_above_lines (2);
  $tview->set_pixels_below_lines (2);
 # $scrolled_window->set_placement('bottom_left' );
  return ($scrolled_window,$tview);
}


#################
#	table
################

sub def_table{
	my ($row,$col,$homogeneous)=@_;
	my $table = Gtk2::Table->new ($row, $col, $homogeneous);
	$table->set_row_spacings (0);
	$table->set_col_spacings (0);
	return $table;

}

sub attach_widget_to_table {
	my ($table,$row,$label,$inf_bt,$widget,$column)=@_;
	$column = 0 if(!defined $column);
	$column *=4;
	#my $tmp=gen_label_in_left(" "); 
	if(defined $label)  {$table->attach  ($label , $column, $column+1,  $row,$row+1,'fill','shrink',2,2);$column++;}
	if(defined $inf_bt) {$table->attach  ($inf_bt , $column, $column+1, $row,$row+1,'fill','shrink',2,2);$column++;}
	if(defined $widget) {$table->attach  ($widget , $column, $column+1, $row,$row+1,'fill','shrink',2,2);$column++;}
	#$table->attach  ($tmp , $column+3, $column+4, $row,$row+1,'fill','shrink',2,2);
}


#sub attach_widget_to_table2 {
#	my ($table,$row,$label,$inf_bt,$widget)=@_;
	
#	my $tmp=gen_label_in_left(" "); 
#	$table->attach  ($label , 0, 4,  $row,$row+1,'fill','shrink',2,2);
#	$table->attach  ($inf_bt , 4, 5, $row,$row+1,'fill','shrink',2,2);
#	$table->attach  ($widget , 5, 9, $row,$row+1,'fill','shrink',2,2);
#	$table->attach  ($tmp , 9, 10, $row,$row+1,'fill','shrink',2,2);
#}


######
#  state
#####

sub def_state{
	my ($initial)=@_;
	my $entry = Gtk2::Entry->new;
	$entry->set_text($initial);
	my $timeout=0;
	my @state= ($entry,$timeout);
	return \@state

}	





sub set_gui_status{
	my ($object,$status,$timeout)=@_;
	$object->object_add_attribute('gui_status','status',$status);
	$object->object_add_attribute('gui_status','timeout',$timeout);
}	


sub get_gui_status{
	my ($object)=@_;
	my $status= $object->object_get_attribute('gui_status','status');
	my $timeout=$object->object_get_attribute('gui_status','timeout');
	return ($status,$timeout);	
}	



##################
#	show_info
##################
sub show_info{
	my ($textview_ref,$info)=@_;
	my $buffer = $$textview_ref->get_buffer();
  	$buffer->set_text($info);
}

sub add_info{
	my ($textview_ref,$info)=@_;
	my $buffer = $$textview_ref->get_buffer();
	my $textiter = $buffer->get_end_iter();
	#Insert some text into the buffer
	$buffer->insert($textiter,$info);
	
}


sub new_on_textview{
	my ($textview,$info)=@_;
	my $buffer = $textview->get_buffer();
  	$buffer->set_text($info);
}

sub append_to_textview{
	my ($textview,$info)=@_;
	my $buffer = $textview->get_buffer();
	my $textiter = $buffer->get_end_iter();
	#Insert some text into the buffer
	$buffer->insert($textiter,$info);
	
	
}


sub show_colored_info{
	my ($textview_ref,$info,$color)=@_;
	my $buffer = $$textview_ref->get_buffer();
  	#$buffer->set_text($info);
	my $textiter = $buffer->get_start_iter();
	$buffer->insert_with_tags_by_name ($textiter, "$info", "${color}_tag");
}

sub add_colored_info{
	my ($textview_ref,$info,$color)=@_;
	my $buffer = $$textview_ref->get_buffer();
	my $textiter = $buffer->get_end_iter();
	#Insert some text into the buffer
	#$buffer->insert($textiter,$info);
	$buffer->insert_with_tags_by_name ($textiter, "$info", "${color}_tag");
	
}

sub add_colors_to_textview{
	my $tview= shift;
	add_colored_tag($tview,'red');
	add_colored_tag($tview,'blue');
	add_colored_tag($tview,'green');
}


sub add_colored_tag{
	my ($textview_ref,$color)=@_;
	my $buffer = $textview_ref->get_buffer();
  	$buffer->create_tag ("${color}_tag", foreground => $color);  
}

 

####################
#	 file
##################


sub read_verilog_file{
	my @files            = @_;
	my %cmd_line_defines = ();
	my $quiet            = 1;
	my @inc_dirs         = ();
	my @lib_dirs         = ();
	my @lib_exts         = ();
	my $vdb = rvp->read_verilog(\@files,[],\%cmd_line_defines,
			  $quiet,\@inc_dirs,\@lib_dirs,\@lib_exts);

	my @problems = $vdb->get_problems();
	if (@problems) {
	    foreach my $problem ($vdb->get_problems()) {
		print STDERR "$problem.\n";
	    }
	    # die "Warnings parsing files!";
	}

	return $vdb;
}

sub add_color_to_gd{
	foreach (my $i=0;$i<32;$i++ ) {
		my ($red,$green,$blue)=get_color($i);	    
		add_colour("my_color$i"=>[$red>>8,$green>>8,$blue>>8]);
		
	}	
}



sub append_text_to_file {
	my  ($file_path,$text)=@_;
	open(my $fd, ">>$file_path");
	print $fd $text;
	close $fd;
}




sub save_file {
	my  ($file_path,$text)=@_;
	open my $fd, ">$file_path" or die "could not open $file_path: $!";
	print $fd $text;
	close $fd;	
}

sub load_file {
	my $file_path=shift;
	my $str;
	if (-f "$file_path") { 
				
		$str = do {
	    		local $/ = undef;
	    		open my $fh, "<", $file_path
			or die "could not open $file_path: $!";
	    		<$fh>;
		};

	}
	return $str;
}




sub merg_files {
	my  ($source_file_path,$dest_file_path)=@_;
	local $/=undef;
  	open FILE, $source_file_path or die "Couldn't open file: $!";
  	my $string = <FILE>;
  	close FILE;
	 append_text_to_file ($dest_file_path,$string);	
}



sub copy_file_and_folders{
	my ($file_ref,$project_dir,$target_dir)=@_;

	foreach my $f(@{$file_ref}){
		my $name= basename($f);				
		my $n="$project_dir$f";
		if (-f "$n") { #copy file
			copy ("$n","$target_dir"); 		
		}elsif(-f "$f" ){
			copy ("$f","$target_dir");     			 	
		}elsif (-d "$n") {#copy folder
			dircopy ("$n","$target_dir/$name"); 		
		}elsif(-d "$f" ){
			dircopy ("$f","$target_dir/$name"); 		
    			 	
		}
	}

}

sub read_file_cntent {
	my ($f,$project_dir)=@_;
	my $n="$project_dir$f";
	my $str;
	if (-f "$n") { 
				
		$str = do {
	    		local $/ = undef;
	    		open my $fh, "<", $n
			or die "could not open $n: $!";
	    		<$fh>;
		};

	}elsif(-f "$f" ){
		$str = do {
	    		local $/ = undef;
	    		open my $fh, "<", $f
			or die "could not open $f: $!";
	    		<$fh>;
		};
		
						 	
	}
	return $str;

}


sub check_file_has_string {
    my ($file,$string)=@_;
    my $r;
    open(FILE,$file);
    if (grep{/$string/} <FILE>){
       $r= 1; #print "word  found\n";
    }else{
       $r= 0; #print "word not found\n";
    }
    close FILE;
    return $r;
}


###########
#  color
#########





	
sub get_color {
	my $num=shift;
	
	my @colors=(
	0x6495ED,#Cornflower Blue
	0xFAEBD7,#Antiquewhite
	0xC71585,#Violet Red
	0xC0C0C0,#silver
	0xADD8E6,#Lightblue	
	0x6A5ACD,#Slate Blue
	0x00CED1,#Dark Turquoise
	0x008080,#Teal
	0x2E8B57,#SeaGreen
	0xFFB6C1,#Light Pink
	0x008000,#Green
	0xFF0000,#red
	0x808080,#Gray
	0x808000,#Olive
	0xFF69B4,#Hot Pink
	0xFFD700,#Gold
	0xDAA520,#Goldenrod
	0xFFA500,#Orange
	0x32CD32,#LimeGreen
	0x0000FF,#Blue
	0xFF8C00,#DarkOrange
	0xA0522D,#Sienna
	0xFF6347,#Tomato
	0x0000CD,#Medium Blue
	0xFF4500,#OrangeRed
	0xDC143C,#Crimson	
	0x9932CC,#Dark Orchid
	0x800000,#marron
	0x800080,#Purple
	0x4B0082,#Indigo
	0xFFFFFF,#white	
	0x000000 #Black		
		);
	
	my $color= 	($num< scalar (@colors))? $colors[$num]: 0xFFFFFF;	
	my $red= 	($color & 0xFF0000) >> 8;
	my $green=	($color & 0x00FF00);
	my $blue=	($color & 0x0000FF) << 8;
	
	return ($red,$green,$blue);
	
}


sub get_color_hex_string {
	my $num=shift;
	
	my @colors=(
	"6495ED",#Cornflower Blue
	"FAEBD7",#Antiquewhite
	"C71585",#Violet Red
	"C0C0C0",#silver
	"ADD8E6",#Lightblue	
	"6A5ACD",#Slate Blue
	"00CED1",#Dark Turquoise
	"008080",#Teal
	"2E8B57",#SeaGreen
	"FFB6C1",#Light Pink
	"008000",#Green
	"FF0000",#red
	"808080",#Gray
	"808000",#Olive
	"FF69B4",#Hot Pink
	"FFD700",#Gold
	"DAA520",#Goldenrod
	"FFA500",#Orange
	"32CD32",#LimeGreen
	"0000FF",#Blue
	"FF8C00",#DarkOrange
	"A0522D",#Sienna
	"FF6347",#Tomato
	"0000CD",#Medium Blue
	"FF4500",#OrangeRed
	"DC143C",#Crimson	
	"9932CC",#Dark Orchid
	"800000",#marron
	"800080",#Purple
	"4B0082",#Indigo
	"FFFFFF",#white	
	"000000" #Black		
		);
	
	my $color= 	($num< scalar (@colors))? $colors[$num]: "FFFFFF";	
	return $color;
	
}



##############
#  clone_obj
#############

sub clone_obj{
	my ($self,$clone)=@_;
	
	foreach my $p (keys %$self){
		delete ($self->{$p});
	}
	foreach my $p (keys %$clone){
		$self->{$p}= $clone->{$p};
		my $ref= ref ($clone->{$p});
		if( $ref eq 'HASH' ){
			
			foreach my $q (keys %{$clone->{$p}}){
				$self->{$p}{$q}= $clone->{$p}{$q};	
				my $ref= ref ($self->{$p}{$q});
				if( $ref eq 'HASH' ){
				
					foreach my $z (keys %{$clone->{$p}{$q}}){
						$self->{$p}{$q}{$z}= $clone->{$p}{$q}{$z};	
						my $ref= ref ($self->{$p}{$q}{$z});
						if( $ref eq 'HASH' ){
							
							foreach my $w (keys %{$clone->{$p}{$q}{$z}}){
								$self->{$p}{$q}{$z}{$w}= $clone->{$p}{$q}{$z}{$w};	
								my $ref= ref ($self->{$p}{$q}{$z}{$w});
								if( $ref eq 'HASH' ){
									
							
									foreach my $m (keys %{$clone->{$p}{$q}{$z}{$w}}){
										$self->{$p}{$q}{$z}{$w}{$m}= $clone->{$p}{$q}{$z}{$w}{$m};	
										my $ref= ref ($self->{$p}{$q}{$z}{$w}{$m});
										if( $ref eq 'HASH' ){
											
											foreach my $n (keys %{$clone->{$p}{$q}{$z}{$w}{$m}}){
												$self->{$p}{$q}{$z}{$w}{$m}{$n}= $clone->{$p}{$q}{$z}{$w}{$m}{$n};	
												my $ref= ref ($self->{$p}{$q}{$z}{$w}{$m}{$n});	
												if( $ref eq 'HASH' ){
												
													foreach my $l (keys %{$clone->{$p}{$q}{$z}{$w}{$m}{$n}}){
														$self->{$p}{$q}{$z}{$w}{$m}{$n}{$l}= $clone->{$p}{$q}{$z}{$w}{$m}{$n}{$l};	
														my $ref= ref ($self->{$p}{$q}{$z}{$w}{$m}{$n}{$l});	
														if( $ref eq 'HASH' ){
														}
													}
												
												}#if														
											}#n
										}#if
									}#m							
								}#if
							}#w
						}#if
					}#z
				}#if
			}#q
		}#if	
	}#p
}#sub	


############
#	get file folder list
###########

sub get_directory_name {
	my ($object,$title,$entry,$attribute1,$attribute2,$status,$timeout)= @_;
	my $browse= def_image_button("icons/browse.png");

	$browse->signal_connect("clicked"=> sub{
		my $entry_ref=$_[1];
 		my $file;
		$title ='select directory' if(!defined $title);
		my $dialog = Gtk2::FileChooserDialog->new(
		    	$title, undef,
			#       	'open',
			'select-folder',
		    	'gtk-cancel' => 'cancel',
		    	'gtk-ok'     => 'ok',
			);
	       
			
			if ( "ok" eq $dialog->run ) {
		    	$file = $dialog->get_filename;
				$$entry_ref->set_text($file);
				$object->object_add_attribute($attribute1,$attribute2,$file);
				set_gui_status($object,$status,$timeout) if(defined $status);			
				#check_input_file($file,$socgen,$soc_state,$info);
		    		#print "file = $file\n";
	       		 }
	       		$dialog->destroy;
	       		


		} , \$entry);
	
	return $browse;

}

sub remove_project_dir_from_addr{
	my $file=shift;
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/../../"); #mpsoc directory address
	$file =~ s/$project_dir//; 
	return $file;	
}

sub add_project_dir_to_addr{
	my $file=shift;
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/../../"); #mpsoc directory address
	return $file if(-f $file ); 
	return "$project_dir/$file";	
	
}

sub get_file_name {
	my ($object,$title,$entry,$attribute1,$attribute2,$extension,$lable,$open_in)= @_;
	my $browse= def_image_button("icons/browse.png");
	
	$browse->signal_connect("clicked"=> sub{
		my $entry_ref=$_[1];
 		my $file;
		$title ='select directory' if(!defined $title);
		my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);
	 if(defined $extension){
		my $filter = Gtk2::FileFilter->new();
		$filter->set_name($extension);
		$filter->add_pattern("*.$extension");
		$dialog->add_filter ($filter);
	 }
	  if(defined  $open_in){
		$dialog->set_current_folder ($open_in); 
		# print "$open_in\n";
		 
	}
		
			if ( "ok" eq $dialog->run ) {
		    	$file = $dialog->get_filename;
				#remove $project_dir form beginig of each file
            	$file =remove_project_dir_from_addr($file); 
				$$entry_ref->set_text($file);
				$object->object_add_attribute($attribute1,$attribute2,$file) if(defined $object);
				my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
				if(defined $lable){
					$lable->set_markup("<span  foreground= 'black' ><b>$name$suffix</b></span>");
					$lable->show;
				}
						
				#check_input_file($file,$socgen,$soc_state,$info);
		    		#print "file = $file\n";
	       		 }
	       		$dialog->destroy;
	       		


		} , \$entry);
	
	return $browse;

}


#################
#	widget update object
#################

sub gen_entry_object {
	my ($object,$attribute1,$attribute2,$default,$status,$timeout)=@_;
	my $old=$object->object_get_attribute($attribute1,$attribute2);
	my $widget;
	if(defined $old ){
		$widget=gen_entry($old);
	}
	else
	{
		$widget=gen_entry($default);
		$object->object_add_attribute($attribute1,$attribute2,$default);		
	}	
	$widget-> signal_connect("changed" => sub{
		my $new_param_value=$widget->get_text();
		$object->object_add_attribute($attribute1,$attribute2,$new_param_value);
		set_gui_status($object,$status,$timeout) if (defined $status);
	});
	return $widget;
}


sub gen_combobox_object {
 	my ($object,$attribute1,$attribute2,$content,$default,$status,$timeout)=@_;
	my @combo_list=split(",",$content);
	my $value=$object->object_get_attribute($attribute1,$attribute2);
	my $pos;
	$pos=get_pos($value, @combo_list) if (defined $value);
	if(!defined $pos && defined $default){
		$object->object_add_attribute($attribute1,$attribute2,$default);	
	 	$pos=get_item_pos($default, @combo_list);
	}
	#print " my $pos=get_item_pos($value, @combo_list);\n";
	my $widget=gen_combo(\@combo_list, $pos);
	$widget-> signal_connect("changed" => sub{
		my $new_param_value=$widget->get_active_text();
		$object->object_add_attribute($attribute1,$attribute2,$new_param_value);
		set_gui_status($object,$status,$timeout) if (defined $status);
	 });
	return $widget;		 
	

}


sub gen_comboentry_object {
 	my ($object,$attribute1,$attribute2,$content,$default,$status,$timeout)=@_;
	my @combo_list=split(",",$content);
	my $value=$object->object_get_attribute($attribute1,$attribute2);
	my $pos;
	$pos=get_pos($value, @combo_list) if (defined $value);
	if(!defined $pos && defined $default){
		$object->object_add_attribute($attribute1,$attribute2,$default);	
	 	$pos=get_item_pos($default, @combo_list);
	}
	#print " my $pos=get_item_pos($value, @combo_list);\n";
	my $widget=gen_combo_entry(\@combo_list, $pos);
	($widget->child)->signal_connect('changed' => sub {
		my ($entry) = @_;
		my $new_param_value=$entry->get_text();
		$object->object_add_attribute($attribute1,$attribute2,$new_param_value);
		set_gui_status($object,$status,$timeout) if (defined $status);
	 });
	return $widget;	

}



sub gen_spin_object {
	my ($object,$attribute1,$attribute2,$content, $default,$status,$timeout)=@_;
	my $value=$object->object_get_attribute($attribute1,$attribute2);
	my ($min,$max,$step)=split(",",$content);
	if(!defined $value){
		$value=$default;
		$object->object_add_attribute($attribute1,$attribute2,$value);
	}
	
	$value=~ s/[^0-9.]//g;
	$min=~   s/[^0-9.]//g;
	$max=~   s/[^0-9.]//g;
	$step=~  s/[^0-9.]//g;
	
	
	my $widget=gen_spin($min,$max,$step);
	$widget->set_value($value);
	$widget-> signal_connect("value_changed" => sub{
		my $new_param_value=$widget->get_value();
		$object->object_add_attribute($attribute1,$attribute2,$new_param_value);
		set_gui_status($object,$status,$timeout) if (defined $status);
	});
	return $widget;		
}


sub gen_check_box_object_array {
		my ($object,$attribute1,$attribute2,$content,$default,$status,$timeout)=@_;
    		my $value=$object->object_get_attribute($attribute1,$attribute2);
		$value = $default if (!defined $value);
		my $widget = def_hbox(FALSE,0);
		my @check;
		for (my $i=0;$i<$content;$i++){
			$check[$i]= Gtk2::CheckButton->new;
		}
		for (my $i=0;$i<$content;$i++){
			$widget->pack_end(  $check[$i], FALSE, FALSE, 0);
			
			my @chars = split("",$value);
			#check if saved value match the size of check box
			if($chars[0] ne $content ) {
				$object->object_add_attribute($attribute1,$attribute2,$default);
				$value=$default;
				@chars = split("",$value);
			}
			#set initial value
			
			#print "\@chars=@chars\n";
			for (my $i=0;$i<$content;$i++){
				my $loc= (scalar @chars) -($i+1);
					if( $chars[$loc] eq '1') {$check[$i]->set_active(TRUE);}
					else {$check[$i]->set_active(FALSE);}
			}


			#get new value
			$check[$i]-> signal_connect("toggled" => sub{
				my $new_val="$content\'b";			
 				
				for (my $i=$content-1; $i >= 0; $i--){
					if($check[$i]->get_active()) {$new_val="${new_val}1" ;}
					else {$new_val="${new_val}0" ;}
				}
				$object->object_add_attribute($attribute1,$attribute2,$new_val);
				#print "\$new_val=$new_val\n";
				set_gui_status($object,$status,$timeout) if (defined $status);
			});
	}
	return $widget;

}





sub gen_check_box_object {
		my ($object,$attribute1,$attribute2,$default,$status,$timeout)=@_;
    		my $value=$object->object_get_attribute($attribute1,$attribute2);
		if (!defined $value){
			#set initial value
			$object->object_add_attribute($attribute1,$attribute2,$default);
			$value = $default 
		}
		my $widget = Gtk2::CheckButton->new;
		if($value == 1) {$widget->set_active(TRUE);}
		else {$widget->set_active(FALSE);}
		
		#get new value
		$widget-> signal_connect("toggled" => sub{
			my $new_val;
			if($widget->get_active()) {$new_val=1;}
			else {$new_val=0;}
			$object->object_add_attribute($attribute1,$attribute2,$new_val);
			#print "\$new_val=$new_val\n";
			set_gui_status($object,$status,$timeout) if (defined $status);
		});
	
	return $widget;

}






sub get_dir_in_object {
	my ($object,$attribute1,$attribute2,$content,$status,$timeout,$default)=@_;
	my $widget = def_hbox(FALSE,0);
	my $value=$object->object_get_attribute($attribute1,$attribute2);
	$object->object_add_attribute($attribute1,$attribute2,  $default) if (!defined $value );
	$value = $default if (!defined $value );
	my $entry=gen_entry($value);
	$entry-> signal_connect("changed" => sub{
		my $new_param_value=$entry->get_text();
		$object->object_add_attribute($attribute1,$attribute2,$new_param_value);
		set_gui_status($object,$status,$timeout) if (defined $status);
	});
	my $browse= get_directory_name($object,undef,$entry,$attribute1,$attribute2,$status,$timeout);
	$widget->pack_start( $entry, FALSE, FALSE, 0);
	$widget->pack_start( $browse, FALSE, FALSE, 0);
	return $widget;
}




sub get_file_name_object {
	my ($object,$attribute1,$attribute2,$extension,$open_in)=@_;
	my $widget = def_hbox(FALSE,0);
	my $value=$object->object_get_attribute($attribute1,$attribute2);
	my $lable;
	if(defined $value){
		my ($name,$path,$suffix) = fileparse("$value",qr"\..[^.]*$");
		$lable=gen_label_in_center($name.$suffix);
		
	} else {
			$lable=gen_label_in_center("Selecet a file");
			$lable->set_markup("<span  foreground= 'red' ><b>No file has been selected yet</b></span>");
	}
	my $entry=gen_entry();
	my $browse= get_file_name($object,undef,$entry,$attribute1,$attribute2,$extension,$lable,$open_in);
	$widget->pack_start( $lable, FALSE, FALSE, 0);
	$widget->pack_start( $browse, FALSE, FALSE, 0);
	return $widget;
}











sub add_param_widget {
	 my ($mpsoc,$name,$param, $default,$type,$content,$info, $table,$row,$column,$show,$attribut1,$ref_delay,$new_status,$loc)=@_;
	 my $label;
	 $label =gen_label_in_left(" $name") if(defined $name);
	 my $widget;
	 my $value=$mpsoc->object_get_attribute($attribut1,$param);
	 if(! defined $value) {
			$mpsoc->object_add_attribute($attribut1,$param,$default);
			$mpsoc->object_add_attribute_order($attribut1,$param);
			$value=$default;
	 }
	 if(! defined $new_status){
		$new_status='ref';
	 }
	 if ($type eq "Entry"){
		$widget=gen_entry($value);
		$widget-> signal_connect("changed" => sub{
			my $new_param_value=$widget->get_text();
			$mpsoc->object_add_attribute($attribut1,$param,$new_param_value);
			set_gui_status($mpsoc,$new_status,$ref_delay) if(defined $ref_delay);
			

		});
		
		
	 }
	 elsif ($type eq "Combo-box"){
		 my @combo_list=split(",",$content);
		 my $pos=get_pos($value, @combo_list) if(defined $value);
		 if(!defined $pos){
		 	$mpsoc->object_add_attribute($attribut1,$param,$default);	
		 	$pos=get_item_pos($default, @combo_list) if (defined $default);
		 		 	
		 }
		#print " my $pos=get_item_pos($value, @combo_list);\n";
		 $widget=gen_combo(\@combo_list, $pos);
		 $widget-> signal_connect("changed" => sub{
		 my $new_param_value=$widget->get_active_text();
		 $mpsoc->object_add_attribute($attribut1,$param,$new_param_value);
		 set_gui_status($mpsoc,$new_status,$ref_delay) if(defined $ref_delay);


		 });
		 
	 }
	 elsif 	($type eq "Spin-button"){ 
		  my ($min,$max,$step)=split(",",$content);
		  $value=~ s/\D//g;
		  $min=~ s/\D//g;
		  $max=~ s/\D//g;
		  $step=~ s/\D//g;
		  $widget=gen_spin($min,$max,$step);
		  $widget->set_value($value);
		  $widget-> signal_connect("value_changed" => sub{
		  my $new_param_value=$widget->get_value_as_int();
		  $mpsoc->object_add_attribute($attribut1,$param,$new_param_value);
		  set_gui_status($mpsoc,$new_status,$ref_delay) if(defined $ref_delay);

		  });
		 
		 # $box=def_label_spin_help_box ($param,$info, $value,$min,$max,$step, 2);
	 }
	
	elsif ( $type eq "Check-box"){
		$widget = def_hbox(FALSE,0);
		my @check;
		for (my $i=0;$i<$content;$i++){
			$check[$i]= Gtk2::CheckButton->new;
		}
		for (my $i=0;$i<$content;$i++){
			$widget->pack_end(  $check[$i], FALSE, FALSE, 0);
			
			my @chars = split("",$value);
			#check if saved value match the size of check box
			if($chars[0] ne $content ) {
				$mpsoc->object_add_attribute($attribut1,$param,$default);
				$value=$default;
				@chars = split("",$value);
			}
			#set initial value
			
			#print "\@chars=@chars\n";
			for (my $i=0;$i<$content;$i++){
				my $loc= (scalar @chars) -($i+1);
					if( $chars[$loc] eq '1') {$check[$i]->set_active(TRUE);}
					else {$check[$i]->set_active(FALSE);}
			}


			#get new value
			$check[$i]-> signal_connect("toggled" => sub{
				my $new_val="$content\'b";			
 				
				for (my $i=$content-1; $i >= 0; $i--){
					if($check[$i]->get_active()) {$new_val="${new_val}1" ;}
					else {$new_val="${new_val}0" ;}
				}
				$mpsoc->object_add_attribute($attribut1,$param,$new_val);
				#print "\$new_val=$new_val\n";
				set_gui_status($mpsoc,$new_status,$ref_delay) if(defined $ref_delay);
			});
		}




	}
	elsif ( $type eq "DIR_path"){
			$widget =get_dir_in_object ($mpsoc,$attribut1,$param,$value,'ref',10);
			set_gui_status($mpsoc,$new_status,$ref_delay) if(defined $ref_delay);
	}	
	elsif ( $type eq "FILE_path"){ # use $content as extention
			$widget =get_file_name_object ($mpsoc,$attribut1,$param,$content,undef);
			set_gui_status($mpsoc,$new_status,$ref_delay) if(defined $ref_delay);
	}	
	
	else {
		 $widget =gen_label_in_left("unsuported widget type!");
	}

	my $inf_bt= (defined $info)? gen_button_message ($info,"icons/help.png"):gen_label_in_left(" ");
	if($show==1){
		attach_widget_to_table ($table,$row,$label,$inf_bt,$widget,$column);
		if ($loc eq "vertical"){
			#print "$loc\n";
			 $row ++;}
		else {
			$column+=4;
		}	 
	}
    return ($row,$column);
}




################
# ADD info and label to widget
################


sub labele_widget_info{
	my ($label_name,$widget,$info)=@_;
	my $box = def_hbox(FALSE,0);
	#label
	if(defined $label_name){
		my $label= gen_label_in_left($label_name);	
		$box->pack_start( $label, FALSE, FALSE, 3);
	}
	$box->pack_start( $widget, FALSE, FALSE, 3);
	#info	
	if(defined $info){
		my $button=def_image_button("icons/help.png");
		$button->signal_connect("clicked" => sub {message_dialog($info);});	
		$box->pack_start( $button, FALSE, FALSE, 3);
	}
	$box->show_all;	
	return $box;
}	




################
#	general
#################




sub  trim { my $s = shift;  $s=~s/[\n]//gs; return $s };

sub remove_all_white_spaces($)
{
  my $string = shift;
  $string =~ s/\s+//g;
  return $string;
}




sub get_scolar_pos{
	my ($item,@list)=@_;
	my $pos;
	my $i=0;
	foreach my $c (@list)
	{
		if(  $c eq $item) {$pos=$i}
		$i++;
	}	
	return $pos;	
}	

sub remove_scolar_from_array{
	my ($array_ref,$item)=@_;
	my @array=@{$array_ref};
	my @new;
	foreach my $p (@array){
		if($p ne $item ){
			push(@new,$p);
		}		
	}
	return @new;	
}

sub replace_in_array{
	my ($array_ref,$item1,$item2)=@_;
	my @array=@{$array_ref};
	my @new;
	foreach my $p (@array){
		if($p eq $item1 ){
			push(@new,$item2);
		}else{
			push(@new,$p);
		}		
	}
	return @new;	
}



# return an array of common elemnts between two input arays 
sub get_common_array{
	my ($a_ref,$b_ref)=@_;
	my @A=@{$a_ref};
	my @B=@{$b_ref};
	my @C;
	foreach my $p (@A){
		if( grep (/^\Q$p\E$/,@B)){push(@C,$p)};
	}
	return  @C;	
}

#a-b
sub get_diff_array{
	my ($a_ref,$b_ref)=@_;
	my @A=@{$a_ref};
	my @B=@{$b_ref};
	my @C;
	foreach my $p (@A){
		if( !grep  (/^\Q$p\E$/,@B)){push(@C,$p)};
	}
	return  @C;	
	
}



sub compress_nums{
	my 	@nums=@_;
	my @f=sort { $a <=> $b } @nums;
	my $s;
	my $ls;	
	my $range=0;
	my $x;	
	

	foreach my $p (@f){
		if(!defined $x) {
			$s="$p";
			$ls=$p;		
			
		}
		else{ 
			if($p-$x>1){ #gap exist
				if( $range){
					$s=($x-$ls>1 )? "$s:$x,$p": "$s,$x,$p";
					$ls=$p;
					$range=0;
				}else{
				$s= "$s,$p";
				$ls=$p;

				}
			
			}else {$range=1;}


		
		}
	
		$x=$p
	}
 	if($range==1){ $s= ($x-$ls>1 )? "$s:$x":  "$s,$x";}
	#update $s($ls,$hs);

	return $s;
	
}



sub metric_conversion{
	my $size=shift;	
	my $size_text=	$size==0	 ? 'Error': 
			$size<(1 << 10)? $size:
			$size<(1 << 20)? join (' ', ($size>>10,"K")) :
			$size<(1 << 30)? join (' ', ($size>>20,"M")) :
					 join (' ', ($size>>30,"G")) ;
return $size_text;
}



sub check_verilog_identifier_syntax {
	my $in=shift;
	my $error=0;
	my $message='';
# an Identifiers must begin with an alphabetic character or the underscore character
	if ($in =~ /^[0-9\$]/){
		return 'an Identifier must begin with an alphabetic character or the underscore character';
	}
	

#	Identifiers may contain alphabetic characters, numeric characters, the underscore, and the dollar sign (a-z A-Z 0-9 _ $ )
	if ($in =~ /[^a-zA-Z0-9_\$]+/){
		 print "use of illegal character after\n" ;
		 my @w= split /([^a-zA-Z0-9_\$]+)/, $in; 
		 return "Contain illegal character of \"$w[1]\". Identifiers may contain alphabetic characters, numeric characters, the underscore, and the dollar sign (a-z A-Z 0-9 _ \$ )\n";
		
	}


# check Verilog reserved words
	my @keys =			("always","and","assign","automatic","begin","buf","bufif0","bufif1","case","casex","casez","cell","cmos","config","deassign","default","defparam","design","disable","edge","else","end","endcase","endconfig","endfunction","endgenerate","endmodule","endprimitive","endspecify","endtable","endtask","event","for","force","forever","fork","function","generate","genvar","highz0","highz1","if","ifnone","incdir","include","initial","inout","input","instance","integer","join","large","liblist","library","localparam","macromodule","medium","module","nand","negedge","nmos","nor","noshowcancelled","not","notif0","notif1","or","output","parameter","pmos","posedge","primitive","pull0","pull1","pulldown","pullup","pulsestyle_onevent","pulsestyle_ondetect","remos","real","realtime","reg","release","repeat","rnmos","rpmos","rtran","rtranif0","rtranif1","scalared","showcancelled","signed","small","specify","specparam","strong0","strong1","supply0","supply1","table","task","time","tran","tranif0","tranif1","tri","tri0","tri1","triand","trior","trireg","unsigned","use","vectored","wait","wand","weak0","weak1","while","wire","wor","xnor","xor");
	if( grep (/^$in$/,@keys)){
		return  "$in is a Verlig reserved word.";
	}
	return undef;
	
}


sub capture_number_after {
	my ($after,$text)=@_;
	my @q =split  (/$after/,$text);
	#my $d=$q[1];
	my @d = split (/[^0-9. ]/,$q[1]);
	return $d[0]; 

}

sub capture_string_between {
	my ($start,$text,$end)=@_;
	my @q =split  (/$start/,$text);
	my @d = split (/$end/,$q[1]);
	return $d[0];
}


1
