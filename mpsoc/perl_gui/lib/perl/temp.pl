#!/usr/bin/perl -w
use strict;
use warnings;
use IO::CaptureOutput qw(capture qxx qxy);
use Gtk3;
my ($screen_x,$screen_y);

sub get_default_screen_size{
    return  ($screen_x,$screen_y) if (defined $screen_x && defined $screen_y);
    my $fh= 'xrandr --current | awk \'$2~/\*/{print $1}\'' ;
    my ($stdout, $stderr, $success) = qxx( ($fh) );
    my @a = split ("\n",$stdout);
    my ($screen_x,$screen_y) = split ("x",$a[0]);
    $screen_x = 600 if(!defined $screen_x);
    $screen_y = 800 if(!defined $screen_y);
    return  ($screen_x,$screen_y);
}

my ($x,$y)  =get_default_screen_size();
print "$x,$y\n";
sub get_screen_size{
    my $screen = Gtk3::Gdk::Screen::get_default;
    my $hight = $screen->get_height();
    my $width = $screen->get_width();
    return ($width,$hight);
}
($x,$y)  =get_screen_size();
print "$x,$y\n";
