#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use Consts;

use constant::boolean;


use Data::Dumper;
use File::Basename;
use Cwd 'abs_path';

use base 'Class::Accessor::Fast';

use Consts;
BEGIN {
    my $module = (Consts::GTK_VERSION==2) ? 'Gtk2' : 'Gtk3';
    my $file = $module;
    $file =~ s[::][/]g;
    $file .= '.pm';
    require $file;
    $module->import;
}


require "widget.pl"; 


__PACKAGE__->mk_accessors(qw{
	window
	sourceview
	buffer
	filename
	search_regexp
	search_case
	search_entry
	regexp
	highlighted
	open_list_ref
	source_view_notebook
	menue
	modified
	label
	ask_to_save
	close_b
});





my $NAME = 'ProNoC';
my 	$path = "";
our $FONT_SIZE='default';
our $ICON_SIZE='default';

exit gtk_gui_run(\&software_main_stand_alone) unless caller;


sub software_main_stand_alone(){
	$path = "../../";
	
	set_path_env();
	my $project_dir	  = get_project_dir(); #mpsoc dir addr
	my $paths_file= "$project_dir/mpsoc/perl_gui/lib/Paths";
	if (-f 	$paths_file){#} && defined $ENV{PRONOC_WORK} ) {
		my $paths= do $paths_file;
		my %p=%{$paths};
		$FONT_SIZE= $p{'GUI_SETTING'}{'FONT_SIZE'} if (defined $p{'GUI_SETTING'}{'FONT_SIZE'});
		$ICON_SIZE= $p{'GUI_SETTING'}{'ICON_SIZE'} if (defined $p{'GUI_SETTING'}{'ICON_SIZE'});
	}
	
	set_defualt_font_size();
	my ($app,$table,$tview,$window) = software_main("../../../../../back/tmp",undef,) ;
	$window->signal_connect (destroy => sub { gui_quite();});	
}
	
 



sub software_main {
	my ($sw,$file,$pages_ref,$label_ref) = @_;

	

	my $app = __PACKAGE__->new();
	my ($table,$tview,$widget)=$app->build_gui($sw,$pages_ref,$label_ref);
	my $main_c=(defined $file)? "$sw/$file" : "$sw/main.c";
	my @tmp;
	$app->open_list_ref(\@tmp);
	$app->ask_to_save(def_button());
	$app->load_source($main_c) if (-f $main_c );
	return ($app,$table,$tview,$widget);
}




sub build_gui {
	my ($app,$sw,$pages_ref,$label_ref) = @_;

	
	my $table= def_table(2,10,FALSE);	
	
	my $vbox = def_vbox(FALSE, 0);
	my $scwin_text = add_widget_to_scrolled_win($vbox);

	my ($scwin_info,$tview)= create_txview();
	my ($tree_view,$tree_store) =$app->build_tree_view($sw);
	my $scwin_dirs = add_widget_to_scrolled_win($tree_view);


	my $hpaned = gen_hpaned($scwin_dirs,0.15,$scwin_text);
	my $vpaned = gen_vpaned($hpaned,0.6,$scwin_info);

	$table->attach_defaults ($vpaned,0, 10, 0,1);

	my $window = def_popwin_size (84,84,'Source Editor','percent');
		
	my @menue_item=("$sw/",$window,$tree_view,$tree_store,$scwin_dirs);	
	$app->menue(\@menue_item);	
	if (defined $pages_ref){
		#first page is software editor
		my $notebook = gen_notebook();
		
		my $label1=def_image_label($path."icons/binary.png","Software Editor",1);
		$notebook->append_page ($table,$label1);
		$label1->show_all;
		
		
		my @pages=@{$pages_ref};
		my @labels=@{$label_ref};
		my $i=0;
		foreach my $page (@pages){
			my $label=$labels[$i];
			$notebook->append_page ($page,$label);
			$label->show_all;
			$i++;	
		}
		$notebook->show_all;
		$notebook->set_current_page(0);
		$window -> add ( $notebook);
	}else {
		$window -> add ( $table);
	}
	
	$app->window($window);

	
	my $hbox = def_table(FALSE, 0);
	my $source_view_notebook = gen_notebook();
	$vbox->pack_start($hbox, FALSE, FALSE, 0);	
	$vbox->pack_start($source_view_notebook, TRUE, TRUE, 0);
	
	
	
	
	$app->source_view_notebook($source_view_notebook);
    $window->show_all();
	
	$window->signal_connect ('delete_event'=> sub {
		$app->ask_to_save_changes();		
		return 0;
		
	}); 
	
	
	
	
	
	return ($table,$tview,$window);
}

