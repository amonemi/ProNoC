#!/usr/bin/perl
use strict;
use warnings;
use YAML::PP;
use YAML::PP::Common qw/ PRESERVE_ORDER PRESERVE_FLOW_STYLE YAML_FLOW_SEQUENCE_STYLE YAML_FLOW_MAPPING_STYLE /;

my $yp = YAML::PP->new(
    preserve => PRESERVE_ORDER,    # preserve mapping order when dumping
);

# Usage:
#   ./gen_mesh_yaml.pl <xdim> <ydim> <endpoints_per_node>
my ($xdim, $ydim, $eps_per_node) = @ARGV;
die "Usage: $0 <xdim> <ydim> <endpoints_per_node>\n"
    unless defined $xdim && defined $ydim && defined $eps_per_node;

my $num_nodes = $xdim * $ydim;

############################################################
# Helpers: create preserved sequence/map objects
############################################################
sub oseq {
    my ($arr_ref) = @_;
    # create a preserved sequence object from arrayref
    return $yp->preserved_sequence([ @$arr_ref ]);
}

sub omap {
    my ($hashref) = @_;
    # create a preserved mapping object and populate keys in insertion order
    my $pm = $yp->preserved_mapping({});
    # copy keys in insertion order from provided hashref
    # NOTE: the passed-in hashref may be a normal hash; we iterate in numeric order where appropriate
    foreach my $k (keys %$hashref) {
        $pm->{$k} = $hashref->{$k};
    }
    return $pm;
}

############################################################
# Generate nodes (id + endpoints) as preserved sequence of preserved maps
############################################################

my @node_items;
my $ep_id = 0;

for my $id (0 .. $num_nodes - 1) {
    my @eps = map { $ep_id++ } 1 .. $eps_per_node;

    # create preserved mapping for this node, and preserved sequence for endpoints
    my $node_map = $yp->preserved_mapping({});
    $node_map->{id}        = $id;
    $node_map->{endpoints} = $yp->preserved_sequence(\@eps);

    push @node_items, $node_map;
}

my $nodes_seq = $yp->preserved_sequence(\@node_items);

############################################################
# Generate mesh connections (preserved sequence of preserved maps)
############################################################

my @conn_items;

for my $y (0 .. $ydim - 1) {
    for my $x (0 .. $xdim - 1) {
        my $id = $y * $xdim + $x;
        my @dest;

        push @dest, $id - 1     if $x > 0;              # left
        push @dest, $id + 1     if $x < $xdim - 1;      # right
        push @dest, $id - $xdim if $y > 0;              # up
        push @dest, $id + $xdim if $y < $ydim - 1;      # down

        my $conn_map = $yp->preserved_mapping({});
        $conn_map->{source} = $id;
        $conn_map->{dest}   = $yp->preserved_sequence(\@dest);

        push @conn_items, $conn_map;
    }
}

my $conns_seq = $yp->preserved_sequence(\@conn_items);

############################################################
# Top-level preserved mapping (ordered)
############################################################

my $top = $yp->preserved_mapping({});
$top->{nodes}       = $nodes_seq;
$top->{connections} = $conns_seq;

print $yp->dump($top);

