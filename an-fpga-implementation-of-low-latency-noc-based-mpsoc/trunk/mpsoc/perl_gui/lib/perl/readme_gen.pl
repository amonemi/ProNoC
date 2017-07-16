#! /usr/bin/perl -w

use Time::Piece;

sub get_license_header {
	my $file_name=shift;
my $t = Time::Piece->new();
my $year=$t->year;
	my $head="
/**********************************************************************
**	File: $file_name
**    
**	Copyright (C) 2014-$year  Alireza Monemi
**    
**	This file is part of ProNoC $ProNOC::VERSION 
**
**	ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**	you can redistribute it and/or modify it under the terms of the GNU
**	Lesser General Public License as published by the Free Software Foundation,
**	either version 2 of the License, or (at your option) any later version.
**
** 	ProNoC is distributed in the hope that it will be useful, but WITHOUT
** 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
** 	or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
** 	Public License for more details.
**
** 	You should have received a copy of the GNU Lesser General Public
** 	License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
******************************************************************************/ 
";


return $head;

}


sub autogen_warning {

my $string ="
/**************************************************************************
**	WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
**	OVERWRITTEN AND LOST. Rename this file if you wish to do any modification.
****************************************************************************/\n\n";

return $string;


}


sub perl_file_header {
	my $file_name=shift;
my $head="#######################################################################
##	File: $file_name
##    
##	Copyright (C) 2014-2016  Alireza Monemi
##    
##	This file is part of ProNoC $ProNOC::VERSION 
##
## 	WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT 
##	MAY CAUSE UNEXPECTED BEHAIVOR.
################################################################################

";
return $head;
}


1;
