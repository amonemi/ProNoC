=head1 NAME

String::Similarity - calculate the similarity of two strings

=head1 SYNOPSIS

 use String::Similarity;

 $similarity = similarity $string1, $string2;
 $similarity = similarity $string1, $string2, $limit;

=head1 DESCRIPTION

=over 4

=cut

package String::Similarity;

use Exporter;
use DynaLoader;

$VERSION = '1.04';
@ISA = qw/Exporter DynaLoader/;
@EXPORT = qw(similarity);
@EXPORT_OK = qw(fstrcmp);

bootstrap String::Similarity $VERSION;

=item $factor = similarity $string1, $string2, [$limit]

The C<similarity>-function calculates the similarity index of
its two arguments.  A value of C<0> means that the strings are
entirely different. A value of C<1> means that the strings are
identical. Everything else lies between 0 and 1 and describes the amount
of similarity between the strings.

It roughly works by looking at the smallest number of edits to change one
string into the other.

You can add an optional argument C<$limit> (default 0) that gives the
minimum similarity the two strings must satisfy. C<similarity> stops
analyzing the string as soon as the result drops below the given limit,
in which case the result will be invalid but lower than the given
C<$limit>. You can use this to speed up the common case of searching for
the most similar string from a set by specifing the maximum similarity
found so far.

=cut

# out of historical reasons, I prefer "fstrcmp" as the original name.
*similarity = *fstrcmp;

1;

=back

=head1 SEE ALSO

 The basic algorithm is described in:
 "An O(ND) Difference Algorithm and its Variations", Eugene Myers,
 Algorithmica Vol. 1 No. 2, 1986, pp. 251-266;
 see especially section 4.2, which describes the variation used below.

 The basic algorithm was independently discovered as described in:
 "Algorithms for Approximate String Matching", E. Ukkonen,
 Information and Control Vol. 64, 1985, pp. 100-118.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

 (the underlying fstrcmp function was taken from gnu diffutils and
 modified by Peter Miller <pmiller@agso.gov.au> and Marc Lehmann
 <schmorp@schmorp.de>).