sub ask_to_save_changes{
	my $app=shift;
	my $save = $app->ask_to_save();
	$save->clicked;	
}

sub update_modified {
	my $self=shift;
	if($self->modified() ==2 ){
		$self->set_source_label_modified(FALSE);
		return;
	}
	elsif($self->modified() ==FALSE ){
	   	#if ($buffer->get_modified()){
	   		$self->set_source_label_modified(TRUE);
	   	#}
	}	
}

sub new_source_view{
	my ($app,$filename)=@_;
	
    my $self = __PACKAGE__->new();
    my ($name,$p,$suffix) = fileparse("$filename",qr"\..[^.]*$");	
	my $label = gen_label_in_left ("${name}${suffix}");
    $self->modified(2);#initial 
	$self->label($label);
	$self->filename($filename);
	
	my $hbox = def_table(FALSE, 0);
	my $vbox = def_vbox(FALSE, 0);
	my $ref =$app->menue();	
	my ($sw,$window,$tree_view,$tree_store,$scwin_dirs) =@{$ref};	
    $hbox->attach($self->build_menu($sw,$window,$tree_view,$tree_store,$scwin_dirs,$app), 0, 1, 0,1,'shrink','shrink',2,2);
  	
	$hbox->attach_defaults($self->build_search_box, 1,2,0,1);
    $vbox->pack_start($hbox, FALSE, FALSE, 0);
    
	my $buffer = $self->create_SourceView_buffer();
	my $sourceview = gen_SourceView_with_buffer($buffer);
	$sourceview->signal_connect('key-press-event' => sub { handle_key( @_,$self ) } );
	$sourceview->set_show_line_numbers(TRUE);
	$sourceview->set_tab_width(2);
	$sourceview->set_indent_on_tab(TRUE);
	$sourceview->set_highlight_current_line(TRUE);
	
	
    #	$sourceview->set_draw_spaces(['tab', 'newline']);
	#
	# Fix TextView's annoying paste behaviour when pasting with the mouse
	# (middle button click). By default gtk will scroll the text view to the
	# original place where the cursor is.
	#
	$sourceview->signal_connect(button_press_event => sub {
		my ($view, $event) = @_;

		# We're only interested on middle mouse clicks (mouse-paste)
		return FALSE unless $event->button == 2;

		# Remember the position of the paste
		my (@coords) = $sourceview->window_to_buffer_coords('text', $event->x, $event->y);
		my ($iter) = $sourceview->get_iter_at_position(@coords);
		$self->{paste_mark} = $buffer->create_mark('paste', $iter, FALSE);

		return FALSE;
	});


	#
	# If a paste is done through the middle click then place the cursor at the end
	# of the pasted text.
	#
	$buffer->signal_connect('paste-done' => sub {
		my $mark = delete $self->{paste_mark} or return;

		my $iter = $buffer->get_iter_at_mark($mark);
		$buffer->place_cursor($iter);

		$self->sourceview->scroll_to_mark(
			$mark,
			0.0,
			FALSE,
			0.0, 0.5
		);
		$buffer->delete_mark($mark);
	});

	$buffer->signal_connect('insert-text' => sub {
		update_modified($self);		
	});
	$buffer->signal_connect('delete-range' => sub {
		update_modified($self);		
	});
	


	my $scroll = add_widget_to_scrolled_win($sourceview);
	$vbox->pack_start($scroll, TRUE, TRUE, 0);
	$self->sourceview($sourceview);
	$self->buffer($sourceview->get_buffer);


	my $notebook = $app->source_view_notebook();
	my $close = def_button('x');
	
	my $box = def_hbox(FALSE,0);
	$box->pack_start($label, TRUE, FALSE, 0);
	$box->pack_start($close, TRUE, FALSE, 0);	
	$notebook->append_page ($vbox,$box);
	set_tip($box,"$filename");
	$box->show_all;
	$notebook->show_all();
	my $n= $notebook->get_n_pages();
	$notebook->set_current_page($n-1);
	#save $sourceview ref in $app
	my %srcviews;
	my $ref2 = $app->sourceview();
	if(defined $ref2){
		%srcviews =%{$ref2};
	}
	$srcviews{$n-1}=$self;
	$app->sourceview(\%srcviews);
	
	
	$close->signal_connect("clicked" => sub {
		#check if the file has been modified or not
		if($self->modified()==TRUE){
			my $r=create_dialog ("Save changes to documnet ${name}${suffix}?","If you do'nt save, changes will be permanently lost.",$path."icons/help.png","Save","Close without saving","Cancel");
			return if ($r eq "Cancel");
			if ($r eq "Save"){
				$self->do_save();
			}
			
		}
		$vbox->destroy;
		$box->destroy;
		$self = undef;
		my $ref =$app->open_list_ref();
		my @new =remove_scolar_from_array($ref,$filename);
		$app->open_list_ref(\@new);
		
	});
	
	my $save = $app->ask_to_save();
    
    $save->signal_connect("clicked" => sub {
		#check if the file has been modified or not
		return if(!defined $self);
		if($self->modified()==TRUE){
			my $r=create_dialog ("Save changes to documnet ${name}${suffix}?"," ",$path."icons/help.png","Save","Continue without saving");
			return if ($r eq "Continue without saving");
			if ($r eq "Save"){
				$self->do_save();
			}
			
		}		
	});    
		
	$self->close_b($close);	
	return $self;	
}



