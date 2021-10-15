#!/usr/bin/perl -w
package HexSpin;

use strict;
use warnings;

#use diagnostics;
use Gtk2;


use Glib qw (TRUE FALSE);


use Glib::Object::Subclass
    Gtk2::Entry::,
    signals => {
	 
    };





use constant SPIN_HEIGHT => 16; # height of arrow pixmap (must
                                                                                # correspond to pixmap data)

use constant SPIN_MIDDLE => ( SPIN_HEIGHT / 2 );

use constant VERT_MARGIN => 3;    # top and bottom margin of widget

use constant REPEAT_LATENCY => 700; # msec before first auto repeat
use constant REPEAT_INTERVAL => 30; # msec before following auto repeat


# Pixmap for arrow item of hex pseudo spinbox
# -------------------------------------------

my $arrow_xpm = Gtk2::Gdk::Pixbuf->new_from_xpm_data (
                        "11 16  3 1",
                        "      c None",
                        "+     c Black",
                        "-     c Gray80",
                        "    -+-    ",
                        "   -+++-   ",
                        "  -++-++-  ",
                        " -++- -++- ",
                        "-++-   -++-",
                        "---     ---",
                        "           ",
                        "           ",
                        "           ",
                        "           ",
                        "---     ---",
                        "-++-   -++-",
                        " -++- -++- ",
                        "  -++-++-  ",
                        "   -+++-   ",
                        "    -+-     " );



# Arrow-button event in pseudo-spinbox entry widget
# =================================================
# Argument  #0 : entry widget (pseudo spinbutton)
#  #1 : entry-item-position step: +1 or -1
#  #2 : event ''
#  #3 : threshold y-coordinate between up and down zone

sub SpinarrowHit {
     my ( $p_box, $p_pos, $p_event, $p_middle ) = @_;
     my 	$page;
     my ( $x_step, $time_out );
     if ( ${$p_box}{'REPEAT'} ne '' ) {

                        # Spin arrow button released: cancel repeat timer

                Glib::Source->remove ( ${$p_box}{'REPEAT'} );
                ${$p_box}{'REPEAT'} = '';
     }
     if ( ref ($p_event) =~ /Button/ ) {

                        # Spin arrow button pressed: step the value, set repeat timer

                if ( index ($p_event->type, 'release' ) > 0 ) {
                        unless ( ${$p_box}{'REPEAT'} eq '' ) {
                                Glib::Source->remove ( ${$p_box}{'REPEAT'} );
                                ${$p_box}{'REPEAT'} = '';
                        }
                        return;
                }
		my $step = ${$p_box}{'STEP'};
                my $pos_y = $p_event-> y;
		
                if ( $pos_y <= $p_middle - 1 ) {
                        $x_step = 1 * $step;
                } elsif ( $pos_y > $p_middle + 1 ) {
                        $x_step = -1 * $step;
                } else {
                        return;
                }
                $time_out = REPEAT_LATENCY;
		$page=1;    
	 } else {

                        # Repeat timer struck: step and re-launch the repeat timer

                $x_step = $p_pos;
                $time_out = REPEAT_INTERVAL;
		$page=${$p_box}{'PAGE'}; 
     }

     my $x_value = $p_box->get_text ();
     $x_value =~ s/\s*//;
     unless ( $x_value =~ /^[0-9a-f]+$/i ) { return; }
     $x_value= hex ( $x_value );
     my $new_val= $x_value + $x_step *$page;
     if ( $new_val >= ${$p_box}{'MAX'}  ) { $new_val=${$p_box}{'MAX'} }
     if ( $new_val <= ${$p_box}{'MIN'}  ) { $new_val=${$p_box}{'MIN'} }
     set_hex_test($p_box,$new_val);
     ${$p_box}{'REPEAT'} = Glib::Timeout->add ( $time_out,
                                sub {
                                        SpinarrowHit ( $p_box, $x_step, '', $p_middle );
                                        return FALSE;
                                } );
} # sub SpinarrowHit



# Check contents of the pseudo spinbox against non-hex characters
# ===============================================================
#   Restore to last valid value in case of error
#
# Argument  #0 : entry widget (pseudo spinbutton)
#  #1 : entry-item-position step: +1 or -1
#  #2 : event

sub SpinvalueCheck {
     my ( $p_box, $p_pos, $p_event ) = @_;

     my $new_value;
     my $old_value = ${$p_box}{'VALUE'};
     my $x_shown = $p_box->get_text ();
     if ( $x_shown =~ /^[0-9a-f]+$/i ) {
                $new_value = hex ( $x_shown );
                if( $old_value ==  $new_value){ print "$new_value\n"};
		$new_value = ${$p_box}{'MAX'} if ($new_value >= ${$p_box}{'MAX'} );
    		$new_value = ${$p_box}{'MIN'} if ($new_value <= ${$p_box}{'MIN'} );


                ${$p_box}{'VALUE'} = $new_value;
     } else {
                 set_hex_test($p_box, $old_value );
            
     }
} # SpinvalueCheck



