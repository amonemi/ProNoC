#add home dir in perl 5.6
use FindBin;
use lib $FindBin::Bin;
use constant::boolean;

use strict;
use warnings;
#use YAML::XS qw(LoadFile);
use Data::Dumper;
use List::MoreUtils qw(uniq);
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use List::Util qw(min max);
use YAML::PP;
use YAML::PP::Common;
my $yp = YAML::PP->new( preserve => YAML::PP::Common->PRESERVE_ORDER );

require "src/multi_mesh.pl";


my $dirname = dirname(__FILE__);
my $noc_dir = "$dirname/../../rtl/src_noc";
my $noc_param_object_file="$dirname/../../Integration_test/synthetic_sim/src/deafult_noc_param";

my $yaml_file = $ARGV[0];
my $out_dir= "$dirname/../../rtl/src_multi_mesh/build";

if (!defined $yaml_file)  {
    print "Error:
    usage: perl yaml_noc_gen.pl yamal_file  target_dir\n";
    exit 1;
}

my $config = $yp->load_file( $yaml_file );
my %cluster_tree; # a Tree struct saving cluster connections in parent child format
my %cluster_ids; #keep cluster ids based on dfs

#my $config = LoadFile($yaml_file);
my $topology = $config->{'topology'};
my $buffer_depth=$config->{'buffer_depth'};
my $flit_size=$config->{'flit_size'};


# Create directory with -p equivalent
make_path($out_dir) or die "Failed to create directory '$out_dir': $!" unless(-d $out_dir);

generate_pronoc_multimesh() if(exists $config->{'multi_mesh'});


sub connect_nodes{
    my ($self,$node1,$port1,$node2,$port2)=@_;
    $self->{'PCONNECT'}{$node1}{"Port[$port1]"}="$node2,$port2";
    # $self->{$node2}{'PCONNECT'}{$port2}="$node1,$port1";
}


sub connect_nodes_local{
    my ($self,$mesh1,$x1,$y1,$z1,$port1,$mesh2,$x2,$y2,$z2,$port2,$dim_x,$dim_y,$dim_z)=@_;
    my $id1=$x1 + $y1*$dim_x+ $z1*$dim_x*$dim_y;
    my $node1=$mesh1."_".$id1;
    my $id2=$x2+ $y2*$dim_x+ $z2*$dim_x*$dim_y;
    my $node2=$mesh2."_".$id2;
    connect_nodes($self,$node1,$port1,$node2,$port2);
}

