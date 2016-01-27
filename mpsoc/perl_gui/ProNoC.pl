#!/usr/bin/perl -w

use Glib qw/TRUE FALSE/;


use Gtk2;
use strict;
use warnings;
#use Image::Base::Gtk2::Gdk::Pixbuf;

use lib 'lib/perl';
require "widget.pl"; 
require "interface_gen.pl";
require "ip_gen.pl";
require "soc_gen.pl";
require "mpsoc_gen.pl";
require "noc_sim.pl";





sub set_deafualt_font{
	my($width,$hight)=@_;
	#print "($width,$hight)\n";
	my $font_size;
	if($width>1600){
	    $font_size=10;
		Gtk2::Rc->parse_string(<<__);
			style "normal" { 
				font_name ="Verdana 10" 
			}
			widget "*" style "normal"
__

	}
	elsif ($width>1400){
		$font_size=9;
		Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 9" 
			}
			widget "*" style "normal"
__

	}
	elsif ($width>1200){
		$font_size=8;
		Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 8" 
			}
			widget "*" style "normal"
__

	}
	elsif ($width>1000){
	    $font_size=7;
		Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 7" 
			}
			widget "*" style "normal"
__

	}
	else{
	    $font_size=6;
		Gtk2::Rc->parse_string(<<__);
		style "normal" { 
				font_name ="Verdana 6" 
			}
			widget "*" style "normal"
__

	}
	#print "	    \$font_size=	    $font_size\n";
	return 	    $font_size;
	

}

sub get_mpsoc{
	my ($ipgen,$soc_state,$info)=@_;
	my $description = "Will be available soon!";
	my $table = Gtk2::Table->new (15, 15, TRUE);
	#my $window=def_popwin_size(500,500,"Add description");
	my ($scrwin,$text_view)=create_text();
	#my $buffer = $textbox->get_buffer();
	my $ok=def_image_button("icons/select.png",' Ok ');
	
	$table->attach_defaults($scrwin,0,15,0,14);
	$table->attach_defaults($ok,6,9,14,15);
	my $text_buffer = $text_view->get_buffer;
	if(defined $text_buffer) {$text_buffer->set_text($description)};
	
	$ok->signal_connect("clicked"=> sub {
				 
		my $text = $text_buffer->get_text($text_buffer->get_bounds, TRUE);
		# $ipgen->ipgen_set_description($text);	
		print "$text\n";
		
	});
	
	#$window->add($table);
	#$window->show_all();
	return $table;
	
}	




sub main{



my $notebook = Gtk2::Notebook->new;
#$hbox->pack_start ($notebook, TRUE, TRUE, 0);

my($width,$hight)=max_win_size();
set_deafualt_font_size();



my $intfc_gen=  intfc_main();
$notebook->append_page ($intfc_gen,Gtk2::Label->new_with_mnemonic ("_Interface generator"));

my $ipgen=ipgen_main();
$notebook->append_page ($ipgen,Gtk2::Label->new_with_mnemonic ("_IP generator"));

my $socgen=socgen_main();			
$notebook->append_page ($socgen,Gtk2::Label->new_with_mnemonic ("_Processing tile generator"));

my $mpsocgen =mpsocgen_main();
$notebook->append_page ($mpsocgen,Gtk2::Label->new_with_mnemonic ("_NoC based MPSoC generator"));	

								
			
			
			
		my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
		$scrolled_win->set_policy( "automatic", "automatic" );
		$scrolled_win->add_with_viewport($notebook);	
		
		my $window = def_win_size($width-100,$hight-100,"ProNoC");
		$window->add($scrolled_win);
		

		my $navIco = Gtk2::Gdk::Pixbuf->new_from_file("./icons/ProNoC.png");         # advance1.png");  
		$window->set_default_icon($navIco); 


		$window->set_resizable (1);
		$window->show_all();
		
		
	 
	 





}			




Gtk2->init;
main;
Gtk2->main();
