#!/usr/bin/perl

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use Gtk2::SourceView2;
use Data::Dumper;


use base 'Class::Accessor::Fast';
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
});

my $NAME = 'Otec';


exit main() unless caller;


sub software_main {
	my ($sw,$file) = @_;

	

	my $app = __PACKAGE__->new();
	my ($table,$tview,$window)=$app->build_gui($sw);
	my $main_c=(defined $file)? "$sw/$file" : "$sw/main.c";
	$app->load_source($main_c) if (-f $main_c );

	#Gtk2->main();

	return ($app,$table,$tview,$window);
}


sub build_gui {
	my ($self,$sw) = @_;

	my $window = def_popwin_size (75,75,'Source Editor','percent');
	my $table= def_table(2,10,FALSE);
	



	my $hpaned = Gtk2::HPaned -> new;
	my $vpaned = Gtk2::VPaned -> new;
	$table->attach_defaults ($vpaned,0, 10, 0,1);
	#my $make = def_image_button('icons/run.png','Compile');
	#$table->attach ($make,9, 10, 1,2,'shrink','shrink',0,0);
	#$make -> signal_connect("clicked" => sub{
		#$self->do_save();
		#run_make_file($sw,$tview);	

	#});

	$window -> add ( $table);

	my($width,$hight)=max_win_size();
	
	my $scwin_dirs = Gtk2::ScrolledWindow -> new;
	$scwin_dirs -> set_policy ('automatic', 'automatic');
	$hpaned -> pack1 ($scwin_dirs, TRUE, TRUE);
	$hpaned ->set_position ($width*.15);

	my $scwin_text = Gtk2::ScrolledWindow -> new;
	$scwin_text -> set_policy ('automatic', 'automatic');
	$hpaned -> pack2 ($scwin_text, TRUE, TRUE);
	

	my ($scwin_info,$tview)= create_text();
	add_colors_to_textview($tview);
	$vpaned-> pack1 ($hpaned, TRUE, TRUE);
	$vpaned ->set_position ($hight*.5);
	$vpaned-> pack2 ($scwin_info, TRUE, TRUE);




# Directory name, full path
my $tree_store = Gtk2::TreeStore->new('Glib::String', 'Glib::String');
my $tree_view = Gtk2::TreeView->new($tree_store);
my $column = Gtk2::TreeViewColumn->new_with_attributes('', Gtk2::CellRendererText->new(), text => "0");
$tree_view->append_column($column);
$tree_view->set_headers_visible(FALSE);
$tree_view->signal_connect (button_release_event => sub{
	my $tree_model = $tree_view->get_model();
 	my $selection = $tree_view->get_selection();
 	my $iter = $selection->get_selected();
 	if(defined $iter){
		my $path = $tree_model->get($iter, 1) ;
		$path= substr $path, 0, -1;
		
		 $self->load_source($path) if(-f $path);
	}
	 return;
});


$tree_view->signal_connect ('row-expanded' => sub {
	my ($tree_view, $iter, $tree_path) = @_;
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
});


$scwin_dirs -> add($tree_view);



my $child = $tree_store->append(undef);
$tree_store->set($child, 0, $sw, 1, '/');
add_to_tree($tree_view,$tree_store, $child, '/', "$sw/");
#print "$sw/\n";

	#my $window = Gtk2::Window->new();
	#$window->set_size_request(480, 360);
	#$window->set_title($NAME);
	$self->window($window);

	my $vbox = Gtk2::VBox->new(FALSE, 0);
	$scwin_text->add_with_viewport($vbox);

	$vbox->pack_start($self->build_menu, FALSE, FALSE, 0);
	$vbox->pack_start($self->build_search_box, FALSE, FALSE, 0);

	my $scroll = Gtk2::ScrolledWindow->new();
	$scroll->set_policy('automatic', 'automatic');
	$scroll->set_shadow_type('in');
	$vbox->pack_start($scroll, TRUE, TRUE, 0);

	my $buffer = $self->create_buffer();
	my $sourceview = Gtk2::SourceView2::View->new_with_buffer($buffer);
	$sourceview->set_show_line_numbers(TRUE);
	$sourceview->set_tab_width(2);
	$sourceview->set_indent_on_tab(TRUE);
	$sourceview->set_highlight_current_line(TRUE);
#	$sourceview->set_draw_spaces(['tab', 'newline']);

	#
	# Fix Gtk2::TextView's annoying paste behaviour when pasting with the mouse
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


	$scroll->add($sourceview);
	$self->sourceview($sourceview);
	$self->buffer($sourceview->get_buffer);

	$window->signal_connect(delete_event => sub {
		Gtk2->main_quit();
		return TRUE;
	});

	$window->show_all();
	return ($table,$tview,$window);
}


