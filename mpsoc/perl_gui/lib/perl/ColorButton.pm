#!/usr/bin/perl -w

use strict;

package ColorButton;

use Gtk2;
use Glib::Object::Subclass
    Gtk2::Button::,
    signals => {
        color_changed => {},
        show => \&on_show,
    },
    properties => [
        Glib::ParamSpec->int (
                'red',
                'Red',
                'The Red component of the RGB color',
                0,
                0xffff,
                0xffff,
                [qw/readable writable/]
        ),
        Glib::ParamSpec->int (
                'green',
                'Green',
                'The Green component of the RGB color',
                0,
                0xffff,
                0xffff,
                [qw/readable writable/]
        ),
        Glib::ParamSpec->int (
                'blue',
                'Blue',
                'The Blue component of the RGB color',
                0,
                0xffff,
                0xffff,
                [qw/readable writable/]
        ),
	 Glib::ParamSpec->string (
                'label',
                'Label',
                'The lable of button',
                "BBB",
                [qw/readable writable/]
        ),

    ]
    ;

sub INIT_INSTANCE {
        my $self = shift;
        $self->{red} = 0xffff;
        $self->{green} = 0xffff;
        $self->{blue} = 0xffff;
	$self->{label} = "Colored_button";
	

        my $frame = Gtk2::Frame->new;
        $frame->set_border_width (3);
        $frame->set_shadow_type ('etched-in');
        $self->add ($frame);
        $frame->show;
        my $event_box = Gtk2::EventBox->new;
        $event_box->set_size_request (14, 14);
	my $lable   = Gtk2::Label->new($self->{label});
	$event_box->add($lable);
	
        $frame->add ($event_box);
        $event_box->show;
        $self->{colorbox} = $event_box;
	$self->{labelbox} = $lable; 
}

sub on_show {
        my $self = shift;
        $self->set_color (red => $self->{red},
                          green => $self->{green},
                          blue => $self->{blue});
	$self->{labelbox}->set_label ($self->{label});

        $self->signal_chain_from_overridden;
}

sub set_color {
        my $self = shift;
        my %params = @_;
        my $color = Gtk2::Gdk::Color->new ($params{red},
                                           $params{green},
                                           $params{blue});
        $self->{colorbox}->get_colormap->alloc_color ($color, 0, 1);
        $self->{colorbox}->modify_bg ('normal', $color);
       # $self->{colorbox}->modify_bg ('active', $color);
       # $self->{colorbox}->modify_bg ('prelight', $color);
        $self->{red} = $params{red};
        $self->{green} = $params{green};
        $self->{blue} = $params{blue};
        $self->signal_emit ('color-changed');
}
 
1