sub build_tree_view{
	my ($app,$sw)=@_;

	# Directory name, full path
	my ($tree_store,$tree_view) =file_edit_tree();
	
#	$tree_view->signal_connect (button_release_event => sub{
	$tree_view->signal_connect (row_activated  => sub{
		my $tree_model = $tree_view->get_model();
	 	my $selection = $tree_view->get_selection();
	 	my $iter = $selection->get_selected();
	 		
	 	if(defined $iter){
			my $path = $tree_model->get($iter, 1) ;
			$path= substr $path, 0, -1;
			#$self->do_save();
			#print "open $path\n";
			 $app->load_source($path) if(-f $path);
		}
		 return;
	});


	$tree_view->signal_connect ('row-expanded' => sub {
		my ($tree_view, $iter, $tree_path) = @_;
	 	my $tree_model = $tree_view->get_model();
		my ($dir, $path) = $tree_model->get($iter);
		
		# for each of $iter's children add any subdirectories
		my $child = $tree_model->iter_children ($iter);
		
		
		my $r;
		$r=$tree_model->iter_is_valid($child);
		while ($child && $r ==1) {
						
	  		my ($dir, $path) = $tree_model->get($child, 0, 1);
	  		add_to_tree($tree_view,$tree_store, $child, $dir, $path);
	  		$child=treemodel_next_iter($child , $tree_model);
	  		$r=$tree_model->iter_is_valid($child) if (defined $child);
	  		
	 	}
		 return;
});

my $child = $tree_store->append(undef);
	
$tree_store->set($child, 0, $sw, 1, '/');
add_to_tree($tree_view,$tree_store, $child, '/', "$sw/");
return ($tree_view,$tree_store);

}



sub build_search_box {
	my $self = shift;

	# Elements of the search box
	my $hbox = def_hbox(FALSE, 0);

	my $search_entry = gen_entry();
	$search_entry->signal_connect(activate => sub {$self->do_search()});
	$search_entry->signal_connect(icon_release => sub {$self->do_search()});
	$self->search_entry($search_entry);

	my $search_regexp = gen_checkbutton('RegExp');
	$search_regexp->signal_connect(toggled => sub {
		$self->search_regexp($search_regexp->get_active);
	});

	my $search_case = gen_checkbutton('Case');
	$search_case->signal_connect(toggled => sub {
		$self->search_case($search_case->get_active);
	});

	
	
	my $search_icon = def_image_button($path."icons/browse.png");
	$search_entry->set_icon_from_stock(primary => 'gtk-find');

	
	$hbox->pack_start($search_entry, TRUE, TRUE , 0);
	$hbox->pack_start($search_regexp, FALSE, FALSE, 0);
	$hbox->pack_start($search_case, FALSE, FALSE, 0);

	return $hbox;
}