sub build_search_box {
	my $self = shift;

	# Elements of the search box
	my $hbox = Gtk2::HBox->new(FALSE, 0);

	my $search_entry = Gtk2::Entry->new();
	$search_entry->signal_connect(activate => sub {$self->do_search()});
	$search_entry->signal_connect(icon_release => sub {$self->do_search()});
	$self->search_entry($search_entry);

	my $search_regexp = Gtk2::CheckButton->new('RegExp');
	$search_regexp->signal_connect(toggled => sub {
		$self->search_regexp($search_regexp->get_active);
	});

	my $search_case = Gtk2::CheckButton->new('Case');
	$search_case->signal_connect(toggled => sub {
		$self->search_case($search_case->get_active);
	});

	my $search_icon = Gtk2::Button->new_from_stock('gtk-find');
	$search_entry->set_icon_from_stock(primary => 'gtk-find');

	$hbox->pack_start($search_entry, TRUE, TRUE , 0);
	$hbox->pack_start($search_regexp, FALSE, FALSE, 0);
	$hbox->pack_start($search_case, FALSE, FALSE, 0);

	return $hbox;
}


sub create_buffer {
	my $self = shift;
	my $tags = Gtk2::TextTagTable->new();

	add_tag($tags, search => {
			background => 'yellow',
	});
	add_tag($tags, goto_line => {
			'paragraph-background' => 'orange',
	});

	my $buffer = Gtk2::SourceView2::Buffer->new($tags);
	$buffer->signal_connect('notify::cursor-position' => sub {
		$self->clear_highlighted();
	});

	return $buffer;
}


sub add_tag {
	my ($tags, $name, $properties) = @_;

	my $tag = Gtk2::TextTag->new($name);
	$tag->set(%{ $properties });
	$tags->add($tag);
}


sub detect_language {
	my $self = shift;
	my ($filename) = @_;

	# Guess the programming language of the file
	my $manager = Gtk2::SourceView2::LanguageManager->get_default;
	my $language = $manager->guess_language($filename);
	$self->buffer->set_language($language);
}


