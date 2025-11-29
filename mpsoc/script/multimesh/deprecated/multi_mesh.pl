#add home dir in perl 5.6
use FindBin;
use lib $FindBin::Bin;
use constant::boolean;

use strict;
use warnings;

# Function to add an edge with separate parent and child nodes
sub add_edge_old {
    my ($graph,$parent_cluster, $parent_node, $child_cluster, $child_node, $dir) = @_;
    # Initialize clusters if not present
    $graph->{$parent_cluster} //= { parents => [], children => [] };
    $graph->{$child_cluster}   //= { parents => [], children => [] };
    # Add child connection to parent
    push @{$graph->{$parent_cluster}{children}}, { cluster => $child_cluster, parent_node => $parent_node, child_node => $child_node, dir=>$dir};
    # Add parent connection to child
    push @{$graph->{$child_cluster}{parents}}, { cluster => $parent_cluster, parent_node => $parent_node, child_node => $child_node, dir=>$dir};
}

# Function to add an edge with separate parent and child nodes
sub add_edge {
    my ($graph,$src_cluster, $src_node, $dest_cluster, $dest_node, $dir) = @_;
    # Initialize clusters if not present
    $graph->{$src_cluster} //= { $dir => [] };
    # Add child connection to parent
    push @{$graph->{$src_cluster}{$dir}}, { cluster => $dest_cluster, src_node => $src_node, dest_node => $dest_node};
}

sub get_clusters_in_dir {
    my ($graph, $cluster,$dir) = @_;
    my @childs = exists $graph->{$cluster} ? map { $_->{cluster} } @{$graph->{$cluster}{$dir}} : ();
    return unify (@childs);
}

sub dfs_assign_ids {
    my ($graph, $global_id, $cluster, $visited, $current_id) = @_;
    return $current_id if exists $visited->{$cluster};  # Skip if already visited
    $visited->{$cluster} = 1;
    $global_id->{$cluster} = $current_id++;  # Assign and increment ID
    foreach my $child (get_clusters_in_dir($graph, $cluster, 'up')) {
        $current_id = dfs_assign_ids($graph, $global_id, $child, $visited, $current_id);
    }
    return $current_id;
}

sub find_interpose{
    my $config = shift;
    my @f= keys %{$config->{multi_mesh}};
    return $f[0];
}

# Function to start DFS traversal from a root cluster
sub assign_global_ids {
    my ($graph, $global_id, $root_cluster) = @_;
    my %visited;
    dfs_assign_ids($graph, $global_id, $root_cluster, \%visited, 0);  # Start ID from 0
}

# Function to get cluster IDs with DFS ordering
sub get_cluster_ids {
    my ($config,$graph) = @_;
    my %global_id;  # Stores assigned IDs
    my $I = find_interpose($config);  # Find the root cluster
    assign_global_ids($graph, \%global_id, $I);  # Start DFS from root
    return %global_id;
}

sub unify {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

sub get_all_connection_nodes_to_a_cluster {
    my ($graph, $cluster_key, $direction, $target_cluster) = @_;
    return unless exists $graph->{$cluster_key}{$direction};  # Ensure the path exists
    my @src_nodes = map { $_->{src_node} }
                    grep { $_->{cluster} eq $target_cluster }
                    @{ $graph->{$cluster_key}{$direction} };
    return @src_nodes;  # Return as an array
}

sub get_clusters_up_to_leaf {
    my ($tree, $cluster)=@_;
    my %visited;
    return get_clusters_up_to_leaf_unique($tree, $cluster, \%visited);
}

sub get_clusters_up_to_leaf_unique {
    my ($tree, $cluster, $visited) = @_;
    return if exists $visited->{$cluster};  # Avoid duplicates
    $visited->{$cluster} = 1;
    return ($cluster) unless exists $tree->{$cluster}{'up'};
    my @leaves = ($cluster);
    foreach my $child (@{$tree->{$cluster}{'up'}}) {
        push @leaves, get_clusters_up_to_leaf_unique($tree, $child->{cluster}, $visited);
    }
    return @leaves;
}

return 1;
