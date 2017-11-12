#! /usr/bin/perl -w
use Glib qw/TRUE FALSE/;
use strict;
use warnings;
use Gtk2;
use Gtk2::Ex::Graph::GD;
use GD::Graph::Data;
use emulator;
use IO::CaptureOutput qw(capture qxx qxy);
use GD::Graph::colour qw/:colours/;
use Proc::Background;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep  clock_gettime clock_getres clock_nanosleep clock stat );

use File::Basename;
use File::Path qw/make_path/;
use File::Copy;
use File::Find::Rule;

require "widget.pl"; 
require "emulate_ram_gen.pl"; 
require "mpsoc_gen.pl"; 
require "mpsoc_verilog_gen.pl"; 
require "readme_gen.pl";

use List::MoreUtils qw(uniq);


# hardware parameters taken from noc_emulator.v
use constant PCK_CNTw =>30;  # packet counter width in bits (results in maximum of 2^30 = 1  G packets)
use constant PCK_SIZw =>14;  # packet size width in bits (results in maximum packet size of 2^14 = 16 K flit)
use constant MAXXw    =>4;   # maximum nodes in x dimention is 2^MAXXw equal to 16 nodes in x dimention
use constant MAXYw    =>4;   # 16 nodes in y dimention : hence max emulator size is 16X16
use constant MAXCw    =>4;   # 16 message classes  
use constant RATIOw   =>7;   # log2(100)
use constant MAX_PATTERN => 124;  
use constant RAM_SIZE => (MAX_PATTERN+4);          

    
#use constant MAX_PCK_NUM => (2**PCK_CNTw)-1;
use constant MAX_PCK_NUM => (2**PCK_CNTw)-1;
use constant MAX_PCK_SIZ => (2**PCK_SIZw)-1; 
use constant MAX_SIM_CLKs=> 100000000; # simulation end at if clock counter reach this number           

use constant EMULATION_RTLS => "/mpsoc/src_emulate/rtl/noc_emulator.v , /mpsoc/src_peripheral/jtag/jtag_wb/ , /mpsoc/src_peripheral/ram/generic_ram.v, /mpsoc/src_noc/";





sub gen_chart {
	my $emulate=shift;	
	my($width,$hight)=max_win_size();
	my $graph_w=$width/2.5;
	my $graph_h=$hight/2.5;
	my $graph = Gtk2::Ex::Graph::GD->new($graph_w, $graph_h, 'linespoints');
	my @x;
	my @legend_keys;    
	my $sample_num=$emulate->object_get_attribute("emulate_num",undef);
	my $scale= $emulate->object_get_attribute("graph_scale",undef);
	my @results;
	$results[0]=[0];
	$results[1]= [0];
my $legend_info="This attribute controls placement of the legend within the graph image. The value is supplied as a two-letter string, where the first letter is placement (a B or an R for bottom or right, respectively) and the second is alignment (L, R, C, T, or B for left, right, center, top, or bottom, respectively). ";
	
my $fontsize="Tiny,Small,MediumBold,Large,Giant";



my @ginfo = (
#{ label=>"Graph Title", param_name=>"G_Title", type=>"Entry", default_val=>undef, content=>undef, info=>undef, param_parent=>'graph_param', ref_delay=>undef },  
{ label=>"Y Axix Title", param_name=>"Y_Title", type=>"Entry", default_val=>'Latency (clock)', content=>undef, info=>undef, param_parent=>'graph_param', ref_delay=>undef },
  { label=>"X Axix Title", param_name=>"X_Title", type=>"Entry", default_val=>'Load per router (flits/clock (%))', content=>undef, info=>undef, param_parent=>'graph_param',ref_delay=>undef },
  { label=>"legend placement", param_name=>"legend_placement", type=>'Combo-box', default_val=>'BL', content=>"BL,BC,BR,RT,RC,RB", info=>$legend_info, param_parent=>'graph_param', ref_delay=>1},
 
 { label=>"Y min", param_name=>"Y_MIN", type=>'Spin-button', default_val=>0, content=>"0,1024,1", info=>"Y axix minimum value", param_parent=>'graph_param', ref_delay=> 5},
 { label=>"X min", param_name=>"X_MIN", type=>'Spin-button', default_val=>0, content=>"0,1024,1", info=>"X axix minimum value", param_parent=>'graph_param', ref_delay=> 5},
{ label=>"X max", param_name=>"X_MAX", type=>'Spin-button', default_val=>100, content=>"0,1024,1", info=>"X axix maximum value", param_parent=>'graph_param', ref_delay=> 5},
 { label=>"Line Width", param_name=>"LINEw", type=>'Spin-button', default_val=>3, content=>"1,20,1", info=>undef, param_parent=>'graph_param', ref_delay=> 5},
{ label=>"legend font size", param_name=>"legend_font", type=>'Combo-box', default_val=>'MediumBold', content=>$fontsize, info=>undef, param_parent=>'graph_param', ref_delay=>1}, 
{ label=>"label font size", param_name=>"label_font", type=>'Combo-box', default_val=>'MediumBold', content=>$fontsize, info=>undef, param_parent=>'graph_param', ref_delay=>1},
  { label=>"label font size", param_name=>"x_axis_font", type=>'Combo-box', default_val=>'MediumBold', content=>$fontsize, info=>undef, param_parent=>'graph_param', ref_delay=>1},
);	





	if(defined  $sample_num){
		my @color;
		my $min_y=200;		
		for (my $i=1;$i<=$sample_num; $i++) {
			my $color_num=$emulate->object_get_attribute("sample$i","color");
			my $l_name= $emulate->object_get_attribute("sample$i","line_name");
			$legend_keys[$i-1]= (defined $l_name)? $l_name : "NoC$i";
			$color_num=$i+1 if(!defined $color_num);
			push(@color, "my_color$color_num");
			my $ref=$emulate->object_get_attribute ("sample$i","result");
			if(defined $ref) {
				push(@x, sort {$a<=>$b} keys %{$ref});		    	
		    	}
						
		}#for
	my  @x2;
	@x2 =  uniq(sort {$a<=>$b} @x) if (scalar @x);
	
	my  @x1; #remove x values larger than x_max
	my $x_max= $emulate->object_get_attribute( 'graph_param','X_MAX');
	foreach  my $p (@x2){
		if(defined $x_max) {push (@x1,$p) if($p<$x_max);}
		else {push (@x1,$p);}
	}

	#print "\@x1=@x1\n";
	if (scalar @x1){
		$results[0]=\@x1;
		my $i;
		for ($i=1;$i<=$sample_num; $i++) {
			my $j=0;
			my $ref=$emulate->object_get_attribute ("sample$i","result");
			if(defined $ref){
				#print "$i\n";
				my %line=%$ref;
				foreach my $k (@x1){
					$results[$i][$j]=$line{$k};
					$min_y= $line{$k} if (defined $line{$k} && $line{$k}!=0 && $min_y > $line{$k});
					$j++;
				}#$k
			}#if
			else {
				$results[$i][$j]=undef;

			}
					
		}#$i
		
		
		
	}#if
	my $max_y=$min_y*$scale;
	
	my $s=scalar @x1;
	
	# all results which is larger than ymax will be changed to ymax,
	for (my $i=1;$i<=$sample_num; $i++) {
		for (my $j=1;$j<=$s; $j++) {
			$results[$i][$j]=($results[$i][$j]>$max_y)? $max_y: $results[$i][$j] if (defined $results[$i][$j]);
		}	
	}
	
	
	

	my $graphs_info;
	foreach my $d ( @ginfo){
		$graphs_info->{$d->{param_name}}=$emulate->object_get_attribute( 'graph_param',$d->{param_name});
		if(!defined $graphs_info->{$d->{param_name}}){
			$graphs_info->{$d->{param_name}}= $d->{default_val}; 
			$emulate->object_add_attribute( 'graph_param',$d->{param_name},$d->{default_val} );
		}
	}
	
	 

	$graph->set (
            	x_label         => $graphs_info->{X_Title},
               	y_label         => $graphs_info->{Y_Title},
               	y_max_value     => $max_y,
               	y_min_value	=> $graphs_info->{Y_MIN},
		y_tick_number   => 8,
               #	x_min_value     => $graphs_info->{X_MIN}, # dosent work?
               	title           => $graphs_info->{G_Title},
               	bar_spacing     => 1,
                shadowclr       => 'dred',
		 
		box_axis       => 0,
		skip_undef=> 1,
           #     transparent     => 1,

	 	transparent       => '0',
	   	bgclr             => 'white',
	   	boxclr            => 'white',
	   	fgclr             => 'black',
		textclr		  => 'black',
		labelclr	  => 'black',
		axislabelclr	  => 'black',
		legendclr	  =>  'black',
	   cycle_clrs        => '1',

		line_width 		=> $graphs_info->{LINEw},
	#	cycle_clrs		=> 'black',
		legend_placement => $graphs_info->{legend_placement},
		dclrs=>\@color,
		y_number_format=>"%.1f",
		BACKGROUND=>'black', 
		
       		);
     }#if
	$graph->set_legend(@legend_keys);
	
	


	


	my $data = GD::Graph::Data->new(\@results) or die GD::Graph::Data->error;
	$data->make_strict();
	
        my $image = my_get_image($emulate,$graph,$data);
        
	
        
      # print  Data::Dumper->Dump ([\@results],['ttt']); 
        
        
        
        
        my $table = Gtk2::Table->new (25, 10, FALSE);
        
           
		my $box = Gtk2::HBox->new (TRUE, 2);
		my $filename;
		$box->set_border_width (4);
		my   $align = Gtk2::Alignment->new (0.5, 0.5, 0, 0);
		my $frame = Gtk2::Frame->new;
		$frame->set_shadow_type ('in');
		$frame->add ($image);
		$align->add ($frame);
		
		
		my $plus = def_image_button('icons/plus.png',undef,TRUE);
		my $minues = def_image_button('icons/minus.png',undef,TRUE);
		my $setting = def_image_button('icons/setting.png',undef,TRUE);
		my $save = def_image_button('icons/save.png',undef,TRUE);

		$minues -> signal_connect("clicked" => sub{ 
			$emulate->object_add_attribute("graph_scale",undef,$scale+0.5);
			set_gui_status($emulate,"ref",1);	
		});	

		$plus  -> signal_connect("clicked" => sub{ 
			$emulate->object_add_attribute("graph_scale",undef,$scale-0.5) if( $scale>0.5);
			set_gui_status($emulate,"ref",5);
		});	

		$setting -> signal_connect("clicked" => sub{ 
			get_graph_setting ($emulate,\@ginfo);
		});	
		
		$save-> signal_connect("clicked" => sub{ 
			 my $G = $graph->{graph};
			 my @imags=$G->export_format();  
			save_graph_as ($emulate,\@imags);
		});	
		
		
		
		
		$table->attach_defaults ($align , 0, 9, 0, 25);
		my $row=0;
		$table->attach ($plus , 9, 10, $row, $row+1,'shrink','shrink',2,2); $row++;
		$table->attach ($minues, 9, 10, $row, $row+1,'shrink','shrink',2,2); $row++;
		$table->attach ($setting, 9, 10, $row,  $row+1,'shrink','shrink',2,2); $row++;
		$table->attach ($save, 9, 10, $row,  $row+1,'shrink','shrink',2,2); $row++;
		while ($row<10){
			
			my $tmp=gen_label_in_left('');
			$table->attach_defaults ($tmp, 9, 10, $row,  $row+1);$row++;
		}
		
        return $table;
	
}


