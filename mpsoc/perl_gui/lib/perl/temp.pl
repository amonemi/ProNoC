#!/usr/bin/perl

 
use strict;
use warnings;

my $scalar = "a1b.2";
$scalar =~ s/\D//g;
print "\n $scalar \n";