sub load_source {
	my $self = shift;
	my ($filename) = @_;
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

	$buffer->set_modified(FALSE);
	$buffer->place_cursor($buffer->get_start_iter);

	$self->filename($filename);
	$self->window->set_title("$filename - $NAME");
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
	if ($self->search_regexp) {
		# Gtk2::SourceView2 nor Gtk2::SourceView support regular expressions so we
		# have to do the search by hand!

		my $text = $self->get_text;
		my $regexp = $case ? qr/$criteria/m : qr/$criteria/im;

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
			@iters = Gtk2::SourceView2::Iter->forward_search($iter, $criteria, $flags);
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
	my $self = shift;
	my $buffer = $self->buffer;

	# Set no language
	$buffer->set_language(undef);

	# Showing a blank editor should not be undoable.
	$buffer->begin_not_undoable_action();
	$buffer->set_text('');
	$buffer->end_not_undoable_action();

	$buffer->set_modified(FALSE);
	$buffer->place_cursor($buffer->get_start_iter);

	$self->filename('');
	$self->window->set_title("Untitled - $NAME");
}


sub do_file_open {
	my $self = shift;
	my ($window, $action, $menu_item) = @_;

	my $dialog = Gtk2::FileSelection->new("Open file...");
	$dialog->signal_connect(response => sub {
		my ($dialog, $response) = @_;

		if ($response eq 'ok') {
			my $file = $dialog->get_filename;
			return if -d $file;
			$self->load_source($file);
		}

		$dialog->destroy();
	});
	$dialog->show();
}


sub do_show_about_dialog {
	my $self = shift;

	my $dialog = Gtk2::AboutDialog->new();
	$dialog->set_authors("Emmanuel Rodriguez");
	$dialog->set_comments("Gtk2::SourceView2 Demo");
	$dialog->signal_connect(response => sub {
		my ($dialog, $response) = @_;
		$dialog->destroy();
	});
	$dialog->show();
}


sub do_ask_goto_line {
	my $self = shift;

	my $dialog = Gtk2::Dialog->new_with_buttons(
		"Goto to line",
		$self->window,
		[ 'modal' ],
		'gtk-cancel' => 'cancel',
		'gtk-ok'     => 'ok',
	);

	my $hbox = Gtk2::HBox->new(FALSE, 0);
	$hbox->pack_start(
		Gtk2::Label->new("Line number: "),
		FALSE, FALSE, 0
	);
	my $entry = Gtk2::Entry->new();
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
	$dialog->destroy();
	return unless $response eq 'ok';

	return unless my ($line) = ($entry->get_text =~ /(\d+)/);
	my $buffer = $self->buffer;
	my $start = $buffer->get_iter_at_line($line - 1);
	my $end = $start->copy;
	$end->forward_to_line_end;

	$self->clear_highlighted();
	$self->show_highlighted(goto_line => $start, $end);
}


sub do_quit {
	my $self = shift;
	Gtk2->main_quit();
}


sub do_save_as {
	my $self = shift;

	# If no file is associated with the editor then ask the user for a file where
	# to save the contents of the buffer.
	my $dialog = Gtk2::FileChooserDialog->new(
		"Save file", $self->window, 'save',
		'gtk-cancel' => 'cancel',
		'gtk-save'   => 'ok',
	);

	my $response = $dialog->run();
	if ($response eq 'ok') {
		$self->filename($dialog->get_filename);
		$self->do_save();
	}
	$dialog->destroy();
}


sub do_save {
	my $self = shift;

	my $filename = $self->filename;

	# If there's no file then do a save as...
	if (! $filename) {
		$self->do_save_as();
		return;
	}

	my $buffer = $self->buffer;
	open my $handle, '>:encoding(UTF-8)', $filename or die "Can't write to $filename: $!";
	print $handle $self->get_text;
	close $handle;

	if (! $buffer->get_language) {
		$self->detect_language($filename);
	}
}


sub build_menu {
	my $self = shift;

	my $entries = [
		# name, stock id, label
		[ "FileMenu",  undef, "_File" ],
		[ "SearchMenu",  undef, "_Search" ],
		[ "HelpMenu",  undef, "_Help" ],

		# name, stock id, label, accelerator, tooltip, method
		[
			"New",
			'gtk-new',
			"_New",
			"<control>N",
			"Create a new file",
			sub { $self->do_file_new(@_) }
		],
		[
			"Open",
			'gtk-open',
			"_Open",
			"<control>O",
			"Open a file",
			sub { $self->do_file_open(@_) }
		],
		[
			"Save",
			'gtk-save',
			"_Save",
			"<control>S",
			"Save current file",
			sub { $self->do_save(@_) }
		],
		[
			"SaveAs",
			'gtk-save',
			"Save _As...",
			"<control><shift>S",
			"Save to a file",
			sub { $self->do_save_as(@_) }
		],
		[
			"Quit",
			'gtk-quit',
			"_Quit",
			"<control>Q",
			"Quit",
			sub { $self->do_quit() }
		],
		[
			"About",
			'gtk-about',
			"_About",
			undef,
			"About",
			sub { $self->do_show_about_dialog(@_) }
		],
		[
			"GotoLine",
			undef,
			"Goto to _Line",
			"<control>L",
			"Go to line",
			sub { $self->do_ask_goto_line(@_) }
		],
	];

	my $actions = Gtk2::ActionGroup->new("Actions");
	$actions->add_actions($entries, undef);

	my $ui = Gtk2::UIManager->new();
	$ui->insert_action_group($actions, 0);
	$ui->add_ui_from_string(<<'__UI__');
<ui>
	<menubar name='MenuBar'>
		<menu action='FileMenu'>
			<menuitem action='New'/>
			<menuitem action='Open'/>
			<separator/>
			<menuitem action='Save'/>
			<menuitem action='SaveAs'/>
			<separator/>
			<menuitem action='Quit'/>
		</menu>
		<menu action='SearchMenu'>
			<menuitem action='GotoLine'/>
		</menu>
		<menu action='HelpMenu'>
			<menuitem action='About'/>
		</menu>
	</menubar>
</ui>
__UI__

	$self->window->add_accel_group($ui->get_accel_group);

	return $ui->get_widget('/MenuBar');
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
   $tree_store->set($child, 0, $subdir, 1, "$path$subdir/");
  }
 }
 closedir(DIRHANDLE);
}


# Directory expanded. Populate subdirectories in readiness.

sub populate_tree {

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
	add_info(\$outtext,"$cmd\n");
	
	my ($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout( $cmd);
	#($stdout,$exit,$stderr)=run_cmd_in_back_ground_get_stdout( $cmd);

	
	if($exit){
		if($stderr){
			$stderr=~ s/[‘,’]//g;
			add_info(\$outtext,"$stdout\n"); 
			add_colored_info(\$outtext,"$stderr\n","red"); 
		}
		add_colored_info(\$outtext,"Compilation failed.\n",'red'); 
		return 0;

	}else{
		add_info(\$outtext,"$stdout\n"); 
		if($stderr){ #probebly had warning
			$stderr=~ s/[‘,’]//g;
			#add_info(\$outtext,"$stdout\n"); 
			add_colored_info(\$outtext,"$stderr\n","green"); 
		}
		
		add_colored_info(\$outtext,"Compilation finished successfully.\n",'blue');  
		return 1;
	}
			
	#add_info(\$outtext,"**********Quartus compilation is done successfully in $target_dir!*************\n") if($error==0);



}




1;