sub refresh_source {
	my $app = shift;
	my ($filename) = abs_path(@_);
	
	
	my $ref =$app->open_list_ref();
	my @open_list;
	@open_list = @{$ref} if(defined $ref); 
	#check if the file is opend before activate its notebook win, remove its content
	my $pos=get_scolar_pos ($filename,@open_list);
	my $self;
	if (defined $pos){
		my $notebook = $app->source_view_notebook();
		$notebook->set_current_page($pos);
		
		my $ref = $app->sourceview();
		if(defined $ref){
			my %srcviews =%{$ref};
			my $n = $notebook->get_current_page;
			$self=$srcviews{$n};
		}else {		
			return;
		}		
	}
	else {
		$self=new_source_view($app,"$filename");
		push(@open_list,$filename);
		$app->open_list_ref(\@open_list);
	
	}
	my $buffer = $self->buffer;

	# Guess the programming language of the file
	$self->detect_language($filename);

	# Loading a file should not be undoable.
	my $content;
	do {
		open my $handle, $filename or die "Can't read file $filename because $!";
		local $/;
		$content = <$handle>;
		close $handle;
	};
	$buffer->begin_not_undoable_action();
	$buffer->set_text($content);
	$buffer->end_not_undoable_action();

	#$buffer->set_modified(FALSE);
	$buffer->place_cursor($buffer->get_start_iter);

	
		
	my $notebook = $app->source_view_notebook();
	$notebook->show_all();
	
	
	#$self->window->set_title("$filename - $NAME");
}
	
	
	
	
	
	
	




sub load_source {
	my $app = shift;
	my ($filename) = abs_path(@_);
	
	
	my $ref =$app->open_list_ref();
	my @open_list;
	@open_list = @{$ref} if(defined $ref); 
	#check if the file is opend before activate its notebook win
	my $pos=get_scolar_pos ($filename,@open_list);
	
	if (defined $pos){
		my $notebook = $app->source_view_notebook();
		$notebook->set_current_page($pos);
		return;		
	}
	
	
	#create a new source view and load the file there
	
	my $self=new_source_view($app,"$filename");
	
	push(@open_list,$filename);
	$app->open_list_ref(\@open_list);
	
	
	
	my $buffer = $self->buffer;

	# Guess the programming language of the file
	$self->detect_language($filename);

	# Loading a file should not be undoable.
	my $content;
	do {
		open my $handle, $filename or die "Can't read file $filename because $!";
		local $/;
		$content = <$handle>;
		close $handle;
	};
	$buffer->begin_not_undoable_action();
	$buffer->set_text($content);
	$buffer->end_not_undoable_action();

	#$buffer->set_modified(FALSE);
	$buffer->place_cursor($buffer->get_start_iter);

	
		
	my $notebook = $app->source_view_notebook();
	$notebook->show_all();
	
	
	#$self->window->set_title("$filename - $NAME");
}


sub clear_highlighted {
	my $self = shift;

	my $highlighted = delete $self->{highlighted} or return;

	my $buffer = $self->buffer;

	my @iters;
	foreach my $mark (@{ $highlighted->{marks} }) {
		my $iter = $buffer->get_iter_at_mark($mark);
		push @iters, $iter;
		$buffer->delete_mark($mark);
	}

	$buffer->remove_tag_by_name($highlighted->{name}, @iters);
}


sub get_text {
	my $self = shift;
	my $buffer = $self->buffer;
	return $buffer->get_text($buffer->get_start_iter, $buffer->get_end_iter, FALSE);
}