##############
#	save_graph_as
##############

sub save_graph_as {
	my ($emulate,$ref)=@_;
	
	my $file;
	my $title ='Save as';



	my @extensions=@$ref;
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
			
			$emulate->object_add_attribute("graph_save","name",$file);
			$emulate->object_add_attribute("graph_save","extension",$ext);
			$emulate->object_add_attribute("graph_save","save",1);
			set_gui_status($emulate,"ref",1);


					
	      		 }
	     		$dialog->destroy;
	       		


	 


}




sub my_get_image {
	my ($emulate,$self, $data) = @_;
	$self->{graphdata} = $data;
	my $graph = $self->{graph};
	my $font;
	
	$font=  $emulate->object_get_attribute( 'graph_param','label_font');
	$graph->set_x_label_font(GD::Font->$font);
  	$graph->set_y_label_font(GD::Font->$font);
	$font=  $emulate->object_get_attribute( 'graph_param','legend_font');
	$graph->set_legend_font(GD::Font->$font);

	$font=  $emulate->object_get_attribute( 'graph_param','x_axis_font');
  	#$graph->set_values_font(GD::gdGiantFont);
	$graph->set_x_axis_font(GD::Font->$font);
	$graph->set_y_axis_font(GD::Font->$font);

	my $gd2=$graph->plot($data) or warn $graph->error;
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	
	
	#cut the upper side of the image to remove the stright line created by chaanging large results to ymax
       
	
	my $gd1=  GD::Image->new($gd2->getBounds);
	my $white= $gd1->colorAllocate(255,255,254);
	my ($x,$h)=$gd2->getBounds;
	$gd1->transparent($white);
	$gd1->copy( $gd2, 0, 0, 0, ,$h*0.05, $x ,$h*.95 );
	
	
	$loader->write ($gd1->png);
	$loader->close;

	my $save=$emulate->object_get_attribute("graph_save","save");
	$save=0 if (!defined $save);	
	if ($save ==1){
		my $file=$emulate->object_get_attribute("graph_save","name");
		my $ext=$emulate->object_get_attribute("graph_save","extension");
		$emulate->object_add_attribute("graph_save","save",0);

		#image
		open(my $out, '>', $file);
		if (tell $out )
		{
			warn "Cannot open '$file' to write: $!";  
		}else
		{	
			#my @extens=$graph->export_format();
			binmode $out;
			print $out $gd1->$ext;# if($ext eq 'png');
			#print $out  $gd1->gif  if($ext eq 'gif');
			close $out;
		}
		#text_file
		open(  $out, '>', "$file.txt");
		if (tell $out )
		{
			warn "Cannot open $file.txt to write: $!";  
		}
		else
		{	
			my $sample_num=$emulate->object_get_attribute("emulate_num",undef);			
			if (defined  $sample_num){
				for (my $i=1;$i<=$sample_num; $i++) {
					my $l_name= $emulate->object_get_attribute("sample$i","line_name");
					my $ref=$emulate->object_get_attribute ("sample$i","result");
					my @x;
					if(defined $ref) {
						
						print $out "$l_name\n";
						foreach my $x (sort {$a<=>$b} keys %{$ref}) {
							my $y=$ref->{$x};
							print $out "\t$x , $y\n";
						}
						print $out "\n\n";
					}				
				}#for

			} 
		
			close $out;
		}

	}
	
		

	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);


	$self->{graphimage} = $image;
	my $hotspotlist;
	if ($self->{graphtype} eq 'bars' or
		$self->{graphtype} eq 'lines' or
		$self->{graphtype} eq 'linespoints') {
		foreach my $hotspot ($graph->get_hotspot) {
			push @$hotspotlist, $hotspot if $hotspot;
		}
	}
	$self->{hotspotlist} = $hotspotlist;
	my $eventbox = $self->{eventbox};
	my @children = $eventbox->get_children;
	foreach my $child (@children) {
		$eventbox->remove($child);
	}
	
	
	
	
	$eventbox->add ($image);

	$eventbox->signal_connect ('button-press-event' => 
		sub {
			my ($widget, $event) = @_;
			return TRUE;
			return FALSE unless $event->button == 3;
			$self->{optionsmenu}->popup(
				undef, # parent menu shell
				undef, # parent menu item
				undef, # menu pos func
				undef, # data
				$event->button,
				$event->time
			);
		}
	);	
	$eventbox->show_all;
	return $eventbox;
}


