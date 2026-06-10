#add home dir in perl 5.6
use FindBin;
use lib $FindBin::Bin;
use Consts;

BEGIN {
    my $module = (Consts::GTK_VERSION==2) ? 'Gtk2' : 'Gtk3';
    my $file = $module;
    $file =~ s[::][/]g;
    $file .= '.pm';
    require $file;
    $module->import;
}

if(Consts::GTK_VERSION==2){
    require "widget2.pl"; 
}else{
    require "widget3.pl";
}
1;
