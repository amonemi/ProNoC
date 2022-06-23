#!/usr/bin/perl -w
package ProNOC;

use Getopt::Std;


# perl verify.pl [model-name] p min max step


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



# declare the perl command line flags/options we want to allow
my %options=();
getopts("hp:u:l:s:m:d:", \%options);

# test for the existence of the options on the command line.
# in a normal program you'd do more than just print these.



# other things found on the command line
print "Other things found on the command line:\n" if $ARGV[0];
foreach (@ARGV)
{
  print "$_\n";
}


if (defined $options{h} ) { 
print " Usage: perl verify.pl [options]
      -h show this help 
      -p <int number>  : Enter the number of parallel simulations or
                         compilations. The default value is 4.
      -u <int number>  : Enter the maximum injection ratio in %. Default is 80
      -l <int number>  : Enter the minimum injection ratio in %. Default is 5
      -s <int number>  : Enter the injection step increase ratio in %. 
                         Default value is 25.
      -d <dir name>    : The dir name where the simulation models configuration
      					 files are located in. The default dir is \"models\"
      -m <simulation model name1,simulation model name2,...> : Enter the 
                         simulation model name in simulation dir. If the simulation model name
                         is not provided, it runs the simulation for all 
                         existing models.
";
exit; 
}

my $paralel_run= 4;
#defne minimum , maximum and increasing step of injection ratio
my ($MIN,$MAX,$STEP)= (5,80,25);
my $model_dir="models";

my @models;



$paralel_run=$options{p} if defined $options{p};
$MAX = $options{u} if defined $options{u};
$MIN = $options{l} if defined $options{l};
$STEP = $options{s} if defined $options{s};
$model_dir = $options{d} if defined $options{d};

if (defined $options{m}){
	@models = split(",",$options{m});
}








__PACKAGE__->mk_accessors(qw{
	models	
});

my $app = __PACKAGE__->new();



my $dirname = dirname(__FILE__);
require "$dirname/src/src.pl";


my @inputs =($paralel_run,$MIN,$MAX,$STEP,$model_dir);


print "Maximum number of parallel simulation is $paralel_run.\n The injection ratio is set as MIN=$MIN,MAX=$MAX,STEP=$STEP.\n";
print "\t The simulation models are taken from $model_dir\n";
if (defined $options{m}){
	foreach my $p (@models ){ print "\t\t$p\n";}
}

my @log_report_match =("Error","Warning" ); 



save_file ("$dirname/report","Verification Results:\n");

recompile_synful();

copy_src_files();

gen_models(\@models,\@inputs);

compile_models($app,\@inputs,\@models);

check_compilation($app,\@log_report_match,\@inputs,\@models);

run_all_models($app,\@inputs,\@models);



print "done!\n"