############
#	get_graph_setting
###########

sub get_graph_setting {
	my ($emulate,$ref)=@_;
	my $window=def_popwin_size(33,33,'Graph Setting','percent');
	my $table = def_table(10, 2, FALSE);
	my $row=0;


my @data=@$ref;
foreach my $d (@data) {
	$row=noc_param_widget ($emulate, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay});
}
	
	
	
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	my $ok = def_image_button('icons/select.png',' OK ');
	
	
	my $mtable = def_table(10, 1, FALSE);
	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable->attach($ok,0,1,9,10,'shrink','shrink',2,2);
	$window->add ($mtable);
	$window->show_all();
	
	$ok-> signal_connect("clicked" => sub{ 
		$window->destroy;
		set_gui_status($emulate,"ref",1);
	});



}












 ################
 # get_color_window
 ###############
 
 sub get_color_window{
	 my ($emulate,$atrebute1,$atrebute2)=@_;     
	 my $window=def_popwin_size(40,40,"Select line color",'percent');
	 my ($r,$c)=(4,8);	 
	 my $table= def_table(5,6,TRUE);
	 for (my $col=0;$col<$c;$col++){
		  for (my $row=0;$row<$r;$row++){
			my $color_num=$row*$c+$col;
			my $color=def_colored_button("    ",$color_num);
			$table->attach_defaults ($color, $col, $col+1, $row, $row+1); 
			$color->signal_connect("clicked"=> sub{
				$emulate->object_add_attribute($atrebute1,$atrebute2,$color_num);
				#print "$emulate->object_add_attribute($atrebute1,$atrebute2,$color_num);\n";
				set_gui_status($emulate,"ref",1);
				$window->destroy;
			});
		 }
	 }
	 
	 $window->add($table);
	
	$window->show_all();

}




sub check_inserted_ratios {
		my $str=shift;
		my @ratios;
	    	
	    my @chunks=split(',',$str);
	    foreach my $p (@chunks){
			if($p !~ /^[0-9.:,]+$/){ message_dialog ("$p has invalid character(S)" ); return undef; }
			my @range=split(':',$p);
			my $size= scalar @range;
			if($size==1){ # its a number
				if ( $range[0] <= 0 || $range[0] >100  ) { message_dialog ("$range[0] is out of boundery (1:100)" ); return undef; }
				push(@ratios,$range[0]);
			}elsif($size ==3){# its a range
				my($min,$max,$step)=@range;
				if ( $min <= 0 || $min >100  ) { message_dialog ("$min in  $p is out of boundery (1:100)" ); return undef; }
				if ( $max <= 0 || $max >100  ) { message_dialog ("$max in  $p is out of boundery (1:100)" ); return undef; }
				for (my $i=$min; $i<=$max; $i=$i+$step){
						push(@ratios,$i);
				}			
				
			}else{
				 message_dialog ("$p has invalid format. The correct format for range is \$min:\$max:\$step" );
				
			}
			
			
			
		}#foreach
		my @r=uniq(sort {$a<=>$b} @ratios);
		return \@r;
			
}







sub get_injection_ratios{
		my ($emulate,$atrebute1,$atrebute2)=@_;
		my $box = Gtk2::HBox->new( FALSE, 0 );
		my $init=$emulate->object_get_attribute($atrebute1,$atrebute2);
		my $entry=gen_entry($init);
		my $button=def_image_button("icons/right.png",'Check');		
		$button->signal_connect("clicked" => sub {
			my $text= $entry->get_text();
			my $r=check_inserted_ratios($text);	
			if(defined 	$r){	
				my $all=  join (',',@$r);
				message_dialog ("$all" );
			}
			
			
		});	
		$entry->signal_connect ("changed" => sub {	
			my $text= $entry->get_text();
			$emulate->object_add_attribute($atrebute1,$atrebute2,$text);
			
		});	
		$box->pack_start( $entry, 1,1, 0);
		$box->pack_start( $button, 0, 1, 3);
		return 	$box;
}



