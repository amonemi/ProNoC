#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

# Usage: perl compare_results.pl file1.txt file2.txt

my ($file1, $file2) = @ARGV;
die "Usage: $0 file1 file2\n" unless $file1 && $file2;


# Parse files normally
my %data1 = parse_file($file1);
my %data2 = parse_file($file2);

foreach my $design (sort keys %data2) {
    my @fields = sort keys %{$data2{$design}};
    print "=== $design ===\n";
    for my $i (@fields) {
        my $v1 = $data1{$design}{$i}// 'N/A';
        my $v2 = $data2{$design}{$i}// 'N/A';
        my $delta = 
        ($v1 eq '0' && $v2 eq '0') ? 0: 
        ($v1 eq 'N/A' && $v2 eq 'N/A') ? 'N/A' :
        ($v1 eq 'N/A' || $v1 eq '0') ? 'N/A' : 
        ($v2 eq 'N/A' ) ? 'N/A' :
        sprintf("%.2f", (($v2 - $v1) / $v1) * 100);
        
        my $color = ($delta eq 'N/A') ? '' :
            (($delta > 0 && $i ne 'Maxfrequency') || ($delta < 0 && $i eq 'Maxfrequency'))       ? "\e[31m" :  # red for positive
            (($delta < 0 && $i ne 'Maxfrequency') || ($delta > 0 && $i eq 'Maxfrequency'))       ? "\e[32m" :  # green for negative
            "";         # default (0)
        my $reset = "\e[0m";
        printf "%-25s: %10s -> %10s (%s%s%%%s)\n", $i, $v1, $v2, $color, $delta, $reset;
    }
    print "\n";
}

# Parse and return both field names and data hash
sub parse_file {
    my ($fname) = @_;
    open my $fh, '<', $fname or die "Cannot open $fname: $!\n";

    my @fields;
    my %results;

    while (<$fh>) {
        chomp;
        next if /^\s*$/; #skip empty line
        next if /^---$/; #skip separtion lines
        if (scalar @fields ==0) {
            s/^\s+|\s+$//g;
            @fields = split /\|/;
            shift @fields;  # remove first column name
            s/^\s+|\s+$//g for @fields;
            next;
        }

        my @cols = split /\|/;
        s/^\s+|\s+$//g for @cols;
        my $name = $cols[0];

        my @values;
        my $num=0;
        for my $field (@cols) {
            next if($name eq $field);
            my ($used) = split /,/, $field;
            $results{$name}{$fields[$num]} = $used;
            $num++;
        }
    #    print Dumper(\$results{$name});
    }
    close $fh;
    return (%results);
}