sub do_search {
	my $self = shift;
	my $criteria = $self->search_entry->get_text;
	if ($criteria eq '') {return;}

	my $case = $self->search_case;
	my $buffer = $self->buffer;


	# Start the search at the last search result or from the current cursor's
	# position. As a fall back we also add the beginning of the document. Once we
	# have the start position we can erase the previous search results.
	my @start;
	if (my $highlighted = $self->highlighted) {
		# Search from the last match
		push @start, $buffer->get_iter_at_mark($highlighted->{marks}[1]);
		$self->clear_highlighted();
	}
	else {
		# Search from the cursor
		push @start, $buffer->get_iter_at_offset(
			$buffer->get_property('cursor-position')
		);
	}
	push @start, $buffer->get_start_iter;

	my @iters;
	#if ($self->search_regexp) {
	if(1){	
		# SourceView does not support regular expressions so we
		# have to do the search by hand!

		my $text = $self->get_text;
		my $regexp;
		if ($self->search_regexp){
			$regexp = $case ? qr/$criteria/m : qr/$criteria/im;
		}else {
			$regexp = $case ? qr/\Q${criteria}\E/m : qr/\Q${criteria}\E/im;
			
		}

		foreach my $iter (@start) {
			# Tell Perl where to start the regexp lookup
			pos($text) = $iter->get_offset;

			if ($text =~ /($regexp)/g) {
				my $word = $1;
				my $pos = pos($text);
				@iters = (
					$buffer->get_iter_at_offset($pos - length($word)),
					$buffer->get_iter_at_offset($pos),
				);
				last;
			}
		}
	}
	else {
		# Use the builtin search mechanism
		my $flags = $case ? [ ] : [ 'case-insensitive' ];
		foreach my $iter (@start) {
			#@iters = Gtk3::SourceView::Iter->forward_search($iter, $criteria, $flags);
			last if @iters;
		}
	}

	$self->show_highlighted(search => @iters) if @iters;
}


sub show_highlighted {
	my $self = shift;
	my ($tag_name, $start, $end) = @_;
	my $buffer = $self->buffer;

	# Highlight the region, remember it and scroll to it
	my $match_start = $buffer->create_mark('match-start', $start, TRUE);
	my $match_end = $buffer->create_mark('match-end', $end, FALSE);

	$buffer->apply_tag_by_name($tag_name, $start, $end);

	# We have a callback that listens to when the cursor is placed and we don't
	# want it to undo our work! So let's unhighlight the previous entry.
	delete $self->{highlighted};
	$buffer->place_cursor($end);

	$self->sourceview->scroll_to_mark(
		$match_start,
		0.2,
		FALSE,
		0.0, 0.5
	);

	# Keep a reference to the markers once they have been added to the buffer.
	# Using them before can be catastrophic (segmenation fault).
	#
	$self->highlighted({
		name  => $tag_name,
		marks => [$match_start, $match_end],
	});
}


sub do_file_new {
	my ($self,$sw,$window,$tree_view,$tree_store,$scwin_dirs,$app) = @_;
	
	my $dialog = save_file_dialog('New file');
	if(defined  $sw){
		$dialog->set_current_folder ($sw); 
		#print "open_in:$sw\n";
		 
	}

	my $response = $dialog->run();
	if ($response eq 'ok') {
		my $file=$dialog->get_filename;
		save_file($file,'');
		$tree_view->destroy;
		($tree_view,$tree_store) =$app->build_tree_view($sw);
		add_widget_to_scrolled_win($tree_view,$scwin_dirs);
		$scwin_dirs->show_all;
		$app->load_source($file);	
	}
	$dialog->destroy();	
}

sub do_remove{
	my ($self,$sw,$window,$tree_view,$tree_store,$scwin_dirs,$app) = @_;
	my $fname  = $self->filename;
	my $r = yes_no_dialog ("Are you sure you want to permanently delete $fname file?");
	return if $r eq 'no';
	$self->close_b()->clicked;
	unlink $fname;
	$tree_view->destroy;
	($tree_view,$tree_store) =$app->build_tree_view($sw);
	add_widget_to_scrolled_win($tree_view,$scwin_dirs);
	$scwin_dirs->show_all;
	
	
}


sub do_file_open {
	my ($self,$sw,$window,$tree_view,$tree_store,$scwin_dirs,$app) = @_;

	my $dialog = gen_file_dialog("Open file...");
	$dialog->signal_connect(response => sub {
		my ($dialog, $response) = @_;

		if ($response eq 'ok') {
			my $file = $dialog->get_filename;
			return if -d $file;
			$app->load_source($file);
		}

		$dialog->destroy();
	});
	$dialog->show();
}


sub do_show_about_dialog {
	 about(Consts::VERSION);
}


