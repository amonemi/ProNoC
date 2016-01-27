#! /usr/bin/perl -w
use Glib qw/TRUE FALSE/;
use strict;
use warnings;

use lib 'lib/perl';
use Gtk2;
# clean names for column numbers.

require "widget.pl"; 



######################
#	instances setting box
######################

sub generate_instance_box{
	my $table = def_table (15, 12, TRUE);
	my $label = gen_label_in_center("Instances");
	
	
	#$table->attach_defaults ($event_box, $col, $col+1, $row, $row+1);
	$table->attach_defaults ($label, 0, 12, 0,1);
	return $table;
}

#######################
#	simulation setting box
#######################
sub generate_sim_setting_box{
	my $table = def_table (15, 12, TRUE);
	
	
	return $table;
	
	
}

######################
#	graph setting box
#####################

sub generate_graph_setting_box{
	my $table = def_table (15, 12, TRUE);
	
	
	return $table;
	
	
}



####################	
#	graph box
####################	
	
sub generate_graph_box{
	my $table = def_table (15, 12, TRUE);
	my $label = gen_label_in_center("Instances");
	
	
	#$table->attach_defaults ($event_box, $col, $col+1, $row, $row+1);
	$table->attach_defaults ($label, 0, 12, 0,1);
	
	return $table;
	
	
	
	
}






############
#    main
############
sub noc_sim_main{
	
	my $soc_state=  def_state("ideal");
	my $main_table = def_table (12, 12, TRUE);
	
	# The box which holds the info, warning, error ...  mesages
	my ($infobox,$info)= create_text();	
	
	
	
	#instances setting box
	my $inst_box= generate_instance_box();
	#simulation setting box
	my $sim_set_box= generate_sim_setting_box();
	#graph setting box
	my $graph_set_box= generate_graph_setting_box();
	#graph box
	my $graph_box= generate_graph_box();
	
	my $refresh_dev_win = Gtk2::Button->new_from_stock('ref');
	my $generate = def_image_button('icons/gen.png','Generate');
	my $genbox=def_hbox(TRUE,5);
	$genbox->pack_start($generate,   FALSE, FALSE,3);
	
	
	

	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
	#my  $device_win=show_active_dev($soc,$lib,$infc,$soc_state,\$refresh_dev_win,$info);
	
	
	#$table->attach_defaults ($event_box, $col, $col+1, $row, $row+1);
	$main_table->attach_defaults ($inst_box, 0, 6, 0,4);
	$main_table->attach_defaults ($sim_set_box, 0, 6, 4,8);
	$main_table->attach_defaults ($graph_box, 6, 12, 0,4);
	$main_table->attach_defaults ($graph_set_box, 6, 12, 4,8);
	$main_table->attach_defaults ($infobox  , 0, 12, 8,12);
	#$main_table->attach_defaults ($genbox, 6, 8, 14,15);

	#check soc status every 0.5 second. referesh device table if there is any changes 
Glib::Timeout->add (100, sub{ 
	 
		my ($state,$timeout)= get_state($soc_state);
		if ($timeout>0){
			$timeout--;
			set_state($soc_state,$state,$timeout);		
		}
		elsif( $state ne "ideal" ){
			$refresh_dev_win->clicked;
			set_state($soc_state,"ideal",0);
			
			
		}	
		return TRUE;
		
		} );
		
		
	$generate-> signal_connect("clicked" => sub{ 
		
		
		$refresh_dev_win->clicked;
	
});

	#show_selected_dev($info,\@active_dev,\$dev_list_refresh,\$dev_table);



#$box->show;
	#$window->add ($main_table);
	$main_table->show_all;
	return $main_table;
	

}

