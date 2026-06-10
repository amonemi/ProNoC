#!/usr/bin/perl
use strict;
use warnings;

my $tolerance=5;

use Getopt::Std;

# declare the perl command line flags/options we want to allow
my %options=();
getopts("hn:o:", \%options);

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
      -o <file name>  : Enter the golden refrence results file
      -n <file name>  : Enter the newly obtained results file    
";
exit;
}

my $new_file= $options{n} // "result_new.txt";
my $old_file= $options{o} // "result_old.txt";
my $fail_report="$ENV{PRONOC_WORK}/failures.txt";
# Track whether any failures or degradations were found
my $has_failures = 0;

my (%old_results, %new_results);
my @failures=();

# Parse result files
parse_file($old_file, \%old_results);
parse_file($new_file, \%new_results);



foreach my $key (sort keys %new_results) {
    my $new = $new_results{$key};
    
    if ($new->{status} eq "FAIL") {
        print_error("[FAILURE] $key: Simulation failed");      
        next;
    }

    unless (exists $old_results{$key}) {
        print "[NEW ENTRY] $key: No reference in old file.\n";
        next;
    }

    my $old = $old_results{$key};

    my $zero_delay_change = percent_increase($old->{zero_delay}, $new->{zero_delay});
    my $sat_inj_change    = percent_decrease($old->{sat_inj}, $new->{sat_inj});

    if ($zero_delay_change > $tolerance || $sat_inj_change > $tolerance) {
        my $err=sprintf("[DEGRADED] %-60s Zero delay ↑ %.2f%%, Sat inj ↓ %.2f%%\n",  $key, $zero_delay_change, $sat_inj_change);
            print_error($err);
    } else {
        print "[OK] $key\n";
    }
}


sub print_error {
    my ($msg) = @_;  # Capture the argument
    print "$msg.\n";
    push @failures, $msg;
    $has_failures = 1;
}

sub parse_file {
    my ($file, $result_hash) = @_;
    open my $fh, '<', $file or die "Cannot open $file: $!";
    my $key = "";
    while (<$fh>) {
        if (/^\*+(.+?): (.*?) \*+:/) {
            $key = "$1 : $2";
        } elsif (/Error in running simulation|%Error:/) {
            $$result_hash{$key}{status} = "FAIL";
        } elsif (/Passed:\s+zero load \(\d+,([\d.]+)\)\s+saturation \((\d+),([\d.]+)\)/) {
            $$result_hash{$key}{status} = "OK";
            $$result_hash{$key}{zero_delay} = $1;  # Delay cycles
            $$result_hash{$key}{sat_inj}    = $2;  # Injection ratio
        }
    }
    close $fh;
}

sub percent_increase {
    my ($old, $new) = @_;
    return 0 unless defined $old && $old != 0;
    return (($new - $old) / $old) * 100;
}

sub percent_decrease {
    my ($old, $new) = @_;
    return 0 unless defined $old && $old != 0;
    return (($old - $new) / $old) * 100;
}



open my $out, ">>$fail_report" or die "could not open $fail_report: $!";
open my $in, '<', $new_file or die "Cannot open $new_file: $!";

foreach my $fail (@failures) {
    print "$fail\n";
    print $out "$fail\n";
}

while (my $line = <$in>) {
    print $out $line;
}

close $in;
close $out;

exit($has_failures);