sub update_multimesh_config {
    my ($mesh,$config,$vcs)=@_;
    my $dim_x = $config->{'multi_mesh'}{$mesh}{'dim_x'};
    my $dim_y = $config->{'multi_mesh'}{$mesh}{'dim_y'};
    my $dim_z = $config->{'multi_mesh'}{$mesh}{'dim_z'};
    my $vc    = $config->{'multi_mesh'}{$mesh}{'n_virtual_channels'};
    my $first_router_id = $config->{'router_counter'}//0;
    my $cluster_counter = $config->{'cluster_counter'}//0;
    $config->{'max_x'} = max($config->{'max_x'} // 0, $dim_x);
    $config->{'max_y'} = max($config->{'max_y'} // 0, $dim_y);
    $config->{'max_z'} = max($config->{'max_z'} // 0, $dim_z);
    $config->{'cluster_counter'} = $cluster_counter+1;
    $vcs->{$mesh}=$vc;
    my $nodes_num = $dim_x * $dim_y * $dim_z;
    my $max_port=7;
    $config->{'multi_mesh'}{$mesh}{'MAX_P'}=$max_port;
    $config->{'multi_mesh'}{$mesh}{'RID_INT'}=$first_router_id;
    $config->{'multi_mesh'}{$mesh}{'NR'}=$nodes_num;
    $first_router_id+=$nodes_num;
    $config->{'router_counter'}=$first_router_id;
    $config->{'endp_counter'}=$first_router_id;
    my ($LOCAL, $EAST, $NORTH, $WEST, $SOUTH, $UP, $DOWN) = (0..6);
    my  $CLUSTER = ($dim_z==1)? 5 : 7;
 #   for my $x (0..$dim_x-1) {
 #       for my $y (0..$dim_y-1) {
 #           for my $z (0..$dim_z-1) {
 #               connect_nodes_local($config,$mesh,$x,$y,$z,$EAST,$mesh,($x+1),$y,$z,$WEST,$dim_x,$dim_y,$dim_z) if ($x < $dim_x-1);
 #               connect_nodes_local($config,$mesh,$x,$y,$z,$NORTH,$mesh,$x,$y-1,$z,$SOUTH,$dim_x,$dim_y,$dim_z) if ($y > 0  );
 #               connect_nodes_local($config,$mesh,$x,$y,$z,$WEST,$mesh,$x-1,$y,$z,$EAST,$dim_x,$dim_y,$dim_z)  if ($x > 0);
 #               connect_nodes_local($config,$mesh,$x,$y,$z,$SOUTH,$mesh,$x,$y+1,$z,$NORTH,$dim_x,$dim_y,$dim_z) if ($y<$dim_y-1);
 #               if($dim_z>1){
 #                   connect_nodes_local($config,$mesh,$x,$y,$z,$UP,$mesh,$x,$y,$z+1,$DOWN,$dim_x,$dim_y,$dim_z) if($z<$dim_z-1);
 #                   connect_nodes_local($config,$mesh,$x,$y,$z,$DOWN,$mesh,$x,$y,$z-1,$UP,$dim_x,$dim_y,$dim_z) if($z>0 );
 #               }
 #           }
 #       }
 #   }
}

#sub get_all_minimal_paths_between_two_endps{
#    my ($self,$src, $dst)=@_;
#    my @proceed_nodes;
#    my @head_nodes;
#    my $offset = 1; # this make sure a minimal path selection.
#    my $max_len = 1000;
#    push (@head_nodes,$src);
#    push (@proceed_nodes,$src);
#    my @paths;
#    my @ports;
#    my @paths_to_dst;
#    my @ports_to_dst;
#    my @first_path=($src);
#    my @first_port=(0);
#    $paths[0]=\@first_path;
#    $ports[0]=\@first_port;
#    # select one path
#    my $n=0;
#    my $min_dist=1000000;
#    do{
#        my @current_path= @{$paths[$n]};
#        my @current_port= @{$ports[$n]};
#        # get head node
#        my $head_node =     $current_path[-1];
#        if(defined $head_node){
#            # get connected nodes for all ports
#            #print "hn=$head_node\n";
#            my $pnum =  7;
#            for (my $i=0;$i<$pnum; $i++){
#                my @new_path=@current_path;
#                my @new_ports=@current_port;
#                my $src_port = "Port[${i}]";
#                my $connect = $self->{'PCONNECT'}{$head_node}{$src_port};
#                if(defined $connect){
#                    my ($node,$pnode)=split(/\s*,\s*/,$connect);
#                    #add connected nodes to head_nodes if they are not in path before
#                    if(!defined get_scolar_pos($node,@new_path)){
#                        my $size=scalar @new_path;
#                        #if ($min_dist > $size){
#                        if( ($min_dist+$offset) > $size &&   $max_len>=$size){
#                            push (@new_path,$node);
#                            push (@new_ports,$pnode);
#                            push (@paths,\@new_path);
#                            push (@ports,\@new_ports);
#                            if($node eq $dst){
#                                push(@paths_to_dst,\@new_path);
#                                push(@ports_to_dst,\@new_ports);
#                                $min_dist=$size+1 if ($min_dist > $size);
#                            }
#                        }
#                    } #if
#                }
#            }#for
#        }
#        $n++;
#    # print "******$n,    @{$paths[$n]}\n" if defined $paths[$n];
#    }while( defined $paths[$n]);
#    #print "\@paths_to_dst". Dumper(@paths_to_dst). "\n \@ports_to_dst". Dumper(@ports_to_dst) . "\n" ;
#    return (\@paths_to_dst,\@ports_to_dst);
#}


sub gen_multi_mesh_io_assign {
    my $mesh=shift;
    return
    "
    for(int i=0;i<CLUSTER_${mesh}_NE;i++) begin
        CLUSTER_${mesh}_endpoint_chan_in[i] = chan_in_all[CLUSTER_${mesh}_EID_INIT+i];
        chan_out_all[CLUSTER_${mesh}_EID_INIT+i]= CLUSTER_${mesh}_endpoint_chan_out[i];
    end
    ";
}

sub gen_io_name_per_cluster {
    my $mesh=shift;
    return
    "    CLUSTER_${mesh}_endpoint_chan_in,
    CLUSTER_${mesh}_endpoint_chan_out,\n";
}

sub gen_multi_mesh_cluster_localparam {
    my ($mesh,$config) =@_;

    $config->{'multi_mesh'}{$mesh}{'EID_INT'} = $config->{'multi_mesh'}{$mesh}{'RID_INT'};
    my $opt_nr = "-1";
    my $opt_ne = "+1";
    # Not interposer case
    if ($config->{'multi_mesh'}{$mesh}{'RID_INT'}) {
        $opt_ne = "";
        $opt_nr = "";
        $config->{'multi_mesh'}{$mesh}{'EID_INT'} = $config->{'multi_mesh'}{$mesh}{'RID_INT'}+1;
    }

    return"
    /****************
    * CLUSTER_${mesh} localparams
    ****************/
    localparam
        CLUSTER_${mesh}_NX = $config->{'multi_mesh'}{$mesh}{'dim_x'},
        CLUSTER_${mesh}_NY = $config->{'multi_mesh'}{$mesh}{'dim_y'},
        CLUSTER_${mesh}_NZ = $config->{'multi_mesh'}{$mesh}{'dim_z'},
        CLUSTER_${mesh}_MAX_P = $config->{'multi_mesh'}{$mesh}{'MAX_P'},
        CLUSTER_${mesh}_RID_INIT = $config->{'multi_mesh'}{$mesh}{'RID_INT'},
        CLUSTER_${mesh}_EID_INIT = $config->{'multi_mesh'}{$mesh}{'EID_INT'},
        CLUSTER_${mesh}_NE = CLUSTER_${mesh}_NX * CLUSTER_${mesh}_NY * CLUSTER_${mesh}_NZ${opt_ne},
        CLUSTER_${mesh}_NR = CLUSTER_${mesh}_NE${opt_nr},
        CLUSTER_${mesh}_NVP = 2 * (CLUSTER_${mesh}_NX * CLUSTER_${mesh}_NY);
";
}


sub gen_multi_mesh_cluster_instant {
    my $mesh=shift;
    return "
    `ifdef IO_PER_CLUSTER
    input smartflit_chanel_t CLUSTER_${mesh}_endpoint_chan_in [CLUSTER_${mesh}_NE-1:0];
    output smartflit_chanel_t CLUSTER_${mesh}_endpoint_chan_out[CLUSTER_${mesh}_NE-1:0];
    `else
    smartflit_chanel_t CLUSTER_${mesh}_endpoint_chan_in [CLUSTER_${mesh}_NE-1:0];
    smartflit_chanel_t CLUSTER_${mesh}_endpoint_chan_out[CLUSTER_${mesh}_NE-1:0];
    `endif
    smartflit_chanel_t CLUSTER_${mesh}_inter_cluster_chan_in[CLUSTER_${mesh}_NVP-1:0];
    smartflit_chanel_t CLUSTER_${mesh}_inter_cluster_chan_out[CLUSTER_${mesh}_NVP-1:0];
    router_event_t CLUSTER_${mesh}_router_event [CLUSTER_${mesh}_NR-1:0][CLUSTER_${mesh}_MAX_P-1:0];

    mesh_cluster #(
        .NOC_ID(NOC_ID),
        .CLUSTER_ID(${mesh}_ID),
        .RID_INIT(CLUSTER_${mesh}_RID_INIT),
        .CLUSTER_NX(CLUSTER_${mesh}_NX),
        .CLUSTER_NY(CLUSTER_${mesh}_NY),
        .CLUSTER_NZ(CLUSTER_${mesh}_NZ),
        .CLUSTER_NE(CLUSTER_${mesh}_NE)
    )the_${mesh}(
        .reset(reset),
        .clk(clk),
        .cluster_id(${mesh}_ID),
        .endpoint_chan_in(CLUSTER_${mesh}_endpoint_chan_in),
        .endpoint_chan_out(CLUSTER_${mesh}_endpoint_chan_out),
        .inter_cluster_chan_in(CLUSTER_${mesh}_inter_cluster_chan_in),
        .inter_cluster_chan_out(CLUSTER_${mesh}_inter_cluster_chan_out),
        .router_event(CLUSTER_${mesh}_router_event)
    );\n    ";
}

sub get_xyz {
    my ($config, $mesh, $id) = @_;
    my $dim_x = $config->{'multi_mesh'}{$mesh}{'dim_x'};
    my $dim_y = $config->{'multi_mesh'}{$mesh}{'dim_y'};
    my $dim_z = $config->{'multi_mesh'}{$mesh}{'dim_z'};
    my $z = int($id / ($dim_x * $dim_y));  # Compute Z index
    my $l = $id % ($dim_x * $dim_y);       # Remaining index in the XY plane
    my $x = $l % $dim_x;                   # Compute X index
    my $y = int($l / $dim_x);              # Compute Y index
    return ($x, $y, $z);
}

sub process_vertival_link_placement{
    my ($ref,$src,$dst,$dir,$verticals)=@_;
    my @links=@{$ref};
    foreach my $link (@links){
        my ($src_endp,$dst_endp)=@$link;
        #print "$dir link : $src $src_endp $dst $dst_endp \n";
        $verticals->{$dir}=()if (! exists $verticals->{$dir});
        push @{$verticals->{$dir}}, "$src:$src_endp:$dst:$dst_endp";
        my $node1=$src."_".$src_endp;
        my $node2=$dst."_".$dst_endp;
        my $port1 = 7;
        my $port2 = 7;
        connect_nodes($config,$node1,$port1,$node2,$port2);
        add_edge(\%cluster_tree,$src,$src_endp,$dst,$dst_endp,$dir);
    }
}

sub vertical_links_placement{
    my ($mesh,$config,$vref,$I)=@_;
    foreach my $direction (keys %{ $config->{'multi_mesh'}{$mesh}{'vertical_links_placement'} }) {
        my $ref1=$config->{'multi_mesh'}{$mesh}{'vertical_links_placement'}{$direction};
        if (ref($ref1) eq 'HASH'){
            foreach my $dst_mesh (sort keys %{$ref1}){
                process_vertival_link_placement(@{$ref1}{$dst_mesh},$mesh,$dst_mesh,$direction,$vref);
            }
        }else{
            process_vertival_link_placement($ref1,$mesh,$I,$direction,$vref);
        }
    }
}

sub process_vertival_link_selection{
    my ($ref,$src,$dst,$dir,$verticals)=@_;
    my @links=@{$ref};
    foreach my $link (@links){
        my ($src_endp,$dst_endp)=@$link;
        #print "$dir link : $src $src_endp $dst $dst_endp \n";
        $verticals->{$dir}{$src}{$dst}{$src_endp}=$dst_endp;
    }
}
sub vertical_links_selection{
    my ($mesh,$config,$vref,$I)=@_;
    foreach my $direction (keys %{ $config->{'multi_mesh'}{$mesh}{'vertical_links_selection'} }) {
        my $ref1=$config->{'multi_mesh'}{$mesh}{'vertical_links_selection'}{$direction};
        if (ref($ref1) eq 'HASH'){
            foreach my $dst_mesh (sort keys %{$ref1}){
                process_vertival_link_selection(@{$ref1}{$dst_mesh},$mesh,$dst_mesh,$direction,$vref);
            }
        }else{
            process_vertival_link_selection($ref1,$mesh,$I,$direction,$vref);
        }
    }
}

sub get_vp_id{
    my ($config,$mesh, $node,$dir)=@_;
    my ($x, $y, $z) = get_xyz($config, $mesh, $node);
    my $dimx = $config->{'multi_mesh'}{$mesh}{'dim_x'};
    my $dimy = $config->{'multi_mesh'}{$mesh}{'dim_y'};
    my $dimz = $config->{'multi_mesh'}{$mesh}{'dim_z'};
    # Ensure inter-cluster connections are only at the first (0) or last ($dimz-1) position in the Z dimension
    if ($z != 0 && $z != $dimz - 1) {
        die "Error: Inter-cluster connection at Z=$z is invalid. It must be at either the first (0) or last ($dimz-1) position in the Z dimension.";
    }
    # If the router is at the first Z-dimension layer (Z=0) and not the only layer,
    # it must only have a 'down' connection.
    if ($z == 0 && $dimz > 1 && $dir ne 'down') {
        die "Error: Routers at the first Z layer (Z=0) can only have a 'down' connection.";
    }
    # If the router is at the last Z-dimension layer (Z=$dimz-1) and not the only layer,
    # it must only have an 'up' connection.
    if ($z == $dimz - 1 && $dimz > 1 && $dir ne 'up') {
        die "Error: Routers at the last Z layer (Z=$dimz-1) can only have an 'up' connection.";
    }
    my $vp= ($dir eq 'down')? ($y * $dimx) + $x : ($dimx * $dimy) + ($y * $dimx) + $x;
    return $vp;
}

sub gen_multi_mesh_vertical_link_assign{
    my ($vref,$is_connected,$connections_hash)=@_;
    my %verticals=%{$vref};
    my $links_assign="";
    my $unconnected_err="";
    foreach my $dir  (sort keys %verticals){
        #get number of up/down links
        my @connections = @{$verticals{$dir}};
        my $link_num=scalar @connections;
        my $DIR = uc $dir;
        #$rtl_cluster_instant.="    localparam ${DIR}_LINK_NUM=$link_num;\n";
        $links_assign.="        //cluster_to_cluster $dir connections\n";
        foreach my $c (@connections){
            my ($src,$src_endp,$dst,$dst_endp) = split ":", $c;
            #print "($src:$src_endp:$dst:$dst_endp)\n";
            my $src_dir=$dir;
            my $src_vp = get_vp_id($config,$src,$src_endp,$src_dir);
            my $dst_dir= ($src_dir eq 'up')? 'down' : 'up';
            my $dst_vp = get_vp_id($config,$dst,$dst_endp,$dst_dir);
            $links_assign.="        CLUSTER_${dst}_inter_cluster_chan_in[$dst_vp] = CLUSTER_${src}_inter_cluster_chan_out[$src_vp]; // ${src}[$src_endp] dir $src_dir to ${dst}[$dst_endp] dir $dst_dir\n";
            $is_connected->{'IN'}{$dst}{$dst_vp}=1;
            $is_connected->{'OUT'}{$src}{$src_vp}=1;
            # Store the connection in a hash
            $connections_hash->{"$src,$src_vp"}{"$dst,$dst_vp"} = 1;
        }
    }#$direction
    $links_assign.="        //Unconnected cluster connections are grounded\n";
    my %connected = %{$is_connected->{'IN'}};
    foreach my $m (sort keys %connected){
        foreach my $p (sort { $a <=> $b } keys %{$connected{$m}}){
            if ($connected{$m}{$p}==0){
                $links_assign.="        CLUSTER_${m}_inter_cluster_chan_in[$p] = is_grounded;\n";
            }
        }
    }
    %connected = %{$is_connected->{'OUT'}};
    foreach my $m (sort keys %connected){
        foreach my $p (sort { $a <=> $b } keys %{$connected{$m}}){
            if ($connected{$m}{$p}==0){
                $unconnected_err.="        if( CLUSTER_${m}_inter_cluster_chan_out[$p].flit_chanel.flit_wr) begin `ERROR_UNCNT(\"${m}\",$p) end\n";
            }
        }
    }
    return ($links_assign,$unconnected_err);
}

sub gen_multimesh_unidir_vlinks{
    my ($vref,$connections_hash)=@_;
    my %verticals=%{$vref};
    my $uni_dir="";
    foreach my $dir  (sort keys %verticals){
        my @connections = @{$verticals{$dir}};
        foreach my $c (@connections) {
            my ($src, $src_endp, $dst, $dst_endp) = split ":", $c;
            my $src_dir=$dir;
            my $src_vp = get_vp_id($config,$src,$src_endp,$src_dir);
            my $dst_dir= ($src_dir eq 'up')? 'down' : 'up';
            my $dst_vp = get_vp_id($config,$dst,$dst_endp,$dst_dir);

            # Check if the reverse connection exists
            if (!exists $connections_hash->{"$dst,$dst_vp"}{"$src,$src_vp"}) {
                #push @unidirectional_channels, "$src:$src_endp:$dst:$dst_endp";
                print "[info]: Unidirectional chanel is detected $src,$src_endp -> $dst,$dst_endp\n";
                $uni_dir.=
"                CLUSTER_${src}_inter_cluster_chan_in[$src_vp].flit_chanel.credit = CLUSTER_${dst}_inter_cluster_chan_out[$dst_vp].flit_chanel.credit;
                 CLUSTER_${src}_inter_cluster_chan_in[$src_vp].ctrl_chanel = CLUSTER_${dst}_inter_cluster_chan_out[$dst_vp].ctrl_chanel;\n"
            }
        }
    }#$direction
    return  $uni_dir;
}

sub gen_noc_localparam {
    my ($vcs,$config)=@_;
    my $rtl="";
    #Create Noc configuration file
    my @values = values %$vcs;
    # Compute min and max
    my $min_vc = min(@values);
    my $max_vc = max(@values);
    my $pp;
    $pp= do "$noc_param_object_file";
    die "Error reading: $@" if $@;
    $pp->{'noc_param'}{"TOPOLOGY"}="\"$topology\"";
    $pp->{'noc_param'}{"T1"}=$config->{'router_counter'};
    $pp->{'noc_param'}{"MIN_PCK_SIZE"}= 1;
    #$pp->{'noc_param'}{"T2"}=$config->{'endp_counter'};
    $pp->{'noc_param'}{"T3"}=1;
    $pp->{'noc_param'}{"V"}=$max_vc;
    $pp->{'noc_param'}{"B"}=$config->{'buffer_depth'};
    $pp->{'noc_param'}{"Fpay"}=64;
    $pp->{'noc_param'}{"ROUTE_NAME"}="\"$config->{'routing_algorithm'}\"";
    $pp->{'noc_param'}{"SELF_LOOP_EN"} = '"YES"';

    if($min_vc !=$max_vc ){
        $pp->{'noc_param'}{'HETERO_VC'} = 1;
        $pp->{'noc_param'}{'MAX_ROUTER'} = $config->{'router_counter'};  ;
        $pp->{'noc_param'}{'MAX_PORT'} = 1;
        my $hetero_vc="'{\n    //VC  cluster local_id global_id\n";
        my $coma="";
        foreach my $mesh (keys %{$config->{multi_mesh}}) {
            my $nr =$config->{'multi_mesh'}{$mesh}{'NR'};
            my $rid_int= $config->{'multi_mesh'}{$mesh}{'RID_INT'};
            my $r=0;
            my $v=$vcs->{$mesh};
            for (my $n=$rid_int; $n < $rid_int + $nr;$n++){
                    $hetero_vc.= "    $coma'{$v} // $mesh:  r$r   R$n  \n";
                    $coma=",";
                    $r++;
            }
        }
        $hetero_vc.="} ";
        $pp->{'noc_param'}{'int VC_CONFIG_TABLE [MAX_ROUTER][MAX_PORT]'} = "$hetero_vc";
    } else {
        $pp->{'noc_param'}{'HETERO_VC'} = 0;
        my $homogeneous_vc = "'{'{0}};";
        $pp->{'noc_param'}{'int VC_CONFIG_TABLE [MAX_ROUTER][MAX_PORT]'} = "$homogeneous_vc";
    }

    my $param = $pp->{'noc_param'};
    my %default_noc_param=%{$param};
    my @params_order=@{$pp->{'parameters_order'}{'noc_param'}};
    $rtl.="
    `ifdef   NOC_LOCAL_PARAM
    /*************************************
    *   ProNoC localparams
    *************************************/\n
    `include \"define.tmp.h\"\n";
    foreach my $p (@params_order){
        next if ($p eq "T2");
        $rtl.="    localparam $p = $default_noc_param{$p};\n";
    }

    my $count = 0;
    my @lines;
    foreach my $mesh (keys %{$config->{multi_mesh}}) {
        push @lines, sprintf("        %s_ID = %d,", uc $mesh , $cluster_ids{$mesh});
    }
    $rtl.="
    /*************************************
    *   multimesh localparams
    *************************************/
    localparam\n".join("\n", @lines)."
        MAX_RID= T1,
        RIDw = \$clog2(MAX_RID),
        CLUSTER_NUM = $config->{'cluster_counter'},
        CLUSTER_IDw= (CLUSTER_NUM==1) ? 1 : \$clog2(CLUSTER_NUM),
        CLUSTER_MAX_X=$config->{'max_x'},
        CLUSTER_Xw = (CLUSTER_MAX_X==1)? 1 : \$clog2(CLUSTER_MAX_X),
        CLUSTER_MAX_Y=$config->{'max_y'},
        CLUSTER_Yw = (CLUSTER_MAX_Y==1)? 1 : \$clog2(CLUSTER_MAX_Y),
        CLUSTER_MAX_Z=$config->{'max_z'},
        CLUSTER_Zw = (CLUSTER_MAX_Z==1)? 1 : \$clog2(CLUSTER_MAX_Z);

    typedef struct packed {
        logic [CLUSTER_IDw-1: 0] c;
        logic [CLUSTER_Zw-1 : 0] z;
        logic [CLUSTER_Yw-1 : 0] y;
        logic [CLUSTER_Xw-1 : 0] x;
    } multimesh_router_addr_t;
    localparam T2= \$bits(multimesh_router_addr_t);
    ";

    return $rtl;
}
sub gen_muli_mesh_topology_rtl{
    my ($rtl_io_per_cluster,$rtl_cluster_instant,$rtl_io_assign, $rtl_vertical_links_assign ,$v_err ) = @_;
    return
    "
`include \"pronoc_def.v\"
module multi_mesh #(
    parameter NOC_ID=0
    )(
    `ifndef IO_PER_CLUSTER
    chan_in_all,
    chan_out_all,
    router_event,
    `else
$rtl_io_per_cluster
    `endif
    reset,
    clk
);

    `NOC_CONF
    `ifndef IO_PER_CLUSTER
    input   smartflit_chanel_t chan_in_all  [NE-1 : 0];
    output  smartflit_chanel_t chan_out_all [NE-1 : 0];
    //Events
    output  router_event_t  router_event [NR-1 : 0][MAX_P-1 : 0];
    `endif

    input reset,clk;

    //Unused Input channels are connected to ground
    smartflit_chanel_t is_grounded = {SMARTFLIT_CHANEL_w{1'b0}};

$rtl_cluster_instant

    //chiplet interconnect
    always_comb begin
    `ifndef IO_PER_CLUSTER
$rtl_io_assign
    `endif
$rtl_vertical_links_assign    end

`define ERROR_UNCNT(cluster, port) \\
        \$display(\"Error: A flit was injected into an unconnected NoC router port.\"); \\
        \$display(\"Cluster: \%s, Port: %0d\", cluster, port); \\
        \$display(\"Simulation will terminate due to this unexpected behavior.\"); \\
        \$finish;


`ifdef SIMULATION
    always \@ ( posedge clk ) begin
$v_err
    end
`endif

endmodule
";
}
sub get_rtl_hdr_file{
    my $file_name=shift;
    return
"//Autogen warning for $file_name ....
//lisence
";
}
###########
# functions
###########
sub gen_noc_cluster_id_func{
    my $config=shift;
    my $lines1="";
    my $lines2="";
    my $if="if";
    my $addr_id_rtl="";
    my $lines3="";
    foreach my $mesh (keys %{$config->{multi_mesh}}) {
        my $MESH=uc $mesh;
        $lines1.="        $if (rid < CLUSTER_${MESH}_RID_INIT + CLUSTER_${MESH}_NR)   router_id_to_cluster_id =${MESH}_ID;\n";
        $lines2.="        $if (rid < CLUSTER_${MESH}_RID_INIT + CLUSTER_${MESH}_NR)   router_id_to_cluster_router_id = rid - CLUSTER_${MESH}_RID_INIT;\n";
        $if="else if";
    }
    return"
    function automatic [CLUSTER_IDw-1:0] router_id_to_cluster_id ;
    input [RIDw-1 : 0] rid;
    begin
$lines1    end
    endfunction

    //This function get the global unique router id and return the router local id in cluster
    function automatic [RIDw-1 : 0] router_id_to_cluster_router_id ;
    input [RIDw-1 : 0] rid;
    begin
$lines2   end
    endfunction
";
}

sub find_nearest_vlink {
    my ($config, $mesh, $up, $dir, $rid) = @_;
    my @nodes = get_all_connection_nodes_to_a_cluster(\%cluster_tree, $mesh, $dir, $up);
    my $min;
    my $nearest_node;
    foreach my $node (@nodes) {
        my ($x1, $y1, $z1) = get_xyz($config, $mesh, $node);
        my ($x2, $y2, $z2) = get_xyz($config, $mesh, $rid);
        my $manhattan_dist = abs($x1 - $x2) + abs($y1 - $y2) + abs($z1 - $z2);
        if (!defined $min || $manhattan_dist < $min) {
            $min = $manhattan_dist;
            $nearest_node = $node;
        }
    }
    return $nearest_node;
}

sub get_cmin_cmax{
    my($tree,$mesh)=@_;
    my @up_leaf = get_clusters_up_to_leaf ($tree, $mesh);
    # Get the IDs of all leaf clusters
    my @ids = sort { $a <=> $b } map { $cluster_ids{$_} } @up_leaf;
    # Ensure the IDs are continuous
    for my $i (0 .. $#ids - 1) {
        die "Error: Cluster IDs are not continuous!: @ids \n" if $ids[$i] + 1 != $ids[$i + 1];
    }
    # Return the min and max ID
    return ($ids[0], $ids[-1]);
}

sub create_inter_cluster_routing {
    my ($config,$Vlinks_sel)=@_;
    my $not_dynamic="";
    my $not_dynamic_modules="";
    my $if="if";
    foreach my $mesh (keys %{$config->{multi_mesh}}) {
        my $MESH=uc $mesh;
        my $nr =$config->{'multi_mesh'}{$mesh}{'NR'};
        $not_dynamic .="    $if ( CLUSTER_ID == ${MESH}_ID ) begin
        hard_coded_icr_${MESH} #(
            .CLUSTER_ID(CLUSTER_ID),
            .RID(RID)
        )icr_comb (
            .dest_address(dest_address),
            .local_cluster_endp_addr(local_cluster_endp_addr),
            .up_dir_sel(up_dir_sel)
        );\n";
        $if="else if";
        $not_dynamic_modules .=
    "module hard_coded_icr_${MESH} #(
    parameter CLUSTER_ID=0,
    parameter RID=0\n)(
    dest_address,
    local_cluster_endp_addr,
    up_dir_sel\n);
    `NOC_CONF
    input multimesh_router_addr_t dest_address;
    output multimesh_router_addr_t local_cluster_endp_addr;
    output logic up_dir_sel;
    localparam unsigned [CLUSTER_IDw-1 : 0] current_cluster_id = CLUSTER_ID;
    typedef struct packed {
        logic [CLUSTER_IDw-1 : 0] Cmin,Cmax;
        multimesh_router_addr_t endp_addr;
        bit valid;
    } cluster_hid_entry_t;
    multimesh_router_addr_t
        local_cluster_endp_addr_up_dir,
        local_cluster_endp_addr_down_dir;
    ";
        my @up_clusters = get_clusters_in_dir (\%cluster_tree,$mesh,'up');
        my @down_clusters = get_clusters_in_dir (\%cluster_tree,$mesh,'down');
        if(scalar @down_clusters>1){
            die "Error: multiple Cluster @down_clusters are detected for $mesh chiplet which is not supported by 2.5 D mesh \n";
        }
        my $no_down=((scalar @down_clusters)==0)? 1 : 0;
        $not_dynamic_modules .= " " x 8 . "localparam NO_DOWNLINK = $no_down;\n";
        if(scalar @up_clusters){
            my $s=scalar @up_clusters;
            $not_dynamic_modules .= " " x 8 . "localparam MAX_ENTRY_${MESH} = $s;\n";
            $not_dynamic_modules .= " " x 8 . "cluster_hid_entry_t  address_table [MAX_ENTRY_${MESH}];\n";
            $not_dynamic_modules .= " " x 8 . "multimesh_router_addr_t endp_addr_array [MAX_ENTRY_${MESH}];\n";
            $not_dynamic_modules .= " " x 8 . "wire [CLUSTER_IDw-1 : 0] Cmax_array_${MESH} [MAX_ENTRY_${MESH}];\n";
            $not_dynamic_modules .= " " x 8 . "wire [CLUSTER_IDw-1 : 0] Cmin_array_${MESH} [MAX_ENTRY_${MESH}];\n";
            my $i=0;
            foreach my $up (@up_clusters){
                my ($cmin,$cmax) = get_cmin_cmax(\%cluster_tree,$up);
                $not_dynamic_modules .= " " x 8 . "assign Cmax_array_${MESH} [$i]= $cmax;\n";
                $not_dynamic_modules .= " " x 8 . "assign Cmin_array_${MESH} [$i]= $cmin;\n";
                $i++;
            }
        }else {
            $not_dynamic_modules .=" " x 8 ."//There are no upper chiplet. Select between local and down chiplet\n";
        }
        $not_dynamic_modules .=" " x 8 ."generate \n case (RID)\n";
        for (my $rid=0;$rid<$nr;$rid++){
            $not_dynamic_modules .=" " x 8 . "$rid: begin \n";
            my $i=0;
            my $coma="";
            foreach my $up (@up_clusters){
                #check if vertical link connection exsited in yaml file
                my $local_dst=$Vlinks_sel->{'up'}{$mesh}{$up}{$rid};
                my $via_yml = (defined $local_dst)? 1:0;
                $local_dst= ($via_yml==1)? $local_dst : find_nearest_vlink($config,$mesh,$up,"up",$rid);
                my ($x,$y,$z)=get_xyz($config,$mesh,$local_dst);
                my $comment =($via_yml ==1)?
                    "S:Yaml,T:$up,R:$local_dst":
                    "S:Auto,T:$up,R:$local_dst";
                $not_dynamic_modules .=" "  x 12 . "assign endp_addr_array[$i]='{x:$x, y:$y, z:$z, c:${mesh}_ID};/*$comment*/\n";
                $i++;
                $coma=",";
            }
            unless($no_down){
            my $local_dst=find_nearest_vlink($config,$mesh,$down_clusters[0],"down",$rid);
            my ($x,$y,$z)=get_xyz($config,$mesh,$local_dst);
            my $comment ="S:Auto,T:$down_clusters[0],R:$local_dst";
            $not_dynamic_modules .=" "  x 12 . "assign local_cluster_endp_addr_down_dir ='{x:$x, y:$y, z:$z, c:${mesh}_ID};/*$comment*/\n";
            }
            $not_dynamic_modules .=" "  x 8 ."end //$rid\n";
        }
        $not_dynamic_modules .=" " x 8 . "endcase\n    endgenerate\n";
        if(scalar @up_clusters){
            $not_dynamic_modules .=" " x 8 . "always_comb begin
            local_cluster_endp_addr_up_dir=0;
            up_dir_sel=1'b0;
            for (int i=0;i< MAX_ENTRY_${MESH};i++) begin
                if(Cmin_array_${MESH}[i] <= dest_address.c &&  dest_address.c <= Cmax_array_${MESH}[i]) begin
                    local_cluster_endp_addr_up_dir = endp_addr_array[i];
                    up_dir_sel=1'b1;
                end
            end
        end\n";
        }else{
            $not_dynamic_modules .=" " x 8 . "always_comb begin
            local_cluster_endp_addr_up_dir=0;
            up_dir_sel=1'b0;
        end\n";
        }
    $not_dynamic .="    end\n";
    $not_dynamic_modules .="
    assign local_cluster_endp_addr =
        ( dest_address.c == current_cluster_id )? dest_address:
        ( up_dir_sel) ? local_cluster_endp_addr_up_dir:
        local_cluster_endp_addr_down_dir;
endmodule\n\n";
    }

my $rtl="
`include \"pronoc_def.v\"
module global_id_to_local_cluster_endp #(
    parameter NOC_ID=0
    `ifndef DYNAMIC_CLUSTER_INIT
    ,parameter CLUSTER_ID=0,
    parameter RID=0
    `endif
)(
    `ifdef DYNAMIC_CLUSTER_INIT
    address_table,
    local_cluster_endp_addr_down_dir,
    current_cluster_id,
    `endif
    dest_address,
    local_cluster_endp_addr,
    up_dir_sel
);
    `NOC_CONF
    input multimesh_router_addr_t dest_address;
    output multimesh_router_addr_t local_cluster_endp_addr;
    output logic up_dir_sel;

    `ifdef DYNAMIC_CLUSTER_INIT
    input  cluster_hid_entry_t  address_table [MAX_ENTRY];
    input  multimesh_router_addr_t local_cluster_endp_addr_down_dir;
    input [CLUSTER_IDw-1 : 0] current_cluster_id;
    `endif

    `ifndef DYNAMIC_CLUSTER_INIT
    generate
$not_dynamic
    endgenerate
    `else
    dynamic_icr  icr (
        .dest_address(dest_address),
        .local_cluster_endp_addr(local_cluster_endp_addr),
        .local_cluster_endp_addr_down_dir(local_cluster_endp_addr_down_dir),
        .current_cluster_id(current_cluster_id),
        .address_table(address_table),
        up_dir_sel(up_dir_sel)
    );
    `endif
endmodule

`ifdef DYNAMIC_CLUSTER_INIT
module dynamic_icr (
    dest_address,
    local_cluster_endp_addr,
    local_cluster_endp_addr_down_dir,
    current_cluster_id,
    address_table,
    up_dir_sel
);
    `NOC_CONF
    input multimesh_router_addr_t dest_address;
    output multimesh_router_addr_t local_cluster_endp_addr;
    input multimesh_router_addr_t    local_cluster_endp_addr_down_dir;
    input [CLUSTER_IDw-1 : 0] current_cluster_id;
    input cluster_hid_entry_t  address_table [MAX_ENTRY];
    output logic up_dir_sel;

    multimesh_router_addr_t local_cluster_endp_addr_up_dir;

    always_comb begin
        local_cluster_endp_addr_up_dir=0;
        up_dir_sel=1'b0;
        for (int i=0;i< MAX_ENTRY;i++) begin
            if(address_table[i].valid) begin
                if(address_table[i].Cmin <= dest_address.c &&  dest_address.c < address_table[i].Cmax) begin
                    local_cluster_endp_addr_up_dir = address_table[i].endp_addr;
                    up_dir_sel=1'b1;
                end
            end
        end
    end

    assign local_cluster_endp_addr =
        ( dest_address.c == current_cluster_id )? dest_address:
        ( up_dir_sel) ? local_cluster_endp_addr_up_dir:
        local_cluster_endp_addr_down_dir;
endmodule

module dynamic_hids_per_router (
    local_cluster_endp_addr_down_dir,
    current_cluster_id,
    address_table,
    program_port,
    reset,
    clk
);
    `NOC_CONF
    output cluster_hid_entry_t  address_table [MAX_ENTRY];
    input clk,reset;
    input program_port_t program_port;
    output multimesh_router_addr_t local_cluster_endp_addr_down_dir;
    output logic [CLUSTER_IDw-1 : 0] current_cluster_id;

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            local_cluster_endp_addr_down_dir=0;
            foreach (address_table[i]) begin
                address_table[i].valid <= 1'b0;
                current_cluster_id<=0;
            end
        end else begin
            if(program_port.data.valid) begin
                if( !program_port.down_sel ) begin
                        address_table[program_port.addr] <= program_port.data;
                        current_cluster_id <= program_port.current_cluster_id;
                end else local_cluster_endp_addr_down_dir=program_port.data.endp_addr;
            end
        end
    end
endmodule

`else
$not_dynamic_modules
`endif

";
return $rtl;


}
###########
#   modules
#########

sub create_routing_modules{
    my $rtl = multimesh_address_encoder(@_);
    $rtl.= multimesh_address_decoder(@_);
    return $rtl;
}

sub  multimesh_address_decoder{
    my $config=shift;
    my $lines="";
    foreach my $mesh (keys %{$config->{multi_mesh}}) {
        my $MESH=uc $mesh;
        $lines.="
        for (int z=0; z<CLUSTER_${MESH}_NZ; z=z+1) begin: ${MESH}Z_
            for (int y=0; y<CLUSTER_${MESH}_NY; y=y+1) begin: ${MESH}Y_
                for (int x=0; x<CLUSTER_${MESH}_NX; x=x+1) begin: ${MESH}X_
                    //int  RID=(z*(CLUSTER_${MESH}_NY * CLUSTER_${MESH}_NY) + (y * CLUSTER_${MESH}_NX) + x) + CLUSTER_${MESH}_RID_INIT;
                    multimesh_router_addr_t  CODED;
                    CODED.x=x;
                    CODED.y=y;
                    CODED.z=z;
                    CODED.c=${MESH}_ID;
                    addr_table[CODED]=(z*(CLUSTER_${MESH}_NY * CLUSTER_${MESH}_NY) + (y * CLUSTER_${MESH}_NX) + x) + CLUSTER_${MESH}_RID_INIT;
                end
            end
        end
        ";
    }

return "

module multimesh_address_decoder (
    rid_out,
    addr_st_i
);
    `NOC_CONF
    output  [RIDw-1 : 0] rid_out;
    input multimesh_router_addr_t addr_st_i;
    localparam BITS= \$bits(multimesh_router_addr_t);
    logic [RIDw-1 : 0] addr_table [2**BITS-1 :0];
    always_comb begin
    $lines
    end
    assign rid_out = addr_table [addr_st_i];
endmodule
";
}

sub  multimesh_address_encoder{
    my $config=shift;
    my $lines="";
    foreach my $mesh (keys %{$config->{multi_mesh}}) {
        my $MESH=uc $mesh;
        $lines.="
        for (z=0; z<CLUSTER_${MESH}_NZ; z=z+1) begin: ${MESH}Z_
            for (y=0; y<CLUSTER_${MESH}_NY; y=y+1) begin: ${MESH}Y_
                for (x=0; x<CLUSTER_${MESH}_NX; x=x+1) begin: ${MESH}X_
                    localparam RID=(z*(CLUSTER_${MESH}_NY * CLUSTER_${MESH}_NY) + (y * CLUSTER_${MESH}_NX) + x) + CLUSTER_${MESH}_RID_INIT;
                    assign addr_table [RID].x=x;
                    assign addr_table [RID].y=y;
                    assign addr_table [RID].z=z;
                    assign addr_table [RID].c=${MESH}_ID;
                end
            end
        end
        ";
    }
    return "
`include \"pronoc_def.v\"

module multimesh_address_encoder (
    rid_in,
    addr_st_o
);
    `NOC_CONF
    input  [RIDw-1 : 0] rid_in;
    output multimesh_router_addr_t addr_st_o;

    multimesh_router_addr_t addr_table [MAX_RID];
    genvar x,y,z;
    generate
    $lines
    endgenerate

    assign addr_st_o = addr_table [rid_in];
endmodule"
;

}

sub multimesh_routing_xyz {
    my $conf=shift;
    return "

module multimesh_route #(
    parameter type multimesh_router_addr_t
)(
    current_router_addr_i,
    destination_router_addr_i,
    router_port_out
);
    `NOC_CONF
    input  multimesh_router_addr_t current_router_addr_i,destination_router_addr_i;
    output [MAX_P-1 : 0] router_port_out;

    generate
    if(current_router_addr_in.c != destination_router_addr_i.c) begin
        multimesh_cluster_to_clusterr_route  c_to_c(
            .current_router_addr_i(current_router_addr_i),
            .destination_router_addr_i(destination_router_addr_i),
            .router_port_out(router_port_out)
        );
    end else begin
        intercluster_route_xyz the_xyz (
            .current_router_addr_i(current_router_addr_i),
            .destination_router_addr_i(destination_router_addr_i),
            .router_port_out(router_port_out)
        );
    end
    endgenerate
endmodule
";
}

sub get_scolar_pos{
    my ($item,@list)=@_;
    return (grep { $list[$_] eq $item } 0..$#list)[0];
}

sub create_rtl_file{
    my ($rtl_file,$rtl_code)=@_;
    # Extract filename and extension
    my ($filename, $dirs, $ext) = fileparse($rtl_file, qr/\.[^.]*/);
    my $header=get_rtl_hdr_file("$filename.$ext");

    open(my $output_fh, '>', $rtl_file) or die "Could not create file '$rtl_file' $!";
    print $output_fh $header.$rtl_code;
    close($output_fh);
    print"[info:] Create $rtl_file\n";
}

sub generate_pronoc_multimesh{
    my %verticals;
    my %Vlinks_sel;
    my %is_connected;
    my %connections_hash;
    my %vcs;
    #generate routers_global_ids
    my $I=find_interpose($config);
    my %router_ids;
    my $multimesh_rtl_file="$out_dir/".lc $topology.".sv";
    my $noc_param_file="$out_dir/noc_localparam.v";
    my $multimesh_routing_file="$out_dir/". lc ${topology}."_routing.sv";
    my $intercluster_routing_table="$out_dir/". lc ${topology}."_icr.sv";
    my $rtl_io_per_cluster ="";
    my $rtl_cluster_instant="";
    my $rtl_io_assign="";
    my $rtl_cluster_localparam="";
    my $rtl_noc_localparam="";
    my $rtl_vertical_links_assign="";

    print"[info:]generating $topology topology file in $multimesh_rtl_file\n";
    foreach my $mesh (keys %{$config->{multi_mesh}}) {
        print "\t[info:] Add CLUSTER_${mesh} instantiation \n";
        update_multimesh_config($mesh,$config,\%vcs);
        $rtl_io_assign.=gen_multi_mesh_io_assign($mesh);
        $rtl_io_per_cluster.=gen_io_name_per_cluster($mesh);
        $rtl_cluster_localparam.=gen_multi_mesh_cluster_localparam($mesh,$config);
        $rtl_cluster_instant.=gen_multi_mesh_cluster_instant($mesh);
        my $nodes_num = $config->{'multi_mesh'}{$mesh}{'NR'};
        for( my $i=0; $i<$nodes_num; $i++) {
            $is_connected{'IN'}{$mesh}{$i}=0;
            $is_connected{'OUT'}{$mesh}{$i}=0;
        }
        if (exists $config->{'multi_mesh'}{$mesh}{'vertical_links_placement'}) {
            vertical_links_placement($mesh,$config,\%verticals,$I);
        }
        if (exists $config->{'multi_mesh'}{$mesh}{'vertical_links_selection'}){
            vertical_links_selection($mesh,$config,\%Vlinks_sel,$I);
        }
    }
    %cluster_ids=get_cluster_ids($config,\%cluster_tree);
    my ($v_links,$v_err)=gen_multi_mesh_vertical_link_assign(\%verticals,\%is_connected,\%connections_hash);
    $rtl_vertical_links_assign.=$v_links;
    #Uni directional channels
    my $uni_dir=gen_multimesh_unidir_vlinks(\%verticals,\%connections_hash);
    if (length ($uni_dir) >3){
        $rtl_vertical_links_assign.=
        "//fix credit/ctrl chanel connection for unidirectional channels\n$uni_dir";
    }

    my $rtl_code=gen_muli_mesh_topology_rtl  ($rtl_io_per_cluster,$rtl_cluster_instant,$rtl_io_assign, $rtl_vertical_links_assign, $v_err  ) ;
    create_rtl_file( $multimesh_rtl_file,$rtl_code);

    $rtl_code=gen_noc_localparam(\%vcs,$config);
    $rtl_code.=$rtl_cluster_localparam;
    $rtl_code.=gen_noc_cluster_id_func($config);
    $rtl_code.="  typedef struct packed {
        logic [CLUSTER_IDw-1 : 0] Cmin,Cmax;
        multimesh_router_addr_t endp_addr;
        bit valid;
    } cluster_hid_entry_t;

    localparam [1:0]
        Z_PLUS_SEL=2'b00,
        Z_MIN_SEL=2'b01,
        BOTH_SEL=2'b10,
        SAME_SEL=2'b11;


    `ifdef DYNAMIC_CLUSTER_INIT
    localparam MAX_ENTRY=10;
    typedef struct packed {
        cluster_hid_entry_t data;
        logic [\$clog2(MAX_ENTRY)-1 : 0] addr;
        logic [CLUSTER_IDw-1 : 0] current_cluster_id;
        bit down_sel;
    } program_port_t;
    `endif
    `endif\n";
    create_rtl_file($noc_param_file,$rtl_code);
    $rtl_code=create_routing_modules($config);
    create_rtl_file($multimesh_routing_file,$rtl_code);
    $rtl_code= create_inter_cluster_routing($config,\%Vlinks_sel);
    create_rtl_file($intercluster_routing_table,$rtl_code);

#my @children = get_clusters_in_dir (\%cluster_tree,'C1','down');
#print "'C1 down: @children\n";
#@children = get_clusters_in_dir (\%cluster_tree,'C1','up');
#print "'C1 up: @children\n";
#@children = get_clusters_in_dir (\%cluster_tree,'I','down');
#print "'I down: @children\n";
#@children = get_clusters_in_dir (\%cluster_tree,'I','up');
#print "'I up: @children\n";
#print Dumper(\%cluster_ids);

}

#sub get_nearest_vlink{
#    my ($config,$mesh1,$id1,$mesh2,$id2)=@_;
#    print "$mesh1,$id1,$mesh2,$id2\n";
#    return undef if($mesh1 eq $mesh2);
#    my ($paths_to_dst,$ports_to_dst) = get_all_minimal_paths_between_two_endps($config,$mesh1."_".$id1,$mesh2."_".$id2);
#    my $min_index=100000;
#    my $i=0;
#    my @a;
#    foreach my $path (@{$ports_to_dst}) {
#        if (defined $path){
#            my @ports=@{$path};
#            my $p= get_scolar_pos(7,@ports) //  get_scolar_pos(5,@ports);
#            if($min_index>$p){
#                $min_index=$p;
#                @a= @{$paths_to_dst->[$i]};
#            }
#        }
#        $i++;
#    }
#
#    my @l=split ("_", $a[$min_index-1]);
#    #print "** @a : $min_index\n";
#    print "local selection $a[$min_index-1]\n mesh is $l[0], id is $l[1]\n";
#    return $l[1];
#}

1;

