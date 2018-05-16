#!/usr/bin/perl
use strict;
use warnings;
use GD::Graph::bars3d;
use Glib qw/TRUE FALSE/;





sub gen_multiple_charts{
	my ($self,$pageref,$charts_ref)=@_;
	my @pages=@{$pageref};
	my @charts=@{$charts_ref};
	my $notebook = Gtk2::Notebook->new;
	$notebook->set_scrollable(TRUE);
	$notebook->can_focus(FALSE);



	foreach my $page (@pages){	
		my @selects;
		my $page_id= "P$page->{page_num}";
		my $active = $self->object_get_attribute ($page_id,'active');	
		
		foreach my $chart (@charts){	
			push (@selects,$chart->{graph_name})if($page->{page_num} == $chart->{page_num} );
			
		}
		$active =$selects[0] if (!defined $active);
		
		foreach my $chart (@charts){
			my $graph_id= $page_id."$chart->{graph_name}";
				
			if($active eq $chart->{graph_name} && $page->{page_num} == $chart->{page_num}){
				
				my $p=  gen_graph  ($self,$chart,@selects);
				$notebook->append_page ($p,Gtk2::Label->new_with_mnemonic ($page->{page_name})); 
				$self->object_add_attribute ($graph_id,'type',$chart->{type});	
			}
			
		}
		
		
		#print "$page->{page_name} : @selects \n";
		
	}	
	
		
		
		
	my $scrolled_win = new Gtk2::ScrolledWindow (undef, undef);
	$scrolled_win->set_policy( "automatic", "automatic" );
	$scrolled_win->add_with_viewport($notebook);
	$scrolled_win->show_all;
	
	my $page_num=$self->object_get_attribute ("chart_notebook","currentpage");
	$notebook->set_current_page ($page_num) if(defined $page_num);
	$notebook->signal_connect( 'switch-page'=> sub{			
		$self->object_add_attribute ("chart_notebook","currentpage",$_[2]);	#save the new pagenumber
		#print "$self->object_add_attribute (\"chart_notebook\",\"currentpage\",$_[2]);\n";			
	});
		
	#return ($scrolled_win,$set_win);
	return $scrolled_win;


	

}



sub get_uniq_keys {
	my ($ref,@x)=@_;
	
	if(defined $ref) {
				my %r=%$ref;
				
				push(@x, sort {$a<=>$b} keys %r);
	
	my  @x2;
	@x2 =  uniq(sort {$a<=>$b} @x) if (scalar @x);
	return @x2;	
	}
	return @x;
}


sub gen_graph {
	my ($self,$chart,@selects)=@_;	
	if($chart->{type} eq '2D_line') {return gen_2D_line($self,$chart,@selects);}
	return  gen_3D_bar($self,$chart,@selects);
}





