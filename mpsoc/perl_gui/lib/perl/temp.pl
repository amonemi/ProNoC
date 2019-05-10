#!/usr/bin/perl -w
use strict;
use GraphViz;
 
my $g = GraphViz->new();
 
$g->add_node('London');
$g->add_node('Paris', label => 'City of\nlurve');
$g->add_node('New York');
 
$g->add_edge('London' => 'Paris');
$g->add_edge('London' => 'New York', label => 'Far');
$g->add_edge('Paris' => 'London');
 
print $g->as_png;
