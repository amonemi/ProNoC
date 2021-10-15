#! /usr/bin/perl -w

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;


use Regexp::Common qw /comment/;
require "common.pl";


sub extract_sv_code {
	my $file=shift;
	my $text = load_file($file);
	$text =~ s/($RE{comment}{'C++'})//g;
    return $text;
       

}


sub read_sv_file {
	my $file=shift;
	#read file and remove all comments
	my $code = extract_sv_code($file); 
	print $code;
}