sub do_ask_goto_line {
	my $self = shift;
	
	my $dialog=new_dialog_with_buttons($self);
	
	my $hbox =def_hbox(FALSE, 0);
	$hbox->pack_start(
		gen_label_in_left("Line number: "),
		FALSE, FALSE, 0
	);
	my $entry = gen_entry();
	$hbox->pack_start($entry, TRUE, TRUE, 0);

	$dialog->get_content_area->add($hbox);
	$dialog->show_all();


	# Signal handlers
	$entry->signal_connect(activate => sub {
		if ($entry->get_text =~ /(\d+)/) {
			$dialog->response('ok');
		}
	});

	# Run the dialog
	my $response = $dialog->run();
	
	return unless $response eq 'ok';

	return unless my ($line) = ($entry->get_text =~ /(\d+)/);
	my $buffer = $self->buffer;
	my $start = $buffer->get_iter_at_line($line - 1);
	my $end = $start->copy;
	$end->forward_to_line_end;

	$self->clear_highlighted();
	$self->show_highlighted(goto_line => $start, $end);
	$dialog->destroy();
}


sub do_quit {
	my ($self,$window) = @_;
	$window->destroy;
}


sub do_save_as {
	my ($self,$sw,$window,$tree_view,$tree_store,$scwin_dirs,$app) = @_;

	# If no file is associated with the editor then ask the user for a file where
	# to save the contents of the buffer.
	my $dialog = save_file_dialog('Save file');
	if(defined  $sw){
		$dialog->set_current_folder ($sw); 
		#print "open_in:$sw\n";
		 
	}

	my $response = $dialog->run();
	if ($response eq 'ok') {
		my $file=$dialog->get_filename;
		
		my $buffer = $self->buffer;
		open my $handle, '>:encoding(UTF-8)', $file or die "Can't write to $file: $!";
		print $handle $self->get_text;
		close $handle;
		
		$tree_view->destroy;
		($tree_view,$tree_store) =$app->build_tree_view($sw);
		add_widget_to_scrolled_win($tree_view,$scwin_dirs);
		$scwin_dirs->show_all;
		$app->load_source($file);
		
	
	}
	$dialog->destroy();
	

}


sub do_save {
	my $self = shift;

	my $filename = $self->filename;

	# If there's no file then do a save as...
	if (! $filename) {
		#$self->do_save_as();
		return;
	}

	my $buffer = $self->buffer;
	open my $handle, '>:encoding(UTF-8)', $filename or die "Can't write to $filename: $!";
	print $handle $self->get_text;
	close $handle;
	$self->set_source_label_modified(FALSE);
	if (! $buffer->get_language) {
		$self->detect_language($filename);
	}
}


sub set_source_label_modified{
	my ($self,$is_modified)=@_;
	$self->modified($is_modified); 
	my $buffer = $self->buffer;
	$buffer->set_modified($is_modified); 
	my $label=$self->label(); 
    my $fname = $self->filename; 
    my ($name,$p,$suffix) = fileparse("$fname",qr"\..[^.]*$");	
   
    if ($is_modified ==TRUE){
    	$label->set_markup("<span  foreground= 'black' ><b>*${name}${suffix}</b></span>");
    }else{	   
    	$label->set_markup("<span  foreground= 'black' >${name}${suffix}</span>");
    	
    }	    
	$label->show_all;		  
}

sub build_menu {
	my ($self,$sw,$window,$tree_view,$tree_store,$scwin_dirs,$app) = @_;



 my @menu_items = (
  [ "/_File",            undef,        undef,          0, "<Branch>" ],
  [ "/File/_New",       "<control>N", sub { $self->do_file_new($sw,$window,$tree_view,$tree_store,$scwin_dirs,$app); },  0,  undef ],
  [ "/File/_Open",      "<control>O", sub { $self->do_file_open($sw,$window,$tree_view,$tree_store,$scwin_dirs,$app) },  0, undef  ],
  [ "/File/_Save",      "<control>S", sub { $self->do_save($sw,$window,$tree_view,$tree_store,$scwin_dirs,$app)      },  0, undef  ],
  [ "/File/_SaveAs",	"<control><shift>S", sub { $self->do_save_as($sw,$window,$tree_view,$tree_store,$scwin_dirs,$app)} , 0, undef],
  [ "/File/_Delete",	"<control>D", sub { $self->do_remove($sw,$window,$tree_view,$tree_store,$scwin_dirs,$app)} , 0, undef],
  [ "/File/_Quit",		"<control>Q", sub { $self->do_quit($window) },  0, undef  ],
		
  [ "/_Search",           undef,        undef,          0, "<Branch>" ],
  [ "/Search/_Goto a Line",  "<control>L", 	sub { $self->do_ask_goto_line($sw,$window,$tree_view,$tree_store,$scwin_dirs,$app)},  0, undef  ],

  [ "/_Help", 		undef,		undef,          0, 	"<Branch>" ],
  [ "/_Help/_About",  	"F1", 		sub { $self->do_show_about_dialog($sw,$window,$tree_view,$tree_store,$scwin_dirs,$app) } ,	0,	undef ],
 


);
	

	return gen_MenuBar($window,@menu_items);    
		
}



