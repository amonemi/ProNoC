
use Glib qw/TRUE FALSE/;
use Gtk2 '-init';

our $spinner1;

sub get_value
{
	my ($button, $format) = @_;

	if ('int' eq $format)
	{
		$button->{val_label}->set_text (sprintf ("%d",
				$spinner1->get_value_as_int));
	}
	else
	{
		$button->{val_label}->set_text (sprintf ("%0.*f",
				$spinner1->get_digits,
				$spinner1->get_value));
	}
}

$window = Gtk2::Window->new ('toplevel');
$window->signal_connect (destroy => sub { Gtk2->main_quit; 0; });
$window->set_title ("Spin Button");

$main_vbox = Gtk2::VBox->new (FALSE, 5);
$main_vbox->set_border_width (10);
$window->add ($main_vbox);

$frame = Gtk2::Frame->new ("Not accelerated");
$main_vbox->pack_start ($frame, TRUE, TRUE, 0);

$vbox = Gtk2::VBox->new (FALSE, 0);
$vbox->set_border_width (10);
$frame->add ($vbox);

# Day, month, year spinners
$hbox = Gtk2::HBox->new (FALSE, 0);
$vbox->pack_start ($hbox, TRUE, TRUE, 5);

$vbox2 = Gtk2::VBox->new (FALSE, 0);
$hbox->pack_start ($vbox2, TRUE, TRUE, 5);

$label = Gtk2::Label->new ("Day :");
$label->set_alignment (0.0, 0.5);	# left halignment, middle valignment
$vbox2->pack_start ($label, FALSE, TRUE, 0);

$adj = Gtk2::Adjustment->new (1.0, 1.0, 31.0, 1.0, 5.0, 0.0);
$spinner = Gtk2::SpinButton->new ($adj, 0, 0);
$spinner->set_wrap (TRUE);
$vbox2->pack_start ($spinner, FALSE, TRUE, 0);

$vbox2 = Gtk2::VBox->new (FALSE, 0);
$hbox->pack_start ($vbox2, TRUE, TRUE, 5);

$label = Gtk2::Label->new ("Month :");
$label->set_alignment (0.0, 0.5);	# left halignment, middle valignment
$vbox2->pack_start ($label, FALSE, TRUE, 0);

$adj = Gtk2::Adjustment->new (1.0, 1.0, 12.0, 1.0, 5.0, 0.0);
$spinner = Gtk2::SpinButton->new ($adj, 0, 0);
$spinner->set_wrap (TRUE);
$vbox2->pack_start ($spinner, FALSE, TRUE, 0);

$vbox2 = Gtk2::VBox->new (FALSE, 0);
$hbox->pack_start ($vbox2, TRUE, TRUE, 5);

$label = Gtk2::Label->new ("Year :");
$label->set_alignment (0.0, 0.5);	# left halignment, middle valignment
$vbox2->pack_start ($label, FALSE, TRUE, 0);

$adj = Gtk2::Adjustment->new (1998.0, 1.0, 2100.0, 1.0, 100.0, 0.0);
$spinner = Gtk2::SpinButton->new ($adj, 0, 0);
$spinner->set_wrap (TRUE);
$spinner->set_size_request (55, -1);
$vbox2->pack_start ($spinner, FALSE, TRUE, 0);

$frame = Gtk2::Frame->new ("Accelerated");
$main_vbox->pack_start ($frame, TRUE, TRUE, 0);

$vbox = Gtk2::VBox->new (FALSE, 0);
$vbox->set_border_width (5);
$frame->add ($vbox);

$hbox = Gtk2::HBox->new (FALSE, 0);
$vbox->pack_start ($hbox, TRUE, TRUE, 5);

$vbox2 = Gtk2::VBox->new (FALSE, 0);
$hbox->pack_start ($vbox2, TRUE, TRUE, 5);

$label = Gtk2::Label->new ("Value :");
$label->set_alignment (0.0, 0.5);	# left halignment, middle valignment
$vbox2->pack_start ($label, FALSE, TRUE, 0);

$adj = Gtk2::Adjustment->new (0.0, -10000.0, 10000.0, 0.5, 100.0, 0.0);
$spinner1 = Gtk2::SpinButton->new ($adj, 1.0, 2);
$spinner1->set_wrap (TRUE);
$spinner1->set_size_request (100, -1);
$vbox2->pack_start ($spinner1, FALSE, TRUE, 0);

$vbox2 = Gtk2::VBox->new (FALSE, 0);
$hbox->pack_start ($vbox2, TRUE, TRUE, 5);

$label = Gtk2::Label->new ("Digits :");
$label->set_alignment (0.0, 0.5);	# left halignment, middle valignment
$vbox2->pack_start ($label, FALSE, TRUE, 0);

$adj = Gtk2::Adjustment->new (2, 1, 5, 1, 1, 0);
$spinner2 = Gtk2::SpinButton->new ($adj, 0.0, 0);
$spinner2->set_wrap (TRUE);
$adj->signal_connect (value_changed => sub {
		$spinner1->set_digits ($spinner2->get_value_as_int ());
	});
$vbox2->pack_start ($spinner2, FALSE, TRUE, 0);

$button = Gtk2::CheckButton->new ("Snap to 0.5-ticks");
$button->signal_connect (clicked => sub {
		$spinner1->set_snap_to_ticks ($_[0]->get_active);
	});
$vbox->pack_start ($button, TRUE, TRUE, 0);
$button->set_active (TRUE);

$button = Gtk2::CheckButton->new ("Numeric only input mode");
$button->signal_connect (clicked => sub {
		$spinner1->set_numeric ($_[0]->get_active);
	});
$vbox->pack_start ($button, TRUE, TRUE, 0);
$button->set_active (TRUE);

$val_label = Gtk2::Label->new ("");

$hbox = Gtk2::HBox->new (FALSE, 0);
$vbox->pack_start ($hbox, FALSE, TRUE, 5);
$button = Gtk2::Button->new ("Value as Int");
$button->{val_label} = $val_label;
$button->signal_connect (clicked => \&get_value, 'int');
$hbox->pack_start ($button, TRUE, TRUE, 5);

$button = Gtk2::Button->new ("Value as Float");
$button->{val_label} = $val_label;
$button->signal_connect (clicked => \&get_value, 'float');
$hbox->pack_start ($button, TRUE, TRUE, 5);

$vbox->pack_start ($val_label, TRUE, TRUE, 0);
$val_label->set_text ("0");

$hbox = Gtk2::HBox->new (FALSE, 0);
$main_vbox->pack_start ($hbox, FALSE, TRUE, 0);

$button = Gtk2::Button->new ("Close");
$button->signal_connect (clicked => sub { $window->destroy; });
$hbox->pack_start ($button, TRUE, TRUE, 0);

$window->show_all;

Gtk2->main;

0;
