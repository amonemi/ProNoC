#!/usr/bin/perl
use warnings;
use strict;
use List::Util 'shuffle';



sub remove_scolar_from_array{
	my ($array_ref,$item)=@_;
	my @array=@{$array_ref};
	my @new;
	foreach my $p (@array){
		if($p ne $item ){
			push(@new,$p);
		}		
	}
	return @new;	
}

sub random_dest_gen {
	my $n=shift;
	my @c=(0..$n-1);
	my @o;	
	for (my $i=0; $i<$n; $i++){
		my @l= shuffle @c;
		@l=remove_scolar_from_array(\@l,$i);
		$o[$i]=\@l;
		
	}
	return \@o;

}

my $ref=random_dest_gen(16);
my @random= @{$ref};

for (my $i=0; $i<16; $i++){
	for (my $j=0; $j<15; $j++){
	print @{$random[$i]}[$j];
	print ",";
}
print "\n";
}