sub gen_3D_bar{
	my ($self,$chart,@selects)=@_;

	my($width,$hight)=max_win_size();
	my $page_id= "P$chart->{page_num}";
	my $graph_id= $page_id."$chart->{graph_name}";
	#my $graph_name=$chart->{graph_name};
	my $result_name= $chart->{result_name};
	
	my @legend_keys;    
	
	
	my @results;
	$results[0]= [0];
	$results[1]= [0];
	#$results[2]= [0];

	

	my $legend_info="This attribute controls placement of the legend within the graph image. The value is supplied as a two-letter string, where the first letter is placement (a B or an R for bottom or right, respectively) and the second is alignment (L, R, C, T, or B for left, right, center, top, or bottom, respectively). ";
	
my $fontsize="Tiny,Small,MediumBold,Large,Giant";



my @ginfo = (
#{ label=>"Graph Title", param_name=>"G_Title", type=>"Entry", default_val=>undef, content=>undef, info=>undef, param_parent=>"${graph_name}_param"    , ref_delay=>undef },  
{ label=>"Y Axix Title", param_name=>"Y_Title", type=>"Entry", default_val=>$chart->{"Y_Title"}, content=>undef, info=>undef, param_parent=>"${graph_id}_param"    , ref_delay=>undef },
  { label=>"X Axix Title", param_name=>"X_Title", type=>"Entry", default_val=>$chart->{"X_Title"}, content=>undef, info=>undef, param_parent=>"${graph_id}_param"    ,ref_delay=>undef },
  { label=>"legend placement", param_name=>"legend_placement", type=>'Combo-box', default_val=>'BL', content=>"BL,BC,BR,RT,RC,RB", info=>$legend_info, param_parent=>"${graph_id}_param"    , ref_delay=>1},
 
 { label=>"Y min", param_name=>"Y_MIN", type=>'Spin-button', default_val=>0, content=>"0,1024,1", info=>"Y axix minimum value", param_parent=>"${graph_id}_param"    , ref_delay=> 5},
 { label=>"X min", param_name=>"X_MIN", type=>'Spin-button', default_val=>0, content=>"0,1024,1", info=>"X axix minimum value", param_parent=>"${graph_id}_param"    , ref_delay=> 5},
{ label=>"X max", param_name=>"X_MAX", type=>'Spin-button', default_val=>100, content=>"0,1024,1", info=>"X axix maximum value", param_parent=>"${graph_id}_param"    , ref_delay=> 5},
 { label=>"Line Width", param_name=>"LINEw", type=>'Spin-button', default_val=>3, content=>"1,20,1", info=>undef, param_parent=>"${graph_id}_param"    , ref_delay=> 5},
#{ label=>"Y Axis Values", param_name=>"y_value", type=>'Combo-box', default_val=>'Original', content=>"Original,Normalized to 1,Normalized to 100", info=>undef, param_parent=>"${graph_name}_param"    , ref_delay=>1},
{ label=>"legend font size", param_name=>"legend_font", type=>'Combo-box', default_val=>'MediumBold', content=>$fontsize, info=>undef, param_parent=>"${graph_id}_param"    , ref_delay=>1}, 
{ label=>"label font size", param_name=>"label_font", type=>'Combo-box', default_val=>'MediumBold', content=>$fontsize, info=>undef, param_parent=>"${graph_id}_param"    , ref_delay=>1},
  { label=>"label font size", param_name=>"x_axis_font", type=>'Combo-box', default_val=>'MediumBold', content=>$fontsize, info=>undef, param_parent=>"${graph_id}_param"    , ref_delay=>1},
);	

my $content=join( ',', @selects);

my $dimention=gen_combobox_object ($self,$graph_id,"dimention","2D,3D","3D",'ref',2);
my $active_page=gen_combobox_object ($self,$page_id,"active",$content,$selects[0],'ref',2);


#print "${graph_name}_${dir}_result\n";		
		my @ratios;
		my @color;
		my $min_y=200;
		my $i=0;
		my @samples =$self->object_get_attribute_order("samples");	
		@samples = ('no_name') if (scalar @samples == 0);
		foreach my $sample (@samples){
			
			my $color_num=$self->object_get_attribute($sample,"color");
			my $l_name= $self->object_get_attribute($sample,"line_name");
			
			
			#push(@color, "my_color$color_num");
			my $ref=$self->object_get_attribute ($sample,$result_name);
			if(defined $ref){
				$i++;
				@ratios=get_uniq_keys($ref,@ratios);
				$color_num=$i+1 if(!defined $color_num);
				push(@color, "my_color$color_num");
				$legend_keys[$i-1]= (defined $l_name)? $l_name : $sample;
			}
			
						
		}#for
	$content = join(",", @ratios); 
	my $ratio_combx=gen_combobox_object ($self,${graph_id},"ratio",$content,$ratios[0],'ref',2);
	
	@color= ("my_color0") if ((scalar @color) ==0);
	@legend_keys=("-")  if ((scalar @legend_keys) ==0);


	my $ymax=10;
	my $ratio = $self->object_get_attribute ($graph_id,"ratio");
	
	
	my @x;
	if (defined $ratio){
		
		foreach my $sample (@samples){
			my $ref=$self->object_get_attribute ($sample,"$result_name");
			if(defined $ref){
				@x=get_uniq_keys($ref->{$ratio},@x);
			}
		}
		my $i=1;
		foreach my $sample (@samples){
			my @y;
			my $ref=$self->object_get_attribute ($sample,"$result_name");
			if(defined $ref){
				foreach my $v (@x){
					my $w=$ref->{$ratio}->{$v};
					push(@y,$w);
					$ymax=$w+1 if($w>$ymax);
				}
				$results[$i]=\@y if(scalar @x);
				$i++;
			}
		}
		
		
		
		
	}
	
	$results[0]=\@x if(scalar @x);
	
	$i=1;
	
	# all results which is larger than ymax will be changed to ymax,
	$i=0;
	
	#foreach my $sample (@samples){
		#$i++;
		#for (my $j=1;$j<=$s; $j++) {
		#	$results[$i][$j]=($results[$i][$j]>$max_y)? $max_y: $results[$i][$j] if (defined $results[$i][$j]);
		#}	
	#}
	
	
	my $graphs_info;
	foreach my $d ( @ginfo){
		$graphs_info->{$d->{param_name}}=$self->object_get_attribute( "${graph_id}_param"    ,$d->{param_name});
		if(!defined $graphs_info->{$d->{param_name}}){
			$graphs_info->{$d->{param_name}}= $d->{default_val}; 
			$self->object_add_attribute( "${graph_id}_param"    ,$d->{param_name},$d->{default_val} );
		}
	}
	
	my $graph_w=$width/2.5;
	my $graph_h=$hight/2.5;
	my $graph = new GD::Graph::bars3d($graph_w, $graph_h);
	my $dim = $self->object_get_attribute (${graph_id},"dimention");
	#my $dir = $self->object_get_attribute ($graph_name,"direction"); 
	my $over= ($dim eq "2D")? 0 : 1;
	$graph->set(
	    overwrite => $over,
	    x_label => $graphs_info->{X_Title},
	    y_label => $graphs_info->{Y_Title},
	    title   => $graphs_info->{G_Title},
	    y_max_value => $ymax,
	    y_tick_number => 18,
	    y_label_skip => 2,
	    x_label_skip => 1,
	    x_all_ticks => 1,
	    x_labels_vertical => 1,
	    box_axis => 0,
	    y_long_ticks => 1,
	    legend_placement => $graphs_info->{legend_placement},
		dclrs=>\@color,
		y_number_format=>"%.1f",
		
		transparent       => '0',
	   	bgclr             => 'white',
	   	boxclr            => 'white',
	   	fgclr             => 'black',
		textclr		  => 'black',
		labelclr	  => 'black',
		axislabelclr	  => 'black',
		legendclr	  =>  'black',
	    #cycle_clrs        => '1',
		
		 # Draw bars with width 3 pixels
    bar_width   => 3,
    # Sepearte the bars with 4 pixels
    bar_spacing => 10,
    # Show the grid
    #long_ticks  => 1,
    # Show values on top of each bar
    #show_values => 1,
    );
    
   
	$graph->set_legend(@legend_keys);
	
	my $font;
	
	$font=  $self->object_get_attribute( "${graph_id}_param"    ,'label_font');
	$graph->set_x_label_font(GD::Font->$font);
  	$graph->set_y_label_font(GD::Font->$font);
	$font=  $self->object_get_attribute( "${graph_id}_param"    ,'legend_font');
	$graph->set_legend_font(GD::Font->$font);

	$font=  $self->object_get_attribute( "${graph_id}_param"    ,'x_axis_font');
  	#$graph->set_values_font(GD::gdGiantFont);
	$graph->set_x_axis_font(GD::Font->$font);
	$graph->set_y_axis_font(GD::Font->$font);
	
	#@results=reorder_result(@results);
	
	my $gd =  $graph->plot( \@results );
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	$loader->write ($gd->png);
	$loader->close;
	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);
	
	write_image ($self,$graph_id,$gd);
	write_image_result	($self,$graph_id,$graph,$result_name,$chart->{type},\@results);
   # my $image = my_get_image($self,$graph,$data,$graph_name);
        
	
        
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
		my $scale= $self->object_get_attribute("${graph_id}_graph_scale",undef);
		$scale = 5 if(!defined $scale);
		$minues -> signal_connect("clicked" => sub{ 
			$self->object_add_attribute("${graph_id}_graph_scale",undef,$scale+0.5);
			set_gui_status($self,"ref",1);	
		});	

		$plus  -> signal_connect("clicked" => sub{ 
			$self->object_add_attribute("${graph_id}_graph_scale",undef,$scale-0.5) if( $scale>0.5);
			set_gui_status($self,"ref",5);
		});	

		$setting -> signal_connect("clicked" => sub{ 
			get_graph_setting ($self,\@ginfo);
		});
		set_tip($setting, "Setting");		
		
		$save-> signal_connect("clicked" => sub{ 
			# my $G = $graph->{graph};
			 my @imags=$graph->export_format();  
			 save_graph_as ($self,\@imags,$graph_id);
		});	
		set_tip($save, "Save graph");
		
		
		
		$table->attach_defaults ($align , 0, 9, 0, 25);
		my $row=0;
		$table->attach (gen_label_in_center('Injection-Ratio'), 9, 10, $row, $row+1,'shrink','shrink',2,2); $row++;
		$table->attach ($ratio_combx, 9, 10, $row, $row+1,'shrink','shrink',2,2); $row++;
		$table->attach ($active_page, 9, 10, $row, $row+1,'shrink','shrink',2,2); $row++;
		$table->attach ($dimention, 9, 10, $row, $row+1,'shrink','shrink',2,2); $row++;
		
		#$table->attach ($plus , 9, 10, $row, $row+1,'shrink','shrink',2,2); $row++;
		#$table->attach ($minues, 9, 10, $row, $row+1,'shrink','shrink',2,2); $row++;
		$table->attach ($setting, 9, 10, $row,  $row+1,'shrink','shrink',2,2); $row++;
		$table->attach ($save, 9, 10, $row,  $row+1,'shrink','shrink',2,2); $row++;
		while ($row<10){
			
			my $tmp=gen_label_in_left('');
			$table->attach_defaults ($tmp, 9, 10, $row,  $row+1);$row++;
		}
		
        return $table;
}














