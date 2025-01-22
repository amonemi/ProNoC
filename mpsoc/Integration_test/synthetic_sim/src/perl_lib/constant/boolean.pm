#!/usr/bin/perl -c

package constant::boolean;

=head1 NAME

constant::boolean - Define TRUE and FALSE constants.

=head1 SYNOPSIS

  use constant::boolean;

  use File::Spec;

  sub is_package_exist {
    my ($package) = @_;
    return FALSE unless defined $package;
    foreach my $inc (@INC) {
        my $filename = File::Spec->catfile(
            split( /\//, $inc ), split( /\::/, $package )
        ) . '.pm';
        return TRUE if -f $filename;
    };
    return FALSE;
  };

  no constant::boolean;

=head1 DESCRIPTION

Defines C<TRUE> and C<FALSE> constants in caller's namespace.  You could use
simple values like empty string or zero for false, or any non-empty and
non-zero string value as true, but the C<TRUE> and C<FALSE> constants are more
descriptive.

It is virtually the same as:

  # double "not" operator is used for converting scalar to boolean value
  use constant TRUE => !! 1;
  use constant FALSE => !! '';

The constants exported by C<constant::boolean> are not reported by
L<Test::Pod::Coverage>, so it is more convenient to use this module than to
define C<TRUE> and C<FALSE> constants by yourself.

The constants can be removed from class API with C<no constant::boolean>
pragma or some universal tool like L<namespace::clean>.

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.02';


sub import {
    my $caller = caller;

    no strict 'refs';
    # double "not" operator is used for converting scalar to boolean value
    *{"${caller}::TRUE"}  = sub () { !! 1 };
    *{"${caller}::FALSE"} = sub () { !! '' };

    return 1;
};


sub unimport {
    require Symbol::Util;

    my $caller = caller;
    Symbol::Util::delete_sub("${caller}::$_") foreach qw( TRUE FALSE );

    return 1;
};


1;


=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=constant-boolean>

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
