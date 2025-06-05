#!/usr/bin/perl  
package ProNOC;
use strict;
use warnings;
use File::Basename;


#add home dir in perl 5.6
use FindBin;
use lib $FindBin::Bin;
use Cwd qw(realpath);




use File::Path qw(make_path);


use strict;
use warnings;




my $script_path = dirname(__FILE__);

require "$script_path/../../synthetic_sim/src/src.pl";
use lib "../synthetic_sim/src/perl_lib";

use constant::boolean;
use base 'Class::Accessor::Fast';

my $conf_file=$ARGV[0];


sub create_noc_param_vv {
    my ($conf_file)=@_;
    my $o = do $conf_file;
    die "Could not parse $conf_file: $@" if $@;
    die "Could not read $conf_file: $!" unless defined $o;
    my $param = $o->{'noc_param'};
    my ($param_v,$include_h,$tops)=   gen_noc_localparam_v( $o,$param);
    save_file("$script_path/noc_localparam.v",$param_v);
}

create_noc_param_vv ($conf_file);
