use constant::boolean;
use Gtk3;
use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use Data::Dumper;
use Gtk3::SourceView;
use Consts;

require "common.pl"; 


use IO::CaptureOutput qw(capture qxx qxy);

#use ColorButton;
use HexSpin3;

#use Tk::Animation;

our %glob_setting;

##############
# combo box
#############
sub gen_combo{
	my ($combo_list, $combo_active_pos)= @_;
	my $combo = Gtk3::ComboBoxText->new();
	
	combo_set_names($combo,$combo_list);
	$combo->set_active($combo_active_pos) if(defined $combo_active_pos);
	
	#my $font = Gtk3::Pango::FontDescription->from_string('Tahoma 5');
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
		my ($label_name,$combo_list,$combo_active_pos,$label_w,$comb_w)=@_;
		my $table= def_table(1,3,TRUE);
		my $label= gen_label_in_left($label_name);	
		my $combo= gen_combo($combo_list, $combo_active_pos);
		$table->attach_defaults ($label, 0, $label_w, 0, 1);
		$table->attach_defaults ($combo, 1, $label_w+$comb_w, 0, 1);
		return ($table,$combo);
}	


sub gen_combo_model{
	my $ref=shift;
	my %inputs=%{$ref};
	my $store = Gtk3::TreeStore->new('Glib::String');
  	 for my $i (sort { $a cmp $b} keys %inputs ) {
    	 	my $iter = $store->append(undef);
		
    	 	$store->set($iter, 0, $i);
    		for my $capital (sort { $a cmp $b} keys %{$inputs{$i}}) {
      			my $iter2 = $store->append($iter);
       			$store->set($iter2, 0, $capital);
    		}
 	}
	return $store;

}

sub gen_tree_combo{
	my $model=shift;
	my $combo = Gtk3::ComboBox->new_with_model($model);
   	my $renderer = Gtk3::CellRendererText->new();
    	$combo->pack_start($renderer, TRUE);
    	$combo->set_attributes($renderer, "text", 0);
    	$combo->set_cell_data_func($renderer, \&is_capital_sensitive);
	return $combo;

}


sub TreePath_new_from_indices {
	 my @indices =@_;
	 my $path = Gtk3::TreePath->new_from_indices(@indices);
	 return $path;

}


##############
# spin button
#############
sub gen_spin{
	my ($min,$max,$step,$digit)= @_;
	
	return Gtk3::SpinButton->new_with_range ($min, $max, $step);
	 if(!defined $digit){
		my $d1 = get_float_precision($min);
		my $d2 = get_float_precision($max);
		my $d3 = get_float_precision($step);
		$digit = ($d1 >$d2)? $d1 : $d2;
		$digit = $d3 if($d3>$digit);				
	}
	print "($min,$max,$step,$digit)\n";	
	return Gtk3::SpinButton->new_with_range ($min, $max, $step) if($digit ==0);
    return gen_spin_float($min,$max,$step,$digit);	
}

sub get_float_precision{
	my $num=shift; 
	my $digit = length(($num =~ /\.(.*)/)[0]);
	$digit=0 if(!defined $digit);
	return $digit;
}

sub gen_spin_float{
	my ($min,$max,$step,$digit)= @_;
	#$page_inc = ($max - $min)/ 
	my $adj = Gtk3::Adjustment->new (0, $min, $max, $step,3.1, 0);	
	my $spinner = Gtk3::SpinButton->new ($adj, 1.0,$digit);
	return $spinner; 
}


sub gen_spin_help {
	my ($help, $min,$max,$step,$digit)= @_;
	my $box = def_hbox(FALSE, 0);
	my $spin= gen_spin($min,$max,$step,$digit);
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
	my $entry = Gtk3::Entry->new;
	if(defined $initial){ $entry->set_text($initial)};
	return $entry;
}


sub gen_entry_new_with_max_length{
	my ($n,$initial) = @_;
	my $entry = Gtk3::Entry->new ();
	$entry->set_max_length($n);
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

	#my $combo_box_entry = Gtk3::ComboBoxEntry->new_text;

    my $lstore =
    Gtk3::ListStore->new('Glib::String');

    foreach my $p (@list){
        my $iter = $lstore->append();
        $lstore->set( $iter,  0, $p );
    }
    


	$pos=0 if(! defined $pos || scalar @list < $pos ); 
	my $combo_box_entry = Gtk3::ComboBox->new_with_model_and_entry($lstore);
	$combo_box_entry->set_entry_text_column(0);
	$combo_box_entry->set_active($pos);

	return $combo_box_entry;
	
}

sub combo_entry_get_chiled{
	my $combentry =shift;
    return 	Gtk3::Bin::get_child($combentry);
}




sub update_combo_entry_content {
	my ($self,$content,$pos)=@_;
	my @combo_list=split(/\s*,\s*/,$content) if(defined $content);
	foreach my $p (@combo_list){
		$self->append_text($p);
	}
	$pos=0 if(! defined $pos ); 
	$self->set_active($pos);	
}

###########
# checkbutton
###########

sub def_h_labeled_checkbutton{
	my ($label_name)=@_;
	my $box = def_hbox(TRUE,0);
	my $label= gen_label_in_left($label_name) if (defined $label_name);	
	my $check= Gtk3::CheckButton->new;
	#if($status==1) $check->
	$box->pack_start( $label, FALSE, FALSE, 3) if (defined $label_name);	
	$box->pack_start( $check, FALSE, FALSE, 3);
	return ($box,$check);
	
}	

sub gen_checkbutton{
	my $label=shift;
	return Gtk3::CheckButton->new_with_label($label) if (defined $label);
	return Gtk3::CheckButton->new;
}


#############
#  label
############

sub gen_label_in_left{
	my ($data)=@_;
	my $label   = Gtk3::Label->new($data);
	$label->set_alignment( 0, 0.5 );
	#my $font = Gtk3::Pango::FontDescription->from_string('Tahoma 5');
	#$label->modify_font($font);
	return $label;
}


sub gen_label_in_center{
	my ($data)=@_;
	my $label   = Gtk3::Label->new($data);
	return $label;
}

