#!/usr/bin/perl -w
package ProNOC;




use File::Copy::Recursive qw(dircopy);
use File::Basename;
use File::Copy;
use Data::Dumper;
use File::Find::Rule;

#add home dir in perl 5.6
use FindBin;
use lib $FindBin::Bin;
use constant::boolean;




use strict;
use warnings;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw{
	models	
});

my $app = __PACKAGE__->new();



my $dirname = dirname(__FILE__);
require "$dirname/src/src.pl";

my $paralel_run= 4;
#defne minimum , maximum and increasing step of injection ratio
my ($MIN,$MAX,$STEP)= (5,80,25);



if(defined $ARGV[0]){
 $paralel_run= $ARGV[0] if(is_integer($ARGV[0]));
}

if(defined $ARGV[1]){
 $MIN= $ARGV[1] if(is_integer($ARGV[1]));
}

if(defined $ARGV[2]){
 $MAX= $ARGV[2] if(is_integer($ARGV[2]));
}

if(defined $ARGV[3]){
 $STEP= $ARGV[3] if(is_integer($ARGV[3]));
}

my @inputs =($paralel_run,$MIN,$MAX,$STEP);


print "Maximum number of parallel simulation is $paralel_run.\n The injection ratio is set as MIN=$MIN,MAX=$MAX,STEP=$STEP.\n";




my @log_report_match =("Error","Warning" ); 



save_file ("$dirname/report","Verification Results:\n");


copy_src_files();

gen_models();

compile_models($app,\@inputs);

check_compilation($app,\@log_report_match,\@inputs);

run_all_models($app,\@inputs);



print "done!\n"




