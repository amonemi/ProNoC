use warnings;
use strict;


package wb_addr;





sub wb_addr_new {
    # be backwards compatible with non-OO call
    my $class = ("ARRAY" eq ref $_[0]) ? "wb_addr" : shift;
    my $self;
   
    $self = {};
	wb_add_all_addr($self);

    bless($self,$class);

   
    return $self;
} 


sub wb_add_all_addr{
	my $self=shift;
	wb_add_addr($self,'0xf000_0000', '0xffff_ffff ', 'Cached',    256,   'ROM');
	wb_add_addr($self,'0xb800_0000', '0xbfff_ffff', 'Uncached',  128, 	'custom devices');
	wb_add_addr($self,'0xa600_0000', '0xb7ff_ffff', 'Uncached',  288, 	'Reserved1');
	wb_add_addr($self,'0xa500_0000', '0xa5ff_ffff', 'Uncached',  16,  	'Debug');
	wb_add_addr($self,'0xa400_0000', '0xa4ff_ffff', 'Uncached',  16,  	'Digital Camera Ctrl');
	wb_add_addr($self,'0xa300_0000', '0xa3ff_ffff', 'Uncached',  16,  	'I2C Controller');
	wb_add_addr($self,'0xa200_0000', '0xa2ff_ffff', 'Uncached',  16,  	'TDM Controller');
	wb_add_addr($self,'0xa100_0000', '0xa1ff_ffff', 'Uncached',  16,  	'HDLC Controller');
	wb_add_addr($self,'0xa000_0000', '0xa0ff_ffff', 'Uncached',  16,  	'Real-Time Clock');
	wb_add_addr($self,'0x9f00_0000', '0x9fff_ffff', 'Uncached',  16,  	'Firewire Controller');
	wb_add_addr($self,'0x9e00_0000', '0x9eff_ffff', 'Uncached',  16,  	'IDE Controller');	
	wb_add_addr($self,'0x9d00_0000', '0x9dff_ffff', 'Uncached',  16,  	'Audio Controller');
	wb_add_addr($self,'0x9c00_0000', '0x9cff_ffff', 'Uncached',  16,  	'USB Host Controller');
	wb_add_addr($self,'0x9b00_0000', '0x9bff_ffff', 'Uncached',  16,  	'USB Func Controller');
	wb_add_addr($self,'0x9a00_0000', '0x9aff_ffff', 'Uncached',  16,  	'General-Purpose DMA');
	wb_add_addr($self,'0x9900_0000', '0x99ff_ffff', 'Uncached',  16,  	'PCI Controller');
	wb_add_addr($self,'0x9800_0000', '0x98ff_ffff', 'Uncached',  16,  	'IrDA Controller');
	wb_add_addr($self,'0x9700_0000', '0x97ff_ffff', 'Uncached',  16,  	'Graphics Controller');
	wb_add_addr($self,'0x9600_0000', '0x96ff_ffff', 'Uncached',  16,  	'PWM/Timer/Counter Ctrl');
	wb_add_addr($self,'0x9500_0000', '0x95ff_ffff', 'Uncached',  16,  	'Traffic COP');
	wb_add_addr($self,'0x9400_0000', '0x94ff_ffff', 'Uncached',  16,  	'PS/2 Controller');
	wb_add_addr($self,'0x9300_0000', '0x93ff_ffff', 'Uncached',  16,  	'Memory Controller');
	wb_add_addr($self,'0x9200_0000', '0x92ff_ffff', 'Uncached',  16,  	'Ethernet Controller');
	wb_add_addr($self,'0x9100_0000', '0x91ff_ffff', 'Uncached',  16,  	'General-Purpose I/O');
	wb_add_addr($self,'0x9000_0000', '0x90ff_ffff', 'Uncached',  16,  	'UART16550 Controller');
	wb_add_addr($self,'0x8000_0000', '0x8fff_ffff', 'Uncached',  256, 	'PCI I/O');
	wb_add_addr($self,'0x4000_0000', '0x7fff_ffff', 'Uncached',  1024,	'Reserved2');
	wb_add_addr($self,'0x0000_0000','0x3fff_ffff', 'Cached',    1024,	'RAM');

}


sub wb_add_addr{
		my($self,$start,$end,$cashed,$size,$name)=@_;
		$self->{names}{$name}={};
		$self->{names}{$name}{start}=$start;
		$self->{names}{$name}{end}=$end;
		$self->{names}{$name}{cashed}=$cashed;
		$self->{names}{$name}{size}=$size;
		
}	

sub wb_list_names{
	my($self)=@_;
	my @names;
	foreach my $n ( keys %{$self->{names}}){
		push (@names,$n);	
	}	
	return @names;	
	
}	


sub wb_get_addr_info{
	my($self,$name)=@_;
	my($start,$end,$cashed,$size);
	if(exists ($self->{names}{$name})){
		 $start	=$self->{names}{$name}{start};
		 $end		=$self->{names}{$name}{end};
		 $cashed	=$self->{names}{$name}{cashed};
		 $size	=$self->{names}{$name}{size};	
	}	
	return ($start,$end,$cashed,$size);	
	
}	

1;
