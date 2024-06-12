#!/usr/bin/perl 
###################
#  This script generates a unique phsycal NoC RTL code.
#  It allows having multiple phsycal NoCs witch each has
#  a unique package,parameters,and rtl modules.
###################

#add home dir in perl 5.6
use FindBin;
use lib $FindBin::Bin;
use constant::boolean;


use strict;
use warnings;


my $noc_id = $ARGV[0];
my $out_dir= $ARGV[1];

if (!defined $noc_id) {
    print "Error: No NoC_ID is given. You need to give the NoC ID as input. All RTL modules names and parameters are appended with [NOC_ID].
    usage: perl phy_noc_gen.pl [NoC_ID]  ";
    exit 1;
}
$out_dir = "./$noc_id" if(!defined $out_dir);

#check that NoC ID is valid verilog syntac
#Identifiers may contain alphabetic characters, numeric characters, the underscore, and the dollar sign (a-z A-Z 0-9 _ $ )
if ($noc_id =~ /[^a-zA-Z0-9_\$]+/){
		 #print "use of illegal character after\n" ;
		 my @w= split /([^a-zA-Z0-9_\$]+)/, $noc_id; 
		 die "NOC_ID ($noc_id) contains the illegal character of \"$w[1]\" after $w[0]. Identifiers may contain alphabetic characters, numeric characters, the underscore, and the dollar sign (a-z A-Z 0-9 _ \$ )\n";

}


my %replace;
$replace{"`NOC_CONF"} = "import pronoc_pkg::*;";
$replace{"noc_localparam.v"} = "noc_localparam_${noc_id}.v";
$replace{"topology_localparam.v"} = "topology_localparam_${noc_id}.v";
$replace{"pronoc_pkg"} = "pronoc_pkg_${noc_id}";

#create out dir

system("mkdir -p $out_dir");

#get list of all files
my $noc_dir = "/home/alireza/work/git/hca_git/git-hub/ProNoC/mpsoc/rtl/src_noc";
opendir(my $dir, $noc_dir) or die "Could not open $noc_dir for reading: $!\n";
my @files = readdir($dir);
closedir($dir);
# Filter out '.' and '..' special entries
@files = grep { $_ ne '.' && $_ ne '..' } @files;

#get list of all modules
my @module_names;
foreach my $file (@files) {
    # Open the file
    open(my $fh, '<', "$noc_dir/$file") or die "Could not open file $file $!";
    # Read the file line by line
    while (my $line = <$fh>) {
        # Match module keyword followed by name until encountering space, #, ;, or (
         while ($line =~ /^\s*module\s+(\w+)[\s#;\(]/g) {
          push @module_names, $1;
        }
    } 
   
   
}


 # Print the module names
foreach my $module (@module_names) {
    print "$module\n";
}

foreach my $file (@files) {
    print "$file\n";    
    my ($file_name, $extension) = $file =~ /^(.+)\.(\w+)$/;
    my $output_filename = "$out_dir/${file_name}_${noc_id}.$extension";
    
    open(my $input_fh, '<', "$noc_dir/$file") or die "Could not open file '$file' $!";

    # Open a new file for writing the modified content
    open(my $output_fh, '>', $output_filename) or die "Could not create file '$output_filename' $!";
    if($file eq "pronoc_pkg.sv"){
         print $output_fh "`define IMPORT_PRONOC_PCK\n`define PRONOC_PKG\n";
    }
    # Read the input file line by line
    while (my $line = <$input_fh>) {
       # Iterate through each module name and replace it with the modified version
        foreach my $module (@module_names) {
            my $replacement = "${module}_$noc_id";
            #in each file add noc id to module names
            $line =~ s/\b\Q$module\E\b/$replacement/g;
            
        }
       foreach my $key (sort keys %replace){
        #replace NoC_CONF with import noc_id package
            my $replacement=$replace{$key};
            $line =~ s/\Q$key\E/$replacement/g;  
       }
       foreach my $file (@files){
            my ($file_name, $extension) = $file =~ /^(.+)\.(\w+)$/;
            my $replacement="${file_name}_${noc_id}.$extension";
            $line =~ s/\Q$file\E/$replacement/g;  
       }
          
        # Write the modified line to the output file
        print $output_fh $line;
    }

# Close the input and output files
close($input_fh);
close($output_fh);
}


#save each file with apending noc_id
#replace includes