sub gen_2D_line {

	my ($self,$chart,@selects)=@_;	
	my($width,$hight)=max_win_size();
	my $page_id= "P$chart->{page_num}";
	my $graph_id=  $page_id."$chart->{graph_name}";
	#my $graph_name=$chart->{graph_name};
	my $result_name= $chart->{result_name};
	my @x;
	my @legend_keys;    
	
	
	my @results;
	$results[0]=[0];
	$results[1]= [0];
	my $legend_info="This attribute controls placement of the legend within the graph image. The value is supplied as a two-letter string, where the first letter is placement (a B or an R for bottom or right, respectively) and the second is alignment (L, R, C, T, or B for left, right, center, top, or bottom, respectively). ";
	
	my $fontsize="Tiny,Small,MediumBold,Large,Giant";

my $content=join( ',', @selects);
my $active_page=gen_combobox_object ($self,$page_id,"active",$content,$selects[0],'ref',2);



my @ginfo = (
#{ label=>"Graph Title", param_name=>"G_Title", type=>"Entry", default_val=>undef, content=>undef, info=>undef, param_parent=>"${graph_name}_param"    , ref_delay=>undef },  
{ label=>"Y Axis Title", param_name=>"Y_Title", type=>"Entry", default_val=>$chart->{"Y_Title"}, content=>undef, info=>undef, param_parent=>"${graph_id}_param"    , ref_delay=>undef },
  { label=>"X Axis Title", param_name=>"X_Title", type=>"Entry", default_val=>$chart->{"X_Title"}, content=>undef, info=>undef, param_parent=>"${graph_id}_param"    ,ref_delay=>undef },
  { label=>"legend placement", param_name=>"legend_placement", type=>'Combo-box', default_val=>'BL', content=>"BL,BC,BR,RT,RC,RB", info=>$legend_info, param_parent=>"${graph_id}_param"    , ref_delay=>1},
 
 { label=>"Y min", param_name=>"Y_MIN", type=>'Spin-button', default_val=>0, content=>"0,1024,1", info=>"Y axis minimum value", param_parent=>"${graph_id}_param"    , ref_delay=> 5},
 { label=>"X min", param_name=>"X_MIN", type=>'Spin-button', default_val=>0, content=>"0,1024,1", info=>"X axis minimum value", param_parent=>"${graph_id}_param"    , ref_delay=> 5},
{ label=>"X max", param_name=>"X_MAX", type=>'Spin-button', default_val=>100, content=>"0,1024,1", info=>"X axis maximum value", param_parent=>"${graph_id}_param"    , ref_delay=> 5},
 { label=>"Line Width", param_name=>"LINEw", type=>'Spin-button', default_val=>3, content=>"1,20,1", info=>undef, param_parent=>"${graph_id}_param"    , ref_delay=> 5},
#{ label=>"Y Axis Values", param_name=>"y_value", type=>'Combo-box', default_val=>'Original', content=>"Original,Normalized to 1,Normalized to 100", info=>undef, param_parent=>"${graph_name}_param"    , ref_delay=>1},

{ label=>"legend font size", param_name=>"legend_font", type=>'Combo-box', default_val=>'MediumBold', content=>$fontsize, info=>undef, param_parent=>"{$graph_id}_param"    , ref_delay=>1}, 
{ label=>"label font size", param_name=>"label_font", type=>'Combo-box', default_val=>'MediumBold', content=>$fontsize, info=>undef, param_parent=>"${graph_id}_param"    , ref_delay=>1},
  { label=>"label font size", param_name=>"x_axis_font", type=>'Combo-box', default_val=>'MediumBold', content=>$fontsize, info=>undef, param_parent=>"${graph_id}_param"    , ref_delay=>1},
);	





		my @color;
		my $min_y;#=200;
		my $i=0;
		my @samples =$self->object_get_attribute_order("samples");	
		@samples = ('no_name') if (scalar @samples == 0);
		foreach my $sample (@samples){
			my $ref=$self->object_get_attribute ($sample,$result_name);
			$i++;
			my $color_num=$self->object_get_attribute($sample,"color");
			my $l_name= $self->object_get_attribute($sample,"line_name");
			$legend_keys[$i-1]= (defined $l_name)? $l_name : $sample;
			$color_num=$i+1 if(!defined $color_num);
			push(@color, "my_color$color_num");
			
			if(defined $ref) {
				push(@x, sort {$a<=>$b} keys %{$ref});
					    	
		    	}
						
		}#for
		
	my  @x2;
	@x2 =  uniq(sort {$a<=>$b} @x) if (scalar @x);
	
	my  @x1; #remove x values larger than x_max
	my $x_max= $self->object_get_attribute( "${graph_id}_param"    ,'X_MAX');
	foreach  my $p (@x2){
		if(defined $x_max) {push (@x1,$p) if($p<$x_max);}
		else {push (@x1,$p);}
	}

	#print "\@x1=@x1\n";
	if (scalar @x1){
		$results[0]=\@x1;
		$i=0;
		foreach my $sample (@samples){
			$i++;
			my $j=0;
			my $ref=$self->object_get_attribute ($sample,$result_name);
			if(defined $ref){
				#print "$i\n";
				my %line=%$ref;
				foreach my $k (@x1){
					$results[$i][$j]=$line{$k};
					if(defined $line{$k}){
						$min_y = $line{$k} if (!defined $min_y);
						$min_y= $line{$k} if ($line{$k}!=0 && $min_y > $line{$k});
						$j++;
					}
				}#$k
			}#if
			else {
				$results[$i][$j]=undef;
			}					
		}#$i		
	}#if
	
	$min_y = 200 if (!defined $min_y);
	my $scale= $self->object_get_attribute("${graph_id}_graph_scale",undef);
	$scale = 5 if(!defined $scale);

	my $max_y=$min_y* $scale;
	my $s=scalar @x1;
	
	# all results which is larger than ymax will be changed to ymax,
	$i=0;
	
	foreach my $sample (@samples){
		$i++;
		for (my $j=1;$j<=$s; $j++) {
			$results[$i][$j]=($results[$i][$j]>$max_y)? $max_y: $results[$i][$j] if (defined $results[$i][$j]);
		}	
	}
	
	
	my $graphs_info;
	foreach my $d ( @ginfo){
		$graphs_info->{$d->{param_name}}=$self->object_get_attribute( "${graph_id}_param"    ,$d->{param_name});
		if(!defined $graphs_info->{$d->{param_name}}){
			$graphs_info->{$d->{param_name}}= $d->{default_val}; 
			$self->object_add_attribute( "${graph_id}_param"    ,$d->{param_name},$d->{default_val} );
		}
	}
	
	my $graph_w=$width/2.5;
	my $graph_h=$hight/2.5;
	my $graph = Gtk2::Ex::Graph::GD->new($graph_w, $graph_h, 'linespoints');

	$graph->set (
            	x_label         => $graphs_info->{X_Title},
               	y_label         => $graphs_info->{Y_Title},
               	y_max_value     => $max_y,
               	y_min_value		=> $graphs_info->{Y_MIN},
				y_tick_number   => 8,
               #	x_min_value     => $graphs_info->{X_MIN}, # dosent work?
               	title           => $graphs_info->{G_Title},
               	bar_spacing     => 1,
                shadowclr       => 'dred',


		 
		box_axis       => 0,
		skip_undef=> 1,
	   # transparent     => 1,
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
    
   
	$graph->set_legend(@legend_keys);
	
	


	


	my $data = GD::Graph::Data->new(\@results) or die GD::Graph::Data->error;
	$data->make_strict();
	
    my $image = my_get_image($self,$graph,$data,$graph_id,$result_name,$chart->{type});
        
	
        
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
			$self->object_add_attribute("${graph_id}_graph_scale",undef,$scale+0.5);
			set_gui_status($self,"ref",1);	
		});
		set_tip($minues, "Zoom out");	

		$plus  -> signal_connect("clicked" => sub{ 
			$self->object_add_attribute("${graph_id}_graph_scale",undef,$scale-0.5) if( $scale>0.5);
			set_gui_status($self,"ref",5);
		});
		set_tip($plus, "Zoom in");

		$setting -> signal_connect("clicked" => sub{ 
			get_graph_setting ($self,\@ginfo);
		});	
		set_tip($setting, "Setting");			

		$save-> signal_connect("clicked" => sub{ 
			 my $G = $graph->{graph};
			 my @imags=$G->export_format();  
			save_graph_as ($self,\@imags,$graph_id);
		});	
		set_tip($save, "Save graph");
		
		
		
		$table->attach_defaults ($align , 0, 9, 0, 25);
		my $row=0;
		$table->attach ($active_page, 9, 10, $row, $row+1,'shrink','shrink',2,2); $row++;
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
	my ($self,$ref,$graph_name)=@_;
	
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
			
			$self->object_add_attribute("graph_save","name",$file);
			$self->object_add_attribute("graph_save","extension",$ext);
			$self->object_add_attribute("graph_save","save",1);
			$self->object_add_attribute("graph_save","save_result",1);
			$self->object_add_attribute("graph_save","graph_name",$graph_name);
			set_gui_status($self,"ref",1);
					
	      		 }
	     		$dialog->destroy;
}



