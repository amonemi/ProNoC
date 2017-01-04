###############################################################################
#
# File:         rvp.pm
# RCS:          $Header: /home/cc/v2html/build/../RCS/rvp.pm,v 7.61 2006/03/25 22:24:57 cc Exp $
# Description:  The Rough Verilog Parser Perl Module
# Author:       Costas Calamvokis
# Created:      Fri Apr 10 16:59:30 1998
# Modified:     Thu Jan 12 10:45:27 2006
# Language:     Perl
#
# Copyright 1998-2006 Costas Calamvokis
#
#  This file nay be copied, modified and distributed only in accordance
#  with the terms of the limited licence contained in the accompanying
#  file LICENCE.TXT.
#
###############################################################################
#

=head1 rvp - Rough Verilog Parser Perl Module

The basic idea is that first you call read_verilog will a list of all of your
files. The files are parsed and information stored away. You are then 
handed back a pointer to the information which you can use in calls
to the various get_ function to get information about the verilog design.

For Example:

 #!/usr/bin/perl -w
 use rvp;   # use the rough verilog parser

 # Read in all the files specified on the command line
 $vdata = rvp->read_verilog(\@ARGV,[],{},1,[],[],'');

 # Print out all the modules found
 foreach $module ($vdata->get_modules()) { print "$module\n"; }

Unless you are doing something very strange, you can probably ignore all
of the functions that have the words 'context' or 'anchors' in them!

=cut

package rvp;

#use strict;
#use Tie::IxHash;

use File::Basename;

use vars qw(@verilog_gatetype_keywords $verilog_gatetype_regexp 
	    @verilog_compiler_keywords
	    @verilog_signal_keywords @verilog_sigs $verilog_sigs_regexp 
	    $quiet $debug $VID $HVID $VNUM
	    $takenArcs
            $baseEval $rvpEval $debugEval $languageDef $vid_vnum_or_string
            $version $VERSION);