sub add_to_tree {
 my ($tree_view,$tree_store, $parent, $dir, $path) = @_;
my $tree_model = $tree_view->get_model();

# If $parent already has children, then remove them first
 
 my $child = $tree_model->iter_children ($parent);
 while ($child) {
  
  $tree_store->remove ($child);
  $child = $tree_model->iter_children ($parent);
 }

# Add children from directory listing
 opendir(DIRHANDLE, $path) || return ; #die "Cannot open directory:$path $!\n";
 foreach my $subdir (sort readdir(DIRHANDLE)) {
  if ($subdir ne '.' and $subdir ne '..'
                                   # and -d $path.$subdir and -r $path.$subdir
) {
   my $child = $tree_store->append($parent);
 
   
   $tree_store->set($child, 0, $subdir, 1, "$path$subdir/") ;
   
  }
 }
 closedir(DIRHANDLE);
}


# Directory expanded. Populate subdirectories in readiness.

sub populate_treeo {

# $iter has been expanded
 my ($tree_view,$tree_store, $iter, $tree_path) = @_;
 my $tree_model = $tree_view->get_model();
 my ($dir, $path) = $tree_model->get($iter);

# for each of $iter's children add any subdirectories
 my $child = $tree_model->iter_children ($iter);
 while ($child) {
  my ($dir, $path) = $tree_model->get($child, 0, 1);
  add_to_tree($tree_view,$tree_store, $child, $dir, $path);
  $child = $tree_model->iter_next ($child);
 }
 return;
}


sub run_make_file {
	my ($dir,$outtext, $args)=@_;
	my $cmd =	(defined $args) ? "cd \"$dir/\" \n  make $args" :  "cd \"$dir/\" \n  make ";
	my $error=0;		
	add_info($outtext,"$cmd\n");
	
	my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout( $cmd);
	#($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout( $cmd);

	
	if($exit){
		if($stderr){
			$stderr=~ s/[‘,’]//g;
			add_info($outtext,"$stdout\n"); 
			add_colored_info($outtext,"$stderr\n","red"); 
		}
		add_colored_info($outtext,"Compilation failed.\n",'red');
		print " failed!\n";   
		return 0;

	}else{
		add_info($outtext,"$stdout\n"); 
		if($stderr){ #probebly had warning
			$stderr=~ s/[‘,’]//g;
			#add_info($outtext,"$stdout\n"); 
			add_colored_info($outtext,"$stderr\n","green"); 
		}
		
		add_colored_info($outtext,"Compilation finished successfully.\n",'blue');
		print " successful!\n";  
		return 1;
	}
			
	#add_info($outtext,"**********Quartus compilation is done successfully in $target_dir!*************\n") if($error==0);



}

sub handle_key {
    my ($widget, $event, $self) = @_;
    my $key = get_pressed_key ($event);
    my $buffer = $widget->get_buffer();
    if ( ($key eq 'f') && control_pressed( $event ) ) {
    	
    	
    	my ($start, $end) = $buffer->get_selection_bounds;
    	if (defined $start && defined $end){
    		my $string = $buffer->get_text ($start, $end, 0);
        	#print "CTRL+F copy $string to serach box\n";
        	$self->search_entry->set_text($string);
    	}
    }
    
    return FALSE; # FALSE -> means propagate key further
}

sub control_pressed {
    my ( $event ) = @_;

    return $event->state & 'control-mask';
}



1;