sub def_label{
	my @data=@_;
	my $label   = Gtk3::Label->new(@data);
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

sub gen_label_with_mnemonic {
	my $name=shift;
	Gtk3::Label->new_with_mnemonic($name);

}
	
##############
# button
#############

sub button_box{
# create a new button
	my $label=@_;
	my $button = Gtk3::Button->new_from_stock($label);
	my $box=def_hbox(TRUE,5);
	$box->pack_start($button,   FALSE, FALSE,0);
	
	return ($box,$button);

}
	

sub get_icon_pixbuff{
    my $icon_file=shift;
    my $size;
    if ($glob_setting{'ICON_SIZE'} eq 'default'){
   		my $font_size=get_defualt_font_size();
		$size=($font_size *2.5);
    }else{
    	$size = int ($glob_setting{'ICON_SIZE'});
    }
	my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file_at_scale($icon_file,$size,$size,FALSE);
	return $pixbuf;
}


sub def_icon{
	my $icon_file=shift;
	return Gtk3::Image->new_from_pixbuf(get_icon_pixbuff($icon_file));
}

sub call_gtk_drag_finish{
	Gtk3::drag_finish(@_);
}



sub add_drag_dest_set{
	my ($widget,$a,$b,$c) = @_;
	$widget->drag_dest_set(['all'],[def_gtk_target_entry($a,$b,$c)], ['copy']);
}

sub def_gtk_target_entry{
	return Gtk3::TargetEntry->new(@_);
}


sub add_drag_source {
	my ($widget,$a,$b,$c) = @_;
	$widget->drag_source_set (
                                ['button1_mask', 'button3_mask'],
								[def_gtk_target_entry($a,$b,$c)],
                                ['copy']
                        );
}

sub drag_set_icon_pixbuf {
	my ($icon_view,$icon_pixbuf)=@_;	
	#$icon_view->drag_source_set_icon_pixbuf ($icon_pixbuf);
}

sub gen_iconview {
	my ($tree_model,$marc_col,$pix_con)=@_;
	my $icon_view = Gtk3::IconView->new_with_model($tree_model);
    $icon_view->set_markup_column($marc_col);
    $icon_view->set_pixbuf_column($pix_con);
	return $icon_view;
}


sub add_frame_to_image{
	my $image=shift;
	my $align = Gtk3::Alignment->new (0.5, 0.5, 0, 0);
   	my $frame = Gtk3::Frame->new;
	$frame->set_shadow_type ('in');
	# Animation
	$frame->add ($image);
	$align->add ($frame);
	return $align;
}

sub gen_frame {
	return  Gtk3::Frame->new;
}



sub new_image_from_file{
	return  Gtk3::Image->new_from_file (@_);
}


sub gen_pixbuf{
	my $file=shift;
	return Gtk3::Gdk::Pixbuf->new_from_file($file);	
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
	$image_file ="icons/blank.png"  unless(-f $image_file);
	my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file_at_scale($image_file,$x,$y,TRUE);
 	my $image = Gtk3::Image->new_from_pixbuf($pixbuf);
	return $image;
}

sub open_inline_image{
	my ($image_string,$x,$y,$unit)=@_;
	if(defined $unit){
		my($width,$hight)=max_win_size();
		if($unit eq 'percent'){
			$x= ($x * $width)/100;
			$y= ($y * $hight)/100;
		} # else its pixels
			
	}
	my $pixbuf = do {
        my $loader = Gtk3::Gdk::PixbufLoader->new();
        $loader->set_size(  $x,$y ) if (defined $y);
        $loader->write( [unpack 'C*', $image_string] );        
        $loader->close();
        $loader->get_pixbuf();
    };
	

 	my $image = Gtk3::Image->new_from_pixbuf($pixbuf);
 	 
	return $image;
}

sub find_icon{
	my $file =shift;
	return $file if(-f $file); #called from perl_gui
	return "../../$file"; #called from lib/perl 		
}

sub def_image_button{
	my ($image_file, $label_text, $homogeneous, $mnemonic)=@_;
	# create box for image and label 
	$homogeneous = FALSE if(!defined $homogeneous);
	my $box = def_hbox($homogeneous,0);
	my $image; 
	$image_file = find_icon( $image_file);
	$image = def_icon($image_file) if(-f $image_file); 
	
	# now on to the image stuff
	#my $image = Gtk3::Image->new_from_file($image_file);
	$box->pack_start($image, FALSE, FALSE, 0) if(defined  $image);
	$box->set_border_width(0);
	$box->set_spacing (0);
	# Create a label for the button
	if(defined $label_text ) {
		my $label;
		$label = Gtk3::Label->new("  $label_text") unless (defined $mnemonic);
		$label = Gtk3::Label->new_with_mnemonic (" $label_text") if (defined $mnemonic);
		$box->pack_start($label, FALSE, FALSE, 0);
	}	
	
	my $button = Gtk3::Button->new();
	$button->add($box);
	$button->set_border_width(0);
	$button->show_all;
	return $button;
}

sub def_button{
	my ($label_text)=@_;
	my $label = Gtk3::Label->new("$label_text") if(defined $label_text);
	my $button= Gtk3::Button->new();
	$button->add($label) if(defined $label_text);
	return $button;
}	


sub def_image_label{
	my ($image_file, $label_text,$mnemonic)=@_;
	# create box for image and label 
	my $box = def_hbox(FALSE,1);
	# now on to the image stuff
	my $image = def_icon($image_file);
	$box->pack_start($image, TRUE, FALSE, 0);
	# Create a label for the button
	if(defined $label_text ) {
		my $label; 
		$label = Gtk3::Label->new("  $label_text") unless (defined $mnemonic);
		$label = Gtk3::Label->new_with_mnemonic (" $label_text") if (defined $mnemonic);
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
	
	
	my $button= Gtk3::Button->new();
	my $label = gen_label_in_center($label_text) if(defined $label_text);
		

	# do custom css #####################################################
	my $css_provider = Gtk3::CssProvider->new;

	my ($red,$green,$blue) = get_color($color_num);
	my $r =int ($red*100/65535);
	my $g =int ($green*100/65535);
	my $b =int ($blue*100/65535);

	
	#select lable color based on backgorund 
	my $lc = (($r*0.299 + $g*0.587 + $b*0.114) > 50)? 0 : 1; # use #000000 else use #ffffff
	
	$label->set_markup("<span  foreground= 'white' >$label_text</span>")  if(defined $label_text && $lc==1);	
	
	

	$css_provider->load_from_data ([map ord, split //, "
	
button {
	background-image: none; 
	background-color: rgba($r%,$g%,$b%,100);
}"
]);

	
	my $style_context = $button->get_style_context;
	$style_context->add_provider ( $css_provider, Gtk3::STYLE_PROVIDER_PRIORITY_USER);

	$button->add($label)  if(defined $label_text);
	
	$button->show_all;
	return $button;
}





sub entry_set_text_color {
	my ($entry,$color_num)=@_;
	my $color_hex = get_color_hex_string($color_num);
	
	my $css_provider = Gtk3::CssProvider->new;
	$css_provider->load_from_data ([map ord, split //, "
entry {
  color: #$color_hex;
}"
	]);

	my $style_context = $entry->get_style_context;
	$style_context->add_provider ( $css_provider, Gtk3::STYLE_PROVIDER_PRIORITY_USER);
	
}








sub show_gif{
	my $gif = shift;
	$gif=find_icon( $gif);
	my $vbox = Gtk3::HBox->new (TRUE, 8);
    my $filename;
      eval {
          $filename = main::demo_find_file ($gif);
      };
    my $image = Gtk3::Image->new_from_file ($gif);
    $vbox->set_border_width (4);
    my   $align = Gtk3::Alignment->new (0.5, 0.5, 0, 0);
	my $frame = Gtk3::Frame->new;
	$frame->set_shadow_type ('in');
    # Animation
    $frame->add ($image);
    $align->add ($frame);
	$vbox->pack_start ($align, FALSE, FALSE, 0);
  	return $vbox;
}

sub gen_radiobutton {
	my ($from,$label,$icon,$tip) =@_;
	my $rbtn = (defined $from )? Gtk3::RadioToolButton->new_from_widget($from) : Gtk3::RadioToolButton->new (undef);
	$rbtn->set_label ($label) if(defined $label);
	$rbtn->set_icon_widget (def_icon($icon)) if(defined $icon);
	set_tip($rbtn, $tip) if(defined $tip);
	return $rbtn;
}

sub gen_colored_label{
	my ($label_text, $color_num)=@_;

	my $color_hex = get_color_hex_string($color_num);
    my $label   = Gtk3::Label->new($label_text);
	$label->set_markup("<span 
 background= '#$color_hex'
 foreground= 'black' ><b>$label_text</b></span>");
	
	return $label;
}


############
#	message_dialog
############

sub message_dialog {
  my ($message,$type)=@_;
  $type = 'info' if (!defined $type);
  my $window;
  my $dialog = Gtk3::MessageDialog->new ($window,
				   [qw( modal destroy-with-parent )],
				   $type,
				   'ok',
				    $message);
  
  $dialog->set_transient_for (Gtk3::Window->new('toplevel'));#just to get rid of transient warning
  $dialog->run;
  $dialog->destroy;
 
}



sub set_tip{
	my ($widget,$tip)=@_;
	#my $tooltips = Gtk3::Tooltips->new;
	#$tooltips->set_tip($widget,$tip);
	$widget->set_tooltip_text($tip); 
	
	
}


sub yes_no_dialog {
	my ($message)=@_;
	my $dialog = Gtk3::MessageDialog->new (my $window,
			'destroy-with-parent',
			'question', # message type
			'yes-no', # which set of buttons?
			"$message");
			
	$dialog->set_transient_for (Gtk3::Window->new('toplevel'));#just to get rid of transient warning		
	my $response = $dialog->run;
	
	$dialog->destroy;
	return $response;
}

sub create_dialog {
	my ($message_head,$message_body,$icon,@buttons)=@_;
	# create a new dialog with some buttons 
	my %hash1;
	my %hash2;
	my $i=0;
	foreach my $b (@buttons){
		$hash1{$b}=$i;
		$hash2{$i}=$b;
		$i++;
	}
	
  	my $dialog = Gtk3::Dialog->new (
  		" ", 
  		Gtk3::Window->new('toplevel'),
  		[qw/modal destroy-with-parent/],
        %hash1
    );
	my $content = $dialog->get_content_area ();
	
	my $table = def_table(1,3,TRUE);
	$table->attach  (def_icon($icon) , 0, 1,  0, 2,'expand','expand',2,2) if(defined $icon);
	if(defined $message_head){
		my $hd=gen_label_in_left($message_head);
		$hd->set_markup("<span  foreground= 'black' ><b>$message_head</b></span>");
		$table->attach  ($hd , 1, 10,  0, 1,'fill','shrink',2,2);
	}
	if(defined $message_head){
		$table->attach  (gen_label_in_left($message_body) , 2, 10,  1, 2,'fill','shrink',2,2);
	}
	
	$content->add ($table);
	$content->show_all;
			
	$dialog->set_transient_for (Gtk3::Window->new('toplevel'));#just to get rid of transient warning		
	my $response = $dialog->run;
	
	$dialog->destroy;
	return $hash2{$response};
}

############
# window
###########

sub def_win {
	my @titel=shift;
	my $window = Gtk3::Window->new('toplevel');
	$window->set_title(@titel);
	$window->set_position("center");
	$window->set_default_size(100, 100);
	$window->set_border_width(20);
	$window->signal_connect (delete_event => sub { Gtk3->main_quit });
	return $window;
	
}	


sub def_win_size {
	my $x=shift;
	my $y=shift;
	my @titel=shift;
	my $window = Gtk3::Window->new('toplevel');
	$window->set_title(@titel);
	$window->set_position("center");
	$window->set_default_size($x, $y);
	$window->set_border_width(20);
	$window->signal_connect (delete_event => sub { Gtk3->main_quit });
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
	#my $window = Gtk3::Window->new('popup');
	my $window = Gtk3::Window->new('toplevel');
	$window->set_title($titel);
	$window->set_position("center");
	$window->set_default_size($x, $y);
	$window->set_border_width(20);
	#$window->signal_connect (delete_event => sub { $window->destroy });
	return $window;
	
}	





sub def_scrolled_window_box{
			
	my $window =  def_popwin_size(@_);
	my $box=def_vbox(TRUE,5);
	my $scrolled_window = new Gtk3::ScrolledWindow (undef, undef);
	$scrolled_window->set_policy( "automatic", "automatic" );
	$scrolled_window->add($box);
	$window->add($scrolled_window);
	$window->show_all;
	$box->show_all;
	return ($box,$window);

}


sub get_default_screen {
  return Gtk3::Gdk::Screen::get_default;
}

sub get_defualt_font_size{
	return int($glob_setting{'FONT_SIZE'}) if ($glob_setting{'FONT_SIZE'} ne 'default');	
	
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
	$font_size= int (1.35*$font_size);
# do custom css #####################################################
	my $css_provider = Gtk3::CssProvider->new;
	$css_provider->load_from_data ([map ord, split //, "
	*{
                           
                            font-family:Verdana;
                            font-size:${font_size}px;
                                  }"
	
]);

#font_name = Verdana $font_size"


	#print  $css_provider->to_string,"\n";

	my $d = Gtk3::Gdk::Display::get_default ();
	my $s = $d->get_default_screen;
	
	Gtk3::StyleContext::add_provider_for_screen ( $s, $css_provider, Gtk3::STYLE_PROVIDER_PRIORITY_USER);


	   
		#Gtk3::Rc->parse_string(<<__);
		#	style "normal" { 
		#		font_name ="Verdana $font_size" 
		#	}
		#	widget "*" style "normal"
#__

}

sub add_widget_to_scrolled_win{
	my ($widget,$scrolled_win) =@_;
	if(! defined $scrolled_win){
		$scrolled_win = new Gtk3::ScrolledWindow (undef, undef);
		$scrolled_win->set_policy( "automatic", "automatic" );
		$scrolled_win->set_shadow_type('in');
	}else {
		my @list = $scrolled_win->get_children ();
		foreach my $c( @list){ $scrolled_win->remove($c);}
	}		
	#$scrolled_win->add_with_viewport($widget) if(defined $widget);
	$scrolled_win->add($widget) if(defined $widget);	
	$scrolled_win->show_all;	
	return $scrolled_win ;
}

sub gen_scr_win_with_adjst {
	my ($self,$name)=@_;
	my $scrolled_win = new Gtk3::ScrolledWindow (undef, undef);	
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
	return if (!defined $scrolled_win);
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
	my $value = $adjustment->get_value;
	$self->object_add_attribute($at1,$at2,$value) if (defined $self);
}


sub load_adj {
	my ($self,$adjustment,$at1,$at2)=@_;
	return if(!defined $at1);
    my $value=  $self->object_get_attribute($at1,$at2);
    return if(!defined $value);
    my $lower =  $adjustment->get_lower;
    my $upper = $adjustment->get_upper - $adjustment->get_page_size;
    $value=  ($value < $lower || $value > $upper ) ? 0 : $value; 
    
    $adjustment->set_value($value);   
}

sub set_pronoc_icon{
	my $window=shift;
    my $navIco = gen_pixbuf("./icons/ProNoC.png");        
	$window->set_icon($navIco); 
}

##############
#	box
#############

sub def_hbox {
	my( $homogeneous, $spacing)=@_;
	my $box = Gtk3::HBox->new($homogeneous, $spacing);
	$box->set_border_width(2);
	return $box;
}

sub def_vbox {
	my $box = Gtk3::VBox->new(FALSE, 0);
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
	my $vpaned = Gtk3::VPaned -> new;
	my($width,$hight)=max_win_size();

	
	$vpaned -> pack1($w1, TRUE, TRUE); 	
	$vpaned -> set_position ($hight*$loc);	
	$vpaned -> pack2($w2, TRUE, TRUE); 
	
	return $vpaned;
}


sub gen_hpaned {
	my ($w1,$loc,$w2) = @_;
	my $hpaned = Gtk3::HPaned -> new;
	my($width,$hight)=max_win_size();
	
	$hpaned -> pack1($w1, TRUE, TRUE); 	
	$hpaned -> set_position ($width*$loc);	
	$hpaned -> pack2($w2, TRUE, TRUE); 
	
	return $hpaned;
}


sub gen_hpaned_adj {
	my ($self,$w1,$loc,$w2,$name) = @_;
	my $hpaned = Gtk3::HPaned -> new;
	$hpaned -> pack1($w1, TRUE, TRUE); 
	$hpaned -> pack2($w2, TRUE, TRUE); 	
	
	$hpaned->signal_connect("destroy"=> sub{
	 	my $adj = $hpaned->get_position ();
	 	$self->object_add_attribute("adj",$name,$adj);
	 });	
	
	my $val =$self->object_get_attribute("adj",$name);
	if(defined $val){
		$hpaned -> set_position ($val);
	} else{
		my($width,$hight)=max_win_size();
		$hpaned -> set_position ($width*$loc);		
	}	
	
	return $hpaned;
}


#############
# text_view 
############

sub create_txview {
  my $scrolled_window = Gtk3::ScrolledWindow->new;
  $scrolled_window->set_policy ('automatic', 'automatic');
  $scrolled_window->set_shadow_type ('in');
  my $tview = Gtk3::TextView->new();
  $scrolled_window->add ($tview);
  
  # Make it a bit nicer for text.
  $tview->set_wrap_mode ('word');
  $tview->set_pixels_above_lines (2);
  $tview->set_pixels_below_lines (2);
  # $scrolled_window->set_placement('bottom_left' );
  add_colors_to_textview($tview);
  
  
  $scrolled_window->show_all;
  	
  return ($scrolled_window,$tview);
}


sub txview_scrol_to_end {
  my $tview =shift;
  my $buffer =  $tview->get_buffer;
  my $end_mark = $buffer->create_mark( 'end', $buffer->get_end_iter, 0 );
  $tview->scroll_to_mark( $end_mark, 0.0,0, 0.0, 1.0 );	
}


#################
#	table
################

sub def_table{
	my ($row,$col,$homogeneous)=@_;
	my $table = Gtk3::Table->new ($row, $col, $homogeneous);
	$table->set_row_spacings (0);
	$table->set_col_spacings (0);
	return $table;

}

sub attach_widget_to_table {
	my ($table,$row,$label,$inf_bt,$widget,$column)=@_;
	$column = 0 if(!defined $column);
	#$column *=4;
	#my $tmp=gen_label_in_left(" "); 
	if(defined $label)  {$table->attach  ($label , $column, $column+1,  $row,$row+1,'fill','shrink',2,2);$column++;}
	if(defined $inf_bt) {$table->attach  ($inf_bt , $column, $column+1, $row,$row+1,'fill','shrink',2,2);$column++;}
	if(defined $widget) {$table->attach  ($widget , $column, $column+1, $row,$row+1,'fill','shrink',2,2);$column++;}
	#$table->attach  ($tmp , $column+3, $column+4, $row,$row+1,'fill','shrink',2,2);
}

sub gen_Hsep { 
	return Gtk3::HSeparator->new;
}

sub gen_Vsep { 
	return Gtk3::VSeparator->new;
}


sub add_Hsep_to_table {
	my($table,$col0,$col1,$row)=@_;
	my $separator = gen_Hsep();	
	$table->attach ($separator ,$col0,$col1 , $row, $row+1,'fill','fill',2,2);	
}

sub add_Vsep_to_table {
	my($table,$col,$row1,$row2)=@_;
	my $separator = gen_Vsep();	
	$table->attach ($separator ,$col,$col+1 , $row1, $row2,'fill','fill',2,2);	
}


##################
#	show_info
##################
sub show_info{
	my ($textview,$info)=@_;
	#return;# if(!defined $textview_ref);
	#print "$textview_ref\n";
	my $buffer = $textview->get_buffer();
  	$buffer->set_text($info);
  	txview_scrol_to_end($textview);
}

sub add_info{
	my ($textview,$info)=@_;
	my $buffer = $textview->get_buffer();
	my $textiter = $buffer->get_end_iter();
	#Insert some text into the buffer
	$buffer->insert($textiter,$info);
	txview_scrol_to_end($textview);
	
}




sub show_colored_info{
	my ($textview,$info,$color)=@_;
	my $buffer = $textview->get_buffer();
  	#$buffer->set_text($info);
	my $textiter = $buffer->get_start_iter();
	$buffer->insert_with_tags_by_name ($textiter, "$info", "${color}_tag");
	txview_scrol_to_end($textview);
}

sub add_colored_info{
	my ($textview,$info,$color)=@_;
	my $buffer = $textview->get_buffer();
	my $textiter = $buffer->get_end_iter();
	#Insert some text into the buffer
	#$buffer->insert($textiter,$info);
	$buffer->insert_with_tags_by_name ($textiter, "$info", "${color}_tag");
	txview_scrol_to_end($textview);	
}

sub add_colors_to_textview{
	my $tview= shift;
	add_colored_tag($tview,'red');
	add_colored_tag($tview,'blue');
	add_colored_tag($tview,'brown');
	add_colored_tag($tview,'green');
}


sub add_colored_tag{
	my ($textview_ref,$color)=@_;
	my $buffer = $textview_ref->get_buffer();
  	$buffer->create_tag ("${color}_tag", foreground => $color);  
}

sub add_color_to_gd{
	foreach (my $i=0;$i<32;$i++ ) {
		my ($red,$green,$blue)=get_color($i);	    
		add_colour("my_color$i"=>[$red>>8,$green>>8,$blue>>8]);
		
	}	
}



############
#	get file folder list
###########

sub get_directory_name_widget {
	my ($object,$title,$entry,$attribute1,$attribute2,$status,$timeout)= @_;
	my $browse= def_image_button("icons/browse.png");

	$browse->signal_connect("clicked"=> sub{
		my $entry_ref=$_[1];
 		my $file;
		$title ='select directory' if(!defined $title);
		my $dialog = Gtk3::FileChooserDialog->new(
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
				$dialog->set_transient_for (Gtk3::Window->new('toplevel'));#just to get rid of transient warning
	       		$dialog->destroy;
	       		


		} , \$entry);
	
	return $browse;

}


sub get_dir_name {
	my ($object,$title,$attribute1,$attribute2,$open_in,$status,$timeout)= @_;
	my $dir;
	$title ='select directory' if(!defined $title);
	my $dialog = Gtk3::FileChooserDialog->new(
	  	$title, undef,
		#       	'open',
		'select-folder',
	   	'gtk-cancel' => 'cancel',
	   	'gtk-ok'     => 'ok',
	);

	$dialog->set_transient_for (Gtk3::Window->new('toplevel'));#just to get rid of transient warning

	if(defined  $open_in){
		$dialog->set_current_folder ($open_in); 
	}
	       			
	if ( "ok" eq $dialog->run ) {
		    	$dir = $dialog->get_filename;
				$object->object_add_attribute($attribute1,$attribute2,$dir);
				set_gui_status($object,$status,$timeout) if(defined $status);	
				$dialog->destroy;
	}
}



sub get_file_name {
	my ($object,$title,$entry,$attribute1,$attribute2,$extension,$label,$open_in,$new_status,$ref_delay)= @_;
	my $browse= def_image_button("icons/browse.png");
	
	$browse->signal_connect("clicked"=> sub{
		my $entry_ref=$_[1];
 		my $file;
		$title ='select a file' if(!defined $title);
		my $dialog = Gtk3::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);

	$dialog->set_transient_for (Gtk3::Window->new('toplevel'));#just to get rid of transient warning

	 if(defined $extension){
		my $filter = Gtk3::FileFilter->new();
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
				set_gui_status($object,$new_status,$ref_delay) if(defined $ref_delay);
				my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
				if(defined $label){
					$label->set_markup("<span  foreground= 'black' ><b>$name$suffix</b></span>");
					$label->show;
				}
						
				#check_input_file($file,$socgen,$soc_state,$info);
		    		#print "file = $file\n";
	       		 }
	       		$dialog->destroy;
	       		


		} , \$entry);
	
	return $browse;

}

sub gen_file_dialog  {
	my ($title, @extension)=@_;
	$title = 'Select a File' if (!defined $title);

	my $dialog = Gtk3::FileChooserDialog->new(
            	$title, 
				undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
     );

	$dialog->set_modal(TRUE);
	$dialog->set_transient_for (Gtk3::Window->new('toplevel'));#just to get rid of transient warning

	foreach my $ext (@extension){
		my $filter = Gtk3::FileFilter->new();
		$filter->set_name("$ext");
		$filter->add_pattern("*.$ext");
		$dialog->add_filter ($filter);
	}	

	return $dialog;

}


sub save_file_dialog  {
	my ($title, @extension)=@_;
	$title = 'Select a File' if (!defined $title);

	my $dialog = Gtk3::FileChooserDialog->new(
            	$title, 
				undef,
            	'save',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
     );

	$dialog->set_modal(TRUE);
	$dialog->set_transient_for (Gtk3::Window->new('toplevel'));#just to get rid of transient warning

	foreach my $ext (@extension){
		my $filter = Gtk3::FileFilter->new();
		$filter->set_name("$ext");
		$filter->add_pattern("*.$ext");
		$dialog->add_filter ($filter);
	}	

	return $dialog;

}




sub gen_folder_dialog  {
	my ($title)=@_;
	$title = 'Select Folder' if (!defined $title);
	
	

	my $dialog = Gtk3::FileChooserDialog->new(
		$title, 
		undef,
		'select-folder',
	   	'gtk-cancel' => 'cancel',
	   	'gtk-ok'     => 'ok',
     );
	$dialog->set_modal(TRUE);
	$dialog->set_transient_for (Gtk3::Window->new('toplevel'));#just to get rid of transient warning
	
	return $dialog;

}


sub get_filenames_from_dialog{
	my $dialog=shift;
	my $ref = $dialog->get_filenames;
	my @files;
	@files = @{$ref} if (defined $ref); 
	return @files;
}


sub new_dialog_with_buttons {
	my $self =shift;
	return Gtk3::Dialog->new_with_buttons(
		"Goto to line",
		$self->window,
		[ 'modal' ],
		'gtk-cancel' => 'cancel',
		'gtk-ok'     => 'ok',
	);

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
	my @combo_list=split(/\s*,\s*/,$content);
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
	my @combo_list;
	@combo_list=split(/\s*,\s*/,$content) if(defined $content );
	my $value=$object->object_get_attribute($attribute1,$attribute2);
	my $pos;
	$pos=get_pos($value, @combo_list) if (defined $value);
	if(!defined $pos && defined $default){
		$object->object_add_attribute($attribute1,$attribute2,$default);	
	 	$pos=get_item_pos($default, @combo_list);
	}
	#print " my $pos=get_item_pos($value, @combo_list);\n";
	
	my $widget=gen_combo_entry(\@combo_list, $pos);
	my $child = combo_entry_get_chiled($widget);
	$child->signal_connect('changed' => sub {
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
	my ($min,$max,$step,$digit)=split(/\s*,\s*/,$content);
	if(!defined $value){
		$value=$default;
		$object->object_add_attribute($attribute1,$attribute2,$value);
	}
	
	$value=~ s/[^0-9.\-]//g;
	$min=~   s/[^0-9.\-]//g;
	$max=~   s/[^0-9.\-]//g;
	$step=~  s/[^0-9.\-]//g;
	$digit=~ s/[^0-9.\-]//g if (defined $digit);
	
	my $widget=gen_spin($min,$max,$step,$digit);
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
			$check[$i]= gen_checkbutton();
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
		my $widget = Gtk3::CheckButton->new;
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
	if (defined $default){
		$object->object_add_attribute($attribute1,$attribute2,  $default) if  !(-d $value );
		$value = $default  if !(-d $value );
	};
	
	my $warning;
	
	my $entry=gen_entry($value);
	$entry-> signal_connect("changed" => sub{
		my $new_param_value=$entry->get_text();
		$object->object_add_attribute($attribute1,$attribute2,$new_param_value);
		set_gui_status($object,$status,$timeout) if (defined $status);
		unless (-d $new_param_value ){
			if (!defined $warning){
				$warning = def_icon("icons/warning.png");
				$widget->pack_start( $warning, FALSE, FALSE, 0);
				set_tip($warning,"$new_param_value is not a valid directory");
				$widget->show_all;
			}
			
		}else{
			$warning->destroy if (defined $warning); 
			undef $warning;
			
		}
	
	});
	my $browse= get_directory_name_widget($object,undef,$entry,$attribute1,$attribute2,$status,$timeout);
	
	$widget->pack_start( $entry, FALSE, FALSE, 0);
	$widget->pack_start( $browse, FALSE, FALSE, 0);
	
	 if(defined $value){
		unless (-d $value ){
		 	$warning= def_icon("icons/warning.png");	
			$widget->pack_start( $warning, FALSE, FALSE, 0); 
			set_tip($warning,"$value is not a valid directory path");
		}
	}
	return $widget;
}




sub get_file_name_object {
	my ($object,$attribute1,$attribute2,$extension,$open_in,$new_status,$ref_delay)=@_;
	my $widget = def_hbox(FALSE,0);
	my $value=$object->object_get_attribute($attribute1,$attribute2);
	my $label;
	if(defined $value){
		my ($name,$path,$suffix) = fileparse("$value",qr"\..[^.]*$");
		$label=gen_label_in_center($name.$suffix);
		
	} else {
			$label=gen_label_in_center("Selecet a file");
			$label->set_markup("<span  foreground= 'red' ><b>No file has been selected yet</b></span>");
	}
	my $entry=gen_entry();
	my $browse= get_file_name($object,undef,$entry,$attribute1,$attribute2,$extension,$label,$open_in,$new_status,$ref_delay);
	$widget->pack_start( $label, FALSE, FALSE, 0);
	$widget->pack_start( $browse, FALSE, FALSE, 0);
	return $widget;
}





sub gen_notebook {
	my $notebook = Gtk3::Notebook->new;
	return $notebook;
}
################
# ADD info and label to widget
################


sub gen_label_info{
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


############
#
###########

sub gen_MenuBar{
	my ($window,@menu_items)=@_;
 	
 	my $accel_group = Gtk3::AccelGroup->new;
   	$window->add_accel_group ($accel_group);   
	my $menubar = Gtk3::MenuBar->new;
	my $menu  = Gtk3::Menu->new;
    $menu->set_accel_group ($accel_group);
	
	my %all_menus;
	foreach my $p (@menu_items){
		my ($name,$key,$func,$u,$type)=@{$p};
		$name =~ s/_//;	
		my @l =split ('/',$name);
		
		my $m= pop @l;
		$m =~ s/_//;	
		my $parent = join('/',@l);
		$parent =~ s/_//;	


	#	print "\$parent= $parent **   \$m=$m\n";
	#    print "   all_menus{$parent}  = $all_menus{$parent}\n";
		my $menuitem = Gtk3::MenuItem->new_with_label($m);
		
		if(!defined $all_menus{$parent}){
			my $menu  = Gtk3::Menu->new;
		    $menu->set_accel_group ($accel_group);
			$menuitem->set_submenu($menu);
			$all_menus{$name}{'menu'}=$menu;
			$all_menus{$name}{'num'}=0;
			$menubar->append($menuitem) 
		}else {
			my $menu = $all_menus{$parent}{'menu'};
			my $pos = $all_menus{$parent}{'num'};
			$menu->insert($menuitem,$pos);
			$all_menus{$parent}{'num'}= $pos+1;
			if(defined $type){
			if($type eq "<Branch>"){
				$all_menus{$name}{'menu'}=$menu;				
				$all_menus{$name}{'num'}=0;
			}}
			
		}
		if(defined $key){
			$menuitem->add_accelerator('activate',$accel_group,Gtk3::accelerator_parse($key),'visible');
		}
		if(defined $func){
			$menuitem->signal_connect('activate' => \&$func);
		}
		#print "$name,$key,$func,$u,$type\n";
		$menuitem->show();
	}

	my $box = Gtk3::Box->new( 'vertical', 0 );
	$box->pack_start( $menubar, FALSE, TRUE, 0 );
	$menubar->show();

	return $box;
}



sub creating_detachable_toolbar{
	my @attachments=@_;
	return def_pack_hbox('FALSE', 0, @_);
	#The handle box helps in creating a detachable toolbar 
	my $hb = Gtk3::HandleBox->new;
	#create a toolbar, and do some initial settings
	my $toolbar = Gtk3::Toolbar->new;
	$toolbar->set_icon_size ('small-toolbar');	
	$toolbar->set_show_arrow (FALSE);
	foreach my $p (@attachments){
		$toolbar->insert($p,-1);
		
	}
	$hb->add($toolbar);	
	return $hb;
}

sub gui_quite{
	Gtk3->main_quit;
}

sub gtk_gui_run{
	my ($main)=@_;
	Gtk3->init;
	&$main;
	Gtk3->main();
	return 1;
}




sub refresh_gui{
	while (Gtk3::events_pending) {
     Gtk3::main_iteration;
    }
    Gtk3::Gdk::flush;  
}


sub about {
    my $version=shift;
    my $about = Gtk3::AboutDialog->new;
	my @authors=("Alireza Monemi", "Email: alirezamonemi\@opencores.org");
    $about->set_authors(\@authors);
    $about->set_version( $version );
    $about->set_website('http://opencores.org/project,an-fpga-implementation-of-low-latency-noc-based-mpsoc');
    $about->set_comments('NoC based MPSoC generator.');
    $about->set_program_name('ProNoC');
    my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file_at_scale("icons/ProNoC.png",50,50,FALSE);
    $about->set_logo($pixbuf);

    $about->set_license(
                 "This program is free software; you can redistribute it\n"
                . "and/or modify it under the terms of the GNU General \n"
		. "Public License as published by the Free Software \n"
		. "Foundation; either version 1, or (at your option)\n"
		. "any later version.\n\n"
                 
        );
	# Add the Hide action to the 'Close' button in the AboutDialog():
    $about->signal_connect('response' => sub { $about->hide; });
	
	$about->set_transient_for (Gtk3::Window->new('toplevel'));#just to get rid of transient warning

    $about->run;
    $about->destroy;
    return;
}



############
#  list_store
###########

sub gen_list_store {
	my ($dref,$clmn_type_ref, $clmn_lables_ref)=@_;
	
	
#		my @data = (
#  {0 => "Average distance",  1 =>"$avg"}, 
#  {0 => "Max distance",  1 =>"$max" },  
#  {0 => "Min distance",1 => "$min"},    
#  {0 => "Normlized data per hop", 1 =>"$norm" }
#  );

# my @clmn_type = (#'Glib::Boolean', # => G_TYPE_BOOLEAN
#                                    #'Glib::Uint',    # => G_TYPE_UINT
#                                    'Glib::String',  # => G_TYPE_STRING
#                                  'Glib::String'); # you get the idea

	
	my @data = @{$dref};	
	my @clmn_type = @{$clmn_type_ref}; 	
	my @clmn_lables= @{$clmn_lables_ref};
	
   
    # create list store
    my $store = Gtk3::ListStore->new ( @clmn_type);
   

	# add data to the list store
	foreach my $d (@data) {
		my $iter = $store->append;
		my @clmns = sort keys %{$d};
		my @a=($iter);
	  	foreach my $c (@clmns){
	  		push (@a,($c,$d->{$c}));
				
	  	}
     	$store->set (@a);   
     	
 	}
  

    my $treeview = Gtk3::TreeView->new ($store);
    $treeview->set_rules_hint (TRUE);
	$treeview->set_search_column (1);
    #my $renderer = Gtk3::CellRendererToggle->new;
    #$renderer->signal_connect (toggled => \&fixed_toggled, $store);


	# column for severities
	my $c=0;
	foreach my $l (@clmn_lables){
		my $renderer = Gtk3::CellRendererText->new;
		my $column = Gtk3::TreeViewColumn->new_with_attributes ("$l",
							       $renderer,
							       text => $c
							       );
		$column->set_sort_column_id ($c );
		$treeview->append_column ($column);
		$c++;
	}
 
	
	return $treeview;
}





##############
#	create tree
##############


sub create_tree_model_network_maker{
	my $model = Gtk3::TreeStore->new ('Glib::String', 'Glib::String', 'Glib::Scalar', 'Glib::Boolean');
	my $tree_view = Gtk3::TreeView->new;
	$tree_view->set_model ($model);
	my $selection = $tree_view->get_selection;
	$selection->set_mode ("single");
	my $cell = Gtk3::CellRendererText->new;
	$cell->set ('style' => 'italic');
	my $column = Gtk3::TreeViewColumn->new_with_attributes ("select", $cell, 'text' => 0, 'style_set' => 3);
	return ($model,$tree_view,$column);
}


sub treemodel_next_iter{
	my 	($child , $tree_model)=@_;
	$tree_model->iter_next ($child);
	return $child;
}













# clean names for column numbers.
use constant DISPLAY_COLUMN    => 0;
use constant CATRGORY_COLUMN    => 1;
use constant MODULE_COLUMN     => 2;
use constant ITALIC_COLUMN   => 3;
use constant NUM_COLUMNS     => 4;

sub create_tree {
   my ($self,$label,$info,$tree_ref,$row_selected_func,$row_activated_func)=@_;
   my %tree_in = %{$tree_ref};
   my $model = Gtk3::TreeStore->new ('Glib::String', 'Glib::String', 'Glib::Scalar', 'Glib::Boolean');
   my $tree_view = Gtk3::TreeView->new;
   $tree_view->set_model ($model);
   my $selection = $tree_view->get_selection;
   $selection->set_mode ('browse');   
 
   

   foreach my $p (sort keys %tree_in)
   {
  
	my @modules= @{$tree_in{$p}};
	#my @dev_entry=  @{$tree_entry{$p}}; 	
	my $iter = $model->append (undef);
	$model->set ($iter,
                   DISPLAY_COLUMN,    $p,
                   CATRGORY_COLUMN, $p || '',
                   MODULE_COLUMN,     0     || '',
                   ITALIC_COLUMN,   FALSE);

	next unless  @modules;
	
	foreach my $v ( @modules){
		 my $child_iter = $model->append ($iter);
		 my $entry= '';
		
         	$model->set ($child_iter,
			DISPLAY_COLUMN,    $v,
                   	CATRGORY_COLUMN, $p|| '',
                   	MODULE_COLUMN,     $v     || '',
                   	ITALIC_COLUMN,   FALSE);
      	}	
	


   }
	
   my $cell = Gtk3::CellRendererText->new;
   $cell->set ('style' => 'italic');
   my $column = Gtk3::TreeViewColumn->new_with_attributes
 					("$label",
                                        $cell,
                                        'text' => DISPLAY_COLUMN,
                                        'style_set' => ITALIC_COLUMN);

	$tree_view->append_column ($column);
	my @ll=($model,$info);
   #row selected
	$selection->signal_connect (changed =>sub {
	my ($selection, $ref) = @_;
	my ($model,$info)=@{$ref};
	my $iter = $selection->get_selected;
  	return unless defined $iter;

  	my ($category) = $model->get ($iter, CATRGORY_COLUMN);
  	my ($module) = $model->get ($iter,MODULE_COLUMN );
  	$row_selected_func->($self,$category,$module,$info) if(defined $row_selected_func);
  


}, \@ll);

#  row_activated 
  $tree_view->signal_connect (row_activated => sub{

	my ($tree_view, $path, $column) = @_;
	my $model = $tree_view->get_model;
	my $iter = $model->get_iter ($path);
	my ($category) = $model->get ($iter, CATRGORY_COLUMN);
  	my ($module) = $model->get ($iter,MODULE_COLUMN );
	

	if($module){ 
		#print "$module  is selected via row activaton!\n";
		$row_activated_func->($self,$category,$module,$info) if(defined $row_activated_func);
		#add_module_to_soc($soc,$ip,$category,$module,$info);
			
	}

}, \@ll);

  #$tree_view->expand_all;

  my $scrolled_window = Gtk3::ScrolledWindow->new;
  $scrolled_window->set_policy ('automatic', 'automatic');
  $scrolled_window->set_shadow_type ('in');
  $scrolled_window->add($tree_view);

  my $hbox = Gtk3::HBox->new (FALSE, 0);
  $hbox->pack_start ( $scrolled_window, TRUE, TRUE, 0); 

  return $hbox;
}


sub row_activated_cb{
	 my ($tree_view, $path, $column) = @_;
	 my $model = $tree_view->get_model;
	 my $iter = $model->get_iter ($path);
	 my ($category) = $model->get ($iter, DISPLAY_COLUMN);
  	 my ($module) = $model->get ($iter, CATRGORY_COLUMN);

}



sub file_edit_tree {
	my $model = Gtk3::TreeStore->new('Glib::String', 'Glib::String');
	my $tree_view = Gtk3::TreeView->new;
	$tree_view->set_model ($model);
	my $selection = $tree_view->get_selection;
	$selection->set_mode ("single");	
	my $cell = Gtk3::CellRendererText->new;
	$cell->set ('style' => 'italic');
	my $column = Gtk3::TreeViewColumn->new_with_attributes('Double-click to open',$cell, text => "0");
	$tree_view->append_column($column);
	$tree_view->set_headers_visible(TRUE);
	return ($model,$tree_view);
}


#	my $column = Gtk3::TreeViewColumn->new_with_attributes ("select", $cell, 'text' => 0, 'style_set' => 3);





##########
#  run external commands
##########



sub run_cmd_in_back_ground
{
  my $command = shift;
  #print "\t$command\n";
 
  ### Start running the Background Job:
    my $proc = Proc::Background->new($command);
    my $PID = $proc->pid;
    my $start_time = $proc->start_time;
    my $alive = $proc->alive;

  ### While $alive is NOT '0', then keep checking till it is...
  #  *When $alive is '0', it has finished executing.
  while($alive ne 0)
  {
    $alive = $proc->alive;

    # This while loop will cause Gtk3 to continue processing events, if
    # there are events pending... *which there are...
    while (Gtk3::events_pending) {
     
      Gtk3::main_iteration;
    }
    Gtk3::Gdk::flush;

    usleep(1000);
  }
  
  my $end_time = $proc->end_time;
 # print "*Command Completed at $end_time, with PID = $PID\n\n";

  # Since the while loop has exited, the BG job has finished running:
  # so close the pop-up window...
 # $popup_window->hide;

  # Get the RETCODE from the Background Job using the 'wait' method
  my $retcode = $proc->wait;
  $retcode /= 256;

  #print "\t*RETCODE == $retcode\n\n";
  Gtk3::Gdk::flush;
  ### Check if the RETCODE returned with an Error:
  if ($retcode ne 0) {
    print "Error: The Background Job ($command) returned with an Error...!\n";
    return 1;
  } else {
    #print "Success: The Background Job Completed Successfully...!\n";
    return 0;
  }
	
}

sub run_cmd_in_back_ground_get_stdout
{
	my $cmd=shift;
	my $exit;
	my ($stdout, $stderr);	
	
	#open(OLDERR, ">&STDERR");
	#open(STDERR, ">>/tmp/tmp.spderr") or die "Can't dup stdout";
	#select(STDOUT); $| = 1;     # make unbuffered
	#print OLDERR "";  #this fixed an error about OLDERR not being used 

## do my stuff here.
	
	STDOUT->flush();
	STDERR->flush();
	
	capture { $exit=run_cmd_in_back_ground($cmd) } \$stdout, \$stderr;
	
	#close(STDERR);
	#open(STDERR, ">&OLDERR");
	return ($stdout,$exit,$stderr);
	
}		
	
sub run_cmd_message_dialog_errors{
	my ($cmd)=@_;
	my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
	if(length $stderr>1){			
		message_dialog("$stderr\n",'error');
		return 1;
	}if($exit){
		message_dialog("Error $cmd failed: $stdout\n",'error');
		return 1;		
	}
	return 0;
	
}


sub run_cmd_textview_errors{
	my ($cmd,$tview)=@_;
	my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout($cmd);
	if(length $stderr>1){			
		add_colored_info($tview,"Error: $stderr\n",'red');
		add_colored_info($tview,"$cmd did not run successfully!\n",'red');
		return undef;
	}
	if($exit){
		add_colored_info($tview,"Error:$stdout\n",'red');
		add_colored_info($tview,"$cmd did not run successfully!\n",'red');
		return undef;
	}
	$stdout = "" if (!defined $stdout);
	return 	$stdout
}	


sub create_iconview_model {
#----------------------------------------------------
#The Iconview needs a Gtk3::Treemodel implementation-
#containing at least a Glib::String and -------------
#Gtk3::Gdk::Pixbuf type. The first is used for the --
#text of the icon, and the last for the icon self----
#Gtk3::ListStore is ideal for this ------------------
#----------------------------------------------------
	my ($self,$name,$ref)=@_;
	my @sources= (defined $ref)? @{$ref}:(); 
    my $list_store = Gtk3::ListStore->new(qw/Glib::String Gtk3::Gdk::Pixbuf Glib::String/);

    #******************************************************
    #we populate the Gtk3::ListStore with Gtk3::Stock icons
    #******************************************************

 

    foreach my $val(@sources){
        #get the iconset from the icon_factory
        #my $iconset = $icon_factory->lookup_default($val);
        #try and extract the icon from it
        add_icon_to_tree($self,$name,$list_store,$val);
    }

    return $list_store;
}

####################
#	SourceView
####################

sub	gen_SourceView_with_buffer{
	return Gtk3::SourceView::View->new_with_buffer(@_);
}





sub create_SourceView_buffer {
	my $self = shift;
	my $tags = Gtk3::TextTagTable->new();

	add_tag_to_SourceView($tags, search => {
			background => 'yellow',
	});
	add_tag_to_SourceView($tags, goto_line => {
			'paragraph-background' => 'orange',
	});

	my $buffer = Gtk3::SourceView::Buffer->new($tags);
	$buffer->signal_connect('notify::cursor-position' => sub {
		$self->clear_highlighted();
	});

	return $buffer;
}


sub add_tag_to_SourceView {
	my ($tags, $name, $properties) = @_;

	my $tag = Gtk3::TextTag->new($name);
	$tag->set(%{ $properties });
	$tags->add($tag);
}


sub detect_language {
	my $self = shift;
	my ($filename) = @_;

	# Guess the programming language of the file
	my $manager = Gtk3::SourceView::LanguageManager->get_default;
	my $language = $manager->guess_language($filename);
	$self->buffer->set_language($language);
}


sub get_pressed_key{ 
	my $event=shift;
	my $key = Gtk3::Gdk::keyval_name( $event->keyval );
	return $key;
}









1
