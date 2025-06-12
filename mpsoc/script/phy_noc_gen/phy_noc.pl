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
use List::MoreUtils qw(uniq);

use File::Basename;
use File::Copy;

my $dirname = dirname(__FILE__);
my $noc_dir = "$dirname/../../rtl/src_noc";


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
$replace{"import pronoc_pkg::*;"} = "import pronoc_pkg_${noc_id}::*;";
$replace{"noc_localparam.v"} = "noc_localparam_${noc_id}.v";
$replace{"topology_localparam.v"} = "topology_localparam_${noc_id}.v";
$replace{"pronoc_pkg"} = "pronoc_pkg_${noc_id}";
$replace{"NOC_ID=0"} = "NOC_ID=\"$ARGV[0]\"";



#create out dir

system("mkdir -p $out_dir");

#get list of all files
opendir(my $dir, $noc_dir) or die "Could not open $noc_dir for reading: $!\n";
my @files = readdir($dir);
closedir($dir);
# Filter out '.' and '..' special entries
@files = grep { $_ ne '.' && $_ ne '..' } @files;

#get list of common files in all phy nocs
opendir($dir, "$noc_dir/..") or die "Could not open $noc_dir for reading: $!\n";
my @common_file=  readdir($dir);
@common_file = grep { $_ ne '.' && $_ ne '..' &&  -f "$noc_dir/../$_" } @common_file;
closedir($dir);

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

#get the list of all parameters/localparam 
# Read the entire file content
my @param_list;

my @param_files=("noc_localparam.v","pronoc_pkg.sv","topology_localparam.v");
for my $filename (@param_files){
    open my $fh, '<', "$noc_dir/$filename" or die "Cannot open file '$filename': $!\n";
    my $file_content = do { local $/; <$fh> };
    close $fh;
    # Remove single-line and multi-line comments
    $file_content =~ s{//.*$}{}mg;  # Remove single-line comments
    $file_content =~ s{/\*.*?\*/}{}sg;  # Remove multi-line comments
    # Remove content within quotes
    $file_content =~ s/"(?:[^"\\]|\\.)*"//g;
    # Find all parameters and localparams
    while ($file_content =~ /\b(parameter|localparam)\s+(.*?);/sg) {
        my $declaration = $2;
        # Split the declaration into individual parameter assignments
        my @params = split /,\s*/, $declaration;
        foreach my $param (@params) {
            # Extract the parameter name while skipping 'int', 'signed', 'unsigned'
            if ($param =~ /^\s*(?:int|signed|unsigned)?\s*(\w+)/) {
                push @param_list ,$1;
            }
        }
    }
}
my @replaces = uniq @param_list;


#get the list of structs
    open my $fh, '<', "$noc_dir/pronoc_pkg.sv" or die "Cannot open file pronoc_pkg.sv: $!\n";
    my $file_content = do { local $/; <$fh> };
    close $fh;
    # Remove single-line and multi-line comments
    $file_content =~ s{//.*$}{}mg;  # Remove single-line comments
    $file_content =~ s{/\*.*?\*/}{}sg;  # Remove multi-line comments
    # Remove content within quotes
    $file_content =~ s/"(?:[^"\\]|\\.)*"//g;
    # Find all structs
    while ($file_content =~ /typedef\s+struct\s+packed\s*{.*?}\s*(\w+)\s*;/sg) {
    my $struct_name = $1;
    push @replaces, $struct_name;
    }


#get list of functions
    open $fh, '<', "$noc_dir/topology_localparam.v" or die "Cannot open file topology_localparam.v: $!\n";
    $file_content = do { local $/; <$fh> };
    close $fh;
    # Remove single-line and multi-line comments
    $file_content =~ s{//.*$}{}mg;  # Remove single-line comments
    $file_content =~ s{/\*.*?\*/}{}sg;  # Remove multi-line comments
    # Remove content within quotes
    $file_content =~ s/"(?:[^"\\]|\\.)*"//g;
    # Find all structs
    while ($file_content =~ /function\s+automatic\s+integer\s+(\w+)\s*;/sg) {
        my $func = $1;
        push @replaces, $func;
    }




# Pre-compile regular expressions
my $before = qr/[%!~,=><:\/\n\s\[\]\{\}\(\)\+\-\*\\\.]/;
my $after  = qr/[%!~,=><:\/\s;\[\]\(\)\{\}\+\-\*\\\^]/;

# Compile module replacement regex
my %module_replacements = map { $_ => "${_}_$noc_id" } @module_names;
my $module_regex = join '|', map { quotemeta } @module_names;

# Compile file replacement regex
my %file_replacements = map { 
    my ($file_name, $extension) = /^(.+)\.(\w+)$/;
    $_ => "${file_name}_${noc_id}.$extension"
} @files;
my $file_regex = join '|', map { quotemeta } @files;

# Compile key replacement regex
my %key_replacements = map { $_ => "${_}_${noc_id}" } @replaces;
my $key_regex = join '|', map { quotemeta } @replaces;

# Compile replace hash regex
my $replace_regex = join '|', map { quotemeta } keys %replace;


foreach my $file (@files) {
    #print "$file\n";    
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
    # Replace module names
    $line =~ s/\b($module_regex)\b/$module_replacements{$1}/g;

    # Replace keys in %replace hash
    $line =~ s/($replace_regex)/$replace{$1}/g;

    # Replace file names
    $line =~ s/($file_regex)/$file_replacements{$1}/g;

    # Replace keys with boundary checks
    #$line =~ s/($before)($key_regex)($after)/$1$key_replacements{$2}$3/g;
    while ($line =~ s/($before)($key_regex)($after)/$1$key_replacements{$2}$3/g) {}   

    # Write the modified line to the output file
    print $output_fh $line;
}


# Close the input and output files
close($input_fh);
close($output_fh);
}

foreach my $f (@common_file){
    copy ("$noc_dir/../$f" , "$out_dir/../$f");

}

print "A Phy NoC is created in: $out_dir\n";


#save each file with apending noc_id
#replace includes