sub my_get_image {
	my ($self,$exgraph, $data, $graph_name, $result_name,$charttype) = @_;
	$exgraph->{graphdata} = $data;
	my $graph = $exgraph->{graph};
	my $font;
	
	$font=  $self->object_get_attribute( "${graph_name}_param"    ,'label_font');
	$graph->set_x_label_font(GD::Font->$font);
  	$graph->set_y_label_font(GD::Font->$font);
	$font=  $self->object_get_attribute( "${graph_name}_param"    ,'legend_font');
	$graph->set_legend_font(GD::Font->$font);

	$font=  $self->object_get_attribute( "${graph_name}_param"    ,'x_axis_font');
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

	
	write_image ($self,$graph_name,$gd1);
	write_image_result	($self,$graph_name,$graph,$result_name,$charttype);	

	my $image = Gtk2::Image->new_from_pixbuf($loader->get_pixbuf);


	$exgraph->{graphimage} = $image;
	my $hotspotlist;
	if ($exgraph->{graphtype} eq 'bars' or
		$exgraph->{graphtype} eq 'lines' or
		$exgraph->{graphtype} eq 'linespoints') {
		foreach my $hotspot ($graph->get_hotspot) {
			push @$hotspotlist, $hotspot if $hotspot;
		}
	}
	$exgraph->{hotspotlist} = $hotspotlist;
	my $eventbox = $exgraph->{eventbox};
	my @children = $eventbox->get_children;
	foreach my $child (@children) {
		$eventbox->remove($child);
	}
	
	
	
	
#	$eventbox->add ($image);

	
#	$eventbox->show_all;
	return $image;
}



