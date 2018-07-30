#!/usr/bin/perl

 
use strict;
use warnings;
use Gtk2;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep  clock_gettime clock_getres clock_nanosleep clock stat );
use Proc::Background;
use IO::CaptureOutput qw(capture qxx qxy);

$ENV{TEMP}="ALIREZA";


my $cmd =	"xterm -e sh  t.sh";
my ($stdout,$exit)=run_cmd_in_back_ground_get_stdout( $cmd);



##########
#  run external commands
##########

sub run_cmd_in_back_ground
{
  my $command = shift;
  #print "\t$command\n";
 
  ### Start running the Background Job:
    my $proc = Proc::Background->new($command);
    my $PID = $proc->pid;
    my $start_time = $proc->start_time;
    my $alive = $proc->alive;

  ### While $alive is NOT '0', then keep checking till it is...
  #  *When $alive is '0', it has finished executing.
  while($alive ne 0)
  {
    $alive = $proc->alive;

    # This while loop will cause Gtk2 to conti processing events, if
    # there are events pending... *which there are...
    while (Gtk2->events_pending) {
      Gtk2->main_iteration;
    }
    Gtk2::Gdk->flush;

    usleep(1000);
  }
  
  my $end_time = $proc->end_time;
 # print "*Command Completed at $end_time, with PID = $PID\n\n";

  # Since the while loop has exited, the BG job has finished running:
  # so close the pop-up window...
 # $popup_window->hide;

  # Get the RETCODE from the Background Job using the 'wait' method
  my $retcode = $proc->wait;
  $retcode /= 256;

  print "\t*RETCODE == $retcode\n\n";
  Gtk2::Gdk->flush;
  ### Check if the RETCODE returned with an Error:
  if ($retcode ne 0) {
    print "Error: The Background Job ($command) returned with an Error...!\n";
    return 1;
  } else {
    #print "Success: The Background Job Completed Successfully...!\n";
    return 0;
  }
	
}



sub run_cmd_in_back_ground_get_stdout
{
	my $cmd=shift;
	my $exit;
	my ($stdout, $stderr);
	capture { $exit=run_cmd_in_back_ground($cmd) } \$stdout, \$stderr;
	return ($stdout,$exit,$stderr);
	
}	







#system ("sh t.sh");
