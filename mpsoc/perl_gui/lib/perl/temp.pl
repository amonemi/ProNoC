#! /usr/bin/perl -w
use Glib qw/TRUE FALSE/;

use strict;
use warnings;





my @nums=(0,2,3,6,7);

 my $s=compress_nums(@nums);

print "$s\n";


sub compress_nums{
	my 	@nums=@_;
	my @f=sort { $a <=> $b } @nums;
	my $s;
	my $ls;	
	my $range=0;
	my $x;	
	

	foreach my $p (@f){
		if(!defined $x) {
			$s="$p";
			$ls=$p;		
			
		}
		else{ 
			if($p-$x>1){ #gap exist
				if( $range){
					$s=($x-$ls>1 )? "$s:$x,$p": "$s,$x,$p";
					$ls=$p;
					$range=0;
				}else{
				$s= "$s,$p";
				$ls=$p;

				}
			
			}else {$range=1;}


		
		}
	
		$x=$p
	}
 	if($range==1){ $s= ($x-$ls>1 )? "$s:$x":  "$s,$x";}
	#update $s($ls,$hs);

	return $s;
	
}