sub get_noc_configuration{
	my ($emulate,$mode,$n,$set_win) =@_;
	
	my $table=def_table(10,2,FALSE);
	my $row=0;
		
		
	my $traffics="tornado,transposed 1,transposed 2,bit reverse,bit complement,random"; #TODO hot spot for emulator
	my $dir = Cwd::getcwd();
	if($mode eq "simulate"){
		$traffics=$traffics.",hot spot";
		my $open_in	  = abs_path("$ENV{PRONOC_WORK}/simulate");	
		attach_widget_to_table ($table,$row,gen_label_in_left("Verilated file:"),gen_button_message ("Select the the verilator simulation file. Different NoC simulators can be generated using Generate NoC configuration tab.","icons/help.png"), get_file_name_object ($emulate,"sample$n","sof_file",undef,$open_in)); $row++;
		
	}else{
		
		my $open_in	  = abs_path("$ENV{PRONOC_WORK}/emulate/sof");	
		attach_widget_to_table ($table,$row,gen_label_in_left("SoF file:"),gen_button_message ("Select the SRAM Object File (sof) for this NoC configration.","icons/help.png"), get_file_name_object ($emulate,"sample$n","sof_file",'sof',$open_in)); $row++;
	}

   my @emulateinfo = (
	{ label=>'Configuration name:', param_name=>'line_name', type=>'Entry', default_val=>"NoC$n", content=>undef, info=>"NoC configration name. This name will be shown in load-latency graph for this configuration", param_parent=>"sample$n", ref_delay=> undef},

  	{ label=>"Traffic name", param_name=>'traffic', type=>'Combo-box', default_val=>'random', content=>$traffics, info=>"Select traffic pattern", param_parent=>"sample$n", ref_delay=>undef},

{ label=>"Packet size in flit:", param_name=>'PCK_SIZE', type=>'Spin-button', default_val=>4, content=>"2,".MAX_PCK_SIZ.",1", info=>undef, param_parent=>"sample$n", ref_delay=>undef},

	{ label=>"Packet number limit per node:", param_name=>'PCK_NUM_LIMIT', type=>'Spin-button', default_val=>1000000, content=>"2,".MAX_PCK_NUM.",1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>"sample$n", ref_delay=>undef},

{ label=>"Emulation clocks limit:", param_name=>'SIM_CLOCK_LIMIT', type=>'Spin-button', default_val=>MAX_SIM_CLKs, content=>"2,".MAX_SIM_CLKs.",1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>"sample$n", ref_delay=>undef},

	
);



	my @siminfo = (
	{ label=>'Configuration name:', param_name=>'line_name', type=>'Entry', default_val=>"NoC$n", content=>undef, info=>"NoC configration name. This name will be shown in load-latency graph for this configuration", param_parent=>"sample$n", ref_delay=> undef, new_status=>undef},

  	{ label=>"Traffic name", param_name=>'traffic', type=>'Combo-box', default_val=>'random', content=>$traffics, info=>"Select traffic pattern", param_parent=>"sample$n", ref_delay=>1, new_status=>'ref_set_win'},

	{ label=>"Packet size in flit:", param_name=>'PCK_SIZE', type=>'Spin-button', default_val=>4, content=>"2,".MAX_PCK_SIZ.",1", info=>undef, param_parent=>"sample$n", ref_delay=>undef},

	{ label=>"Total packet number limit:", param_name=>'PCK_NUM_LIMIT', type=>'Spin-button', default_val=>200000, content=>"2,".MAX_PCK_NUM.",1", info=>"Simulation will stop when total numbr of sent packets by all nodes reaches packet number limit  or total simulation clock reach its limit", param_parent=>"sample$n", ref_delay=>undef, new_status=>undef},

	{ label=>"Simulator clocks limit:", param_name=>'SIM_CLOCK_LIMIT', type=>'Spin-button', default_val=>100000, content=>"2,".MAX_SIM_CLKs.",1", info=>"Each node stops sending packets when it reaches packet number limit  or simulation clock number limit", param_parent=>"sample$n", ref_delay=>undef,  new_status=>undef},
	);

my @hotspot_info=(
	{ label=>'Hot Spot num:', param_name=>'HOTSPOT_NUM', type=>'Spin-button', default_val=>1, 
	  content=>"1,5,1", info=>"Number of hot spot nodes in the network", 
	  param_parent=>"sample$n", ref_delay=> 1, new_status=>'ref_set_win'},
	{ label=>'Hot Spot traffic percentage:', param_name=>'HOTSPOT_PERCENTAGE', type=>'Spin-button', default_val=>1, 
	  content=>"1,20,1", info=>"If it is set as n then each node sends n % of its traffic to each hotspot node", 
	  param_parent=>"sample$n", ref_delay=> undef, new_status=>undef},
	
	);
	
	
	
	
	
	
	my @info= ($mode eq "simulate")? @siminfo : @emulateinfo; 
	
		
	foreach my $d ( @info) {
	$row=noc_param_widget ($emulate, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
	}
	my $traffic=$emulate->object_get_attribute("sample$n","traffic");

	if ($traffic eq 'hot spot'){
		foreach my $d ( @hotspot_info) {
			$row=noc_param_widget ($emulate, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay}, $d->{new_status});
		}
		my $num=$emulate->object_get_attribute("sample$n","HOTSPOT_NUM");
		for (my $i=0;$i<$num;$i++){
			my $m=$i+1;
			$row=noc_param_widget ($emulate, "Hotspot $m tile num:", "HOTSPOT_CORE_$m", 0, 'Spin-button', "0,256,1",
			 "Defne the tile number which is  hotspt. All other nodes will send [Hot Spot traffic percentage] of their traffic to this node ", $table,$row,1,"sample$n" );
		
			
		}
	
	}



		my $l= "Define injection ratios. You can define individual ratios seprating by comma (\',\') or define a range of injection ratios with \$min:\$max:\$step format.
			As an example defining 2,3,4:10:2 will result in (2,3,4,6,8,10) injection ratios." ;
		my $u=get_injection_ratios ($emulate,"sample$n","ratios");
		
attach_widget_to_table ($table,$row,gen_label_in_left("Injection ratios:"),gen_button_message ($l,"icons/help.png") , $u); $row++;
	
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
		
	my $ok = def_image_button('icons/select.png','OK');
	my $mtable = def_table(10, 1, TRUE);

	$mtable->attach_defaults($scrolled_win,0,1,0,9);
	$mtable-> attach ($ok , 0, 1,  9, 10,'expand','shrink',2,2); 
	
	$set_win->add ($mtable);
	$set_win->show_all();

	$set_win ->signal_connect (destroy => sub{
		
		$emulate->object_add_attribute("active_setting",undef,undef);
	});



		
		
		
	 
	
	
	
	
	$ok->signal_connect("clicked"=> sub{
		#check if sof file has been selected
		my $s=$emulate->object_get_attribute("sample$n","sof_file");
		#check if injection ratios are valid
		my $r=$emulate->object_get_attribute("sample$n","ratios");
		if(defined $s && defined $r) {	
				$set_win->destroy;
				#$emulate->object_add_attribute("active_setting",undef,undef);
				set_gui_status($emulate,"ref",1);
		} else {
			
			if(!defined $s){
				my $m=($mode eq 'simulate') ? "Please select NoC verilated file" : "Please select sof file!";
				message_dialog($m);  
			} else {
				 message_dialog("Please define valid injection ratio(s)!");
			}
		}
	});
	
		


	
		
		
		
	
	
}	
	 

      
#####################
#		gen_widgets_column
###################      
      
sub gen_emulation_column {
	my ($emulate,$mode, $row_num,$info)=@_;
	my $table=def_table($row_num,10,FALSE);
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	my $set_win=def_popwin_size(40,80,"NoC configuration setting",'percent');
		
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);	
	my $row=0;
	
	#title	
	my $title_l =($mode eq "simulate" ) ? "NoC Simulator" : "NoC Emulator";
	my $title=gen_label_in_center($title_l);
	my $box=def_vbox(FALSE, 1);
	$box->pack_start( $title, FALSE, FALSE, 3);
	my $separator = Gtk2::HSeparator->new;
	$box->pack_start( $separator, FALSE, FALSE, 3);
	$table->attach_defaults ($box , 0, 10,  $row, $row+1); $row++;
	
	
	
	my $lb=($mode ne "simulate" ) ?  gen_label_in_left("Number of emulations"): gen_label_in_left("Number of simulations");
	my $spin= gen_spin_object ($emulate,"emulate_num",undef,"1,100,1",1,'ref','1');
	$table->attach  ($lb, 0, 2, $row, $row+1,'expand','shrink',2,2);
	$table->attach  ($spin, 2, 4, $row, $row+1,'expand','shrink',2,2);
	
	
	#my $mod=gen_combobox_object ($emulate,'mode',undef, 'Emulation,Simulation','Emulation','ref','1');


	
	 
	#$table->attach  ($lb, 4, 6, $row, $row+1,'expand','shrink',2,2);
	#$table->attach  ($mod, 6, 8, $row, $row+1,'expand','shrink',2,2);
$row++; 




	
	$separator = Gtk2::HSeparator->new;	
	$table->attach_defaults ($separator  , 0, 10,  $row, $row+1); $row++;

	my @positions=(0,1,2,3,6,7);
	my $col=0;
	
	my @title=(" Name", " Configuration Setting   ", "Line's color", "Clear Graph","  ");
	foreach my $t (@title){
		
		$table->attach (gen_label_in_left($title[$col]), $positions[$col], $positions[$col+1], $row, $row+1,'fill','shrink',2,2);$col++;
	}
	
	my $traffics="Random,Transposed 1,Transposed 2,Tornado";

	$col=0;
	$row++;
	@positions=(0,1,2,3,4,5,6,7);
	
	my $sample_num=$emulate->object_get_attribute("emulate_num",undef);
	 if(!defined $sample_num){
	 	$sample_num=1;
	 	$emulate->object_add_attribute("emulate_num",undef,1);
	 }
	my $i=0;
	my $active=$emulate->object_get_attribute("active_setting",undef);
	for ($i=1;$i<=$sample_num; $i++){
		$col=0;
		my $sample="sample$i";
		my $n=$i;
		my $set=def_image_button("icons/setting.png");
		my $name=$emulate->object_get_attribute($sample,"line_name");
		my $l;
		my $s=$emulate->object_get_attribute("sample$n","sof_file");
		#check if injection ratios are valid
		my $r=$emulate->object_get_attribute("sample$n","ratios");
		if(defined $s && defined $r && defined $name){
			 $l=gen_label_in_left(" $i- ".$name); 
		} else {
			$l=gen_label_in_left("Define NoC configuration");
			$l->set_markup("<span  foreground= 'red' ><b>Define NoC configuration</b></span>");			 
		}
		#my $box=def_pack_hbox(FALSE,0,(gen_label_in_left("$i- "),$l,$set));
		$table->attach ($l, $positions[$col], $positions[$col+1], $row, $row+1,'fill','shrink',2,2);$col++;
		$table->attach ($set, $positions[$col], $positions[$col+1], $row, $row+1,'shrink','shrink',2,2);$col++;

		
		if(defined $active){#The setting windows ask for refershing so open it again
			get_noc_configuration($emulate,$mode,$n,$set_win) if	($active ==$n);
		}
		
		
		
		$set->signal_connect("clicked"=> sub{
			$emulate->object_add_attribute("active_setting",undef,$n);
			get_noc_configuration($emulate,$mode,$n,$set_win);
		});
		
		
		
		my $color_num=$emulate->object_get_attribute($sample,"color");
		if(!defined $color_num){
			$color_num = $i+1;
			$emulate->object_add_attribute($sample,"color",$color_num);
		}
		my $color=def_colored_button("    ",$color_num);
		$table->attach ($color, $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;
		
		
		
	
		
		
		$color->signal_connect("clicked"=> sub{
			get_color_window($emulate,$sample,"color");
		});
		
		#clear line
		my $clear = def_image_button('icons/clear.png');
		$clear->signal_connect("clicked"=> sub{
			$emulate->object_add_attribute ($sample,'result',undef);
			set_gui_status($emulate,"ref",2);
		});
		$table->attach ($clear, $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;
		#run/pause
		my $run = def_image_button('icons/run.png','Run');
		$table->attach ($run, $positions[$col], $positions[$col+1], $row, $row+1,'expand','shrink',2,2);$col++;
		$run->signal_connect("clicked"=> sub{
			$emulate->object_add_attribute ($sample,"status","run");
			#start the emulator if it is not running	
			my $status= $emulate->object_get_attribute('status',undef);
			if($status ne 'run'){
				
				run_emulator($emulate,$info) if($mode eq 'emulate');
				run_simulator($emulate,$info) if($mode eq 'simulate');  
				set_gui_status($emulate,"ref",2);
			}
			
		});
		
		my $image = gen_noc_status_image($emulate,$i);
		
		$table->attach_defaults ($image, $positions[$col], $positions[$col+1], $row, $row+1);
		
		
		$row++;
		
	}
	while ( $row<15){
		$table->attach_defaults (gen_label_in_left(' '), 0, 1, $row, $row+1); $row++;
	}




	return ($scrolled_win,$set_win);
}	      




##########
#
##########

sub check_sample{
	my ($emulate,$i,$info)=@_;
	my $status=1;
	my $sof=$emulate->object_get_attribute ("sample$i","sof_file");
	
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/../../"); #mpsoc directory address
	$sof= "$project_dir/$sof"   if(!(-f $sof));
	
	
	# ckeck if sample have sof file
	if(!defined $sof){
		add_info($info, "Error: SoF file has not set for NoC$i!\n");
		$emulate->object_add_attribute ("sample$i","status","failed");	
		$status=0;
	} else {
		# ckeck if sof file has info file 
		my ($name,$path,$suffix) = fileparse("$sof",qr"\..[^.]*$");
		my $sof_info= "$path$name.inf";
		if(!(-f $sof_info)){
			add_info($info, "Could not find $name.inf file in $path. An information file is required for each sof file containig the device name and  NoC configuration. Press F4 for more help.\n");
			$emulate->object_add_attribute ("sample$i","status","failed");	
			$status=0;
		}else { #add info
			my $pp= do $sof_info ;

			my $p=$pp->{'noc_param'};
			




			$status=0 if $@;
			message_dialog("Error reading: $@") if $@;
			if ($status==1){
				$emulate->object_add_attribute ("sample$i","noc_info",$p) ;
					#print"hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh\n";
			
			}
			
			
			
		}		
	}
				
	
	return $status;
	
	
}




##########
#  run external commands
##########





sub run_cmd_in_back_ground
{
  my $command = shift;
 


	


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

    # This while loop will cause Gtk2 to conti processing events, if
    # there are events pending... *which there are...
    while (Gtk2->events_pending) {
      Gtk2->main_iteration;
    }
    Gtk2::Gdk->flush;

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

  print "\t*RETCODE == $retcode\n\n";
  Gtk2::Gdk->flush;
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
	capture { $exit=run_cmd_in_back_ground($cmd) } \$stdout, \$stderr;
	return ($stdout,$exit,$stderr);
	
}	


#############
#  images
##########
sub get_status_gif{
		my $emulate=shift;
		my $status= $emulate->object_get_attribute('status',undef);
		if($status eq 'ideal'){
			return show_gif ("icons/ProNoC.png");
		} elsif ($status eq 'run') {
			my($width,$hight)=max_win_size();
			my $image=($width>=1600)? "icons/hamster_l.gif":
			          ($width>=1200)? "icons/hamster_m.gif": "icons/hamster_s.gif"; 
				  
			return show_gif ($image);			
		} elsif ($status eq 'programer_failed') {
			return show_gif ("icons/Error.png");			
		}
	
}	




sub gen_noc_status_image {
	my ($emulate,$i)=@_;
	my   $status= $emulate->object_get_attribute ("sample$i","status");	
	 $status='' if(!defined  $status);
	my $image;
	my $vbox = Gtk2::HBox->new (TRUE,1);
	$image = Gtk2::Image->new_from_file ("icons/load.gif") if($status eq "run");
	$image = def_icon("icons/button_ok.png") if($status eq "done");
	$image = def_icon("icons/cancel.png") if($status eq "failed");
	#$image_file = "icons/load.gif" if($status eq "run");
	
	if (defined $image) {
		my $align = Gtk2::Alignment->new (0.5, 0.5, 0, 0);
     	my $frame = Gtk2::Frame->new;
		$frame->set_shadow_type ('in');
		# Animation
		$frame->add ($image);
		$align->add ($frame);
		$vbox->pack_start ($align, FALSE, FALSE, 0);
	}
	return $vbox;
	
}


############
#	run_emulator
###########

sub run_emulator {
	my ($emulate,$info)=@_;
	#return if(!check_samples($emulate,$info));
	$emulate->object_add_attribute('status',undef,'run');
	set_gui_status($emulate,"ref",1);
	show_info($info, "start emulation\n");

	#search for available usb blaster
	my $cmd = "jtagconfig";
	my ($stdout,$exit)=run_cmd_in_back_ground_get_stdout("$cmd");
	my @matches= ($stdout =~ /USB-Blaster.*/g);
	my $usb_blaster=$matches[0];
  	if (!defined $usb_blaster){
		add_info($info, "jtagconfig could not find any USB blaster cable: $stdout \n");
		$emulate->object_add_attribute('status',undef,'programer_failed');
		set_gui_status($emulate,"ref",2);
		#/***/
		return;	
	}else{
		add_info($info, "find $usb_blaster\n");
	}
	my $sample_num=$emulate->object_get_attribute("emulate_num",undef);
	for (my $i=1; $i<=$sample_num; $i++){
		my $status=$emulate->object_get_attribute ("sample$i","status");	
		next if($status ne "run");
		next if(!check_sample($emulate,$i,$info));
		my $r= $emulate->object_get_attribute("sample$i","ratios");
		my @ratios=@{check_inserted_ratios($r)};
		#$emulate->object_add_attribute ("sample$i","status","run");			
		my $sof=$emulate->object_get_attribute ("sample$i","sof_file");	
		my $dir = Cwd::getcwd();
		my $project_dir	  = abs_path("$dir/../../"); #mpsoc directory address
		$sof= "$project_dir/$sof"   if(!(-f $sof));	
		
		add_info($info, "Programe FPGA device using $sof\n");
		my $Quartus_bin=  $ENV{QUARTUS_BIN};
			

		my $cmd = "$Quartus_bin/quartus_pgm -c \"$usb_blaster\" -m jtag -o \"p;$sof\"";
	
		#my $output = `$cmd 2>&1 1>/dev/null`;           # either with backticks



		#/***/
		my ($stdout,$exit)=run_cmd_in_back_ground_get_stdout("$cmd");	
		if($exit){#programming FPGA board has failed
			$emulate->object_add_attribute('status',undef,'programer_failed');
			add_info($info, "$stdout\n");
			$emulate->object_add_attribute ("sample$i","status","failed");	
			set_gui_status($emulate,"ref",2);
			next;			
		}
		#print "$stdout\n";
		
		# read noc configuration 
		
		
		
		
			
		foreach  my $ratio_in (@ratios){						
	    	
		    	add_info($info, "Configure packet generators for  injection ratio of $ratio_in \% \n");
		    	next if(!programe_pck_gens($emulate,$i,$ratio_in,$info));
		    	
		    	my $avg=read_pack_gen($emulate,$i,$info);
			next if (!defined $avg);
		    	my $ref=$emulate->object_get_attribute ("sample$i","result");
		    	my %results;
		    	%results= %{$ref} if(defined $ref);
		    	#push(@results,$avg);
		    	$results{$ratio_in}=$avg;
		    	$emulate->object_add_attribute ("sample$i","result",\%results);
		    	set_gui_status($emulate,"ref",2);
	    		    	
		}
		$emulate->object_add_attribute ("sample$i","status","done");	
    	
	}
	
	add_info($info, "End emulation!\n");
	$emulate->object_add_attribute('status',undef,'ideal');
	set_gui_status($emulate,"ref",1);
}










sub process_notebook_gen{
		my ($emulate,$info,$mode)=@_;
		my $notebook = Gtk2::Notebook->new;
		$notebook->set_tab_pos ('left');
		$notebook->set_scrollable(TRUE);
		$notebook->can_focus(FALSE);

		
		my ($page1,$set_win)=gen_emulation_column($emulate, $mode,10,$info);
		$notebook->append_page ($page1,Gtk2::Label->new_with_mnemonic ("  _Run emulator  ")) if($mode eq "emulate");
		$notebook->append_page ($page1,Gtk2::Label->new_with_mnemonic ("  _Run simulator ")) if($mode eq "simulate");
		
		
		my $page2=get_noc_setting_gui ($emulate,$info,$mode);
		my $pp=$notebook->append_page ($page2,Gtk2::Label->new_with_mnemonic (" _Generate NoC \n Configuration"));
		
		
		
		
		my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
		$scrolled_win->set_policy( "automatic", "automatic" );
		$scrolled_win->add_with_viewport($notebook);
		$scrolled_win->show_all;	
		my $page_num=$emulate->object_get_attribute ("process_notebook","currentpage");		
		$notebook->set_current_page ($page_num) if(defined $page_num);
		$notebook->signal_connect( 'switch-page'=> sub{			
			$emulate->object_add_attribute ("process_notebook","currentpage",$_[2]);	#save the new pagenumber
					
		});
		
		return ($scrolled_win,$set_win);
	
}


sub get_noc_setting_gui {
	my ($emulate,$info_text,$mode)=@_;
	my $table=def_table(20,10,FALSE);#	my ($row,$col,$homogeneous)=@_;
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($table);
	my $row=noc_config ($emulate,$table);
	    
	my($label,$param,$default,$content,$type,$info);
	my @dirs = grep {-d} glob("../src_emulate/fpga/*");
	my $fpgas;
	foreach my $dir (@dirs) {
		my ($name,$path,$suffix) = fileparse("$dir",qr"\..[^.]*$");
		$default=$name;
		$fpgas= (defined $fpgas)? "$fpgas,$name" : "$name";
		
	}
	
			
my @fpgainfo;
	
	if($mode eq "emulate"){
	
	@fpgainfo = (
	{ label=>'FPGA board', param_name=>'FPGA_BOARD', type=>'Combo-box', default_val=>undef, content=>$fpgas, info=>undef, param_parent=>'fpga_param', ref_delay=> undef},
  	{ label=>'Save as:', param_name=>'SAVE_NAME', type=>"Entry", default_val=>'emulate1', content=>undef, info=>undef, param_parent=>'fpga_param', ref_delay=>undef},
	{ label=>"Project directory", param_name=>"SOF_DIR", type=>"DIR_path", default_val=>"$ENV{'PRONOC_WORK'}/emulate", content=>undef, info=>"Define the working directory for generating .sof file", param_parent=>'fpga_param',ref_delay=>undef },

);	

}
else {

@fpgainfo = (
	#{ label=>'FPGA board', param_name=>'FPGA_BOARD', type=>'Combo-box', default_val=>undef, content=>$fpgas, info=>undef, param_parent=>'fpga_param', ref_delay=> undef},
  	{ label=>'Save as:', param_name=>'SAVE_NAME', type=>"Entry", default_val=>'simulate1', content=>undef, info=>undef, param_parent=>'sim_param', ref_delay=>undef},
	{ label=>"Project directory", param_name=>"BIN_DIR", type=>"DIR_path", default_val=>"$ENV{'PRONOC_WORK'}/simulate", content=>undef, info=>"Define the working directory for generating simulation executable binarry file", param_parent=>'sim_param',ref_delay=>undef },

);	
}


	

foreach my $d (@fpgainfo) {
	$row=noc_param_widget ($emulate, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay});
}





	   
	   	
	   
	   
	    	my $generate = def_image_button('icons/gen.png','Generate');
		
	   
		$table->attach ($generate, 0,3, $row, $row+1,'expand','shrink',2,2);
      
		$generate->signal_connect ('clicked'=> sub{
			generate_sof_file($emulate,$info_text) if($mode eq "emulate");
			generate_sim_bin_file($emulate,$info_text) if($mode eq "simulate");
			
		});
		
	    
	    return $scrolled_win;	
	
}







sub generate_sof_file {
	my ($emulate,$info)=@_;	
		print "start compilation\n";
		my $fpga_board=  $emulate->object_get_attribute ('fpga_param',"FPGA_BOARD");
		#create work directory
		my $dir_name=$emulate->object_get_attribute ('fpga_param',"SOF_DIR");
		$dir_name="$dir_name/$fpga_board";
		my $save_name=$emulate->object_get_attribute ('fpga_param',"SAVE_NAME"); 
		$save_name=$fpga_board if (!defined $save_name);
		$dir_name= "$dir_name/$save_name";

		show_info($info, "generate working directory: $dir_name\n");
		
		
		#copy all noc source codes
		my @files = split(/\s*,\s*/,EMULATION_RTLS);

		my $dir = Cwd::getcwd();
		my $project_dir	  = abs_path("$dir/../../");
		my ($stdout,$exit)=run_cmd_in_back_ground_get_stdout("mkdir -p $dir_name/src/" );
		
			
		
		copy_file_and_folders(\@files,$project_dir,"$dir_name/src/");
		
		foreach my $f(@files){
    			my $n="$project_dir/$f";
    			if (!(-f "$n") && !(-f "$f" ) && !(-d "$n") && !(-d "$f" )     ){
    			 	add_info ($info, " WARNING: file/folder  \"$f\" ($n)  dose not exists \n"); 
    			 	
    			 }
    			
    		
    		}		

		

		
		
		#copy fpga board files
		
		($stdout,$exit)=run_cmd_in_back_ground_get_stdout("cp -Rf \"$project_dir/mpsoc/src_emulate/fpga/$fpga_board\"/*    \"$dir_name/\""); 
		if($exit != 0 ){ 	print "$stdout\n"; 	message_dialog($stdout); return;}
		
		#generate parameters for emulator_top.v file
		my ($localparam, $pass_param)=gen_noc_param_v( $emulate);
		open(FILE,  ">$dir_name/src/noc_parameters.v") || die "Can not open: $!";
		print FILE $localparam;
		close(FILE) || die "Error closing file: $!";
		open(FILE,  ">$dir_name/src/pass_parameters.v") || die "Can not open: $!";
		print FILE $pass_param;
		close(FILE) || die "Error closing file: $!";
				
		
		#compile the code  
		my $Quartus_bin=  $ENV{QUARTUS_BIN};
		add_info($info, "Start Quartus compilation\n $stdout\n");
		my @compilation_command =("cd \"$dir_name/\" \n	xterm  	-e $Quartus_bin/quartus_map --64bit $fpga_board --read_settings_files=on ",
					  "cd \"$dir_name/\" \n	xterm  	-e $Quartus_bin/quartus_fit --64bit $fpga_board --read_settings_files=on ",
					  "cd \"$dir_name/\" \n	xterm  	-e $Quartus_bin/quartus_asm --64bit $fpga_board --read_settings_files=on ",
					  "cd \"$dir_name/\" \n	xterm  	-e $Quartus_bin/quartus_sta --64bit $fpga_board ");





		foreach my $cmd (@compilation_command){
			($stdout,$exit)=run_cmd_in_back_ground_get_stdout( $cmd);
			if($exit != 0){			
				print "Quartus compilation failed !\n";
				add_info($info, "Quartus compilation failed !\n$cmd\n $stdout\n");
				return;
			}
			
		}

 
		
			#save sof file
			my $sofdir="$ENV{PRONOC_WORK}/emulate/sof";
			mkpath("$sofdir/$fpga_board/",1,01777);
			open(FILE,  ">$sofdir/$fpga_board/$save_name.inf") || die "Can not open: $!";
			print FILE perl_file_header("$save_name.inf");
			my %pp;
			$pp{'noc_param'}= $emulate->{'noc_param'};
			$pp{'fpga_param'}= $emulate->{'fpga_param'};
			print FILE Data::Dumper->Dump([\%pp],["emulate_info"]);
			close(FILE) || die "Error closing file: $!";	


			#find  $dir_name -name \*.sof -exec cp '{}' $sofdir/$fpga_board/$save_name.sof" 
			@files = File::Find::Rule->file()
                            ->name( '*.sof' )
                            ->in( "$dir_name" );
			copy($files[0],"$sofdir/$fpga_board/$save_name.sof") or do { 
				my $err= "Error copy($files[0] , $sofdir/$fpga_board/$save_name.sof";	
				print "$err\n"; 	
				message_dialog($err); 
				return;
			};
			message_dialog("sof file has been generated successfully");	
		
		
		
}

##########
#	save_emulation
##########
sub save_emulation {
	my ($emulate)=@_;
	# read emulation name
	my $name=$emulate->object_get_attribute ("emulate_name",undef);	
	my $s= (!defined $name)? 0 : (length($name)==0)? 0 :1;	
	if ($s == 0){
		message_dialog("Please set emulation name!");
		return 0;
	}
	# Write object file
	open(FILE,  ">lib/emulate/$name.EML") || die "Can not open: $!";
	print FILE perl_file_header("$name.EML");
	print FILE Data::Dumper->Dump([\%$emulate],[$name]);
	close(FILE) || die "Error closing file: $!";
	message_dialog("Emulation saved as lib/emulate/$name.EML!");
	return 1;
}

#############
#	load_emulation
############

sub load_emulation {
	my ($emulate,$info)=@_;
	my $file;
	my $dialog = Gtk2::FileChooserDialog->new(
            	'Select a File', undef,
            	'open',
            	'gtk-cancel' => 'cancel',
            	'gtk-ok'     => 'ok',
        	);

	my $filter = Gtk2::FileFilter->new();
	$filter->set_name("EML");
	$filter->add_pattern("*.EML");
	$dialog->add_filter ($filter);
	my $dir = Cwd::getcwd();
	$dialog->set_current_folder ("$dir/lib/emulate");		


	if ( "ok" eq $dialog->run ) {
		$file = $dialog->get_filename;
		my ($name,$path,$suffix) = fileparse("$file",qr"\..[^.]*$");
		if($suffix eq '.EML'){
			my $pp= eval { do $file };
			if ($@ || !defined $pp){		
				add_info($info,"**Error reading  $file file: $@\n");
				 $dialog->destroy;
				return;
			} 

			clone_obj($emulate,$pp);
			#message_dialog("done!");				
		}					
     }
     $dialog->destroy;
}

############
#    main
############
sub emulator_main{
	
	add_color_to_gd();
	my $emulate= emulator->emulator_new();
	set_gui_status($emulate,"ideal",0);
	my $left_table = Gtk2::Table->new (25, 6, FALSE);
	my $right_table = Gtk2::Table->new (25, 6, FALSE);

	my $main_table = Gtk2::Table->new (25, 12, FALSE);
	my ($infobox,$info)= create_text();	
	my $refresh = Gtk2::Button->new_from_stock('ref');
	

	
	
	
	my ($conf_box,$set_win)=process_notebook_gen($emulate,\$info,"emulate");
	my $chart   =gen_chart  ($emulate);
    


	$main_table->set_row_spacings (4);
	$main_table->set_col_spacings (1);
	
	#my  $device_win=show_active_dev($soc,$soc,$infc,$soc_state,\$refresh,$info);
	
	
	my $generate = def_image_button('icons/forward.png','Run all');
	my $open = def_image_button('icons/browse.png','Load');
	
	
	
	
	my ($entrybox,$entry) = def_h_labeled_entry('Save as:',undef);
	$entry->signal_connect( 'changed'=> sub{
		my $name=$entry->get_text();
		$emulate->object_add_attribute ("emulate_name",undef,$name);	
	});	
	my $save = def_image_button('icons/save.png','Save');
	$entrybox->pack_end($save,   FALSE, FALSE,0);
	

	#$table->attach_defaults ($event_box, $col, $col+1, $row, $row+1);
	my $image = get_status_gif($emulate);
	
	
	
	
	
	$left_table->attach_defaults ($conf_box , 0, 6, 0, 20);
	$left_table->attach_defaults ($image , 0, 6, 20, 24);
	$left_table->attach ($open,0, 3, 24,25,'expand','shrink',2,2);
	$left_table->attach ($entrybox,3, 6, 24,25,'expand','shrink',2,2);
	$right_table->attach_defaults ($infobox  , 0, 6, 0,12);
	$right_table->attach_defaults ($chart , 0, 6, 12, 24);
	$right_table->attach ($generate, 4, 6, 24,25,'expand','shrink',2,2);
	$main_table->attach_defaults ($left_table , 0, 6, 0, 25);
	$main_table->attach_defaults ($right_table , 6, 12, 0, 25);
	
	

	#referesh the mpsoc generator 
	$refresh-> signal_connect("clicked" => sub{ 
		my $name=$emulate->object_get_attribute ("emulate_name",undef);	
		$entry->set_text($name) if(defined $name);


		$conf_box->destroy();
		$set_win->destroy();
		$chart->destroy();
		$image->destroy(); 
		$image = get_status_gif($emulate);
		
		($conf_box,$set_win)=process_notebook_gen($emulate,\$info,"emulate");
		$chart   =gen_chart  ($emulate);
		$left_table->attach_defaults ($image , 0, 6, 20, 24);
		$left_table->attach_defaults ($conf_box , 0, 6, 0, 12);
		$right_table->attach_defaults ($chart , 0, 6, 12, 24);

		$conf_box->show_all();
		$main_table->show_all();


	});



	#check soc status every 0.5 second. referesh device table if there is any changes 
	Glib::Timeout->add (100, sub{ 
	 
		my ($state,$timeout)= get_gui_status($emulate);
		
		if ($timeout>0){
			$timeout--;
			set_gui_status($emulate,$state,$timeout);	
			
		}
		elsif($state eq 'ref_set_win'){
			my $s=$emulate->object_get_attribute("active_setting",undef);
			$set_win->destroy();
			$emulate->object_add_attribute("active_setting",undef,$s);
			$refresh->clicked;
			#my $saved_name=$mpsoc->mpsoc_get_mpsoc_name();
			#if(defined $saved_name) {$entry->set_text($saved_name);}
			set_gui_status($emulate,"ideal",0);
			
		}
		elsif( $state ne "ideal" ){
			$refresh->clicked;
			#my $saved_name=$mpsoc->mpsoc_get_mpsoc_name();
			#if(defined $saved_name) {$entry->set_text($saved_name);}
			set_gui_status($emulate,"ideal",0);
			
		}	
		return TRUE;
		
	} );
		
		
	$generate-> signal_connect("clicked" => sub{ 
		my $sample_num=$emulate->object_get_attribute("emulate_num",undef);
		for (my $i=1; $i<=$sample_num; $i++){
			$emulate->object_add_attribute ("sample$i","status","run");	
		}
		run_emulator($emulate,\$info);
		#set_gui_status($emulate,"ideal",2);

	});

#	$wb-> signal_connect("clicked" => sub{ 
#		wb_address_setting($mpsoc);
#	
#	});

	$open-> signal_connect("clicked" => sub{ 
		
		load_emulation($emulate,\$info);
		set_gui_status($emulate,"ref",5);
	
	});	

	$save-> signal_connect("clicked" => sub{ 
		save_emulation($emulate);		
		set_gui_status($emulate,"ref",5);
		
	
	});	

	my $sc_win = new Gtk2::ScrolledWindow (undef, undef);
		$sc_win->set_policy( "automatic", "automatic" );
		$sc_win->add_with_viewport($main_table);	

	return $sc_win;
	

}







############
#	run_simulator
###########

sub run_simulator {
	my ($simulate,$info)=@_;
	#return if(!check_samples($emulate,$info));
	$simulate->object_add_attribute('status',undef,'run');
	set_gui_status($simulate,"ref",1);
	show_info($info, "Start Simulation\n");
	my $name=$simulate->object_get_attribute ("simulate_name",undef);	
	my $log= (defined $name)? "$ENV{PRONOC_WORK}/simulate/$name.log": "$ENV{PRONOC_WORK}/simulate/sim.log";
	#unlink $log; # remove old log file
	
	my $sample_num=$simulate->object_get_attribute("emulate_num",undef);
	for (my $i=1; $i<=$sample_num; $i++){
		my $status=$simulate->object_get_attribute ("sample$i","status");	
		next if($status ne "run");
		next if(!check_sample($simulate,$i,$info));
		my $r= $simulate->object_get_attribute("sample$i","ratios");
		my @ratios=@{check_inserted_ratios($r)};
		#$emulate->object_add_attribute ("sample$i","status","run");			
		my $bin=$simulate->object_get_attribute ("sample$i","sof_file");
		my $dir = Cwd::getcwd();
		my $project_dir	  = abs_path("$dir/../../"); #mpsoc directory address
		$bin= "$project_dir/$bin"   if(!(-f $bin));
		
		#load traffic configuration
		my $patern=$simulate->object_get_attribute ("sample$i",'traffic');
		my $PCK_SIZE=$simulate->object_get_attribute ("sample$i","PCK_SIZE");
		my $PCK_NUM_LIMIT=$simulate->object_get_attribute ("sample$i","PCK_NUM_LIMIT");
		my $SIM_CLOCK_LIMIT=$simulate->object_get_attribute ("sample$i","SIM_CLOCK_LIMIT");
		
		
		my $HOTSPOT_PERCENTAGE=$simulate->object_get_attribute ("sample$i",'HOTSPOT_PERCENTAGE');
    	my $HOTSPOT_NUM=$simulate->object_get_attribute ("sample$i","HOTSPOT_NUM");           
   		my $HOTSPOT_CORE_1=$simulate->object_get_attribute ("sample$i","HOTSPOT_CORE_1");
    	my $HOTSPOT_CORE_2=$simulate->object_get_attribute ("sample$i","HOTSPOT_CORE_2");
    	my $HOTSPOT_CORE_3=$simulate->object_get_attribute ("sample$i","HOTSPOT_CORE_3");
    	my $HOTSPOT_CORE_4=$simulate->object_get_attribute ("sample$i","HOTSPOT_CORE_4");
    	my $HOTSPOT_CORE_5=$simulate->object_get_attribute ("sample$i","HOTSPOT_CORE_5");
			
		$HOTSPOT_PERCENTAGE = 0 if (!defined $HOTSPOT_PERCENTAGE);
		$HOTSPOT_NUM=0 if (!defined $HOTSPOT_NUM);           
   		$HOTSPOT_CORE_1=0 if (!defined $HOTSPOT_CORE_1);
    	$HOTSPOT_CORE_2=0 if (!defined $HOTSPOT_CORE_2);
    	$HOTSPOT_CORE_3=0 if (!defined $HOTSPOT_CORE_3);
    	$HOTSPOT_CORE_4=0 if (!defined $HOTSPOT_CORE_4);
    	$HOTSPOT_CORE_5=0 if (!defined $HOTSPOT_CORE_5);
		
		
		
		
		
				
		
		foreach  my $ratio_in (@ratios){						
	    	
		    	add_info($info, "Run $bin with  injection ratio of $ratio_in \% \n");
		    	my $cmd="$bin -t \"$patern\"  -s $PCK_SIZE  -n  $PCK_NUM_LIMIT  -c	$SIM_CLOCK_LIMIT   -i $ratio_in -p \"100,0,0,0,0\"  -h \"$HOTSPOT_PERCENTAGE,$HOTSPOT_NUM,$HOTSPOT_CORE_1,$HOTSPOT_CORE_2,$HOTSPOT_CORE_3,$HOTSPOT_CORE_4,$HOTSPOT_CORE_5\"";
				add_info($info, "$cmd \n");
				my $time_strg = localtime;
				append_text_to_file($log,"started at:$time_strg\n"); #save simulation output
	 			my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout("$cmd");
	 			if($exit){
	 				add_info($info, "Error in running simulation: $stderr \n");
	 				$simulate->object_add_attribute ("sample$i","status","failed");	
	 				$simulate->object_add_attribute('status',undef,'ideal');
	 				return;
	 			}
	 			
	 			append_text_to_file($log,$stdout); #save simulation output
	 			$time_strg = localtime;
	 			append_text_to_file($log,"Ended at:$time_strg\n"); #save simulation output
	 			my @q =split  (/average latency =/,$stdout);
				my $d=$q[1];
				@q =split  (/\n/,$d);
				my $avg=$q[0];
				#my $avg = sprintf("%.1f", $avg);
		    	   	
		    	
		    	
		    	
		    	next if (!defined $avg);
		    	my $ref=$simulate->object_get_attribute ("sample$i","result");
		    	my %results;
		    	%results= %{$ref} if(defined $ref);
		    	#push(@results,$avg);
		    	$results{$ratio_in}=$avg;
		    	$simulate->object_add_attribute ("sample$i","result",\%results);
		    	set_gui_status($simulate,"ref",2);
		    	
		    	
		    	
		    	
		    	
	    		    	
		}
		$simulate->object_add_attribute ("sample$i","status","done");	
    	
	}
	
	add_info($info, "Simulation is done!\n");
	$simulate->object_add_attribute('status',undef,'ideal');
	set_gui_status($simulate,"ref",1);
}
	
	



