#!/usr/bin/perl
use strict;
use warnings;

die "Usage: $0 <verilator_xml_file>\n" unless @ARGV;
my $xml_file = shift;

open my $fh, '<', $xml_file or die "Could not open '$xml_file': $!";
my $instants=0;
my %insts;
while (my $line = <$fh>) {
    chomp $line;  # Remove the newline character
    if ($line =~ /<cell /) {
        if ($line =~ /submodname="([^"]+)"/) {
           my $submodule= $1;
           # Remove everything after "__"
           $submodule =~ s/\s*__.*$//;
           if (defined $insts{$submodule}){
                $insts{$submodule}++;
           }else{
                $insts{$submodule}=1;
           }
        }
        $instants++;
    }
    
}

print "\n\n-----------------------------------\nTotal module instantiations: $instants\n";
print "Breakdown by module type:\n";
# Determine the longest key length for alignment
my $max_key_len = 0;
$max_key_len = length($_) > $max_key_len ? length($_) : $max_key_len for keys %insts;

# Print sorted by value, aligned
foreach my $key (sort { $insts{$b} <=> $insts{$a} } keys %insts) {
    printf "%-*s  %d\n", $max_key_len, $key, $insts{$key};
}

close $fh;