############
#	get_graph_setting
###########

sub get_graph_setting {
	my ($self,$ref)=@_;
	my $window=def_popwin_size(33,33,'Graph Setting','percent');
	my $table = def_table(10, 2, FALSE);
	my $row=0;


my @data=@$ref;
foreach my $d (@data) {
	$row=noc_param_widget ($self, $d->{label}, $d->{param_name}, $d->{default_val}, $d->{type}, $d->{content}, $d->{info}, $table,$row,1, $d->{param_parent}, $d->{ref_delay});
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
		set_gui_status($self,"ref",1);
	});



}



sub write_image {
	my ($self,$graph_name,$image)=@_;
	my $save=$self->object_get_attribute("graph_save","save");
	
	
	my $active_graph=$self->object_get_attribute("graph_save","graph_name");
	$save=0 if (!defined $save);
	$active_graph = 0 if(!defined $active_graph);
	
	if ($save ==1 && $active_graph eq $graph_name){
		my $file=$self->object_get_attribute("graph_save","name");
		my $ext=$self->object_get_attribute("graph_save","extension");
		$self->object_add_attribute("graph_save","save",0);

		#image
		open(my $out, '>', $file);
		if (tell $out )
		{
			warn "Cannot open '$file' to write: $!";  
		}else
		{	
			#my @extens=$graph->export_format();
			binmode $out;
			print $out $image->$ext;# if($ext eq 'png');
			#print $out  $gd1->gif  if($ext eq 'gif');
			close $out;
		}
	}
	
}