BEGIN {
    # $VERSION is used by 'use', but keep $version for backwards compatibility
    $version = '$Header: /home/cc/v2html/build/../RCS/rvp.pm,v 7.61 2006/03/25 22:24:57 cc Exp $'; #'
    $version =~ s/^\S+ \S+ (\S+) .*$/$1/;
    $VERSION = $version; 

    @verilog_signal_keywords = qw(input    output  inout  
		       wire     tri     tri1   supply0 wand  triand tri0 
		       supply1  wor     time   trireg  trior
		       reg      integer real   realtime

		       genvar
		       );
    @verilog_sigs = @verilog_signal_keywords; # for backwards compatiblity

    #V2001

    $verilog_sigs_regexp = "\\b(?:" . 
	join("|",@verilog_signal_keywords) . 
	    ")\\b";

    @verilog_gatetype_keywords = qw(and  nand  or  nor xor xnor  buf  bufif0 bufif1  
				    not  notif0 notif1  pulldown  pullup
				    nmos  rnmos pmos rpmos cmos rcmos   tran rtran  
				    tranif0  rtranif0  tranif1 rtranif1
				    );

    $verilog_gatetype_regexp = "\\b(?:" . 
	join("|",@verilog_gatetype_keywords) . 
	    ")\\b";

    # Note: optimisation code in _search() assumes all of
    #  these compiler keywords contain a ` 
    @verilog_compiler_keywords = qw( 
     `celldefine            `define 
     `delay_mode_path       `disable_portfaults 
     `else                  `enable_portfaults
     `endcelldefine         `endif 
     `ifdef                 `include 
     `nosuppress_faults     `suppress_faults 
     `timescale             `undef
     `resetall              `delay_mode_distributed

     `default_nettype  `file `line `ifndef `elsif
    );    #`

    # a verilog identifier is this reg exp 
    #  a non-escaped identifier is A-Z a-z _ 0-9 or $ 
    #  an escaped identifier is \ followed by non-whitespace
    #   why \\\\\S+ ? This gets \\\S+ in to the string then when it
    #   it used we get it searching for \ followed by non-whitespace (\S+)
    $VID = '(?:[A-Za-z_][A-Za-z_0-9\$]*|\\\\\S+)';

    # hierarchical VID - just $VID(.$VID)+ but can't write it like this
    #  because of \ escaping (and must include whitespace after esc.ids.)
    $HVID = '(?:(?:[A-Za-z_][A-Za-z_0-9\$]*|\\\\\S+\s+)'.
           '(?:\.(?:[A-Za-z_][A-Za-z_0-9\$]*|\\\\\S+\s+))+)'; 
  # V2001: added [sS] - is this correct
    $VNUM= '(?:(?:[0-9]*\'[sS]?[bBhHdDoO]\s*[0-9A-Fa-f_zZxX?]+)|(?:[-0-9Ee._]+))';


    $quiet=0;
    $debug=0;

}

###########################################################################

=head1 read_verilog

reads in verilog files, parses them and stores results in an internal 
data structure (which I call a RVP database).

  Arguments:  - reference to array of files to read (can have paths)
              - reference to hash of defines with names as keys
              - reference to array of global includes - not used anymore,
                 just kept for backwards compatibility
              - quite flag. 1=be quiet, 0=be chatty.
              - reference to array of include directories
              - reference to array of library directories
              - library extension string (eg '.v') or reference to array of strings

  Returns:    - a pointer to the internal data structure.

  Example:
    $defines{'TRUE'}=1;  # same as +define+TRUE=1 on verilog cmd line
    $vdata = rvp->read_verilog(\@files,[],\%defines,1,
				     \@inc_dirs,\@lib_dirs,\@lib_exts);

=cut
sub read_verilog {
    # be backwards compatible with non-OO call
    my $class = ("ARRAY" eq ref $_[0]) ? "rvp" : shift;
    my ($files,$global_includes,$cmd_line_defines,$local_quiet,$inc_dirs,
	$lib_dirs,$lib_ext_arg,$exp)
	= @_;
    my ($file,$fb,$old_quiet,@search_files,@new_search_files,$lib_exts);

    my $self;

    die "read_verilog needs an array ref as arg 1" unless "ARRAY" eq ref $files;
    die "read_verilog needs an hash ref as arg 2" unless "HASH" eq ref $cmd_line_defines;
    die "read_verilog needs 0 or 1 as arg 3" unless $local_quiet==0 || $local_quiet==1;

    # be backwards compatible
    if (!defined($inc_dirs)) { $inc_dirs=[]; }
    if (!defined($lib_dirs)) { $lib_dirs=[]; }
    
    if (!defined($lib_ext_arg)) {  # no libexts given
	$lib_exts=['']; 
    }           
    elsif (!ref($lib_ext_arg))  {  # a string given
	$lib_exts=[$lib_ext_arg]; 
    }
    else {                         # an array ref given
	$lib_exts=$lib_ext_arg; 
    }


    # make the parser
    if (! defined &parse_line) {

	my $perlCode=_make_parser( $debug ? [ $baseEval,$debugEval,$rvpEval ]:
				          [ $baseEval,$rvpEval ] ,
				 $debug );
	if ($debug) {
	    open(PC,">v2html-parser.pl");
	    print PC $perlCode;
	}
	eval($perlCode);
	print STDERR $@ if ($@);
    }

    if (! defined &_parse_line) { die "Parse code generation failed";}

    $old_quiet=$quiet;
    $quiet=$local_quiet;
    # set up top of main data structure
    $self = {};
    $self->{files}               = {}; # information on each file
    $self->{modules}             = {}; # pointers to module info in {files}
    $self->{defines}             = {};
    $self->{ignored_modules}     = {}; # list of modules were duplicates were found
    $self->{unresolved_modules}  = {}; # modules we have not found yet
    $self->{problems}            = []; # warning/confused messages

    bless($self,$class);

    foreach my $d (keys(%$cmd_line_defines)) {
	_add_define($self->{defines}, $d , $cmd_line_defines->{$d}, '', 0 );
    }

    # go through all the files and find information
    @new_search_files = @{$files};
    while (@new_search_files) {
	@search_files = @new_search_files;
	@new_search_files = ();
	foreach $file (@search_files) {
	    $self->_search($file,$inc_dirs);
	}
	push( @new_search_files , _resolve_modules( $self, $lib_dirs, $lib_exts ) );
    }


    if ($debug) {
	_check_coverage();
    }

    # cross reference files' information
    print "Cross referencing\n" unless $quiet;
    $self->_cross_reference();
    
    $quiet=$old_quiet;

    foreach my $m ( sort (keys %{$self->{unresolved_modules}} )) {
	# find somewhere it is instantiated for warning message
	my $file="";
	my $line="";
	foreach my $m2 (sort (keys %{$self->{modules}})) {
	    foreach my $inst (@{$self->{modules}{$m2}{instances}}) {
		if ($inst->{module} eq $m) {
		    $file = $inst->{file};
		    $line = $inst->{line};
		    last;
		}
	    }
	}
	#$self->_add_warning("$file:$line: Could not find module $m");
    }
    return $self;
} 

###########################################################################

=head1 get_problems

Return any problems that happened during parsing

  Returns:    - array of strings of problems. Each one is:
                    "TYPE:FILE:LINE: description"

=cut
sub get_problems {
    my ($self) = @_;
    
    return (@{$self->{problems}});
}

###########################################################################

=head1 set_debug

Turns on debug printing in the parser.

  Returns:    - nothing

=cut
sub set_debug {
    $debug=1;
}

###########################################################################

=head1 unset_debug

Turns off debug printing in the parser.

  Returns:    - nothing

=cut
sub unset_debug {
    $debug=0;
}

###########################################################################

=head1 get_files

Get a list of all the files in the database.

  Returns:    - list of all the files

  Example:   @all_files = $vdata->get_files();

=cut
sub get_files{
    my ($self) = @_;

    if (wantarray) { 
	return sort (keys %{$self->{files}});
    }
    else { # in a scalar context keys returns the number of elements - sort doesn't
	return keys %{$self->{files}};
    }
}

###########################################################################

=head1 get_files_modules

Get a list of all the modules in a particular file.

  Arguments:  - name of file

  Returns:    - list of module names

  Example:   @modules = $vdata->get_files_modules($file);

=cut
sub get_files_modules{
    my ($self,$file) = @_;
    my (@modules,$m);

    foreach $m (sort (keys %{$self->{files}{$file}{modules}})) {
	push(@modules,$m)
    }

    return @modules;
}


###########################################################################

=head1 get_files_full_name

Get the full name (including path) of a file.

  Arguments:  - name of file

  Returns:    - full path name

  Example  $full_name = $vdata->get_files_full_name($file);

=cut
sub get_files_full_name{
    my ($self,$file) = @_;

    return $self->{files}{$file}{full_name};

}

###########################################################################

=head1 get_files_stats

Get statistics about a file

  Arguments:  - name of file

  Returns:    - number of lines in the file (more later...)

  Example  $full_name = $vdata->get_files_stats($file);

=cut
sub get_files_stats{
    my ($self,$file) = @_;

    return $self->{files}{$file}{lines};

}

###########################################################################

=head1 file_exists

Test if a particular module file  in the database.

  Arguments:  - file name to test.

  Returns:    - 1 if exists otherwise 0

  Example:   if ($vdata->file_exists($file))....

=cut
sub file_exists{
    my ($self,$file) = @_;
    return exists($self->{files}{_ffile($file)});
}

###########################################################################

=head1 get_modules

Get a list of all the modules in the database.


  Returns:   - list of all the modules

  Example:   @all_modules = $vdata->get_modules();

=cut
sub get_modules{
    my ($self) = @_;

    if (wantarray) { 
	return sort (keys %{$self->{modules}});
    }
    else { # in a scalar context keys returns the number of elements - sort doesn't
	return keys %{$self->{modules}};
    }

}


###########################################################################

=head1 get_modules_t_and_f

Get a list of all the tasks and functions in a particular module.

  Arguments:  - name of module

  Returns:    - list of tasks and function names

  Example:    if ( @t_and_f = $vdata->get_modules_t_and_f($m))...

=cut
# return a list of all the tasks and functions in a module
sub get_modules_t_and_f{
    my ($self,$module) = @_;

    if (wantarray) { 
	return sort (keys %{$self->{modules}{$module}{t_and_f}});
    }
    else { # in a scalar context keys returns the number of elements - sort doesn't
	return keys %{$self->{modules}{$module}{t_and_f}};
    }

}

###########################################################################

=head1 get_modules_t_or_f

Get information on a task or function in a module.

  Arguments:  - module name
              - task or function name

  Returns:    - A 4 element list: type (task or function), definition line,
                  file, anchor

  Example:    ($t_type,$t_line ,$t_file,$t_anchor)=
		$vdata->get_modules_t_or_f($m,$tf);

=cut
sub get_modules_t_or_f{
    my ($self,$mod,$t_or_f) = @_;

    if (exists($self->{modules}{$mod}{t_and_f}{$t_or_f})) {
	return($self->{modules}{$mod}{t_and_f}{$t_or_f}{type},
	       $self->{modules}{$mod}{t_and_f}{$t_or_f}{line},
	       $self->{modules}{$mod}{t_and_f}{$t_or_f}{file},
	       $self->{modules}{$mod}{t_and_f}{$t_or_f}{anchor});
    }
    else {
	return ();
    }
}

###########################################################################

=head1 get_modules_signals

Get a list of all the signals in a particular module.

  Arguments:  - name of module

  Returns:    - list of signal names

  Example:    if ( @signs = $vdata->get_modules_signals($m))...

=cut
# return a list of all the tasks and functions in a module
sub get_modules_signals{
    my ($self,$module) = @_;

    if (wantarray) { 
	return sort (keys %{$self->{modules}{$module}{signals}});
    }
    else { # in a scalar context keys returns the number of elements - sort doesn't
	return keys %{$self->{modules}{$module}{signals}};
    }

}

###########################################################################

=head1 get_modules_file

Get the file name (no path) that a module is defined in.

  Arguments:  - module name

  Returns:    - file name without path, and the line number module starts on

  Example:    ($f) = $vdata->get_modules_file($m);

=cut
# get the file name that contains a module
sub get_modules_file{
    my ($self,$module) = @_;

    return ($self->{modules}{$module}{file},$self->{modules}{$module}{line});
}


###########################################################################

=head1 get_modules_type

Get the type of the module - It is one of: module, macromodule or primitive
(rvp treats these all as modules).

  Arguments:  - module name

  Returns:    - type

  Example:    $t = $vdata->get_modules_type($m);

=cut
# get the file name that contains a module
sub get_modules_type{
    my ($self,$module) = @_;

    return ($self->{modules}{$module}{type});
}

###########################################################################

=head1 get_files_includes

Get the file names (no path) of files included in a file.

  Arguments:  - file name

  Returns:    - list of file names without paths

  Example:    @f = $vdata->get_files_includes($file);

=cut
sub get_files_includes {
    my ($self,$f) = @_;
    my @includes_found = ();

    if (exists($self->{files}{$f})) {
	foreach my $inc ( sort ( keys %{$self->{files}{$f}{includes}} )) {
	    push(@includes_found,$inc);
	    # do the includes for the included file
	    push(@includes_found, $self->get_files_includes($inc));
	}
    }

    return @includes_found;
}

###########################################################################

=head1 get_files_included_by

Get the file names (no path) of files that included this file.

  Arguments:  - file name

  Returns:    - list of file names without paths

  Example:    @f = $vdata->get_files_included_by($file);

=cut
sub get_files_included_by {
    my ($self,$f) = @_;

    return @{$self->{files}{$f}{included_by}};
    
}


###########################################################################

=head1 module_ignored

Test if a particular module has been ignored because of duplicates found

  Arguments:  - module name to test

  Returns:    - 1 if ignored otherwise 0

  Example:   if ($vdata->module_ignored($module))....

=cut
sub module_ignored {
    my ($self,$module) = @_;
    return (exists($self->{modules}{$module}) && 
	    $self->{modules}{$module}{duplicate});
}

###########################################################################

=head1 module_exists

Test if a particular module exists in the database.

  Arguments:  - module name to test

  Returns:    - 1 if exists otherwise 0

  Example:   if ($vdata->module_exists($module))....

=cut
sub module_exists{
    my ($self,$module) = @_;
    return exists($self->{modules}{$module});
}

###########################################################################

=head1 get_ignored_modules

Return a list of the ignored modules. These are modules where duplicates
have been found.

  Returns:    - List of ignored modules

  Example:    - foreach $module ($vdata->get_ignored_modules())....

=cut
sub get_ignored_modules {
    my ($self) = @_;
    my @ig =();
    foreach my $m (sort (keys %{$self->{modules}})) {
	push(@ig, $m) if ($self->{modules}{$m}{duplicate});
    }
    return @ig;
}

###########################################################################

=head1 get_module_signal

Get information about a particular signal in a particular module.

  Arguments:  - name of module
              - name of signal

  Returns:    - A list containing: 
                 - the line signal is defined
                 - the line signal is assigned first (or -1)
                 - line in instantiating module where an input 
                       is driven from (or -1)
                 - the type of the signal (input,output,reg etc)
                 - the file the signal is in
                 - posedge flag (1 if signal ever seen with posedge)
                 - negedge flag (1 if signal ever seen with negedge)
                 - second type (eg reg for a registered output)
                 - signal real source file
                 - signal real source line
                 - range string if any ( not including [ and ] )
                 - the file signal is assigned first (or '')
                 - file for the instantiating module where an input 
                       is driven from (or "")
                 - a pointer to an array of dimensions for memories
                       each element of the array is a dimension, array
                       is empty for non-memories

  Note posedge and negedge information is propagated up the hierarchy to
  attached signals. It is not propagated down the hierarchy.

  Example:    ($s_line,$s_a_line,$s_i_line,$s_type,$s_file,$s_p,$s_n,
	       $s_type2,$s_r_file,$s_r_line,$range,$s_a_file,$s_i_file) = 
                      $vdata->get_module_signal($m,$sig);

=cut
sub get_module_signal{
    my ($self,$module,$sig) = @_;
    
    if (exists( $self->{modules}{$module}{signals}{$sig} )) {
	return ($self->{modules}{$module}{signals}{$sig}{line},
		$self->{modules}{$module}{signals}{$sig}{a_line},
		$self->{modules}{$module}{signals}{$sig}{i_line},
		$self->{modules}{$module}{signals}{$sig}{type},
		$self->{modules}{$module}{signals}{$sig}{file},
		$self->{modules}{$module}{signals}{$sig}{posedge},
		$self->{modules}{$module}{signals}{$sig}{negedge},
		$self->{modules}{$module}{signals}{$sig}{type2},
		$self->{modules}{$module}{signals}{$sig}{source}{file},
		$self->{modules}{$module}{signals}{$sig}{source}{line},
		$self->{modules}{$module}{signals}{$sig}{range},
		$self->{modules}{$module}{signals}{$sig}{a_file},
		$self->{modules}{$module}{signals}{$sig}{i_file},
		$self->{modules}{$module}{signals}{$sig}{dimensions});
    }
    else {
	return ();
    }
}

###########################################################################

=head1 get_first_signal_port_con

Get the first port that this signal in this module is connected to.

  Arguments:  - module name
              - signal name

  Returns:    - a 5 element list: instantiated module name, instance name
                  port name, line number and file

  Example:    ($im,$in,$p,$l,$f)=$vdata->get_first_signal_port_con($m,$s);

=cut
sub get_first_signal_port_con{
    my ($self,$module,$signal) = @_;

    $self->{current_signal_port_con}       =0;
    $self->{current_signal_port_con_module}=$module;
    $self->{current_signal_port_con_module_signal}=$signal;

    return $self->get_next_signal_port_con();
}

###########################################################################

=head1 get_next_signal_port_con

Get the next port that this signal in this module is connected to.

  Returns:    - a 5 element list: instantiated module name, instance name
                  port name, line number and file

  Example:    ($im,$in,$p,$l,$f)=$vdata->get_next_signal_port_con();

=cut
sub get_next_signal_port_con{
    my ($self) = @_;
    my ($module,$signal,$i,$pcref);

    $module = $self->{current_signal_port_con_module};
    $signal = $self->{current_signal_port_con_module_signal};
    $i      = $self->{current_signal_port_con};

    $pcref = $self->{modules}{$module}{signals}{$signal}{port_con};
    if (@{$pcref} > $i ) {
	$self->{current_signal_port_con}++;
	return ( $pcref->[$i]{module},$pcref->[$i]{inst},$pcref->[$i]{port},
		$pcref->[$i]{line},$pcref->[$i]{file});
    }
    else {
	return ();
    }
}

###########################################################################

=head1 get_first_signal_con_to

Get the first signal that is connected to this port in an
instantiation of this module. This only works for instances that use
the .port(sig) notation.

  Arguments:  - module name
              - signal name

  Returns:    - a 4 element list: signal connected to this port
                                  module signal is in
		                  instance (of this module) where the connection
			            occurs

  Example:    ($cts,$ctm,$cti)=$vdata->get_first_signal_con_to($m,$s);

=cut
sub get_first_signal_con_to{
    my ($self,$module,$signal) = @_;

    $self->{current_signal_con_to}       =0;
    $self->{current_signal_con_to_module}=$module;
    $self->{current_signal_con_to_module_signal}=$signal;

    return $self->get_next_signal_con_to();
}

###########################################################################

=head1 get_next_signal_con_to

Get the next signal that is connected to this port in an
instantiation of this module. This only works for instances that use
the .port(sig) notation.

  Arguments:  - module name
              - signal name

  Returns:    - a 4 element list: signal connected to this port
                                  module signal is in
		                  instance (of this module) where the connection
			            occurs

  Example:    ($cts,$ctm,$cti)=$vdata->get_next_signal_con_to();

=cut
sub get_next_signal_con_to{
    my ($self) = @_;
    my ($module,$signal,$i,$ctref);

    $module = $self->{current_signal_con_to_module};
    $signal = $self->{current_signal_con_to_module_signal};
    $i      = $self->{current_signal_con_to};

    $ctref = $self->{modules}{$module}{signals}{$signal}{con_to};
    if (@{$ctref} > $i ) {
	$self->{current_signal_con_to}++;
	return ( $ctref->[$i]{signal},$ctref->[$i]{module},$ctref->[$i]{inst});
    }
    else {
	return ();
    }
}

###########################################################################

=head1 get_first_instantiator

Get the first thing that instantiates this module.

  Arguments:  - module name

  Returns:    - a 4 element list: instantiating module, file, instance name, line

  Example:    
		($im,$f,$i) = $vdata->get_first_instantiator($m );

=cut
# Get the first thing that instantiates or empty list if none.
#  Returns: { module, file, inst }
sub get_first_instantiator{
    my ($self,$module) = @_;

    if ( exists( $self->{modules}{$module} )) {
	$self->{current_instantiator}       =0;
	$self->{current_instantiator_module}=$module;
	return $self->get_next_instantiator();
    }
    else {
	return ();
    }
}

###########################################################################

=head1 get_next_instantiator

Get the first thing that instantiates the module specified in 
get_first_instantiator (or _by_context).

  Returns:    - a 4 element list: instantiating module, file, 
                                    instance name, line

  Example:    
		($im,$f,$i) = $vdata->get_next_instantiator();

=cut
sub get_next_instantiator{
    my ($self) = @_;
    my ($module,$i);

    $module = $self->{current_instantiator_module};
    $i      = $self->{current_instantiator};

    if (@{$self->{modules}{$module}{inst_by}} > $i ) {
	$self->{current_instantiator}++;
	return ($self->{modules}{$module}{inst_by}[$i]{module},
	        $self->{modules}{$module}{inst_by}[$i]{file},
		$self->{modules}{$module}{inst_by}[$i]{inst},
		$self->{modules}{$module}{inst_by}[$i]{line} );
    }
    else {
	return ();
    }
}

###########################################################################

=head1 get_first_instantiation

Get the first thing that this module instantiates.

  Arguments:  - module name

  Returns:    - a 4 element list: instantiated module name, file, 
                  instance name, and line number

  Example:    
		($im,$f,$i,$l) = $vdata->get_first_instantiation($m);

=cut
sub get_first_instantiation{
    my ($self,$module) = @_;

    if ( exists( $self->{modules}{$module} )) {
	$self->{current_instantiation}       =0;
	$self->{current_instantiation_module}=$module;
	return $self->get_next_instantiation();
    }
    else {
	return ();
    }
}

###########################################################################

=head1 get_next_instantiation

Get the next thing that this module instantiates.


  Returns:    - a 4 element list: instantiated module name, file, 
                  instance name, and line number

  Example:    
		($im,$f,$i,$l) = $vdata->get_next_instantiation();

=cut
sub get_next_instantiation{
    my ($self) = @_;
    my ($module,$i);

    $module = $self->{current_instantiation_module};
    $i      = $self->{current_instantiation};

    if (@{$self->{modules}{$module}{instances}} > $i ) {
	$self->{current_instantiation}++;
	return ($self->{modules}{$module}{instances}[$i]{module},
	        $self->{modules}{$module}{instances}[$i]{file},
		$self->{modules}{$module}{instances}[$i]{inst_name},
		$self->{modules}{$module}{instances}[$i]{line} );
    }
    else {
	return ();
    }
}

###########################################################################

=head1 get_current_instantiations_port_con

Gets the port connections for the current instantiations (which is got
using get_first_instantiation and get_next_instantiation). If the 
instantiation does not use .port(...) syntax and rvp does not have the
access to the source of the module then the port names will be returned as
numbers in connection order starting at 0.


  Returns:    - A hash (well, really a list that can be assigned to a hash). 
               The keys of the hash are the port names. The values of the
               hash is everything (except comments) that appeared in the 
               brackets in the verilog.

  Example:    %port_con = $vdata->get_current_instantiations_port_con();
	      foreach $port (keys %port_con) { ...

=cut
sub get_current_instantiations_port_con{
    my ($self) = @_;
    my ($module,$i);

    $module = $self->{current_instantiation_module};
    $i      = $self->{current_instantiation} -  1;

    if (@{$self->{modules}{$module}{instances}} > $i ) {
	return (%{$self->{modules}{$module}{instances}[$i]{connections}});
    }
    else {
	return {};
    }
}

###########################################################################

=head1 get_current_instantiations_parameters

Gets the parameters for the current instantiations (which is set using
get_first_instantiation and get_next_instantiation).  If the
instantiation parameters does not use the verilog 2001 .name(...)
syntax and rvp does not have the access to the source of the module
then the parameter names will be returned as numbers reflecting the
order (starting at 0).


  Returns:    - A hash (well, really a list that can be assigned to a hash). 
               The keys of the hash are the parameters names. The values of the
               hash is everything (except comments) in the value.

  Example:    %parameters = $vdata->get_current_instantiations_parameters();
	      foreach my $p (keys %parameters) { ...

=cut
sub get_current_instantiations_parameters{
    my ($self) = @_;
    my ($module,$i);

    $module = $self->{current_instantiation_module};
    $i      = $self->{current_instantiation} -  1;

    my %r;
    if (@{$self->{modules}{$module}{instances}} > $i ) {
	foreach my $p (keys %{$self->{modules}{$module}{instances}[$i]{parameters}}) {
	    $r{$p}=$self->{modules}{$module}{instances}[$i]{parameters}{$p}{value};
	}
    }

    return %r;
}

###########################################################################

=head1 get_modules_parameters

Gets the parameters for a module.

  Arguments:  - module name

  Returns:    - A hash (well, really a list that can be assigned to a hash). 
               The keys of the hash are the parameters names. The values of the
               hash is everything (except comments) in the value.

  Example:    %parameters = $vdata->get_modules_parameters();
	      foreach my $p (keys %parameters) { ...

=cut
sub get_modules_parameters{
    my ($self,$module) = @_;

    my %r;
    foreach my $p (keys %{$self->{modules}{$module}{parameters}}) {
	$r{$p}=$self->{modules}{$module}{parameters}{$p}{value};
    }
    return %r;
}

#######################################################
################### Modified ###########################
#######################################################

=head1 get_modules_parameters_not_local

Gets the parameters for a module.

  Arguments:  - module name

  Returns:    - A hash (well, really a list that can be assigned to a hash). 
               The keys of the hash are the parameters names. The values of the
               hash is everything (except comments) in the value.

  Example:    %parameters = $vdata->get_modules_parameters();
	      foreach my $p (keys %parameters) { ...

=cut
sub get_modules_parameters_not_local{
    my ($self,$module) = @_;

    my %r;
    foreach my $p (keys %{$self->{modules}{$module}{parameters}}) {
	if ($self->{modules}{$module}{parameters}{$p}{ptype} ne "localparam"){
		#print "$p\n";
		$r{$p}=$self->{modules}{$module}{parameters}{$p}{value};
	}
    }
    return %r;
}




=head1 get_modules_parameters_not_local_in_order

Gets the parameter names in_order for a module.



=cut
sub get_modules_parameters_not_local_order{
    my ($self,$module) = @_;
	my @r=@{$self->{modules}{$module}{parameter_order}};#param/localparam inorder
	my @w; #parameter inorder
	foreach my $p (@r) {
		if ($self->{modules}{$module}{parameters}{$p}{ptype} ne "localparam"){
			push(@w,$p);
		}

	}

	return @w;
}




=head1 get_module_ports_inorder

Gets the parameter names in_order for a module.



=cut
sub get_module_ports_order{
    my ($self,$module) = @_;
	return @{$self->{modules}{$module}{port_order}};
}






###########################################################################

=head1 get_define

Find out where a define is defined and what the value is

  Arguments:  - name of the define
             Optional arguments where a you want the correct location and
               value for a particular use of a multiplely defined define:
              - file where define is used 
              - line where define is used

  Returns:    - list with three elements: file, line, value
                 or if the define does not exist it returns a empty list.
                 if the define was defined on the command line it sets file=""
                  and line=0


  Example:    ($f,$l,$v) = $vdata->get_define($word,$file,$line);

=cut
sub get_define {
    my ($self,$define,$file,$line) = @_;

    if ( !defined($self) || !defined($define) ||
	 ( defined($file) && !defined($line) ) ) {
	die "Get define takes either two or four arguments";
    }

    $define =~ s/^\`// ; # remove the ` if any

    if (!exists( $self->{defines}{$define} )) {
	return ();
    }
    my $index = 0;
    my $dh = $self->{defines}{$define};

    if (defined($file) &&
	exists($dh->{used}{$file}) &&
	exists($dh->{used}{$file}{$line})) {
	$index = $dh->{used}{$file}{$line};
    }


    if ($index eq "XX") {   # define has been undefed
	return ();
    }

    return ( $dh->{defined}[$index]{file},
	     $dh->{defined}[$index]{line},
	     $dh->{defined}[$index]{value});
}

###########################################################################

=head1 get_context

Get the context (if any) for a line in a file.

  Arguments:  - file name
              - line number

  Returns:    - line number if there is a context, zero if there is none.

  Example:    	$l = $vdata->get_context($filename,$line);

=cut
sub get_context{
    my ($self,$file,$line) = @_;

    if ( exists( $self->{files}{$file}{contexts}{$line} )) {
	return $line;
    }
    else {
	return 0;
    }
}

###########################################################################

=head1 get_module_start_by_context

Test if the context is a module definition start.

  Arguments:  - file name
              - line number

  Returns:    - module name if it is a module start, 0 otherwise

  Example:     if($vdata->get_module_start_by_context($filename,$line))..

=cut
# return true if the context for this line is a module start
sub get_module_start_by_context{
    my ($self,$file,$line) = @_;

    if ( exists( $self->{files}{$file}{contexts}{$line}{module_start})) {
	return $self->{files}{$file}{contexts}{$line}{module_start};
    }
    else {
	return 0;
    }
}

###########################################################################

=head1 get_has_value_by_context

Check if the context has a value (ie a new module or something). Contexts
that just turn on and off preprocessor ignoring do not have values.

  Arguments:  - file name
              - line number

  Returns:    - 1 if there is a value, 0 otherwise

  Example:    if ($vdata->get_has_value_by_context($file,$line))..

=cut
sub get_has_value_by_context{
    my ($self,$file,$line) = @_;

    return exists( $self->{files}{$file}{contexts}{$line}{value});
}

###########################################################################

=head1 get_context_name_type

Find the reason for a new context - is it a module / function or task.
Contexts that just turn on and off preprocessor ignoring do not have values.

  Arguments:  - file name
              - line number

  Returns:    - name
              - type [ module | function | task ]

  Example:    ($n,$t)=$vdata->get_context_name_type($file,$line);

=cut
sub get_context_name_type{
    my ($self,$file,$line) = @_;
    my ($name,$type);

    $type='';
    if (exists( $self->{files}{$file}{contexts}{$line}{value})) {
	$name= $self->{files}{$file}{contexts}{$line}{value}{name};
	if (exists( $self->{files}{$file}{contexts}{$line}{value}{type})) {
	    $type=$self->{files}{$file}{contexts}{$line}{value}{type};
	    $type='module' if ($type eq 'primitive' || $type eq 'macromodule');
	}
	return ($name,$type);
    }
    else {
	return ();
    }
}

###########################################################################

=head1 get_pre_ignore_by_context

Test if the context is preprocessor ignore.

  Arguments:  - file name
              - line number

  Returns:    - 1 if it is, 0 otherwise

  Example:    if ($vdata->get_pre_ignore_by_context($file,$line))..

=cut
sub get_pre_ignore_by_context{
    my ($self,$file,$line) = @_;
    
    if (exists($self->{files}{$file}{contexts}{$line}{pre_ignore})) {
	return $self->{files}{$file}{contexts}{$line}{pre_ignore};
    }
    else {
	return 0;
    }

}

###########################################################################

=head1 get_first_instantiator_by_context

Get the first thing that instantiates this module using the context. The
context must be a module_start.

  Arguments:  - file name (for context) 
              - line name (for context)

  Returns:    - a 4 element list: instantiating module, file, instance name, line

  Example:    
	      @i=$vdata->get_first_instantiator_by_context($f,$l );

=cut
sub get_first_instantiator_by_context{
    my ($self,$file,$line) = @_;

    # note: the second exists() checks that the module still exists as
    #  it could have been deleted because a duplicate was found
    if (exists($self->{files}{$file}{contexts}{$line}{module_start}) &&
	exists($self->{modules}
	       {$self->{files}{$file}{contexts}{$line}{module_start}}) &&
	exists($self->{files}{$file}{contexts}{$line}{value}{inst_by})) {
	$self->{current_instantiator}       =0;
	$self->{current_instantiator_module}=
	    $self->{files}{$file}{contexts}{$line}{module_start};
	return $self->get_next_instantiator();
    }
    else {
	return ();
    }

}

###########################################################################

=head1 get_inst_on_line

Gets the instance name of a line in a file

  Arguments:  - file name
              - line number

  Returns:    - name if the line has an instance name, 0 otherwise

  Example:    if ( $new_inst = $vdata->get_inst_on_line($file,$line) ) ...

=cut
sub get_inst_on_line{
    my ($self,$file,$line) = @_;

    if ( exists( $self->{files}{$file}{instance_lines}{$line})){
	return $self->{files}{$file}{instance_lines}{$line};
    }
    else {
	return 0;
    }
}

###########################################################################

=head1 get_signal_by_context

Same as get_module_signal but works by specifying a context.

  Arguments:  - context file name
              - context line number
              - signal name

  Returns:    same as get_module_signal

  Example:    

=cut
# get a signal by context - returns: line, a_line, i_line, type, file
sub get_signal_by_context{
    my ($self,$file,$cline,$sig) = @_;

    my $sigp;

    # in tasks and functions signals can come from module (m_signals)
    #  or from the task or function itself (which gets precedence).
    if (exists( $self->{files}{$file}{contexts}{$cline}{value}{signals}{$sig} )) {
	print " found signal $sig\n" if $debug;
	$sigp=$self->{files}{$file}{contexts}{$cline}{value}{signals}{$sig};
    }
    elsif (exists( $self->{files}{$file}{contexts}{$cline}{value}{m_signals}{$sig} )) {
	print " found m_signal $sig\n" if $debug;
	$sigp=$self->{files}{$file}{contexts}{$cline}{value}{m_signals}{$sig};
    }
    else {
	return ();
    }

    return ($sigp->{line},
	    $sigp->{a_line},
	    $sigp->{i_line},
	    $sigp->{type},
	    $sigp->{file},
	    $sigp->{posedge},
	    $sigp->{negedge},
	    $sigp->{type2},
	    $sigp->{source}{file},
	    $sigp->{source}{line},
	    $sigp->{range},
	    $sigp->{a_file},
	    $sigp->{i_file},
	    $sigp->{dimensions});
}

###########################################################################

=head1 get_t_or_f_by_context

Same as get_modules_t_or_f but works by specifying a context.

  Arguments:  - context file name
              - context line number
              - task name

  Returns:    - same as get_modules_t_or_f

  Example:    

=cut
sub get_t_or_f_by_context{
    my ($self,$cfile,$cline,$t_or_f) = @_;

    if (exists($self->{files}{$cfile}{contexts}{$cline}{value}{t_and_f}{$t_or_f})) {
	return($self->{files}{$cfile}{contexts}{$cline}{value}{t_and_f}{$t_or_f}{type},
	       $self->{files}{$cfile}{contexts}{$cline}{value}{t_and_f}{$t_or_f}{line},
	       $self->{files}{$cfile}{contexts}{$cline}{value}{t_and_f}{$t_or_f}{file},
	       $self->{files}{$cfile}{contexts}{$cline}{value}{t_and_f}{$t_or_f}{anchor});
    }
    else {
	return ();
    }
}
###########################################################################

=head1 get_parameter_by_context

Return the file and line for a named parameter using context

  Arguments:  - context file name
              - context line number
              - parameter name

  Returns:    - file and line of definition

  Example:    

=cut
sub get_parameter_by_context{
    my ($self,$cfile,$cline,$parameter) = @_;

    if (exists($self->{files}{$cfile}{contexts}{$cline}{value}{parameters}{$parameter})) {
	return($self->{files}{$cfile}{contexts}{$cline}{value}{parameters}{$parameter}{file},
	       $self->{files}{$cfile}{contexts}{$cline}{value}{parameters}{$parameter}{line});
    }
    else {
	return ();
    }
}
###########################################################################

=head1 get_anchors

Get the anchors for a line in a file.


  Returns:    - a list of anchors

  Example:   foreach $anchor ( $vdata->get_anchors($file,$line) ) ..

=cut
sub get_anchors{
    my ($self,$file,$line) = @_;

    if (exists($self->{files}{$file}{anchors}{$line})) {
	return @{$self->{files}{$file}{anchors}{$line}};
    }
    else {
	return ();
    }
}

###########################################################################

=head1 expand_defines

Expand the defines in a line of verilog code.  for best use this
should be called line by line, so that the defines get the correct
values when defines are defined multiple times

  Arguments:  - a pointer to the string to expand the defines in
              - the file the line is from
              - the line number of the line

  Returns:    - nothing

  Example:   $vdata->expand_defines(\$line_to_expand,$file,$line);

=cut
###############################################################################
#
sub expand_defines {
    my ($self,$bufp,$file,$line) = @_;

    if (exists($self->{files}{$file}{define_lines}{$line})) {
	# do not expand on a `define line - it doesn't make sense to do so
	#  as the substitution of defines in the value only occurs at the
	#  time of use when they could have different values!
	return;
    }


    while ( $$bufp =~ m/^(.*?)\`($VID)/ ) { 
	my $b = $1;
	my $d = $2;
	my $dq = quotemeta($d);
	my $v;
        if ((undef,undef,$v) = $self->get_define($d,$file,$line)) {
	    $$bufp =~ s/\`$dq/$v/;
	}
	else {
	    $$bufp =~ s/\`$dq/_BaCkQuOtE_$dq/;
	}

    }
    $$bufp =~ s/_BaCkQuOtE_/\`/g;
}


###########################################################################

=head1 verilog_gatetype_keywords


  Returns:    - a list of verilog gatetype keywords

  Example:   @keywords = rvp->verilog_gatetype_keywords();

=cut
sub verilog_gatetype_keywords {
    return (@verilog_gatetype_keywords);
}
###########################################################################

=head1 verilog_compiler_keywords

  Returns:    - a list of verilog compiler keywords

  Example:   @keywords = rvp->verilog_compiler_keywords();

=cut
sub verilog_compiler_keywords {
    return (@verilog_compiler_keywords);
}
###########################################################################

=head1 verilog_signal_keywords

  Returns:    - a list of verilog signal keywords

  Example:   @keywords = rvp->verilog_signal_keywords();

=cut
sub verilog_signal_keywords {
    return (@verilog_signal_keywords);
}


###########################################################################

=head1 chunk_read_init

Initialise a file for chunk reading (see chunk_read for more
details). It actually reads the whole file into a string, which
chunk_read then reads a chunk at a time. The file is closed before
chuck_read_init returns.

  Arguments:  - the file to read (with path if needed)
              - tabstop: 0 = leave tabs alone
                         N = turn tabs spaces with each tabstop=N
  Returns:    - a handle to pass to chunk_read or 0 if file open fails

  Example:    
            my $chunkRead = rvp->chunkr_read_init($f,$opts{tabstop});

=cut
sub chunk_read_init {

    my ($class,$f,$tabstop) = @_;
    local (*F);

    open(F,"<$f") || return 0;

    my $chunk = { type => "", 
		  text => "", 
		  isANewLine => 0, 
		  isStart => 0, 
		  isEnd => 1 ,
		  line => 0 };

    my $this = { chunk => $chunk , 
		 tabstop => $tabstop ,
	         linebuf => "" ,
	         state => 0 ,
		 fh => *F };
    return $this;
}

###########################################################################

=head1 chunk_read

Reads verilog a chunk at a time. The file is opened using
chunk_read_init. Then chunk_read is used to read the file a chunk at a
time.  A chunk is a line or part of a line that is all the same type.

  The types are: 
              comment   - either // or /* */ comment
              attribute - verilog 2001 (* *) atribute
              include   - a line containing `include "file"
              string    - a string
              code      - anything else (verilog code, defines, compliler keywords)

Nothing is removed from the file, so if each chunk is printed after being read
you will end up with exactly the same file as you put in.

  Arguments:  - handle (from chunk_read_init)

  Returns:    - 0 at the end of file, or a hash ref with the following keys:
              type       - one of the types (see above)
              text       - the text read from the file
	      line       - the line number the text is on
              isANewLine - true if chunk is the first chunk of the line
              isStart    - true if the chunk is the start (eg "/*..." for 
                             a comment )
              isEnd      - true if the chunk is the end ( eg "*/" )
                      NOTE: isEnd is set to undefined for a
                       type="code" that ends in a newline. This is
                       because chunk_read doesn't know if the code is
                       ending or not. If you need to know in this case
                       you can read the next chunk and see what type it is.

  Example:    
            my $chunkRead = rvp->chunk_read_init($f,0);
            while ($chunk = rvp->chunk_read($chunkRead)) {
                    print $chunk->{text} unless $chunk->{type} eq "comment";
            }

=cut
sub chunk_read {
   my ($class,$this) = @_;

   my $chunk = $this->{chunk};
   $chunk->{isStart} = $chunk->{isEnd};
   $chunk->{isEnd}  = 0;
   $chunk->{isANewLine} = 0;

   if ( $this->{linebuf} eq "" ) {
       if (!defined($this->{linebuf} = readline($this->{fh}))) {
	   close($this->{fh});
	   return 0;
       }
       $chunk->{isANewLine} = 1;
       $chunk->{line}++;
       if ($this->{tabstop}!=0) {
	   # 1 while is some stupid perl thing meaning while (cond) {} may be a bit faster?
	   1 while ($this->{linebuf} =~ s/(^|\n)([^\t\n]*)(\t+)/
		    $1. $2 . (" " x ($this->{tabstop} * length($3) - 
				     (length($2) % $this->{tabstop})))
		    /gsex);
       }
   }
       
 STATE_SWITCH:
   if ( $this->{state} == 0 ) {
       $chunk->{type} = "code";
       if ( $this->{linebuf} =~ 
	    s%^(.*?)((/\*)|           # anything followed by /* comment
		     (//)|            #    or // comment
		     (\(\*(?!\s*\)))| #    or (* attribute (but not (*)
		     (\`include\s)|   #    or `include
		     (\"))            #    or start of string   
	    %$2%ox ) {
	   $chunk->{isEnd} = 1;
	   $chunk->{text} = $1;
	   if (defined($3)) {
	       $this->{state} = 1;  # long comment
	   }
	   elsif (defined($4)) {
	       $this->{state} = 2;  # short comment
	   }
	   elsif (defined($5)) {
	       $this->{state} = 3;  # attribute
	   }
	   elsif (defined($6)) {
	       $this->{state} = 4;  # include
	   }
	   elsif (defined($7)) {
	       $this->{state} = 5;  # string
	   }
	   else {
	       die "chunk_read internal error!";
	   }
	   if (!$chunk->{text}) { 
	       # this happens if we are in state code and a new line
	       #  starts with something that isn't code. So we change
	       #  and go back to the top.
	       $chunk->{isStart} = 1; 
	       $chunk->{isEnd}  = 0;
	       goto STATE_SWITCH;
	   }
       }
       else {
	   $chunk->{text} = $this->{linebuf};
	   $this->{linebuf} = "";
	   # in this case we might be at end, but we don't really know!
	   $chunk->{isEnd}  = undef;
       }
   }
   elsif ( $this->{state} == 1 ) {
       $chunk->{type} = "comment";
       # this first test is needed to work so /*/  */ works
       if ( $chunk->{isStart} && $this->{linebuf} =~ s%^/\*%% ) {
	   $chunk->{text} = "/*";
       }
       else {
	   $chunk->{text} = "";
       }
       if ( $this->{linebuf} =~ s%^(.*?\*/)%% ) {          # anything followed by */
	   $chunk->{text} .= $1;
	   $this->{state} = 0;
	   $chunk->{isEnd} = 1;
       }
       else {
	   $chunk->{text} .= $this->{linebuf};
	   $this->{linebuf} = "";
       }
   }
   elsif ( $this->{state} == 2 ) {
       $chunk->{type} = "comment";
       $chunk->{text} = $this->{linebuf};
       $chunk->{isEnd} = 1;
       $this->{linebuf} = "";
       if ( $chunk->{text} =~ s/\n$// ) {
	   $this->{linebuf} = "\n";
       }
       $this->{state} = 0;
   }
   elsif ( $this->{state} == 3 ) {
       $chunk->{type} = "attribute";
       if ( $this->{linebuf} =~ s%^(.*?\*\))%% ) {          # anything followed by *)
	   $chunk->{text} = $1;
	   $this->{state} = 0;
	   $chunk->{isEnd} = 1;
       }
       else {
	   $chunk->{text} = $this->{linebuf};
	   $this->{linebuf} = "";
       }
   }
   elsif ( $this->{state} == 4 ) {
       $chunk->{type} = "include";
       $chunk->{isEnd} = 1;
       if ( $this->{linebuf} =~ s%^(\`include\s+\".*?\")%% ) {  
	   $chunk->{text} = $1;
	   $this->{state} = 0;
       }
       else {
	   # this is an error - just return the line as code - the parser will 
	   #  report the error
	   $chunk->{type} = 0;
	   $chunk->{text} = $this->{linebuf};
	   $this->{linebuf} = "";
       }
   }
   elsif ( $this->{state} == 5 ) {
       $chunk->{type} = "string";
       # string all on one line
       if ( $this->{linebuf} =~ s%^(\"(?:(?:\\\\)|(?:\\\")|(?:[^\"]))*?\")%% ) {
	   $chunk->{text} = $1;
	   $this->{state} = 0;
	   $chunk->{isEnd} = 1;
       }
       # end of multiline string (doesn't start with quote)
       elsif ( $this->{linebuf} =~ s%^([^\"](?:(?:\\\\)|(?:\\\")|(?:[^\"]))*?\")%% ) {
	   $chunk->{text} = $1;
	   $this->{state} = 0;
	   $chunk->{isEnd} = 1;
       }
       # middle of multiline string
       else { 
	   $chunk->{text} = $this->{linebuf};
	   $this->{linebuf} = "";
       }
   }

   return $chunk;
}

###############################################################################
#  RVP internal functions from now on.... (they all start with _ to 
#   let you know they are internal
###############################################################################

###############################################################################
# search a file, putting the data in $self
#   Note: be careful coding in the main loop... there are a few optimisations
#    which result in big chunks of code being skipped if the line does not
#    contain certain characters (eg ' " / *)
sub _search {
    my ($self,$f,$inc_dirs) = @_;

    my $verilog_compiler_keywords_regexp = "(?:" . 
	join("|",@verilog_compiler_keywords) . 
	    ")";


    my $file=_ffile($f);
    _init_file($self->{files},$f);

    print "Searching $f " unless $quiet;
    my $chunkRead= rvp->chunk_read_init($f,0) || 
	die "Error: can not open file $f to read: $!\n";
    my $file_dir = dirname($f);

    my $rs = {};
    $rs->{modules}   = $self->{modules};
    $rs->{files}     = $self->{files};
    $rs->{unres_mod} = $self->{unresolved_modules};
    
    $rs->{module}   = '';
    $rs->{function} = '';
    $rs->{task}     = '';
    $rs->{t}        = undef; # temp store
    $rs->{p}        = undef;

    my $printline = 1000;

    my $ps = {};
    my $nest=0;
    my $nest_at_ignore;
    my @ignore_from_elsif;
    my $ignoring=0;
    my @fileStack =();
    my $pp_ignore;
    my $chunk;
    while (1) {
	while ($chunk = rvp->chunk_read($chunkRead)) {
	    $self->{files}{$file}{lines} = $chunk->{line};
	    if ($chunk->{line}>$printline && !$quiet) {
		$printline+=1000;
		$|=1; # turn on autoflush
		print ".";
		$|=0 unless $debug; # turn off autoflush
	    }
	    
	    # deal quickly with blank lines
	    if ( $chunk->{text} =~ m/^\s*\n/ ) {
		next;
	    }


	    if ( $chunk->{type} eq "code" ) {

		
		####################################################
		# Optimisation: if there are no ` 
		#  we can parse the line now
		if ( $chunk->{text} !~ m|[\`]| ) { 
		    if ($nest && $ignoring) {
			next;
		    }
		    $self->_parse_line($chunk->{text},$file,$chunk->{line},$ps,$rs);
		    next;
		}

		# handle ifdefs
		if ($nest && $ignoring) {
		    if ( $chunk->{text} =~ m/^\s*\`(?:ifdef|ifndef)\s+($VID)/ ) {
			print " Found at line $chunk->{line} : if[n]def (nest=$nest)\n" if $debug;
			$nest++;
		    }
		    elsif ( $chunk->{text} =~ m/^\s*\`(else|(?:elsif\s+($VID)))/ ) {
			print " Found at line $chunk->{line} : $1 (nest=$nest)\n" if $debug;
			if ($1 eq 'else' || 
			    _parsing_is_defined($self->{defines},$2,
						$file,$chunk->{line})) {
			    # true elsif or plain else
			    if ($nest == $nest_at_ignore && 
				!$ignore_from_elsif[$nest]) {
				$ignoring=0;
				$$pp_ignore = $chunk->{line};
			    }
			}
		    }
		    elsif ( $chunk->{text} =~ m/^\s*\`endif/ ) {
			print " Found at line $chunk->{line} : endif (nest=$nest)\n" if $debug;
			if ($nest == $nest_at_ignore) {
			    $ignoring=0;
			    $$pp_ignore = $chunk->{line};
			}
			$nest--;
		    }
		    next;
		}
		# handle the case where the endif is on the same line as the ifdef
		#  (note: generally I only accept endif at the start of a line)
		if ( $chunk->{text} =~ m/\`(ifdef|ifndef)\s+($VID).*\`endif/ ) {
		    print "$file: ifdef and endif on same line\n" if $debug;
		    my $is_defined = _parsing_is_defined($self->{defines},$2,
							 $file,$chunk->{line});
		    if ( (($1 eq 'ifdef' ) && !$is_defined) ||
			 (($1 eq 'ifndef') &&  $is_defined)) {
			# replace ifdef with nothing
			$chunk->{text} =~ s/\`(ifdef|ifndef)\s+($VID)(.*)\`endif//;
		    }
		    else {
			# replace ifdef with what is between the ifdef and endif
			$chunk->{text} =~ s/\`(ifdef|ifndef)\s+($VID)(.*)\`endif/$3/;
		    }
		}
		if ( $chunk->{text} =~ m/^\s*\`(ifdef|ifndef)\s+($VID)/ ) {
		    $nest++;
		    print " Found at line $chunk->{line} : $1 $2 (nest=$nest)\n" if $debug;
		    my $is_defined = _parsing_is_defined($self->{defines},$2,
							 $file,$chunk->{line});
		    if ( (($1 eq 'ifdef' ) && !$is_defined) ||
			 (($1 eq 'ifndef') &&  $is_defined)) {
			$ignoring=1;
			$self->{files}{$file}{contexts}{$chunk->{line}}{pre_ignore} = 'XX';
			$pp_ignore = \$self->{files}{$file}{contexts}{$chunk->{line}}{pre_ignore};
			$nest_at_ignore=$nest;
			$ignore_from_elsif[$nest]=0;
		    }
		    next;
		}
		if ( $chunk->{text} =~ m/^\s*\`(else|(?:elsif\s+($VID)))/ ) {
		    print " Found at line $chunk->{line} : $1 (nest=$nest)\n" if $debug;
		    if ($nest) {
			$ignoring=1;
			$self->{files}{$file}{contexts}{$chunk->{line}}{pre_ignore} = 'XX';
			$pp_ignore = \$self->{files}{$file}{contexts}{$chunk->{line}}{pre_ignore};
			$nest_at_ignore=$nest;
			# an ignore from an elsif means you will never stop ignoring
			#   at this nest level
			$ignore_from_elsif[$nest]=($1 ne 'else');
		    }
		    else {
			$self->_add_warning("$file:$chunk->{line}: found $1 without \`ifdef");
		    }
		    next;
		}
		if ( $chunk->{text} =~ m/^\s*\`endif/ ) {
		    print " Found at line $chunk->{line} : endif (nest=$nest)\n" if $debug;
		    if ($nest) {
			$nest--;
		    }
		    else {
			$self->_add_warning("$file:$chunk->{line}: found \`endif without \`ifdef");
		    }
		    next;
		}
		
		# match define. Note: /s makes the .* match the \n too
		if ( $chunk->{text} =~ m/^\s*\`define\s+($VID)(.*)/s ) {
		    my $def = $1;
		    my $rest = defined($2)?$2:'';
		    my $defLine = $chunk->{line};
		    $self->{files}{$file}{define_lines}{$chunk->{line}} = 1;

		    # _parsing_expand_defines is called to register the use 
		    #  of any multiplely defined defines in the value part of 
		    #  the define
		    my $tmpValue=$rest;
		    $self->_parsing_expand_defines(\$tmpValue,$file,$chunk->{line});

		    # handle multiline defines: read more stuff if line ends in backslash
		    #  (revisit: verilog spec says leave the newline in the value)
		    # also keep adding stuff to value until it ends in a newline or comment
		    #  because strings are seperated out, `define T $display("test")
		    #  is delivered as chunks '`define T $display(' ,'"test"', ')\n'
		    while ( (($rest =~ s|\\\n|| ) ||  ($rest !~ m/\n$/) )
			    && ($chunk = rvp->chunk_read($chunkRead))) {
			last if $chunk->{type} eq "comment";
			$rest .= $chunk->{text};
			$self->{files}{$file}{define_lines}{$chunk->{line}} = 1;
			# _parsing_expand_defines call: see comment ~15 lines back
			my $tmpValue=$chunk->{text};
			$self->_parsing_expand_defines(\$tmpValue,$file,$chunk->{line});
		    }
		    my $value = $rest;
		    $value =~ s/^\s+(.*)(\n)?/$1/;

		    print " Found in $file line $defLine : define $def = $value\n"
			if $debug;
		    _add_define($self->{defines}, $def , $value , $file, $defLine );
		    _add_anchor($self->{files}{$file}{anchors},$defLine,"");  
		    # Don't substitute now: [defines] shall be substituted after the 
		    # original macro is substituted, not when it is defined(1364-2001 pg353)
		    next;
		}
		
		if ( $chunk->{text} =~ m/^\s*\`undef\s+($VID)/ ) {
		    _undef_define($self->{defines},$1);
		    print " Found at line $chunk->{line} : undef $1\n" if $debug;
		    next;
		}
		
		if ( $chunk->{text} =~ m/^\s*$verilog_compiler_keywords_regexp/ ) {
		    next;
		}
		$self->_parsing_expand_defines(\$chunk->{text},$file,$chunk->{line});
	    
		# Note this is called from two other places (optimisations)
		$self->_parse_line($chunk->{text},$file,$chunk->{line},$ps,$rs);
	    }
	    elsif ( $chunk->{type} eq "include" ) {
		if ($nest && $ignoring) {
		    next;
		}
		
		$chunk->{text} =~ m/^\s*\`include\s+\"(.*?)\"/ ;
		# revisit - need to check for recursive includes
		print " Found at line $chunk->{line} : include $1\n" if $debug;
		$self->{files}{$file}{includes}{_ffile($1)}=$chunk->{line};
		my $inc_file = $1;
		my $inc_file_and_path = _scan_dirs($inc_file,$inc_dirs,$file_dir);
		if ($inc_file_and_path) {
		    push(@fileStack,$chunkRead,$f);
		    $f = $inc_file_and_path;
		    $file=_ffile($f);
		    $file_dir = dirname($f);
		    
		    if (!exists($self->{files}{$file})) {
			_init_file($self->{files},$f);
			if (exists($rs->{modules}{$rs->{module}})) {
			    $self->{files}{$file}{contexts}{"1"}{value} = 
				$rs->{modules}{$rs->{module}};
			}
		    }
		    print "\n Include: $f " unless $quiet;
		    $chunkRead=rvp->chunk_read_init($f,0);
		}
		else {
		    $self->_add_warning("$file:$chunk->{line}: Include file $inc_file not found");
		}
		next;
	    }
	    
	    if (defined($pp_ignore) && $pp_ignore eq "XX") { # no endif
		$$pp_ignore = $chunk->{line};
	    }
	}
	# check if we were included from another file
	if (0==scalar(@fileStack)) {
	    print "Stack is empty\n" if $debug;
	    last;
	}
	else {
	    $f    = pop(@fileStack);
	    $chunkRead = pop(@fileStack);
	    $file = _ffile($f);
	    $file_dir = dirname($f);
	    print "\n Back to $f" unless $quiet;
	}
    }

    print "\n" unless $quiet;

    $self->_check_end_state($file,$self->{files}{$file}{lines},$ps);
    
}

sub _open_file {
    my ($f) = @_;
    local (*F);

    print "Searching $f " unless $quiet;
    open(F,"<$f") || die "Error: can not open file $f to read: $!\n ";
    return *F;
}

# only for use while parsing - returns the last defined value
#  in a multiple define case, and also sets up the {used} info
#  for use later when querying the database
# returns ($value,$errcode)
#  where $errcode = 0  value ok
#                   1  value never defined
#                   2  value has been undefined
sub _parsing_get_define_value {
    my ($defines,$define,$file,$line) = @_;

    if (!exists( $defines->{$define} )) {
	return ('',1);
    }
    my $index = 0;
    my $dh = $defines->{$define};

    if ( 1 < @{$dh->{defined}} ) {
	$index = $#{$dh->{defined}};

	$dh->{used}{$file}{$line} = $index;
    }

    if ($dh->{defined}[$index]{undefed}) {
	$dh->{used}{$file}{$line} = "XX";
	return ('',2);
    }
	 
    return  ( $dh->{defined}[$index]{value} , 0 );
}

sub _parsing_is_defined {
    my ($defines,$define,$file,$line) = @_;

    my $v;
    my $errcode;
    ($v,$errcode) = _parsing_get_define_value($defines,$define,$file,$line);
    if ( ($errcode == 1)  ||   # never defined
	 ($errcode == 2) ) {   # defined then undefed
	return 0;
    }
    elsif ($errcode == 0) {
	return 1;
    }
    else {
	die "parsing_is_defined internal error code=$errcode";
    }
}

sub _undef_define {
    my ($defines,$define) = @_;

    if (exists( $defines->{$define} )) {
	my $index = $#{$defines->{$define}{defined}};
	$defines->{$define}{defined}[$index]{undefed} = 1;
    }
}

###############################################################################
# for best use this should be called line by line, so that the
#  defines get the correct values when defines are defined multiple
#  times
# - this function is only used during the initial parsing of the files
#  (it has the error reproting code in it), use expand_defines() other times
#  it also expands on define lines (used to register the use of multiple
#   define defines) which expand_defines doesn't
#
sub _parsing_expand_defines {
    my ($self,$bufp,$file,$line) = @_;
    
    my $defines = $self->{defines};
    while ( $$bufp =~ m/^(.*?)\`($VID)/ ) { 
	my $b = $1;
	my $d = $2;
	my $dq = quotemeta($d);
	my $v;
	my $errCode=0;
	($v,$errCode)=_parsing_get_define_value($defines,$d,$file,$line);

	if ($errCode == 0) {  # no error
	    $$bufp =~ s/\`$dq/$v/;
	}
	else {
	    if ($errCode == 2) {  # defined but then undefed
		$self->_add_warning("$file:$line: define `$d used after undef");
		$$bufp =~ s/\`$dq//;
	    }
	    elsif ($b =~ m/^\s*$/) {
		$self->_add_warning("$file:$line: unknown define: `$d, guessing it is a compiler directive");
		$$bufp='';
	    }
	    else {
		$self->_add_warning("$file:$line: found undefined define `$d");
		$$bufp =~ s/\`$dq//;
	    }
	}
    }
}

###############################################################################
# Look through all the include/library directories for an include/library file
#  optional $file_dir is used when including - here a relative path is
#   relative to the file doing the including, so check this it checks this
sub _scan_dirs {
    my ($fname,$inc_dirs,$file_dir) = @_;
    my ($dir);

    if ( $fname =~ m|^/| ) { # an absolute path
      return "$fname" if ( -r "$fname" && ! -d "$fname");
    }
    if (defined($file_dir) && -r "$file_dir/$fname" && ! -d "$file_dir/$fname") {
	return "$file_dir/$fname";
    }
    else {
      foreach $dir (@{$inc_dirs}) {
	  $dir =~ s|/$||;
	  return "$dir/$fname" if ( -r "$dir/$fname" && ! -d "$dir/$fname");
      }
    }
    return '';
}

###############################################################################
# Take a look through the unresolved modules , delete any that have already
#  been found, and for the others look on the search path
#
sub _resolve_modules {
    my ($self,$lib_dirs, $lib_exts)= @_;
    my ($m,$file,@resolved,$lib_ext);

    @resolved=();
    foreach $m (sort (keys %{$self->{unresolved_modules}})) {
	if ( exists( $self->{modules}{$m} )) {
	    delete( $self->{unresolved_modules}{$m} );
	}
	else {
	    foreach $lib_ext (@{$lib_exts}) {
		if ($file = _scan_dirs("$m$lib_ext",$lib_dirs)){
		    delete( $self->{unresolved_modules}{$m} );	
		    print "resolve_modules: found $m in $file\n" if $debug;
		    push(@resolved,$file);
		    last;
		}
	    }
	}
    }
    return @resolved;
}


###############################################################################
# Initialize fdata->{files}{FILE} which stores file data
#
sub _init_file {
    my ($fdataf,$file) = @_;
    my ($fb);
    $fb = _ffile($file);
    $fdataf->{$fb} = {};                 # set up hash for each file
    $fdataf->{$fb}{full_name} = $file;   
    $fdataf->{$fb}{anchors}  = {};
    $fdataf->{$fb}{modules}  = {};
    $fdataf->{$fb}{contexts} = {};
    $fdataf->{$fb}{includes} = {};
    $fdataf->{$fb}{inc_done} = 0;
    $fdataf->{$fb}{lines}    = 0;
    $fdataf->{$fb}{instance_lines} = {};
    $fdataf->{$fb}{define_lines} = {};
    $fdataf->{$fb}{included_by} = [];

}

###############################################################################
# Initialize fdata->{FILE}{modules}{MODULE} which stores 
#  module (or macromodule or primitive) data
#
sub _init_module {
    my ($modules,$module,$file,$line,$type) = @_;


    die "Error: attempt to reinit module" if (exists($modules->{$module}));

    $modules->{$module}{line}     = $line;
    $modules->{$module}{name}     = $module;
    $modules->{$module}{type}     = $type;
    $modules->{$module}{end}       = -1;
    $modules->{$module}{file}      = $file;
    $modules->{$module}{t_and_f}   = {}; # tasks and functions
    $modules->{$module}{signals}   = {};
    $modules->{$module}{parameter_order}= [];
    $modules->{$module}{parameters}= {};
    $modules->{$module}{instances} = []; # things that this module instantiates
    $modules->{$module}{inst_by}   = []; # things that instantiated this module
    $modules->{$module}{port_order} = []; 
    $modules->{$module}{named_ports} = 1; # assume named ports in instantiations
    $modules->{$module}{duplicate} = 0;   # set if another definition is found

}

###############################################################################
# Initialize fdata->{FILE}{modules}{MODULE}{t_and_f}{TF} which
#  stores tasks and functions' data
#
sub _init_t_and_f {
    my ($self,$module,$type,$tf,$file,$line,$anchor) = @_;

    if (exists($module->{t_and_f}{$tf})) {
	$self->_add_warning("$file:$line new definition of $tf ".
		    "(discarding previous from ".
		    "$module->{t_and_f}{$tf}{file}:$module->{t_and_f}{$tf}{line})");
    }
    $module->{t_and_f}{$tf} = {};
    $module->{t_and_f}{$tf}{type}      = $type;
    $module->{t_and_f}{$tf}{name}      = $tf;
    $module->{t_and_f}{$tf}{line}      = $line;
    $module->{t_and_f}{$tf}{end}       = -1;
    $module->{t_and_f}{$tf}{file}      = $file;
    $module->{t_and_f}{$tf}{signals}   = {};
    $module->{t_and_f}{$tf}{anchor}    = $anchor;
    # point up at things to share with module:
    #  - task and functions
    #  - module signals
    $module->{t_and_f}{$tf}{t_and_f}    = $module->{t_and_f}; 
    $module->{t_and_f}{$tf}{parameters} = $module->{parameters}; 
    $module->{t_and_f}{$tf}{parameter_order} = $module->{parameter_order}; 
    $module->{t_and_f}{$tf}{m_signals}  = $module->{signals};
}

# note returns 1 if a signal is added (and an anchor needs to be dropped)
sub _init_signal  { 
    my ($self,$signals,$name,$type,$type2,$range,$file,$line,$warnDuplicate,$dims) = @_;

    if (exists( $signals->{$name} )) {
	if ($warnDuplicate) {
	    if (($signals->{$name}{type} eq "output")||
		($signals->{$name}{type} eq "inout")||
		($signals->{$name}{type} eq "input")) {
		if (($signals->{$name}{type} eq "input")
		    && ($type eq "reg")) {
		    $self->_add_warning("$file:$line: ignoring definition".
				" of input $name as reg (defined as input at". 
				" $signals->{$name}{file}:$signals->{$name}{line})");
		}
		else {
		    $signals->{$name}{type2}=$type;
		}
	    }
	    elsif (($signals->{$name}{type} eq "reg")&&  # reg before output
		   (($type eq "output") ||
		    ($type eq "inout"))) {
		$signals->{$name}{type}=$type;
		$signals->{$name}{type2}="reg";
	    }
	    else {
		$self->_add_warning("$file:$line: ignoring another definition".
			    " of signal $name ($type) first seen as". 
			    " $signals->{$name}{type} at".
			    " $signals->{$name}{file}:$signals->{$name}{line}");
	    }
	}
	return 0;
    }
    else {
	$signals->{$name} = { type     => $type, 
			      file     => $file,
			      line     => $line,
			      a_line   => -1,
			      a_file   => "",
			      i_line   => -1,
			      i_file   => "",
			      port_con => [],
			      con_to   => [],
			      posedge  => 0,
			      negedge  => 0,
			      type2    => $type2,
			      source   => { checked => 0, file => "" , 
					    line => "" },
			      range    => $range,
			      dimensions => $dims,
			      };
	return 1;
    }
}

###############################################################################
# Add an anchor to the list of anchors that need to be put in
#  the file
#
sub _add_anchor {
    my ($anchors,$line,$name) = @_;

    my ($a,$no_name_exists);

    if (! exists($anchors->{$line}) ) {
	$anchors->{$line} = [];
    }

    if ( $name ) {
	push( @{$anchors->{$line}} , $name );
    }
    else {
	# if no name is specified then you'll get the line number
	#  as the name, but make sure this only happens once
	$no_name_exists = 0;
	foreach $a ( @{$anchors->{$line}} ) {
	    if ($a eq $line) {
		$no_name_exists=1;
		last;
	    }
	}
	push( @{$anchors->{$line}} , $line ) unless ($no_name_exists);
    }
}

sub _add_define {
    my ($defines,$def_name,$def_value,$file,$line) = @_;

    $def_value = '' if (!defined($def_value));
    $def_value =~ s/\s+$//; # remove whitespace from end of define

    if (!exists($defines->{$def_name})) {
	$defines->{$def_name} = { defined => [] , used => {} };
    }

    if ( (1 == @{$defines->{$def_name}{defined}}) && 
	 ($defines->{$def_name}{defined}[0]{file} eq $file) &&
	 ($defines->{$def_name}{defined}[0]{line} == $line) ) {
	# if the define is already defined once (and only once) and that 
	#  was the same def (file & line the same - for instance in included
	#   file) then there is no need to do anything
    }
    else {
	push (@{$defines->{$def_name}{defined}},
	      { line => $line, file => $file ,
		value => $def_value, undefed => 0 });
    }
}

###############################################################################
#   Cross referencing
###############################################################################

###############################################################################
# Cross-reference all the files:
#  - find the modules and set up $self->{modules}
#  - store the data about where it is instatiated with each module
#  - check for self instantiation
#  - check for files with modules + instances outside modules
#  - set a_line for signals driven by output and i_line
#
sub _cross_reference {
    my ($self) = @_;
    my ($f,$m,$fr,$mr,$m2,$inst,$sig,$sigp,$port_con,$param,$i,$port,$con_to);

    # stores the instantiation data in an 
    #  array so that we can easily tell which modules
    #  are disconnected and which are the tops of the
    #  hierarchy and makes it easier to go up
    foreach $m (sort (keys %{$self->{modules}})) {
	print " Making inst_by for $m\n" if $debug;
	foreach $m2 (sort (keys %{$self->{modules}})) {
	    foreach $inst (@{$self->{modules}{$m2}{instances}}) {
		if (($inst->{module} eq $m) &&
		    exists($self->{modules}{$m})) {
		    print "    inst by $m2\n" if $debug;
		    push( @{$self->{modules}{$m}{inst_by}}, 
			   { module => $m2,
			     file   => $inst->{file},
		             inst   => $inst->{inst_name} ,
			     line   => $inst->{line} } );
		}
	    }
	}
    }

    # Find any modules that appear to instantiate themselves
    #  (to prevent getting into infinite recursions later on)
    foreach $m (sort (keys %{$self->{modules}})) {
	print " Checking  self instantiations for $m\n" if $debug;
	foreach $inst (@{$self->{modules}{$m}{instances}}) {
	    if ($inst->{module} eq $m) {
		$self->_add_warning("$inst->{file}:$inst->{line}: $m ".
			    "instantiates itself");
		$inst->{module} = '_ERROR_SELF_INSTANTIATION_'; 
		# remove the port con for all signals not attached
		foreach $sig (sort (keys %{$self->{modules}{$m}{signals}})) {
		    $sigp = $self->{modules}{$m}{signals}{$sig};
		    my $port_con_ok=[];
		    foreach $port_con (@{$sigp->{port_con}}) {
			if ($port_con->{module} ne $m) { push(@$port_con_ok,$port_con); }
			else {  print " Deleting connection for $sig\n" if $debug; }
		    }
		    $sigp->{port_con} = $port_con_ok;
		}
	    }
	}
    }

    # Go through instances without named ports (port will be a number instead) and
    #  resolve name if you can, otherwise delete. These can appear in signal's port_con
    #  lists and in instances connections lists.
    foreach $m (sort (keys %{$self->{modules}})) {
	if (0 == $self->{modules}{$m}{named_ports}) {
	    $f = $self->{modules}{$m}{file}; # for error messages
	    print " Resolving numbered port connections in $m\n" if $debug;
	    foreach $sig (sort (keys %{$self->{modules}{$m}{signals}})) {
		print "   doing $sig\n" if $debug;
		$sigp = $self->{modules}{$m}{signals}{$sig};

		foreach $port_con (@{$sigp->{port_con}}) {
		    if ($port_con->{port} =~ m/^[0-9]/ ) {
			if ( exists( $self->{modules}{$port_con->{module}}) ) {
			    $m2 = $self->{modules}{$port_con->{module}};
			    if (defined($m2->{port_order}[$port_con->{port}])) {
				$port_con->{port}=$m2->{port_order}[$port_con->{port}];
			    }
			    else {
				$self->_add_warning("$port_con->{file}:$port_con->{line}:".
					    " could not resolve port number to name");
			    }
			}
		    }
		}
	    }

	    foreach $inst (@{$self->{modules}{$m}{instances}}) {
		if ( exists( $self->{modules}{$inst->{module}}) ) {
		    $m2 = $self->{modules}{$inst->{module}};
		    foreach $port (sort (keys %{$inst->{connections}})) {
			last if ($port !~ m/^[0-9]/); # if any are named, all are named
			if (defined($m2->{port_order}[$port])) {
			    # move old connection to named port
			    $inst->{connections}{$m2->{port_order}[$port]} =
				$inst->{connections}{$port};
			    # remove old numbered port from hash
			    delete($inst->{connections}{$port});
			}
			else {
			    $self->_add_warning("$inst->{file}:$inst->{line}:".
					"could not resolve port number $port to name)");
			}
		    }
		}
	    }
	}
    }

    # Go through all instances with parameter lists and try to resolve names parameter
    #  
    foreach $m (sort (keys %{$self->{modules}})) {
	foreach $inst (@{$self->{modules}{$m}{instances}}) {
	    if ($inst->{parameters}) {
		if ( exists( $self->{modules}{$inst->{module}}) ) {
		    my $mp=$self->{modules}{$inst->{module}};
		    foreach my $p (sort (keys %{$inst->{parameters}})){
			last if ( $p !~ m/^[0-9]+$/ );
			my $pn = $mp->{parameter_order}[$p];
			if ($pn) {
			    $inst->{parameters}{$pn} =
				$inst->{parameters}{$p};
			    delete($inst->{parameters}{$p});
			    print "$inst->{parameters}{$pn}{file}:".
				"$inst->{parameters}{$pn}{line}: ".
			        "Resolved $p to $pn = $inst->{parameters}{$pn}{value}\n"
				  if $debug;
			}
			else {
			    $self->_add_warning("$inst->{parameters}{$p}{file}:".
					"$inst->{parameters}{$p}{line} ".
					"could not resolve parameter number $p to name");
			}
		    }
		}
	    }
	}
    }

    # Go through all the modules and each signal inside
    #  looking at whether the signal is connected to any outputs
    #   (set the a_line on the first one if it is not already set)
    #  Also, when you see a signal connected to an input (and that
    #   submod is only instantiated once) reach down into the submod
    #   and set the i_line of that signal, so that clicking on the
    #   input can pop you up to the line that input is driven in
    #   one of the instantiations
    foreach $m (sort (keys %{$self->{modules}})) {
	print " Finding port connections in $m\n" if $debug;
	foreach $sig (sort (keys %{$self->{modules}{$m}{signals}})) {
	    print "   checking signal $sig\n" if $debug;
	    $sigp = $self->{modules}{$m}{signals}{$sig};

	    foreach $port_con (@{$sigp->{port_con}}) {
		if ( exists( $self->{modules}{$port_con->{module}}) ) {
		    print "    connection to $port_con->{module}\n" if $debug;
		    $m2 = $self->{modules}{$port_con->{module}};
		    if (exists( $m2->{signals}{$port_con->{port}})) {
			push(@{$m2->{signals}{$port_con->{port}}{con_to}}, 
			     { signal => $sig , module => $m , inst => $port_con->{inst}});
			if ( ($m2->{signals}{$port_con->{port}}{type} eq 
			      'output') &&
			    ($sigp->{a_line} == -1)) {
			    $sigp->{driven_by_port}=1;
			    $sigp->{a_line} = $port_con->{line};
			    $sigp->{a_file} = $port_con->{file};
			    _add_anchor($self->{files}{$port_con->{file}}{anchors},
				       $port_con->{line},'');
			}
			elsif ($m2->{signals}{$port_con->{port}}{type} eq 
			       'input') {
			    $m2->{signals}{$port_con->{port}}{driven_by_port}=1;
			    if (scalar(@{$m2->{inst_by}}) &&
				($m2->{signals}{$port_con->{port}}{i_line}==-1)) {
				$m2->{signals}{$port_con->{port}}{i_line}=
				  $port_con->{line};
				$m2->{signals}{$port_con->{port}}{i_file}=
				  $port_con->{file};
				_add_anchor($self->{files}{$port_con->{file}}{anchors},
					   $port_con->{line},'');
				print "    set i_line $port_con->{port} ".
				    "$port_con->{file}:$port_con->{line}\n" if $debug;
			    }
			}
		    }
		}
	    }
	}
    }

    # find all signal sources
    foreach $m (sort (keys %{$self->{modules}})) {
	print " Finding signal sources in $m\n" if $debug;
	foreach $sig (sort (keys %{$self->{modules}{$m}{signals}})) {
	    $sigp = $self->{modules}{$m}{signals}{$sig};
	    next if $sigp->{source}{checked};
	    print "   finding signal source for $sig of $m\n" if $debug;
	    $sigp->{source} = $self->_find_signal_source($sigp);
	}
    }
    
    # propagate the posedge, negedge stuff up the hierarchy
    foreach $m (sort (keys %{$self->{modules}})) {
	# only do the recursion for top level modules
	if ( 0== @{$self->{modules}{$m}{inst_by}} ) {
	    $self->_prop_edges($m);
	}
    }
    
    # get included_by information
    foreach $f ( sort (keys %{$self->{files}} )) {
	foreach $i ($self->get_files_includes($f)) {
	    if (exists $self->{files}{$i}) {
		push( @{$self->{files}{$i}{included_by}} , $f );
	    }
	}
    }
}

sub _find_signal_source {
    my ($self,$sigp) = @_;
    my ($con_to,$port_con,$ret_val);

    if ($sigp->{source}{checked}) {
	print "     source already found\n" if $debug;
	$ret_val = $sigp->{source};
    }
    else {
	$ret_val =  { checked => 1, file => '' , line => '' };
	if (exists($sigp->{driven_by_port})) {
	    print "     drive by port\n" if $debug;
	    foreach $con_to (@{$sigp->{con_to}}) {
#		if ($self->{modules}{$con_to->{module}}{signals}{$con_to->{signal}}{type} eq 'input') {
		if ($sigp->{type} eq 'input') {
		    print "       following input $con_to->{signal} $con_to->{module} $con_to->{inst}\n" if $debug;
		    if (!exists($self->{modules}{$con_to->{module}}{signals}{$con_to->{signal}}{i_line})) { die "Error: $con_to->{signal} does not exist $!"; }
		    $ret_val = $self->_find_signal_source(
					      $self->{modules}{$con_to->{module}}{signals}{$con_to->{signal}});
		}
	    }
	    foreach $port_con (@{$sigp->{port_con}}) {
		if (exists ($self->{modules}{$port_con->{module}})) {
		    if (exists($self->{modules}{$port_con->{module}}{signals}{$port_con->{port}})) {
			if ($self->{modules}{$port_con->{module}}{signals}{$port_con->{port}}{type} eq 'output') {
			    print "       following output $port_con->{port} $port_con->{module} $port_con->{inst}\n" if $debug;
			    $ret_val = $self->_find_signal_source(
							  $self->{modules}{$port_con->{module}}{signals}{$port_con->{port}});
			}
		    }
		    else {
			$self->_add_warning("$port_con->{file}:$port_con->{line}:".
				    " Connection to nonexistent port ".
				    " $port_con->{port} of module $port_con->{module}");
		    }
		}
	    }
	}
	else {
	    if ($sigp->{a_line}==-1) {
		if ($sigp->{type} eq 'input') {
		    print "     signal is an input not driven at higher level\n" if $debug;
		    $ret_val =  { checked => 1, file => $sigp->{file} , line => $sigp->{line} };
		}
		else {
		    print "     signal has unknown source\n" if $debug;
		}
	    }
	    else {
		print "     signal is driven in this module\n" if $debug;
		$ret_val =  { checked => 1 , file => $sigp->{a_file} , line => $sigp->{a_line} };
	    }
	}
    }

    $sigp->{source} = $ret_val;
    return $ret_val;
}

###############################################################################
# Propagate posedge and negedge attributes of signals up the hierarchy
#
sub _prop_edges {
    my ($self,$m) = @_;
    my ($imod,@inst,$sig,$sigp,$port_con,$m2);

    print "Prop_edges $m\n" if $debug;

    for ( ($imod) = $self->get_first_instantiation($m) ;
	  $imod;
	  ($imod) = $self->get_next_instantiation()) {
	push(@inst,$imod) if (exists( $self->{modules}{$imod}));
    }
    foreach $imod (@inst) { $self->_prop_edges($imod); }

    # Propagate all the edges up the hierarchy
    foreach $sig (sort (keys %{$self->{modules}{$m}{signals}})) {
	print "   checking signal $sig\n" if $debug;
	$sigp = $self->{modules}{$m}{signals}{$sig};
	
	foreach $port_con (@{$sigp->{port_con}}) {
	    if ( exists( $self->{modules}{$port_con->{module}}) ) {
		print "    connection to $port_con->{module}\n" if $debug;
		$m2 = $self->{modules}{$port_con->{module}};
		if (exists( $m2->{signals}{$port_con->{port}})) {
		    print "Propagating posedge on $sig from $port_con->{module} to $m\n" 
			if ($debug && (!$sigp->{posedge})  && $m2->{signals}{$port_con->{port}}{posedge});
		    $sigp->{posedge} |= $m2->{signals}{$port_con->{port}}{posedge};
		    $sigp->{negedge} |= $m2->{signals}{$port_con->{port}}{negedge};
		}
	    }
	}
    }
}


###############################################################################
# given a source file name work out the file without the path
#
sub _ffile {
    my ($sfile) = @_;

    $sfile =~ s/^.*[\/\\]//;

    return $sfile;
}

sub _add_warning {
    my ($self,$p) = @_;

    print "Warning:$p\n" if $debug;
    push (@{$self->{problems}},"Warning:$p");
}
sub _add_confused {
    my ($self,$p) = @_;

    print "Confused:$p\n" if $debug;
    push (@{$self->{problems}},"Confused:$p");
}

###############################################################################
# 
BEGIN {
$baseEval = {
  START => {
    MODULE => '$rs->{t}={ type=>$match, line=>$line };',
  },
  MODULE => {
    SIGNAL => '$rs->{t}={ type=>$match, range=>"", dimensions=>[], name=>"" , type2=>"",block=>0};',
    # if you add to this also edit {AFTER_INST}{COMMA}
    INST => '$rs->{t}={ mod=>$match, line=>$line, name=>"" , port=>0 , 
                        params=>{}, param_number=>0 , portName=>"" , vids=>[]};', 
  },
  MODULE_NAME => {
    NAME => 'my $nState="MODULE_PPL"; 
             my $type = $rs->{t}{type};  $rs->{t}=undef;',
  },
  IN_CONCAT => {
    VID => 'push(@{$rs->{t}{vids}},{name=>$match,line=>$line}) if (exists($rs->{t}{vids}));',
  },
  IN_BRACKET => {
    VID => 'IN_CONCAT:VID',
  },
  SCALARED_OR_VECTORED => {
    TYPE => 'if ($match eq "reg") { $rs->{t}{type2} = "reg"; }'
  },
  SIGNAL_NAME => {
    VID => '$rs->{t}{name}=$match; $rs->{t}{line}=$line;',
  },
  SIGNAL_AFTER_EQUALS => {
    END => '$rs->{t}=undef;',
  },
  INST_PARAM_BRACKET => {
    NO_BRACKET => '$self->_add_warning("$file:$line: possible missing brackets after \# in instantiation");',
  },
  INST_NAME => {
    VID => '$rs->{t}{name}=$match;',
  },
  INST_PORTS => {
    COMMA => '$rs->{t}{port}++;',
  },
  INST_PORT_NAME => {
    NAME => '$rs->{t}{portName}=$match;
             $rs->{t}{vids} = [];', # throw away any instance parameters picked up
  },
  INST_NAMED_PORT_CON => {
    VID => 'push(@{$rs->{t}{vids}},{name=>$match,line=>$line});',
  },
  INST_NAMED_PORT_CON_AFTER => {
    COMMA => 'if ($rs->{t}{portName} eq "") { $rs->{t}{portName}=$rs->{t}{port}++; }
                 my @vids = @{$rs->{t}{vids}};
                 my $portName = $rs->{t}{portName};
                 $rs->{t}{portName}=""; 
                 $rs->{t}{vids}=[];',
    BRACKET => 'INST_NAMED_PORT_CON_AFTER:COMMA',
  },
  INST_NUMBERED_PORT => {
    COMMA   => 'INST_NAMED_PORT_CON_AFTER:COMMA',
    BRACKET => 'INST_NAMED_PORT_CON_AFTER:COMMA',
    VID => 'push(@{$rs->{t}{vids}},{name=>$match,line=>$line});',
  },
  AFTER_INST => {
    SEMICOLON => '$rs->{t}=undef;',
    COMMA     => '$rs->{t}{line}=$line;
                  $rs->{t}{name}="";
                  $rs->{t}{port}=0;
                  $rs->{t}{portName}="";
                  $rs->{t}{vids}=[];',
  },
  SIGNAL_AFTER_NAME => {
    SEMICOLON => '$rs->{t}=undef;',
  },
  IN_EVENT_BRACKET => {
    EDGE => '$rs->{t}={ type=>$match };',
  },
  IN_EVENT_BRACKET_EDGE => {
    VID => 'my $edgeType = $rs->{t}{type}; $rs->{t}=undef;',
  },
  STMNT => {
    ASSIGN_OR_TASK => '$rs->{t}={ vids=>[{name=>$match,line=>$line}]};', 
    HIER_ASSIGN_OR_TASK => '$rs->{t}={ vids=>[]};', 
    CONCAT             => '$rs->{t}={ vids=>[]};', 
  },
  STMNT_ASSIGN_OR_TASK => { # copy of STMNT_ASSIGN
    EQUALS    => 'my @vids = @{$rs->{t}{vids}}; $rs->{t}=undef;', 
# Revisit: this arc doesn't exist anymore - put this into smnt_semicolon
#    SEMICOLON => '$rs->{t}=undef;', 
    BRACKET   => '$rs->{t}=undef;', 
  },
  STMNT_ASSIGN => { # copy of STMNT_ASSIGN_OR_TASK
    EQUALS => 'STMNT_ASSIGN_OR_TASK:EQUALS',
  },
  IN_SIG_RANGE => {
    END => '$rs->{t}{range}=$fromLastPos;',
  },
  IN_MEM_RANGE => {
    END => 'push(@{$rs->{t}{dimensions}},$fromLastPos);',
  },
  ANSI_PORTS_TYPE => { # V2001 ansi ports
    TYPE =>  '$rs->{t}={ type=>$match, range=>"", dimensions=>[], name=>"" , type2=>"",block=>0};',
  },
  ANSI_PORTS_TYPE2 => { # V2001 ansi ports
    TYPE => 'if ($match eq "reg") { $rs->{t}{type2} = "reg"; }',
  },
  ANSI_PORTS_SIGNAL_NAME => { # V2001 ansi ports
    VID => '$rs->{t}{name}=$match; $rs->{t}{line}=$line;',
  },
};

############################################################
# debugEval
############################################################
$debugEval = {
  ANSI_PORTS_SIGNAL_NAME => {
    VID => 'print "Found $rs->{t}{type} $rs->{t}{name} $rs->{t}{range} [$line]\n";',
  },
  SIGNAL_NAME => {
    VID => 'print "Found $rs->{t}{type} $rs->{t}{name} $rs->{t}{range} [$line]\n";',
  },
  INST_BRACKET => {
    PORTS => 'print "found instance $rs->{t}{name} of $rs->{t}{mod} [$rs->{t}{line}]\n";',
  },
  INST_NAMED_PORT_CON_AFTER => {
    COMMA => 'my @vidnames; 
            foreach my $vid (@vids) {push @vidnames,$vid->{name};}
            print " Port $portName connected to ".join(",",@vidnames)."\n";',
    BRACKET => 'INST_NAMED_PORT_CON_AFTER:COMMA',
  },
  INST_NUMBERED_PORT => {
    COMMA   => 'INST_NAMED_PORT_CON_AFTER:COMMA',
    BRACKET => 'INST_NAMED_PORT_CON_AFTER:COMMA',
  },
};


############################################################
# rvpEval
############################################################

$rvpEval = {
  MODULE => {
    ENDMODULE => 'if ((($rs->{p}{type} eq "primitive")&&($match ne "endprimitive"))||
                         (($rs->{p}{type} ne "primitive")&&($match eq "endprimitive"))){
		     $self->_add_warning("$file:$line: module of type".
                                 " $rs->{p}{type} ended by $match");
	          }
	          $rs->{modules}{$rs->{module}}{end} = $line;
	          $rs->{module}   = "";
	          $rs->{files}{$file}{contexts}{$line}{value}= { name=>"",type=>"" };
                  $rs->{p}= undef;',
    PARAM => '$rs->{t} = { ptype => $match };', # parameter of localparam
  },
  MODULE_NAME => {
    NAME => 'if (exists($rs->{modules}{$match})) {
                 $nState = "IGNORE_MODULE";
	         $rs->{modules}{$match}{duplicate} = 1;
	         $self->_add_warning("$file:$line ignoring new definition of ".
                          "module $match, previous was at ".
		          "$rs->{modules}{$match}{file}:$rs->{modules}{$match}{line})");
             }
             else {
               $rs->{module}=$match;
               _init_module($rs->{modules},$rs->{module},$file,$line,$type);
	       $rs->{files}{$file}{modules}{$rs->{module}} = $rs->{modules}{$rs->{module}};
  	       _add_anchor($rs->{files}{$file}{anchors},$line,$rs->{module});
  	       $rs->{files}{$file}{contexts}{$line}{value}= $rs->{p}= $rs->{modules}{$rs->{module}};
  	       $rs->{files}{$file}{contexts}{$line}{module_start}= $rs->{module};
             }',
  },
  MODULE_PORTS => {
    VID => 'push(@{$rs->{p}{port_order}},$match);',
  },
  FUNCTION => {
    NAME => '$rs->{function}=$match;
                      $self->_init_t_and_f($rs->{modules}{$rs->{module}},"function",
		      $rs->{function},$file,$line,$rs->{module}."_".$rs->{function});
	              _add_anchor($rs->{files}{$file}{anchors},$line,$rs->{module}."_".$rs->{function});
                      $rs->{files}{$file}{contexts}{$line}{value}= $rs->{p}= $rs->{modules}{$rs->{module}}{t_and_f}{$rs->{function}};',
  },
  TASK => {
    NAME => '$rs->{task}=$match;
  	              $self->_init_t_and_f($rs->{modules}{$rs->{module}},"task",
		                   $rs->{task},$file,$line,$rs->{module}. "_" .$rs->{task});
 	              _add_anchor($rs->{files}{$file}{anchors},$line,$rs->{module}. "_" . $rs->{task});
                      $rs->{files}{$file}{contexts}{$line}{value}= $rs->{p}= $rs->{modules}{$rs->{module}}{t_and_f}{$rs->{task}};',
  },
  ENDTASK => {
    ENDTASK => '$rs->{modules}{$rs->{module}}{t_and_f}{$rs->{task}}{end} = $line;
                $rs->{task}="";
	        $rs->{files}{$file}{contexts}{$line}{value}= $rs->{p}= $rs->{modules}{$rs->{module}};',
  },
  T_SIGNAL => {
     SIGNAL => '$rs->{t}={ type=>$match, range=>"", dimensions=>[], name=>"" , type2=>"" , block=>0};',
     ENDTASK => 'ENDTASK:ENDTASK',
     PARAM => 'MODULE:PARAM', # not realy needed yet because T/F parameters are ignored
  },
  ENDFUNCTION => {
      ENDFUNCTION => '$rs->{modules}{$rs->{module}}{t_and_f}{$rs->{function}}{end} = $line;
                     $rs->{function}="";
	             $rs->{files}{$file}{contexts}{$line}{value}= $rs->{p}= $rs->{modules}{$rs->{module}};',
  },
  F_SIGNAL => {
     SIGNAL => '$rs->{t}={ type=>$match, range=>"", dimensions=>[], name=>"" , type2=>"",block=>0};',
     ENDFUNCTION => 'ENDFUNCTION:ENDFUNCTION',
     PARAM => 'MODULE:PARAM', # not realy needed yet because T/F parameters are ignored
  },
  BLOCK_SIGNAL => {
     SIGNAL => '$rs->{t}={ type=>$match, range=>"", dimensions=>[], name=>"" , type2=>"" , block=>1};',
  },
  PARAM_NAME => {
    NAME => 'if ( ($rs->{function} eq "") && ($rs->{task} eq "")) { # ignore parameters in tasks and functions 
              $rs->{t}= { file => $file, line => $line , value => "" ,
                          ptype => $rs->{t}{ptype}}; # ptype is same as the last one
              push(@{$rs->{p}{parameter_order}}, $match) 
                    unless ($rs->{t}{ptype} eq "localparam");
              $rs->{p}{parameters}{$match}=$rs->{t};
	      _add_anchor($rs->{files}{$file}{anchors},$line,""); }',
  },
  PPL_PARAM => {
     PARAM => '$rs->{t} = { ptype => "parameter" };', # this can't be a localparam
  },
  PPL_NAME => {
     NAME => 'PARAM_NAME:NAME',
  },
  PARAM_AFTER_EQUALS => {
    COMMA     => '$rs->{t}{value} = $fromLastPos;',
    SEMICOLON => 'PARAM_AFTER_EQUALS:COMMA',
  },
  PPL_AFTER_EQUALS => {
     COMMA   => 'PARAM_AFTER_EQUALS:COMMA',
     END     => 'PARAM_AFTER_EQUALS:COMMA',
  },
  ASSIGN => {
    VID => 'if ( exists($rs->{p}{signals}{$match}) &&
		              ($rs->{p}{signals}{$match}{a_line} == -1)) {
	       $rs->{p}{signals}{$match}{a_line} = $line;
	       $rs->{p}{signals}{$match}{a_file} = $file;
               _add_anchor($rs->{files}{$file}{anchors},$line,"");
	    }',
  },
  SIGNAL_NAME => { # note skip signals local to a block ({block}==1)
    VID => 'if ($rs->{t}{block} != 1) {
              $self->_init_signal($rs->{p}{signals},$match,$rs->{t}{type},$rs->{t}{type2},
                        $rs->{t}{range},$file,$line,1,$rs->{t}{dimensions})
               && _add_anchor($rs->{files}{$file}{anchors},$line,"");
            }',
  },
  SIGNAL_AFTER_NAME => { # don't assign a_line for reg at definition, as this is 
                         #   only the initial value
    ASSIGN => 'if ($rs->{t}{block} != 1) {
                if ( $rs->{p}{signals}{$rs->{t}{name}}{type} ne "reg" ) {
                  $rs->{p}{signals}{$rs->{t}{name}}{a_line}=$rs->{t}{line};
                  $rs->{p}{signals}{$rs->{t}{name}}{a_file}=$file;
	          _add_anchor($rs->{files}{$file}{anchors},$rs->{t}{line},"");
                }
               }',
  },
  INST_PARAM_VALUE => {
    # Note: the code is nearly the same in INST_PARAM_VALUE:COMMA,
    #   and INST_PARAM_BRACKET:NO_BRACKET, but the first uses $fromLastPos
    #   and the second uses $match to capture the parameter value
    COMMA => 'my $inst_num= $#{$rs->{p}{instances}};
              $rs->{t}{params}{$rs->{t}{param_number}} = 
                     { file => $file , line => $line , value => $fromLastPos };
              $rs->{t}{param_number}++;',
    END   => 'INST_PARAM_VALUE:COMMA',
  },
  INST_PARAM_BRACKET => {
    # Note: the code is nearly the same in INST_PARAM_VALUE:COMMA,
    #   and INST_PARAM_BRACKET:NO_BRACKET, but the first uses $fromLastPos
    #   and the second uses $match to capture the parameter value
    NO_BRACKET => 'my $inst_num= $#{$rs->{p}{instances}};
              $rs->{t}{params}{$rs->{t}{param_number}} = 
                     { file => $file , line => $line , value => $match };
              $rs->{t}{param_number}++;',
  },
  INST_BRACKET => {
    PORTS => '$rs->{unres_mod}{$rs->{t}{mod}}=$rs->{t}{mod};
	      $rs->{files}{$file}{instance_lines}{$rs->{t}{line}} = $rs->{t}{mod};
	      push( @{$rs->{p}{instances}} , { module => $rs->{t}{mod} , 
					       inst_name => $rs->{t}{name} ,
					       file => $file,
					       line => $rs->{t}{line},
                                               parameters => $rs->{t}{params},
					       connections => {} });
	      _add_anchor($rs->{files}{$file}{anchors},$rs->{t}{line},
                         $rs->{module}."_".$rs->{t}{name});',
  },
  INST_NAMED_PORT_CON_AFTER => {
    COMMA =>   'my $inst_num= $#{$rs->{p}{instances}};
              $rs->{p}{instances}[$inst_num]{connections}{$portName}=$fromLastPos;
	      if ($portName =~ /^[0-9]/ ) { # clear named_ports flag if port is a number
                 $rs->{p}{named_ports} = 0;
              }
              else { # remove the bracket from the end if a named port
                 $rs->{p}{instances}[$inst_num]{connections}{$portName}=~s/\)\s*$//s;
              }
	      foreach my $s (@vids) {
                $self->_init_signal($rs->{p}{signals},$s->{name},"wire","","",$file,$s->{line},0,$rs->{t}{dimensions})
                    && _add_anchor($rs->{files}{$file}{anchors},$s->{line},"");
		 push( @{$rs->{p}{signals}{$s->{name}}{port_con}}, 
		        { port   => $portName ,
                          line   => $s->{line},
                          file   => $file,
		          module => $rs->{t}{mod} ,
		          inst   => $rs->{t}{name} });
              }',
    BRACKET => 'INST_NAMED_PORT_CON_AFTER:COMMA',
  },
  INST_NUMBERED_PORT => {
    COMMA   => 'INST_NAMED_PORT_CON_AFTER:COMMA',
    BRACKET => 'INST_NAMED_PORT_CON_AFTER:COMMA',
  },
  IN_EVENT_BRACKET_EDGE => {
    VID => 'if (exists($rs->{p}{signals}{$match})) { 
               $rs->{p}{signals}{$match}{$edgeType}=1; };',
  },

  STMNT_ASSIGN_OR_TASK => { # copy of STMNT_ASSIGN
    EQUALS => 'foreach my $s (@vids) {
                 my $sigp = undef;
	         if ( exists($rs->{p}{signals}{$s->{name}} )) {
                      $sigp = $rs->{p}{signals}{$s->{name}};
                 }
	         elsif ( exists($rs->{p}{m_signals}) &&
                         exists($rs->{p}{m_signals}{$s->{name}}) ) {
                      $sigp = $rs->{p}{m_signals}{$s->{name}};
                 }
                 if (defined($sigp) && ($sigp->{a_line}==-1)) {
		      $sigp->{a_line}=$s->{line};
		      $sigp->{a_file}=$file;
		      _add_anchor($rs->{files}{$file}{anchors},$s->{line},"");
	         }
               }',
  },
  STMNT_ASSIGN => { # copy of STMNT_ASSIGN_OR_TASK
    EQUALS => 'STMNT_ASSIGN_OR_TASK:EQUALS',
  },
  ANSI_PORTS_SIGNAL_NAME => { # V2001 ansi ports
    VID => '$self->_init_signal($rs->{p}{signals},$match,$rs->{t}{type},$rs->{t}{type2},
                        $rs->{t}{range},$file,$line,1,$rs->{t}{dimensions});
            push(@{$rs->{p}{port_order}},$match) if exists $rs->{p}{port_order};
            _add_anchor($rs->{files}{$file}{anchors},$line,"");',
  },
};

############################################################
# language definition
############################################################

$vid_vnum_or_string = 
[ { arcName=> 'HVID',   regexp=> '$HVID', nextState=> ['$ps->{curState}'] ,}, # hier id
  { arcName=> 'VID',    regexp=> '$VID' , nextState=> ['$ps->{curState}'] ,},
  { arcName=> 'NUMBER', regexp=> '$VNUM', nextState=> ['$ps->{curState}'] ,},
  { arcName=> 'STRING', regexp=> '\\"',   nextState=> ['IN_STRING','$ps->{curState}'],},
];

$languageDef =
[
 { 
 stateName =>     'START',
 confusedNextState => 'START',
 search => 
  [
   { arcName   => 'MODULE' ,        regexp => '\b(?:module|macromodule|primitive)\b',
     nextState => ['MODULE_NAME'] ,},
   { arcName   => 'CONFIG',        regexp => '\bconfig\b', # V2001
     nextState => ['CONFIG'] , },
   { arcName   => 'LIBRARY',        regexp => '\blibrary\b', # V2001
     nextState => ['LIBRARY'] , },
  ],
 },
 { 
 stateName =>     'MODULE',
 confusedNextState => 'MODULE',
 search => 
  [
   { arcName   => 'ENDMODULE' ,     regexp => '\b(?:end(?:module|primitive))\b',
     nextState => ['START'] ,  },
   { arcName   => 'FUNCTION',       regexp => '\bfunction\b',
     nextState => ['FUNCTION'] , },
   { arcName   => 'TASK',           regexp => '\btask\b',
     nextState => ['TASK'] ,  },
   { arcName   => 'PARAM',      regexp => '\b(?:parameter|localparam)\b', # v2001: localparm
     nextState => ['PARAM_TYPE','MODULE'] ,  },
   { arcName   => 'SPECIFY',        regexp => '\bspecify\b',
     nextState => ['SPECIFY'] , },
   { arcName   => 'TABLE',          regexp => '\btable\b',
     nextState => ['TABLE'] ,  },
   { arcName   => 'EVENT_DECLARATION' ,    regexp => '\bevent\b' ,
     nextState => ['EVENT_DECLARATION'] ,  },
   { arcName   => 'DEFPARAM' ,       regexp => '\bdefparam\b' ,
     nextState => ['DEFPARAM'] , },
   { arcName   => 'GATE' ,           regexp => "$verilog_gatetype_regexp" ,
     nextState => ['GATE'] ,   },
   { arcName   => 'ASSIGN' ,         regexp => '\bassign\b' ,
     nextState => ['ASSIGN'] , },
   { arcName   => 'SIGNAL' ,         regexp => "$verilog_sigs_regexp" ,
     nextState => ['DRIVE_STRENGTH','MODULE'] , },
   { arcName   => 'INITIAL_OR_ALWAYS', regexp => '\b(?:initial|always)\b' ,
     nextState => ['STMNT','MODULE'] , },
   { arcName   => 'GENERATE',       regexp => '\bgenerate\b', # V2001
     nextState => ['GENERATE'] , },


   { arcName   => 'INST',          regexp    => '$VID' ,
     nextState => ['INST_PARAM'] , },
   # don't put any more states here because $VID matches almost anything
   ],
 },################ END OF MODULE STATE
 {
 stateName =>     'MODULE_NAME',
 search =>   # $nState is usually MODULE_PPL, but is set to
             #   IGNORE_MODULE when a duplicate module is found
  [ { arcName   => 'NAME',  regexp => '$VID' , nextState => ['$nState'] , }, ],
 },
 {
 stateName =>     'IGNORE_MODULE' ,  # just look for endmodule
 allowAnything => 1, 
 search => [ 
   { arcName   => 'ENDMODULE' , regexp    => '\bendmodule\b',
     nextState => ['START'], }, 
   @$vid_vnum_or_string, 
  ],
 },
 {
 stateName =>     'MODULE_PPL' ,  # v2001 module_parameter_port_list (A.1.3)
 failNextState => ['MODULE_PORTS'],
 search => [ { regexp    => '#',  nextState => ['PPL_BRACKET'], }, ],
 },
 {
 stateName =>     'MODULE_PORTS' ,  # just look for signals until ;
 allowAnything => 1, 
 search => [ 
   { arcName   => 'TYPE' , regexp    => '\b(?:input|output|inout)\b',  # V2001 ansi ports
     nextState => ['ANSI_PORTS_TYPE','MODULE'], resetPos => 1, }, 
   { arcName   => 'END', regexp    => ';' , nextState => ['MODULE'] , },
   @$vid_vnum_or_string, 
  ],
 },
 {
 stateName =>     'FUNCTION' , 
 search => [
    { arcName => 'RANGE', regexp => '\[', nextState => ['IN_RANGE','FUNCTION'] , },
    { arcName => 'TYPE',  regexp => '\b(?:real|integer|time|realtime)\b',
      nextState => ['FUNCTION'] ,  },
    { arcName => 'SIGNED', regexp => '\bsigned\b' ,nextState => ['FUNCTION'] ,  }, # V2001
    { arcName => 'AUTO',   regexp => '\bautomatic\b' ,nextState => ['FUNCTION'] ,  }, # V2001
    { arcName => 'NAME',  regexp => '$VID' , nextState => ['FUNCTION_AFTER_NAME'] , 
    },
   ],
 },
 {
 stateName =>     'FUNCTION_AFTER_NAME' , 
 search => [
    { arcName => 'SEMICOLON', regexp => ';', nextState => ['F_SIGNAL'] , },
    { arcName => 'BRACKET',  regexp => '\(' ,   # V2001
      nextState => ['ANSI_PORTS_TYPE','F_SIGNAL'] ,  },
  ],
 },
 {
 stateName =>     'TASK' , 
 search => [
   { arcName => 'AUTO', regexp => '\bautomatic\b', nextState => ['TASK'],}, # V2001
   { arcName => 'NAME', regexp => '$VID', nextState => ['TASK_AFTER_NAME'],},],
 },
 {
 stateName =>     'TASK_AFTER_NAME' , 
 search => [
    { arcName => 'SEMICOLON', regexp => ';', nextState => ['T_SIGNAL'] , },
    { arcName => 'BRACKET',  regexp => '\(' ,   # V2001
      nextState => ['ANSI_PORTS_TYPE','T_SIGNAL'] ,  },
  ],
 },
 { 
 stateName =>     'T_SIGNAL' , 
 failNextState => ['STMNT','ENDTASK'],
 search => [
   { arcName   => 'ENDTASK',        regexp => '\bendtask\b',
     nextState => ['MODULE'] , },
   { arcName   => 'SIGNAL' ,         regexp => "$verilog_sigs_regexp" ,
     nextState => ['DRIVE_STRENGTH','T_SIGNAL'] , },
   { arcName   => 'PARAM',      regexp => '\b(?:parameter|localparam)\b', # v2001: localparm
     nextState => ['PARAM_TYPE','T_SIGNAL'] ,  },
   ],
 },
 {
 stateName =>     'ENDTASK',
 search => [
   { arcName   => 'ENDTASK',        regexp => '\bendtask\b',
     nextState => ['MODULE'] , },
   ],
 },
 { 
 stateName =>     'F_SIGNAL' , 
 failNextState => ['STMNT','ENDFUNCTION'],
 search => [
   { arcName   => 'ENDFUNCTION',     regexp => '\bendfunction\b',
     nextState => ['MODULE'] , },
   { arcName   => 'SIGNAL' ,         regexp => "$verilog_sigs_regexp" ,
     nextState => ['DRIVE_STRENGTH','F_SIGNAL'] , },
   { arcName   => 'PARAM',      regexp => '\b(?:parameter|localparam)\b', # v2001: localparm
     nextState => ['PARAM_TYPE','F_SIGNAL'] ,  },
   ],
 },
 {
 stateName =>     'ENDFUNCTION',
 search => [
   { arcName   => 'ENDFUNCTION',     regexp => '\bendfunction\b',
     nextState => ['MODULE'] , },
   ],
 },
 {
 stateName =>     'PARAM_TYPE',
 failNextState => ['PARAM_NAME'],
 search => [
    { arcName   => 'RANGE', regexp    => '\[' ,
      nextState => ['IN_RANGE','PARAM_NAME'] , },
    { arcName   => 'SIGNED', regexp    => '\bsigned\b' ,
      nextState => ['PARAM_TYPE'] , },  # may be followed by a range
    { arcName   => 'OTHER', regexp    => '\b(?:integer|real|realtime|time)\b' ,
      nextState => ['PARAM_NAME'] , },
   ],
 },
 {
 stateName =>     'PARAM_NAME',
 search => [
    { arcName   => 'NAME',  regexp    => '$VID' , 
      nextState => ['PARAMETER_EQUAL','PARAM_AFTER_EQUALS'] , },
   ],
 },
 {
 stateName =>     'PARAMETER_EQUAL',
  search => [ { regexp    => '=' , storePos => 1, }, ]
 },
 {
 stateName =>     'PARAM_AFTER_EQUALS',
 allowAnything => 1, 
 search => 
  [
   { arcName   => 'CONCAT',      regexp    => '{' ,
     nextState => ['IN_CONCAT','PARAM_AFTER_EQUALS'] ,  },
   { arcName   => 'COMMA',       regexp    => ',' ,
     nextState => ['PARAM_NAME'] ,    },
   { arcName   => 'SEMICOLON', 	 regexp    => ';' , },
   @$vid_vnum_or_string,
  ]
 },
 {
 stateName =>     'IN_CONCAT',
 allowAnything => 1, 
 search => 
  [
   { arcName   => 'CONCAT' ,   regexp    => '{' ,
     nextState => ['IN_CONCAT','IN_CONCAT'] ,     },
   { arcName   => 'END' ,      regexp    => '}' , }, # pop up
   @$vid_vnum_or_string,
  ]
 },
 {
 stateName =>     'IN_RANGE',
 allowAnything => 1, 
 search => 
  [
   { arcName   => 'RANGE' , regexp    => '\[' ,
     nextState => ['IN_RANGE','IN_RANGE'] , },
   { arcName   => 'END' ,   regexp    => '\]' , }, # pop up
   @$vid_vnum_or_string,
  ]
 },
 {
 stateName =>     'IN_SIG_RANGE', # just like in range, but stores
 allowAnything => 1, 
 search => 
  [
   { arcName   => 'RANGE' , regexp    => '\[' ,
     nextState => ['IN_SIG_RANGE','IN_SIG_RANGE'] , },
   { arcName   => 'END' ,   regexp    => '\]' , }, # pop up
   @$vid_vnum_or_string,
  ]
 },
 {
 stateName =>     'IN_MEM_RANGE', # just like in range, but stores
 allowAnything => 1, 
 search => 
  [
   { arcName   => 'RANGE' , regexp    => '\[' ,
     nextState => ['IN_MEM_RANGE','IN_MEM_RANGE'] , },
   { arcName   => 'END' ,   regexp    => '\]' , }, # pop up
   @$vid_vnum_or_string,
  ]
 },
 {
 stateName =>     'IN_BRACKET',
 allowAnything => 1, 
 search => 
  [
   { arcName   => 'BRACKET' ,  regexp    => '\(' ,
     nextState => ['IN_BRACKET','IN_BRACKET'] ,   },
   { arcName   => 'END' ,      regexp    => '\)' ,  }, # pop up
   @$vid_vnum_or_string,
  ]
 },
 { 
 stateName =>     'IN_STRING',
 allowAnything => 1, 
 search => 
  [ # note: put \" in regexp so that emacs colouring doesn't get confused
   { arcName   => 'ESCAPED_QUOTE' ,  regexp => '\\\\\\"' , # match \"
     nextState => ['IN_STRING'] , },
   # match \\ (to make sure that \\" does not match \"
   { arcName   => 'ESCAPE' ,  	     regexp => '\\\\\\\\' ,  
     nextState => ['IN_STRING'] , },
   { arcName   => 'END' ,  	     regexp => '\\"' , }, # match " and pop up
  ]
 },
 {
 stateName =>     'SPECIFY',
 allowAnything => 1, 
 search => [ { regexp => '\bendspecify\b' , nextState => ['MODULE'] ,}, 
	       @$vid_vnum_or_string,],
 },
 {
 stateName =>     'TABLE',
 allowAnything => 1, 
 search => [ { regexp => '\bendtable\b'   , nextState => ['MODULE'] ,},
	     @$vid_vnum_or_string,],
 },
 {
 stateName =>     'EVENT_DECLARATION' ,  # just look for ;
 allowAnything => 1,
 search => [ {	regexp    => ';' ,    nextState => ['MODULE'] , },
             @$vid_vnum_or_string,],
 },
 {
 stateName =>     'DEFPARAM' ,  # just look for ;
 allowAnything => 1,
 search => [ {	regexp    => ';' ,    nextState => ['MODULE'] , },
             @$vid_vnum_or_string,],
 },
 {
  # REVISIT: could find signal driven by gate here (is output always the first one??)
 stateName =>     'GATE' , 
 allowAnything => 1,
 search => [ {	regexp    => ';' ,    nextState => ['MODULE'] , },
             @$vid_vnum_or_string,],
 },
 {
 stateName =>     'ASSIGN',
 allowAnything => 1, 
 search => 
  [
   { arcName   => 'RANGE' ,   regexp    => '\[' ,
     nextState => ['IN_RANGE','ASSIGN'] ,      },
   { arcName   => 'EQUALS' ,  regexp    => '=' ,
     nextState => ['ASSIGN_AFTER_EQUALS'] ,    },
   @$vid_vnum_or_string,
  ]
 },
 {
 stateName =>     'ASSIGN_AFTER_EQUALS' , 
 allowAnything => 1,
  search => 
   [ 
    { arcName=>'COMMA',     regexp => ',',    
      nextState => ['ASSIGN'],},
    { arcName=>'CONCAT',    regexp => '{',
      nextState => ['IN_CONCAT','ASSIGN_AFTER_EQUALS'],},
    # don't get confused by function calls (which can also contain commas)
    {	arcName=>'BRACKET',   regexp => '\(',    
    	nextState => ['IN_BRACKET','ASSIGN_AFTER_EQUALS'],},
    {	arcName=>'END',       regexp => ';',    
    	nextState => ['MODULE'],},
    @$vid_vnum_or_string,
   ],
 },
 { 
 stateName =>     'DRIVE_STRENGTH',  # signal defs - drive strength or charge strength
 failNextState => ['SCALARED_OR_VECTORED'],
 search => [ { regexp => '\(', nextState => ['IN_BRACKET','SCALARED_OR_VECTORED'],}],
 },
 { # REVISIT: V2001 - the name of this is misleading now
 stateName =>     'SCALARED_OR_VECTORED',  # for signal defs
 failNextState => ['SIGNAL_RANGE'],
 search => [ { regexp => '\b(?:scalared|vectored)\b', nextState => ['SIGNAL_RANGE'],},
	     { arcName => 'TYPE' , regexp => "$verilog_sigs_regexp", # V2001
	       nextState => ['SCALARED_OR_VECTORED'],}, 
             { regexp => '\b(?:signed)\b', nextState => ['SCALARED_OR_VECTORED'],},], # V2001
 },
 { 
 stateName =>     'SIGNAL_RANGE',          # for signal defs
  failNextState => ['SIGNAL_DELAY'],
 search => [ { regexp => '\[', nextState => ['IN_SIG_RANGE','SIGNAL_DELAY'],
	       storePos => 1,}, ],
 },
 {   
 stateName =>     'SIGNAL_DELAY',          # for signal defs
 failNextState => ['SIGNAL_NAME'],
 search => [ { regexp => '\#', nextState => ['DELAY_VALUE','SIGNAL_NAME'],},  ],
 },
 { 
 stateName =>     'SIGNAL_NAME',           # for signal defs
  search => [ { arcName   => 'VID' , regexp    => '$VID',  
	       nextState => ['SIGNAL_AFTER_NAME'], }, ],
 },
 { # for signal defs
 stateName =>     'SIGNAL_AFTER_NAME',
 search => 
  [ 
   { regexp => ',',  nextState => ['SIGNAL_NAME'],}, 
   { regexp => '\[', nextState => ['IN_MEM_RANGE','SIGNAL_AFTER_NAME'],
     storePos => 1 , }, # memories
   { arcName => 'SEMICOLON' , regexp => ';',},  # pop up
   { arcName => 'ASSIGN',     regexp => '=', nextState => ['SIGNAL_AFTER_EQUALS'],}
  ],
 },
 {
 stateName =>     'SIGNAL_AFTER_EQUALS' , 
 allowAnything => 1,
 search => 
   [ 
    { regexp => ',',    nextState => ['SIGNAL_NAME'],},
    { regexp => '{',    nextState => ['IN_CONCAT','SIGNAL_AFTER_EQUALS'],},
    { regexp => '\(',   nextState => ['IN_BRACKET','SIGNAL_AFTER_EQUALS'],},
    { arcName => 'END', regexp => ';', }, # pop up
    @$vid_vnum_or_string,
   ],
 },
 { 
 stateName =>     'INST_PARAM',
 failNextState => ['INST_NAME'],
 search => [ { regexp => '\#', nextState=> ['INST_PARAM_BRACKET'],},],
 },
 { 
 stateName =>     'INST_PARAM_BRACKET',
 search => [ { arcName => 'BRACKET' , 
               regexp => '\(',   
	       storePos => 1, 
               nextState=> ['INST_PARAM_VALUE'],},
	     # this is here to catch and illegal case which DC accepts
             { arcName => 'NO_BRACKET' ,
               regexp => '($VID|$VNUM)', 
               nextState=> ['INST_NAME'],}, ],
 },
 { 
 stateName =>     'INST_PARAM_VALUE',
 allowAnything => 1,
 search => [ 
   { regexp => '\(', nextState=> ['IN_BRACKET','INST_PARAM_VALUE'],},
   { regexp => '\[', nextState => ['IN_RANGE','INST_PARAM_VALUE'],},
   { regexp => '\{', nextState => ['IN_CONCAT','INST_PARAM_VALUE'],},
   { arcName => 'COMMA' ,
     regexp => ',', 
     storePos => 1, 
     nextState=> ['INST_PARAM_VALUE'],}, 
   { arcName => 'END' ,
     regexp => '\)', 
     nextState=> ['INST_NAME'],}, 
  ],
 },
 {
 stateName =>     'INST_NAME',
 failNextState => ['INST_BRACKET'],
 search => 
  [ 
   { arcName   => 'VID' ,       regexp => '$VID', 
     nextState => ['INST_RANGE'],      },
  ],
 },
 { 
 stateName =>     'INST_NO_NAME' ,  
 allowAnything => 1,
 search => [ { regexp => ';' , }, @$vid_vnum_or_string,],
 },
 {
 stateName =>     'INST_RANGE',
 failNextState => ['INST_BRACKET'],
 search => [ { regexp => '\[', nextState => ['IN_RANGE','INST_BRACKET'],}, ],
 },
 {
 stateName =>     'INST_BRACKET',
 search => [ { arcName => 'PORTS' , regexp => '\(', nextState => ['INST_PORTS'],},],
 },
 {
 stateName =>     'INST_PORTS',
 failNextState => ['INST_NUMBERED_PORT'],
 failStorePos => 1, 
 search => 
  [ 
   { arcName => 'COMMA', regexp => ',',   nextState => ['INST_PORTS'], },
   { regexp => '\.',  nextState => ['INST_PORT_NAME'],  },
   { regexp => '\)',  nextState => ['AFTER_INST'], },
  ],
 },
 {
 stateName =>     'INST_PORT_NAME',
 search => [ { arcName   => 'NAME' , regexp => '$VID', 
	       nextState => ['INST_NAMED_PORT_BRACKET','INST_NAMED_PORT_CON',
		             'INST_NAMED_PORT_CON_AFTER'], }, ],
 },
 {
   stateName => 'INST_NAMED_PORT_BRACKET',
   search => [ { regexp => '\(' , storePos => 1, },] 
 },
 {
 stateName =>     'INST_NAMED_PORT_CON',
 allowAnything => 1, 
 search => 
  [
   { regexp => '\[' , nextState => ['IN_RANGE','INST_NAMED_PORT_CON'] , },
   { regexp => '\{' , nextState => ['IN_CONCAT','INST_NAMED_PORT_CON'] , },
   { regexp => '\(' , 
     nextState => ['INST_NAMED_PORT_CON','INST_NAMED_PORT_CON'], },
   { arcName => 'END', regexp    => '\)' , },   # pop up 
   @$vid_vnum_or_string,
  ]
 },
 {
 stateName =>     'INST_NAMED_PORT_CON_AFTER',
 search => 
  [ 
   { arcName => 'BRACKET', regexp => '\)' , 
     nextState => ['AFTER_INST']}, 
   { arcName => 'COMMA' ,  regexp => ',' ,  
     nextState => ['INST_DOT']}, 
  ]
 },
 { stateName => 'INST_DOT',     
   search => 
    [ 
     { regexp => '\.' , nextState => ['INST_PORT_NAME']}, 
     { regexp => ','  , nextState => ['INST_DOT']},   # blank port
    ] 
 },
 {
 stateName =>     'INST_NUMBERED_PORT',
 allowAnything => 1, 
 search => 
  [
   { regexp => '\[', nextState => ['IN_RANGE','INST_NUMBERED_PORT'],},
   { regexp => '\{', nextState => ['IN_CONCAT','INST_NUMBERED_PORT'],},
   { regexp => '\(', nextState => ['IN_BRACKET','INST_NUMBERED_PORT'],},
   { arcName => 'BRACKET' , regexp => '\)', nextState => ['AFTER_INST'], },
   { arcName => 'COMMA' ,   regexp => ',' , nextState => ['INST_NUMBERED_PORT'],
     storePos => 1, },
     @$vid_vnum_or_string,
  ]
 },
 { stateName => 'AFTER_INST', 
   search => [ 
    { arcName => 'SEMICOLON', regexp => ';', nextState => ['MODULE'], },
    { arcName => 'COMMA',     regexp => ',', nextState => ['INST_NAME'], },
   ] 
 },
 {
 stateName =>     'STMNT',
 search => 
  [
   { arcName   => 'IF',	                    regexp => '\bif\b' ,
     nextState => ['BRACKET','IN_BRACKET','STMNT','MAYBE_ELSE'] ,},
   { arcName   => 'REPEAT_WHILE_FOR_WAIT',  regexp => '\b(?:repeat|while|for|wait)\b' ,
     nextState => ['BRACKET','IN_BRACKET','STMNT'] ,  },
   { arcName   => 'FOREVER', 	            regexp => '\bforever\b' ,
     nextState => ['STMNT'] , },
   { arcName   => 'CASE',                   regexp => '\bcase[xz]?\b' ,
     nextState => ['BRACKET','IN_BRACKET','CASE_ITEM'] , },
   { arcName   => 'BEGIN',	            regexp => '\bbegin\b' ,
     nextState => ['BLOCK_NAME','IN_SEQ_BLOCK'] , },
   { arcName   => 'FORK',	            regexp => '\bfork\b' ,
     nextState => ['BLOCK_NAME','IN_PAR_BLOCK'] , },
   { arcName   => 'DELAY',                  regexp => '\#' ,
     nextState => ['DELAY_VALUE','STMNT'] , },
   { arcName   => 'EVENT_CONTROL',	    regexp => '\@' ,
     nextState => ['EVENT_CONTROL'] , },
   { arcName   => 'SYSTEM_TASK',  	    regexp    => '\$$VID' ,
     nextState => ['SYSTEM_TASK'] , },
   { arcName   => 'DISABLE_ASSIGN_DEASSIGN_FORCE_RELEASE',
     regexp    => '\b(?:disable|assign|deassign|force|release)\b',
     nextState => ['STMNT_JUNK_TO_SEMICOLON'] , }, # just throw stuff away
   # a assignment to a hierarchical thing mustn't collect the vid
   #  like a normal assign as hierarchical nets/signals will confuse downstream code
   { arcName   => 'HIER_ASSIGN_OR_TASK',	   regexp => '$HVID' ,
     nextState => ['STMNT_ASSIGN_OR_TASK'] , },
   { arcName   => 'ASSIGN_OR_TASK',	   regexp => '$VID' ,
     nextState => ['STMNT_ASSIGN_OR_TASK'] , },
   { arcName   => 'CONCAT',	           regexp => '{' ,
     nextState => ['IN_CONCAT','STMNT_ASSIGN'] ,  },
   { arcName   => 'NULL',                  regexp => ';' ,
     }, # pop up
   { arcName   => 'POINTY_THING',	   regexp    => '->' , # not sure what this is!
     nextState => ['POINTY_THING_NAME'] ,  },
  ],
 },
 {
 stateName =>     'MAYBE_ELSE',
 failNextState => [] , # don't get confused, just pop the stack for the next state
 search => [{ arcName => 'ELSE', regexp => '\belse\b' , nextState => ['STMNT'],},]
 },
 {
 stateName =>     'BLOCK_NAME',
 failNextState => [] , # don't get confused, just pop the stack for the next state
 search => [{ arcName => 'COLON', regexp    => ':' , 
	      nextState => ['BLOCK_NAME_AFTER_COLON'] ,},]
 },
 {
 stateName =>     'BLOCK_NAME_AFTER_COLON',
 search => [ { arcName   => 'VID', regexp => '$VID' , nextState => ['BLOCK_SIGNAL'],}, ]
 },
 { 
 stateName =>     'BLOCK_SIGNAL' , 
 failNextState => [], # don't get confused, just pop the stack for the next state
 search => [
   { arcName   => 'SIGNAL' ,         regexp => "$verilog_sigs_regexp" ,
     nextState => ['DRIVE_STRENGTH','BLOCK_SIGNAL'] , },
   ],
 },


 {
 stateName =>     'IN_SEQ_BLOCK',
 failNextState => ['STMNT','IN_SEQ_BLOCK'] , 
 search => [{ arcName   => 'END', regexp    => '\bend\b' , }, ]
 },
 {
 stateName =>     'IN_PAR_BLOCK',
 failNextState => ['STMNT','IN_PAR_BLOCK'] , 
 search => [{ arcName   => 'JOIN', regexp => '\bjoin\b' , }, ]
 },
 {
 stateName =>     'DELAY_VALUE',
 search => 
  [{ arcName => 'NUMBER',  regexp => '$VNUM', nextState => ['DELAY_COLON1'] },
   { arcName => 'ID',      regexp => '$VID',  nextState => ['DELAY_COLON1'], },
   { arcName => 'BRACKET', regexp => '\(',    nextState => ['IN_BRACKET','DELAY_COLON1'],},]
 },
 {
 stateName =>     'DELAY_COLON1',
 failNextState => [] , # popup
 search => [{ arcName   => 'COLON', regexp => ':' , nextState => ['DELAY_VALUE2'] },]
 },
 {
 stateName =>     'DELAY_VALUE2',
 search => 
  [{ arcName => 'NUMBER',  regexp => '$VNUM', nextState => ['DELAY_COLON2'] },
   { arcName => 'ID',      regexp => '$VID',  nextState => ['DELAY_COLON2'], },
   { arcName => 'BRACKET', regexp => '\(',    nextState => ['IN_BRACKET','DELAY_COLON2'],},]
 },
 {
 stateName =>     'DELAY_COLON2',
 search => [{ arcName   => 'COLON', regexp => ':' , nextState => ['DELAY_VALUE3'] },]
 },
 {
 stateName =>     'DELAY_VALUE3',
 search => 
  [{ arcName => 'NUMBER',  regexp => '$VNUM', },
   { arcName => 'ID',      regexp => '$VID',  },
   { arcName => 'BRACKET', regexp => '\(',  nextState => ['IN_BRACKET'],}, ]
 },
 {
 stateName =>     'EVENT_CONTROL',
 search => 
  [
   { arcName => 'ID',      regexp => '(?:$HVID|$VID)', nextState => ['STMNT'], },
   { arcName => 'STAR',    regexp => '\*', nextState => ['STMNT'], }, # V2001
   { arcName => 'BRACKET', regexp => '\(', 
     nextState => ['IN_EVENT_BRACKET','STMNT'], },
  ]
 },
 {
 stateName =>     'IN_EVENT_BRACKET',
 allowAnything => 1, 
 search => 
  [ 
   # must go before vid_vnum_or_string as posedge and negedge look like VIDs
   { arcName => 'EDGE' ,	   regexp    => '\b(?:posedge|negedge)\b' ,
     nextState => ['IN_EVENT_BRACKET_EDGE'] , },
   { arcName   => 'BRACKET' ,	   regexp    => '\(' ,
     nextState => ['IN_EVENT_BRACKET','IN_EVENT_BRACKET'] , },
   { arcName => 'STAR',    regexp => '\*', nextState => ['IN_EVENT_BRACKET'], }, # V2001
   { arcName   => 'END' ,          regexp    => '\)' , }, # popup
   @$vid_vnum_or_string,
  ]
 },
 { # in theory there could be an expression here, I just take the first VID
 stateName =>     'IN_EVENT_BRACKET_EDGE',
 failNextState => ['IN_EVENT_BRACKET'] ,
 search => [{ arcName => 'VID', regexp => '$VID', nextState => ['IN_EVENT_BRACKET'],},],
 },
 {
 stateName =>     'STMNT_ASSIGN_OR_TASK',
 failNextState => ['STMNT_SEMICOLON'],
 search => 
  [
   { arcName => 'EQUALS',      	   regexp => '[<]?=',  
     nextState => ['STMNT_JUNK_TO_SEMICOLON'], },
   { arcName => 'RANGE',	   regexp => '\[',  
     nextState => ['IN_RANGE','STMNT_ASSIGN'],},
   { arcName => 'BRACKET',         regexp => '\(',     # task with params
     nextState => ['IN_BRACKET','STMNT_SEMICOLON'],  },
  ]
 },
 {
 stateName =>     'STMNT_ASSIGN',
 search => 
  [
   { arcName => 'EQUALS', regexp => '[<]?=', 
     nextState => ['STMNT_JUNK_TO_SEMICOLON'],},
   { arcName => 'RANGE',	   regexp => '\[',  
     nextState => ['IN_RANGE','STMNT_ASSIGN'],},
  ],
 },
 {
 stateName =>     'SYSTEM_TASK',
 failNextState => ['STMNT_SEMICOLON'],
 search => 
  [
   { arcName => 'BRACKET',   	     regexp => '\(',  
     nextState => ['IN_BRACKET','STMNT_SEMICOLON'], },    ],
 },
 {
 stateName =>     'POINTY_THING_NAME',
 search => [{ arcName => 'VID', regexp => '(?:$HVID|$VID)', nextState => ['STMNT_SEMICOLON'], }, ],
 },
 {
 stateName =>     'CASE_ITEM',
 allowAnything => 1, 
 search => 
  [
   { arcName => 'END',      	   regexp => '\bendcase\b',  },
   { arcName => 'COLON',	   regexp => ':',  
     nextState => ['STMNT','CASE_ITEM'], },
   { arcName => 'DEFAULT',	   regexp => '\bdefault\b',  
     nextState => ['MAYBE_COLON','STMNT','CASE_ITEM'], },
   # don't get confused by colons in ranges
   { arcName => 'RANGE',	   regexp => '\[',  
     nextState => ['IN_RANGE','CASE_ITEM'], },
    @$vid_vnum_or_string,
  ],
 },
 {
 stateName =>     'MAYBE_COLON',
 failNextState => [],
 search => [ { regexp    => ':' , }, ]
 },
 { # look for ;  but also allow the ending of a statement with an end 
   #   even though it is not really legal (verilog seems to accept it, so I do too)
 stateName =>     'STMNT_JUNK_TO_SEMICOLON' ,  
 allowAnything => 1,
 search => [ 
	     { regexp => ';' , }, 
	     # popup and reset pos to  before the end/join cope with nosemicolon case
	     { regexp => '\b(?:end|join|endtask|endfunction)\b' , resetPos => 1, }, 
	     @$vid_vnum_or_string,                              
	   ],
 },
 { 
 stateName => 'STMNT_SEMICOLON', 
 search => [ { regexp => ';'  , },
	     # popup and reset pos to  before the end/join cope with nosemicolon case
	     { regexp => '\b(?:end|join|endtask|endfunction)\b' , resetPos => 1, }, 
	   ],
 },
 { stateName => 'BRACKET',   search => [ { regexp => '\(' , },] },
 { stateName => 'SEMICOLON', search => [ { regexp => ';'  , },] },
 # V2001
 {
 stateName =>     'CONFIG',
 allowAnything => 1, 
 search => [ { regexp => '\bendconfig\b' , nextState => ['START'] ,}, 
	       @$vid_vnum_or_string,],
 },
 {
 stateName =>     'LIBRARY' ,  # just look for ;
 allowAnything => 1,
 search => [ {	regexp    => ';' ,    nextState => ['START'] , },
             @$vid_vnum_or_string,],
 },
 {
 stateName =>     'GENERATE',
 allowAnything => 1, 
 search => [ { regexp => '\bendgenerate\b' , nextState => ['MODULE'] ,}, 
	       @$vid_vnum_or_string,],
 },



 { # V2001 ansi module ports
 stateName =>     'ANSI_PORTS_TYPE',  
 failNextState => ['ANSI_PORTS_TYPE2'],
 search => [ { arcName => 'TYPE' , regexp => '\b(?:input|output|inout)\b', 
	       nextState => ['ANSI_PORTS_TYPE2'],},
	     # a null list. note this is only possible for a task or function
	     #  (a null module port list can't look like an ansi port list)
	     #  but it is not legal acording to the BNF. I allow it any way.
	     { regexp => '\)', nextState => ['SEMICOLON'], }, 
	     ],
 },
 { # V2001 ansi module ports
 stateName =>     'ANSI_PORTS_TYPE2',  
 failNextState => ['ANSI_PORTS_SIGNAL_RANGE'],
 search => [ { arcName => 'TYPE' , regexp => "$verilog_sigs_regexp", 
	       nextState => ['ANSI_PORTS_TYPE2'],}, 
             { regexp => '\b(?:signed)\b', nextState => ['ANSI_PORTS_TYPE2'],},],
 },
 { # V2001 ansi module ports
 stateName =>     'ANSI_PORTS_SIGNAL_RANGE',          # for signal defs
  failNextState => ['ANSI_PORTS_SIGNAL_NAME'],
 search => [ { regexp => '\[', nextState => ['IN_SIG_RANGE','ANSI_PORTS_SIGNAL_NAME'],
  	       storePos => 1,}, ],
 },
 { # V2001 ansi module ports
 stateName =>     'ANSI_PORTS_SIGNAL_NAME',
  search => [ 
   { arcName   => 'TYPE' , regexp    => '\b(?:input|output|inout)\b',  
     nextState => ['ANSI_PORTS_TYPE'], resetPos => 1, }, 
   { arcName   => 'VID' , regexp    => '$VID',  
     nextState => ['ANSI_PORTS_SIGNAL_AFTER_NAME'], }, 
  ],
 },
 { # V2001 ansi module ports
 stateName =>     'ANSI_PORTS_SIGNAL_AFTER_NAME',
 search => 
  [ 
   { regexp => ',',  nextState => ['ANSI_PORTS_SIGNAL_NAME'],}, 
   { regexp => '\[', nextState => ['IN_MEM_RANGE','ANSI_PORTS_SIGNAL_AFTER_NAME'],}, # memories
   { regexp => '\)', nextState => ['SEMICOLON'], } # semicolon, then pop up
  ],
 },
 { # v2001 module_parameter_port_list (A.1.3)
 stateName =>     'PPL_BRACKET' ,  
 search => [ { regexp    => '\(',  nextState => ['PPL_PARAM'], }, ],
 },
 { # v2001 module_parameter_port_list (A.1.3)
 stateName =>     'PPL_PARAM' ,  
 search => [ { arcName=>'PARAM', regexp=>'\bparameter\b', nextState => ['PPL_TYPE'],},],
 },
 { # v2001 module_parameter_port_list (A.1.3)
 stateName =>     'PPL_TYPE',    
 failNextState => ['PPL_NAME'],
 search => [
    { arcName   => 'RANGE', regexp    => '\[' ,
      nextState => ['IN_RANGE','PPL_NAME'] , },
    { arcName   => 'SIGNED', regexp    => '\bsigned\b' ,
      nextState => ['PPL_TYPE'] , },  # may be followed by a range
    { arcName   => 'OTHER', regexp    => '\b(?:integer|real|realtime|time)\b' ,
      nextState => ['PPL_NAME'] , },
   ],
 },
 { # v2001 module_parameter_port_list (A.1.3)
 stateName =>     'PPL_NAME', 
 search => [
    { arcName   => 'NAME',  regexp    => '$VID' , 
      nextState => ['PARAMETER_EQUAL','PPL_AFTER_EQUALS'] , },
   ],
 },
 { # v2001 module_parameter_port_list (A.1.3)
 stateName =>     'PPL_AFTER_EQUALS', 
 allowAnything => 1, 
 search => 
  [
   { arcName   => 'CONCAT',      regexp    => '{' ,
     nextState => ['IN_CONCAT','PPL_AFTER_EQUALS'] ,  },
   { arcName   => 'BRACKET',      regexp    => '\(' ,
     nextState => ['IN_BRACKET','PPL_AFTER_EQUALS'] ,  },
   { arcName   => 'COMMA',       regexp    => ',' ,
     nextState => ['PPL_PARAM_OR_NAME'] ,    },
   { arcName   => 'END',       regexp    => '\)' ,
     nextState => ['MODULE_PORTS'] ,    },
   @$vid_vnum_or_string,
  ]
 },
 { # v2001 module_parameter_port_list (A.1.3)
 stateName =>     'PPL_PARAM_OR_NAME' ,  
 failNextState => ['PPL_NAME'],
 search => [ { regexp    => '\bparameter\b',  nextState => ['PPL_TYPE'], }, ],
 },
];
}


############################################################
# make the parser, and return it as a string
############################################################


sub _make_parser {
    my ($evalDefs,$genDebugCode) = @_;

    _check_data_structures($evalDefs);
    
    my $perlCode; # the perl code we are making

    my $debugPrint =  $genDebugCode ? 'print "---- $ps->{curState} $file:$line (".pos($code).")\\n" if defined $ps->{curState} && defined pos($code);':'';
#    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    $perlCode .= <<EOF;
sub _parse_line {

  my (\$self,\$code,\$file,\$line,\$ps,\$rs) = \@_;

  if (!exists(\$ps->{curState})){
      \$ps->{curState} = undef;
      \$ps->{prevState}= undef;
      \$ps->{nextStateStack}= ["START"];
      \$ps->{storing}= 0;
      \$ps->{stored}= "";
      \$ps->{confusedNextState}= "START";
  }

  my \$storePos = -1;
  my \$lastPos = 0;
  my \$posMark;
  my \$fromLastPos;
  PARSE_LINE_LOOP: while (1) {

    \$lastPos = pos(\$code) if (defined(pos(\$code)));

    if ( \$code =~ m/\\G\\s*\\Z/gs ) {
	last PARSE_LINE_LOOP;
    }
    else {
	pos(\$code) = \$lastPos;
    }
    
    \$code =~ m/\\G\\s*/gs ; # skip any whitespace

    \$ps->{prevState} = \$ps->{curState};
    \$ps->{curState} = pop(\@{\$ps->{nextStateStack}}) or
	die "Error: No next state after \$ps->{prevState} ".
	    "\$file line \$line :\n \$code";
    $debugPrint

    goto \$ps->{curState};
    die \"Confused: Bad state \$ps->{curState}\";

    CONFUSED:
	\$posMark = '';
	# make the position marker: tricky because code can contain tabs
	#  which we want to match in the blank space before the ^
	\$posMark = substr(\$code,0,\$lastPos);
	\$posMark =~ tr/\t/ /c ; # turn anything that isn't a tab into a space
	\$posMark .= "^" ;
	if (substr(\$code,length(\$code)-1,1) ne "\\n") { \$posMark="\\n".\$posMark; }
	\$self->_add_confused("\$file:\$line: in state \$ps->{prevState}:\\n".
		    "\$code".\$posMark);
	\@{\$ps->{nextStateStack}} = (\$ps->{confusedNextState});
       return; # ignore the rest of the line
EOF
#    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


  foreach my $state (@$languageDef) {
      my $stateName = $state->{stateName};
      my $allowAnything    = exists($state->{allowAnything}) && $state->{allowAnything};
      my $re = $allowAnything ? '' : '\G'; # allowAnything==0 forces a match 
      #  where we left off last time
      $perlCode.= "    $stateName:\n";
      
      if (exists($state->{confusedNextState})) {
	  $perlCode.= "      \$ps->{confusedNextState}=\"$state->{confusedNextState}\";\n";
      }
	  
      if (exists($state->{search})) {
	  my @searchTerms=();
	  foreach my $search (@{$state->{search}}) { 
	      push @searchTerms, $search->{regexp}; 
	  }
	  $re .= "(?:(". join(")|(",@searchTerms)."))";
	  
	  my $failNextState='';
	  
	  if (exists($state->{failNextState})) {
	      if (scalar(@{$state->{failNextState}}) != 0) {
		  $failNextState="\"".
		      join('","',reverse(@{$state->{failNextState}})).
			  "\"";
	      }
	      # else leave it set at nothing - means just popup
	  }
	  else {
	      $failNextState='"CONFUSED"';
	  }
	  $perlCode.= "        if (\$code =~ m/$re/gos) {\n";
	  
	  my $elsif2="if";
	  my $i=0;
	  foreach my $search (@{$state->{search}}) {
	      $i++;
	      
	      my $arcName = exists($search->{arcName}) ? $search->{arcName} : '';
	      
	      $perlCode.= "          $elsif2 (defined(\$$i)) {\n";
	      if ($genDebugCode) {
		  $perlCode.="           print \"----  -$arcName (\$$i)->\\n\";\n";
		  $perlCode.="           \$takenArcs->{'$stateName'}{$i}++;\n";
	      }
	      $elsif2="elsif";
	      if (exists($search->{resetPos}) && $search->{resetPos}) {
		  $perlCode.="           pos(\$code)=pos(\$code)-length(\$$i);\n";
	      }
	      if (exists($search->{arcName})) {
		  $perlCode.=  # "	      " . 
		      _make_eval_code($evalDefs,$stateName,
				   $search->{arcName},$i,$genDebugCode);
	      }
	      if (exists $search->{nextState}) {
		  $perlCode.= "	      push (\@{\$ps->{nextStateStack}}, \"".
		      join('","',reverse(@{$search->{nextState}}))."\");\n";
	      }
	      if (exists($search->{storePos}) && $search->{storePos}) {
		  $perlCode.= "       \$ps->{storing} == 0 or\n";
		  $perlCode.= "            die \"Setting storing ".
		      "flag when it is already set: $stateName:$arcName\";\n";
		  $perlCode.= "       \$storePos       = pos(\$code);\n";
		  $perlCode.= "       \$ps->{storing}  = 1;\n";
		  $perlCode.= "       \$ps->{stored}   = '';\n";
	      }
	      $perlCode.= "	  }\n";
	  }
	  $perlCode.= "      }\n";
	  
	  if ($allowAnything) {
	      $perlCode.= "      else { ".
		  "push(\@{\$ps->{nextStateStack}},\"$stateName\"); last  PARSE_LINE_LOOP; }\n";
	  }
	  else {
	      $perlCode.= "      else {\n";
	      if (exists($state->{failStorePos}) && $state->{failStorePos}) {
		  $perlCode.= "       \$ps->{storing} == 0 or\n";
		  $perlCode.= "            die \"Setting storing ".
		      "flag when it is already set: $stateName:fail\";\n";
                  #NB:uses lastPos here because there was no match, so can't 
		  #  use pos(code)
		  $perlCode.= "       \$storePos       = \$lastPos;\n"; 
		  $perlCode.= "       \$ps->{storing}  = 1;\n";
		  $perlCode.= "       \$ps->{stored}   = '';\n";
	      }
	      if ($failNextState) {
		  $perlCode.="push(\@{\$ps->{nextStateStack}},$failNextState);";
	      }
	      $perlCode.= " pos(\$code)=\$lastPos; }\n";
	  }
      }
      $perlCode.= "    next PARSE_LINE_LOOP;\n";
  }
  $perlCode.= "  }\n";
  $perlCode.= "  if (\$storePos!=-1) { \$ps->{stored}=substr(\$code,\$storePos);}\n";
  $perlCode.= "  elsif ( \$ps->{storing} ) {   \$ps->{stored} .= \$code; }\n";
  $perlCode.= "}\n";

  return $perlCode;
}

sub _make_eval_code {
    my ($evalDefs,$stateName,$arcName,$matchNo,$genDebugCode) = @_;

    my $eval='';

    foreach my $evalDef (@$evalDefs) {

	if (exists($evalDef->{$stateName}{$arcName})) {
	    if ( $evalDef->{$stateName}{$arcName} =~ m/^(\w+?):(\w+?)$/ ) {
		$eval.=$evalDef->{$1}{$2};
	    }
	    else {
		$eval.=$evalDef->{$stateName}{$arcName};
	    }
	    $eval.="\n";
	}
    }
    # replace $match variable with the actual number of the match
    $eval=~ s/\$match/\$$matchNo/g;

    # if fromLastPos is used then generate the code to work it out
    if ($eval =~ /\$fromLastPos/) {
	my $e;
	$e .= "\$ps->{storing}==1 or die \"fromLastPos used and storing was not set\";\n";
	$e .= "if (\$storePos==-1) {\n"; # on another line
	$e .= "   \$fromLastPos=\$ps->{stored}."; # what was before
	$e .= "       substr(\$code,0,pos(\$code)-length(\$$matchNo));\n"; # some of this line
	$e .= "}\n";
	$e .= "else {\n";
	$e .= "   \$fromLastPos=substr(\$code,\$storePos,pos(\$code)".
	    "-\$storePos-length(\$$matchNo));\n";
	$e .= "}\n";
	$e .= "\$ps->{storing}=0;\n";
	$e .= "\$ps->{stored}='';\n";
	$eval = $e . $eval;

    }
    return $eval;
}

sub _check_end_state {
  my ($self,$file,$line,$ps) = @_;

  if (!exists($ps->{curState})){ 
      # parse_line was never called, file only contained comments, defines etc
      return;
  } 
  $ps->{prevState} = $ps->{curState};
  $ps->{curState} = pop(@{$ps->{nextStateStack}}) or
      $self->_add_confused("$file:$line:".
			  "No next state after $ps->{prevState} at EOF");
  
  if ($ps->{curState} ne 'START') {
      $self->_add_confused("$file:$line:".
			  " at EOF in state $ps->{curState}".
			  (($ps->{curState} eq 'CONFUSED')?
					   ",prevState was $ps->{prevState}":""));
  }
  if (@{$ps->{nextStateStack}}) {
      $self->_add_confused("$file:$line:".
			  " at EOF, state stack not empty: ".
			  join(" ",@{$ps->{nextStateStack}}));
  }

  # at the moment I don't check these:
  # $ps->{storing}= 0;  
  # $ps->{stored}= "";

}

sub _check_data_structures {
    my ($evalDefs) = @_;

    my %stateNames;
    my %statesUnused;

    foreach my $sp (@$languageDef) {
	die "Not hash!" unless ref($sp) eq "HASH";
	if (!exists($sp->{stateName})) {  die "State without name!"; }
	die "Duplicate state$sp->{stateName}" if exists $stateNames{$sp->{stateName}};
	$stateNames{$sp->{stateName}} = $sp;
    }

    %statesUnused = %stateNames;
    # check language def first
    foreach my $sp (@$languageDef) {
	my %t = %$sp;
	if (!exists($sp->{search})) {  die "State without search!"; }
	die "search $sp->{stateName} not array" unless ref($t{search}) eq "ARRAY";
	my %arcNames;
	foreach my $arc (@{$sp->{search}}) {
	    my %a = %$arc;
	    die "arc without regexp in $sp->{stateName}" unless exists $a{regexp}; 
	    delete $a{regexp};
	    if (exists($a{nextState})) {
		die "nextState not array"  unless ref($a{nextState}) eq "ARRAY";
		foreach my $n (@{$a{nextState}}) {
		    next if ($n =~ m/^\$/); #can't check variable ones
		    die "Bad Next state $n" 
			unless exists $stateNames{$n};
		    delete($statesUnused{$n}) if exists $statesUnused{$n};
		}
		delete $a{nextState};
	    }
	    if (exists($a{arcName})) {
		die "Duplicate arc $a{arcName}" if exists $arcNames{$a{arcName}};
		$arcNames{$a{arcName}} = 1;
		delete $a{arcName};
	    }
  	    delete $a{resetPos};
  	    delete $a{storePos};
	    foreach my $k (sort (keys %a)) {
		die "Bad key $k in arc of state $t{stateName}";
	    }
	}
	delete $t{stateName};
	delete $t{search};
	delete $t{allowAnything} if exists $t{allowAnything};

	if (exists($t{confusedNextState})) {
	    die "Bad Next confused state $t{confusedNextState}" 
		unless exists $stateNames{$t{confusedNextState}};
	    delete $t{confusedNextState};
	}
	
	foreach my $n (@{$t{failNextState}}) {
	    next if ($n =~ m/^\$/); #can't check variable ones
	    die "Bad Next fail state $n" 
		unless exists $stateNames{$n};
	    delete($statesUnused{$n}) if exists $statesUnused{$n};
	}
	delete $t{failNextState} if exists $t{failNextState};
	delete $t{failStorePos}  if exists $t{failStorePos};
	foreach my $k (sort (keys %t)) {
	    die "Bad key $k in languageDef state $sp->{stateName}";
	}
    }

    # REVISIT: MODULE PORTS looks like it is unused because it is got to
    #  by setting $nState - should have a flag in language def that turns
    #  off this check on a per state basis.
    foreach my $state (sort (keys %statesUnused)) { 
	#die "State $state was not used";
	print "Warning: State $state looks like it was not used\n" if $debug;
    }

    foreach my $evalDef (@$evalDefs) {
	foreach my $state (sort (keys %$evalDef)) { 
	    if (!exists($stateNames{$state})) {
		die "Couldn't find state $state";
	    }
	    my $statep = $stateNames{$state};
	    
	    foreach my $arc (sort (keys %{$evalDef->{$state}})) {
		my $found = 0;
		foreach my $s (@{$statep->{search}}) {
		    if (exists($s->{arcName}) && ($s->{arcName} eq $arc)) {
			$found=1;
			last;
		    }
		}
		if ($found == 0) {
		    die "No arc $arc in state $state";
		}
		if ( $evalDef->{$state}{$arc} =~ m/^(\w+?):(\w+?)$/ ) {
		    die "No code found for $evalDef->{$state}{$arc}" 
			unless exists $evalDef->{$1}{$2};
		}
	    }
	}
    }
}


sub _check_coverage {

    print "\n\nCoverage Information:\n";
    foreach my $sp (@$languageDef) {
	if (!exists($takenArcs->{$sp->{stateName}})) {
	    print " State $sp->{stateName}: no arcs take (except fail maybe)\n";
	}
	else {
	    my $i=0;
	    foreach my $arc (@{$sp->{search}}) {
		$i++;
		if (!exists( $takenArcs->{$sp->{stateName}}{$i} )) {
		    my $arcName = $i;
		    $arcName = $arc->{arcName} if exists $arc->{arcName};
		    print " Arc $arcName of $sp->{stateName} was never taken\n";
		}
	    }
	}
    }
}


###########################################################################

# when doing require or use we must return 1
1;

