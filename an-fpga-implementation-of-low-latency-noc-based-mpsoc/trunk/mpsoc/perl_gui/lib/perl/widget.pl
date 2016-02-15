use Glib qw/TRUE FALSE/;
#use Gtk2 '-init';
use strict;
use warnings;

use Gtk2::Pango;


##############
# combo box
#############
sub gen_combo{
	my ($combo_list, $combo_active_pos)= @_;
	my $combo = Gtk2::ComboBox->new_text;
	
	combo_set_names($combo,$combo_list);
	$combo->set_active($combo_active_pos);
	
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

##############
# ComboBoxEntry
##############

sub gen_combo_entry{
	my $list_ref=shift;
	my @list=@{$list_ref};	

	my $combo_box_entry = Gtk2::ComboBoxEntry->new_text;
	foreach my $p (@list){
		$combo_box_entry->append_text($p);
	}
	$combo_box_entry->set_active(0);
	return $combo_box_entry;
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
	

sub def_image{
	my $image_file=shift;
	my $font_size=get_deafualt_font_size();
	my $size=($font_size==10)? 25:
		     ($font_size==9 )? 22:
			 ($font_size==8 )? 18:
			 ($font_size==7 )? 15:12 ;
	my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_scale($image_file,$size,$size,FALSE);
 	
 			 
 	my $image = Gtk2::Image->new_from_pixbuf($pixbuf);
	return $image;

}



sub def_image_button{
	my ($image_file, $label_text)=@_;
	# create box for image and label 
	my $box = def_hbox(FALSE,0);
	my $image = def_image($image_file);
		
	
	# now on to the image stuff
	#my $image = Gtk2::Image->new_from_file($image_file);
	$box->pack_start($image, FALSE, FALSE, 0);
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
	my $image = def_image($image_file);
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
	my $font_size=get_deafualt_font_size();
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







############
#	message_dialog
############

sub message_dialog {
  my @message=@_;
  my $window;
  my $dialog = Gtk2::MessageDialog->new ($window,
				   [qw/modal destroy-with-parent/],
				   'info',
				   'ok',
				    @message);
  $dialog->run;
  $dialog->destroy;
 
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
	my $x=shift;
	my $y=shift;
	my @titel=shift;
	#my $window = Gtk2::Window->new('popup');
	my $window = Gtk2::Window->new('toplevel');
	$window->set_title(@titel);
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


sub get_deafualt_font_size{
	my($width,$hight)=max_win_size();
	#print "($width,$hight)\n";
	my $font_size=($width>=1600)? 10:
			      ($width>=1400)? 9:
				  ($width>=1200)? 8:
				  ($width>=1000)? 7:6;
	return $font_size;
}


sub set_deafualt_font_size{
	my $font_size=get_deafualt_font_size();
	if($font_size==10){	    
		Gtk2::Rc->parse_string(<<__);
			style "normal" { 
				font_name ="Verdana 10" 
			}
			widget "*" style "normal"
__

	}
	elsif ($font_size==9){	    
		$font_size=9;
		Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 9" 
			}
			widget "*" style "normal"
__

	}
	elsif ($font_size==8){	    
		$font_size=8;
		Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 8" 
			}
			widget "*" style "normal"
__

	}
	elsif ($font_size==7){	    
	    $font_size=7;
		Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 7" 
			}
			widget "*" style "normal"
__

	}
	else{
	   	Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 6" 
			}
			widget "*" style "normal"
__

	}
	


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

sub set_state{
	my ($state,$initial,$timeout)=@_;
	my ($entry,$time_out)=@{$state};
	$entry->set_text($initial);
	@{$state}[1]=$timeout;
	
}	


sub get_state{
	my ($state)=@_;
	my ($entry,$time_out)=@{$state};
	my $st;
	$st=$entry->get_text();
	return ($st,$time_out);	
}	




##################
#	show_info
##################
sub show_info{
	my ($textview_ref,$info)=@_;
	my $buffer = $$textview_ref->get_buffer();
  	$buffer->set_text($info);
}



####################
#	read verilog file
##################


sub read_file{
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


sub get_color {
	my $num=shift;
	
	my @colors=(
	0x6495ED,#Cornflower Blue
	0xFAEBD7,#Antiquewhite
	0xC71585,#Violet Red
	0xC0C0C0, #silver
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
	0xFFFFFF #white			
		);
	
	my $color= 	($num< scalar (@colors))? $colors[$num]: 0xFFFFFF;	
	my $red= 	($color & 0xFF0000) >> 8;
	my $green=	($color & 0x00FF00);
	my $blue=	($color & 0x0000FF) << 8;
	
	return ($red,$green,$blue);
	
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
							
							foreach my $w (keys %{$clone->{$p}{$q}{$q}}){
								$self->{$p}{$q}{$z}{$w}= $clone->{$p}{$q}{$z}{$w};	
								my $ref= ref ($self->{$p}{$q}{$z}{$w});
								if( $ref eq 'HASH' ){
									
							
									foreach my $m (keys %{$clone->{$p}{$q}{$q}{$w}}){
										$self->{$p}{$q}{$z}{$w}{$m}= $clone->{$p}{$q}{$z}{$w}{$m};	
										my $ref= ref ($self->{$p}{$q}{$z}{$w}{$m});
										if( $ref eq 'HASH' ){
											
											foreach my $n (keys %{$clone->{$p}{$q}{$q}{$w}{$m}}){
												$self->{$p}{$q}{$z}{$w}{$m}{$n}= $clone->{$p}{$q}{$z}{$w}{$m}{$n};	
												my $ref= ref ($self->{$p}{$q}{$z}{$w}{$m}{$n});	
												if( $ref eq 'HASH' ){
												
													foreach my $l (keys %{$clone->{$p}{$q}{$q}{$w}{$m}{$n}}){
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
		if( grep (/^$p$/,@B)){push(@C,$p)};
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
		if( !grep (/^$p$/,@B)){push(@C,$p)};
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


1