sub SpinvalueCheck2 {
     my ( $p_box, $p_pos, $p_event ) = @_;
     return     if( !defined ${$p_box}{'MAX'});
     my $x_shown = $p_box->get_text ();
     $x_shown =~ s/[^0-9a-fA-F]//g;# remove_not_hex( $x_shown);
     my $new_value = hex ( $x_shown );
     #print "$x_shown  ,  $new_value\n"; 
     $new_value = ${$p_box}{'MAX'} if ($new_value >= ${$p_box}{'MAX'} );
     $new_value = ${$p_box}{'MIN'} if ($new_value <= ${$p_box}{'MIN'} );
     ${$p_box}{'VALUE'} = $new_value;
     $p_box->set_text ( $x_shown );
    
} # SpinvalueCheck


sub SpinvalueCheck3 {
     my ( $p_box, $p_pos, $p_event ) = @_;
     my $x_shown = $p_box->get_text ();
     $x_shown =~ s/[^0-9a-fA-F]//g;# remove_not_hex( $x_shown);
     my $new_value = hex ( $x_shown );
     $new_value = ${$p_box}{'MAX'} if ($new_value >= ${$p_box}{'MAX'} );
     $new_value = ${$p_box}{'MIN'} if ($new_value <= ${$p_box}{'MIN'} );

     set_hex_test($p_box,$new_value);

  
   
} # SpinvalueCheck

sub set_hex_test {
	my ($self,$value)=@_;
	${$self}{'VALUE'} = $value;
	my $w= ${$self}{'WIDTH'};
	$w = ($w ==-1 )? "\%x" : "\%0${w}x";	
	$self->set_text ( sprintf ( $w, $value ) );
}

# Create a hex Spinbutton
# =======================
# Argument  #0 : intial value
#  #1 : lower limit
#  #2 : upper limit
#
# Return:  entry widget created (pseudo spinbutton)
#
# - program calls: numeric values are represented as perl values
# - spinbox display: values are represented as hex strings
# - contents of the entry widget are verified (only hex digits?) when
#  focus is lost: in case of an error, revert to the last valid hex value.
#
# State variables attached as hash values:
# ${$widget}{VALUE} last accepted value
# ${$widget}{MIN} lowest value
# ${$widget}{MAX} highest accepted value
# ${$widget}{REPEAT} id of repeat timer

sub new {
	my ($class, $p_value, $p_min, $p_max, $step, $page ) = @_;
	$step =1 if (!defined $step);
	$page = 0xFF * $step if (!defined $page);
	my $w_temp = Gtk2::Entry->new;

	$w_temp->set_max_length (8);


	$w_temp->set_editable ( TRUE );
	$w_temp->set_size_request ( 140, -1 );
	$w_temp->set_icon_from_pixbuf ( 'secondary', $arrow_xpm );
	$w_temp->set_icon_activatable ( 'secondary', TRUE );
	#$w_temp->set_inner_border ( { 'left'=>4, 'right'=>0,'top'=>VERT_MARGIN, 'bottom'=>VERT_MARGIN } );
	$w_temp->signal_connect ( 'icon-press', \&SpinarrowHit, SPIN_MIDDLE );
	$w_temp->signal_connect ( 'icon-release', \&SpinarrowHit, SPIN_MIDDLE );
	$w_temp->signal_connect ( 'changed', \&SpinvalueCheck2 );
        #$w_temp->signal_connect ( 'leave-notify-event', \&SpinvalueCheck );
	$w_temp->signal_connect ( 'activate',\&SpinvalueCheck3 );

        
	${$w_temp}{'MIN'} = $p_min;
	${$w_temp}{'MAX'} = $p_max;
	${$w_temp}{'STEP'} = $step;
	${$w_temp}{'PAGE'} =$page;
	${$w_temp}{'WIDTH'} = 8;
	$w_temp->set_max_length (8);
	$w_temp->set_width_chars(8);

	${$w_temp}{'REPEAT'} = '';
	set_hex_test($w_temp,$p_value);	

	my $self = $w_temp;
	bless($self,$class);
	
	return $self;
} # sub HexSpinButton

sub set_increments {
	my ($self,$step, $page)=@_;
	$step =1 if (!defined $step);
	$page = 0xFF * $step if (!defined $page);
	${$self}{'STEP'} = $step;
	${$self}{'PAGE'} =$page;
}

#set the entry lenth and padding zero with/ Set $digit to -1 if no zero padding  is desired 
sub set_digits {
	my ($self,$digit)=@_;
	if($digit == -1){
		$self->set_max_length (16);
		$self->set_width_chars(16);
		${$self}{'WIDTH'} = -1;

	}else{	
		$self->set_max_length ($digit);
		$self->set_width_chars($digit);
		${$self}{'WIDTH'} = $digit;
	}
	my $p_value= ${$self}{'VALUE'};
	set_hex_test($self,$p_value);	
}


sub get_value {
	my $self=shift;	
	my $x_shown = $self->get_text ();
     $x_shown =~ s/[^0-9a-fA-F]//g;# remove_not_hex( $x_shown);
     my $new_value = hex ( $x_shown );
     return $new_value;
     #print "$x_shown  ,  $new_value\n"; 
}


sub set_value {
	my ($self,$value)=@_;	
	set_hex_test($self,$value);	
}