sub write_image_result {
	my ($self,$graph_name,$graph,$result_name,$charttype,$result_ref)=@_;
	my $save=$self->object_get_attribute("graph_save","save_result");
	my $active_graph=$self->object_get_attribute("graph_save","graph_name");
	$save=0 if (!defined $save);
	$active_graph = 0 if(!defined $active_graph);
	
	
		
	if ($save ==1 && $active_graph eq $graph_name){
		my $file=$self->object_get_attribute("graph_save","name");
		my $ext=$self->object_get_attribute("graph_save","extension");
		$self->object_add_attribute("graph_save","save_result",0);
		
		open( my $out, '>', "$file.txt");
		if (tell $out )
		{
			warn "Cannot open $file.txt to write: $!";  
		}
		else
		{	
			if($charttype eq '2D_line'){			
			
				my @samples =$self->object_get_attribute_order("samples");
				foreach my $sample (@samples){
						my $l_name= $self->object_get_attribute($sample,"line_name");
						my $ref=$self->object_get_attribute ($sample,$result_name);
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
				} else{
					write_3d_graph_results($self,$out,$result_ref);	
					
					
				}		 
		
			close $out;
		}
	}
}


sub write_3d_graph_results{
	my ($self,$out,$result_ref)=@_;
	
	my @r=@{$result_ref};
	
	my @samples =$self->object_get_attribute_order("samples");
	my $i=0;
	if(defined $r[$i]){
		my @k=@{$r[$i]};
		print $out "@k\n\n";
	}
				
	foreach my $sample (@samples){
		$i++;
		my $l_name= $self->object_get_attribute($sample,"line_name");
		print $out "$l_name:\n";
		if(defined $r[$i]){
			my @k=@{$r[$i]};
			print $out "@k\n\n";
		}	
	}
}				



 ################
 # get_color_window
 ###############
 
 sub get_color_window{
	 my ($self,$atrebute1,$atrebute2)=@_;     
	 my $window=def_popwin_size(40,40,"Select line color",'percent');
	 my ($r,$c)=(4,8);	 
	 my $table= def_table(5,6,TRUE);
	 for (my $col=0;$col<$c;$col++){
		  for (my $row=0;$row<$r;$row++){
			my $color_num=$row*$c+$col;
			my $color=def_colored_button("    ",$color_num);
			$table->attach_defaults ($color, $col, $col+1, $row, $row+1); 
			$color->signal_connect("clicked"=> sub{
				$self->object_add_attribute($atrebute1,$atrebute2,$color_num);
				#print "$self->object_add_attribute($atrebute1,$atrebute2,$color_num);\n";
				set_gui_status($self,"ref",1);
				$window->destroy;
			});
		 }
	 }
	 
	 $window->add($table);
	
	$window->show_all();

}


sub reorder_result{
	my @results=@_;
	
	my @app=(
	"a0","a1","a2","a3","a4","a5","a6","a7","a8","a9","a10","a11"," "," "," "," ",
	"b0","b1","b2","b3","b4","b5","b6","b7","b8","b9","b10","b11","b12","b13","b14","b15"," "," "," "," ",
	"c0","c1","c2","c3","c4","c5","c6","c7","c8","c9","c10","c11"," "," "," "," ",
	"d0","d1","d2","d3","d4","d5","d6","d7","d8");
	
	
	
	my %nmap=(
	"b7" => 0 ,"b9" => 1 ,"b8" => 2 ,"a11"=> 3 ,"b11"=> 4 ,"b12"=> 5 ,"b13"=> 6 ,
	"b6" => 7 ,"b5" => 8 ,"a10"=> 9 ,"a8" => 10,"a9" => 11,"b14"=> 12,"b10"=> 13,
	"b3" => 14,"b4" => 15,"a5" => 16,"a7" => 17,"a2" => 18,"d8" => 19,"d0" => 20, 
	"b2" => 21,"a3" => 22,"a6" => 23,"a0" => 24,"a1" => 25,"d1" => 26,"d2" => 27,
	"b1" => 28,"b15"=> 29,"c2" => 30,"a4" => 31,"d4" => 32,"d3" => 33,"d5" => 34,
	"b0" => 35,"c9" => 36,"c8" => 37,"c3" => 38,"d7" => 39,"d6" => 40,"c7" => 41,
	"c11"=> 42,"c10"=> 43,"c5" => 44,"c4" => 45,"c1" => 46,"c0" => 47,"c6" => 48);
	
	my %worst=(
	"a0" => 0 ,"a8" => 1 ,"b7" => 2 ,"d8"=> 3 ,"b1"=> 4 ,"b5"=> 5 ,"b8"=> 6 ,
	"a5" => 7 ,"c2" => 8 ,"c10"=> 9 ,"c3" => 10,"c5" => 11,"b12"=> 12,"b3"=> 13,
	"d1" => 14,"d7" => 15,"c1" => 16,"c7" => 17,"c0" => 18,"c8" => 19,"b10" => 20, 
	"b15" => 21,"d2" => 22,"c4" => 23,"c6" => 24,"c9" => 25,"d3" => 26,"a4" => 27,
	"b2" => 28,"b13"=> 29,"d4" => 30,"c11" => 31,"d5" => 32,"a2" => 33,"a10" => 34,
	"b6" => 35,"b0" => 36,"d0" => 37,"d6" => 38,"a3" => 39,"a9" => 40,"a6" => 41,
	"b9"=> 42,"b4"=> 43,"b11" => 44,"b14" => 45,"a1" => 46,"a11" => 47,"a7" => 48);
	
	my %rnd=(
	"d3" => 0 ,"d6" => 1 ,"b8" => 2 ,"c10"=> 3 ,"d5" => 4 ,"d8" => 5 ,"a3" => 6 ,
	"b15"=> 7 ,"a9" => 8 ,"c3" => 9 ,"b12"=> 10,"a4" => 11,"b9" => 12,"b6" => 13,
	"d2" => 14,"c2" => 15,"b0" => 16,"b13"=> 17,"a5" => 18,"c9" => 19,"a2" => 20, 
	"c0" => 21,"c7" => 22,"c5" => 23,"b14"=> 24,"b7" => 25,"c4" => 26,"b10"=> 27,
	"d1" => 28,"c6" => 29,"b11"=> 30,"a10"=> 31,"b1" => 32,"c1" => 33,"b5" => 34,
	"d7" => 35,"d4" => 36,"a6" => 37,"a11"=> 38,"a7" => 39,"b2" => 40,"c11" => 41,
	"c8" => 42,"a1" => 43,"a0" => 44,"d0" => 45,"a8" => 46,"b3" => 47,"b4" => 48);
	
	my @r;
	
	my $tile=0;
	foreach my $p (@app){
		
		
		#my $l=$nmap{$p};
		#my $l=$rnd{$p};
		my $l=$worst{$p};
		
		
		$r[0][$tile]=$p;
		$r[1][$tile]=(defined $l)? $results[1][$l]: undef;
		$r[2][$tile]=(defined $l)? $results[2][$l]: undef;
		$tile++;
	}
	
	
	
	return @r;
}	

1;
