use strict;
use warnings;

use String::Similarity;

 
sub find_the_most_similar_position{
	my ($item ,@list)=@_;
	my $most_similar_pos=0;
	my $lastsim=0;
	my $i=0;
	# convert item to lowercase
	$item = lc $item;
	foreach my $p(@list){
		my $similarity= similarity $item, $p;
		if ($similarity > $lastsim){
			$lastsim=$similarity;
			$most_similar_pos=$i;
		}
		$i++;
	}
	return $most_similar_pos;
}



####################
#	 file
##################


sub read_verilog_file{
	my @files            = @_;
	my %cmd_line_defines = ();
	my $quiet            = 1;
	my @inc_dirs         = ();
	my @lib_dirs         = ();
	my @lib_exts         = ();
	my $vdb = rvp->read_verilog(\@files,[],\%cmd_line_defines,
			  $quiet,\@inc_dirs,\@lib_dirs,\@lib_exts);

	my @problems = $vdb->get_problems();
	if (@problems) {
	    foreach my $problem ($vdb->get_problems()) {
		print STDERR "$problem.\n";
	    }
	    # die "Warnings parsing files!";
	}

	return $vdb;
}




sub append_text_to_file {
	my  ($file_path,$text)=@_;
	open(my $fd, ">>$file_path") or die "could not open $file_path: $!";
	print $fd $text;
	close $fd;
}




sub save_file {
	my  ($file_path,$text)=@_;
	open my $fd, ">$file_path" or die "could not open $file_path: $!";
	print $fd $text;
	close $fd;	
}

sub load_file {
	my $file_path=shift;
	my $str;
	if (-f "$file_path") { 
				
		$str = do {
	    		local $/ = undef;
	    		open my $fh, "<", $file_path
			or die "could not open $file_path: $!";
	    		<$fh>;
		};

	}
	return $str;
}

sub merg_files {
	my  ($source_file_path,$dest_file_path)=@_;
	local $/=undef;
  	open FILE, $source_file_path or die "Couldn't open file: $!";
  	my $string = <FILE>;
  	close FILE;
	 append_text_to_file ($dest_file_path,$string);	
}



sub copy_file_and_folders{
	my ($file_ref,$project_dir,$target_dir)=@_;

	foreach my $f(@{$file_ref}){
		my $name= basename($f);	
				
		my $n="$project_dir$f";
		if (-f "$n") { #copy file
			copy ("$n","$target_dir/$name"); 		
		}elsif(-f "$f" ){
			copy ("$f","$target_dir/$name");     			 	
		}elsif (-d "$n") {#copy folder
			dircopy ("$n","$target_dir/$name"); 		
		}elsif(-d "$f" ){
			dircopy ("$f","$target_dir/$name"); 		
    			 	
		}
	}

}


sub remove_file_and_folders{
	my ($file_ref,$project_dir)=@_;

	foreach my $f(@{$file_ref}){
		my $name= basename($f);				
		my $n="$project_dir$f";
		if (-f "$n") { #copy file
			unlink ("$n");
		}elsif(-f "$f" ){
			unlink ("$f");     			 	
		}elsif (-d "$n") {#copy folder
			rmtree ("$n");
		}elsif(-d "$f" ){
			rmtree ("$f");    			 	
		}
	}

}

sub read_file_cntent {
	my ($f,$project_dir)=@_;
	my $n="$project_dir$f";
	my $str;
	if (-f "$n") { 
				
		$str = do {
	    		local $/ = undef;
	    		open my $fh, "<", $n
			or die "could not open $n: $!";
	    		<$fh>;
		};

	}elsif(-f "$f" ){
		$str = do {
	    		local $/ = undef;
	    		open my $fh, "<", $f
			or die "could not open $f: $!";
	    		<$fh>;
		};
		
						 	
	}
	return $str;

}


sub check_file_has_string {
    my ($file,$string)=@_;
    my $r;
    open(FILE,$file);
    if (grep{/$string/} <FILE>){
       $r= 1; #print "word  found\n";
    }else{
       $r= 0; #print "word not found\n";
    }
    close FILE;
    return $r;
}

##############
#  clone_obj
#############

sub clone_obj{
	my ($self,$clone)=@_;
	
	foreach my $p (keys %$self){
		delete ($self->{$p});
	}
	foreach my $p (keys %$clone){
		$self->{$p}= $clone->{$p};
		my $ref= ref ($clone->{$p});
		if( $ref eq 'HASH' ){
			
			foreach my $q (keys %{$clone->{$p}}){
				$self->{$p}{$q}= $clone->{$p}{$q};	
				my $ref= ref ($self->{$p}{$q});
				if( $ref eq 'HASH' ){
				
					foreach my $z (keys %{$clone->{$p}{$q}}){
						$self->{$p}{$q}{$z}= $clone->{$p}{$q}{$z};	
						my $ref= ref ($self->{$p}{$q}{$z});
						if( $ref eq 'HASH' ){
							
							foreach my $w (keys %{$clone->{$p}{$q}{$z}}){
								$self->{$p}{$q}{$z}{$w}= $clone->{$p}{$q}{$z}{$w};	
								my $ref= ref ($self->{$p}{$q}{$z}{$w});
								if( $ref eq 'HASH' ){
									
							
									foreach my $m (keys %{$clone->{$p}{$q}{$z}{$w}}){
										$self->{$p}{$q}{$z}{$w}{$m}= $clone->{$p}{$q}{$z}{$w}{$m};	
										my $ref= ref ($self->{$p}{$q}{$z}{$w}{$m});
										if( $ref eq 'HASH' ){
											
											foreach my $n (keys %{$clone->{$p}{$q}{$z}{$w}{$m}}){
												$self->{$p}{$q}{$z}{$w}{$m}{$n}= $clone->{$p}{$q}{$z}{$w}{$m}{$n};	
												my $ref= ref ($self->{$p}{$q}{$z}{$w}{$m}{$n});	
												if( $ref eq 'HASH' ){
												
													foreach my $l (keys %{$clone->{$p}{$q}{$z}{$w}{$m}{$n}}){
														$self->{$p}{$q}{$z}{$w}{$m}{$n}{$l}= $clone->{$p}{$q}{$z}{$w}{$m}{$n}{$l};	
														my $ref= ref ($self->{$p}{$q}{$z}{$w}{$m}{$n}{$l});	
														if( $ref eq 'HASH' ){
														}
													}
												
												}#if														
											}#n
										}#if
									}#m							
								}#if
							}#w
						}#if
					}#z
				}#if
			}#q
		}#if	
	}#p
}#sub	


sub get_project_dir{ #mpsoc directory address
	my $dir = Cwd::getcwd();
	my $project_dir	  = abs_path("$dir/../../");
	return $project_dir;
}


sub remove_project_dir_from_addr{
	my $file=shift;	
	my $project_dir	  = get_project_dir(); 
	$file =~ s/$project_dir//; 
	return $file;	
}

sub add_project_dir_to_addr{
	my $file=shift;
	my $project_dir	  = get_project_dir(); 
	return $file if(-f $file ); 
	return "$project_dir/$file";	
	
}

sub get_full_path_addr{
	my $file=shift;
	my $dir = Cwd::getcwd();
	my $full_path = "$dir/$file";	
	return $full_path  if -f ($full_path );
	return $file;
}

sub regen_object {
	my $path=shift;
	$path = get_full_path_addr($path);
	my $pp= eval { do $path };
	my $r= ($@ || !defined $pp);
	return ($pp,$r,$@);
}


################
#	general
#################




sub  trim { my $s = shift;  $s=~s/[\n]//gs; return $s };

sub remove_all_white_spaces($)
{
  my $string = shift;
  $string =~ s/\s+//g;
  return $string;
}




sub get_scolar_pos{
	my ($item,@list)=@_;
	my $pos;
	my $i=0;
	foreach my $c (@list)
	{
		if(  $c eq $item) {$pos=$i}
		$i++;
	}	
	return $pos;	
}	

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

sub replace_in_array{
	my ($array_ref,$item1,$item2)=@_;
	my @array=@{$array_ref};
	my @new;
	foreach my $p (@array){
		if($p eq $item1 ){
			push(@new,$item2);
		}else{
			push(@new,$p);
		}		
	}
	return @new;	
}



# return an array of common elemnts between two input arays 
sub get_common_array{
	my ($a_ref,$b_ref)=@_;
	my @A=@{$a_ref};
	my @B=@{$b_ref};
	my @C;
	foreach my $p (@A){
		if( grep (/^\Q$p\E$/,@B)){push(@C,$p)};
	}
	return  @C;	
}

#a-b
sub get_diff_array{
	my ($a_ref,$b_ref)=@_;
	my @A=@{$a_ref};
	my @B=@{$b_ref};
	my @C;
	foreach my $p (@A){
		if( !grep  (/^\Q$p\E$/,@B)){push(@C,$p)};
	}
	return  @C;	
	
}



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



sub metric_conversion{
	my $size=shift;	
	my $size_text=	$size==0	 ? 'Error': 
			$size<(1 << 10)? $size:
			$size<(1 << 20)? join (' ', ($size>>10,"K")) :
			$size<(1 << 30)? join (' ', ($size>>20,"M")) :
					 join (' ', ($size>>30,"G")) ;
return $size_text;
}





######
#  state
#####
sub set_gui_status{
	my ($object,$status,$timeout)=@_;
	$object->object_add_attribute('gui_status','status',$status);
	$object->object_add_attribute('gui_status','timeout',$timeout);
}	


sub get_gui_status{
	my ($object)=@_;
	my $status= $object->object_get_attribute('gui_status','status');
	my $timeout=$object->object_get_attribute('gui_status','timeout');
	return ($status,$timeout);	
}




###########
#  color
#########


	
sub get_color {
	my $num=shift;
	
	my @colors=(
	0x6495ED,#Cornflower Blue
	0xFAEBD7,#Antiquewhite
	0xC71585,#Violet Red
	0xC0C0C0,#silver
	0xADD8E6,#Lightblue	
	0x6A5ACD,#Slate Blue
	0x00CED1,#Dark Turquoise
	0x008080,#Teal
	0x2E8B57,#SeaGreen
	0xFFB6C1,#Light Pink
	0x008000,#Green
	0xFF0000,#red
	0x808080,#Gray
	0x808000,#Olive
	0xFF69B4,#Hot Pink
	0xFFD700,#Gold
	0xDAA520,#Goldenrod
	0xFFA500,#Orange
	0x32CD32,#LimeGreen
	0x0000FF,#Blue
	0xFF8C00,#DarkOrange
	0xA0522D,#Sienna
	0xFF6347,#Tomato
	0x0000CD,#Medium Blue
	0xFF4500,#OrangeRed
	0xDC143C,#Crimson	
	0x9932CC,#Dark Orchid
	0x800000,#marron
	0x800080,#Purple
	0x4B0082,#Indigo
	0xFFFFFF,#white	
	0x000000 #Black		
		);
	
	my $color= 	($num< scalar (@colors))? $colors[$num]: 0xFFFFFF;	
	my $red= 	($color & 0xFF0000) >> 8;
	my $green=	($color & 0x00FF00);
	my $blue=	($color & 0x0000FF) << 8;
	
	return ($red,$green,$blue);
	
}


sub get_color_hex_string {
	my $num=shift;
	
	my @colors=(
	"6495ED",#Cornflower Blue
	"FAEBD7",#Antiquewhite
	"C71585",#Violet Red
	"C0C0C0",#silver
	"ADD8E6",#Lightblue	
	"6A5ACD",#Slate Blue
	"00CED1",#Dark Turquoise
	"008080",#Teal
	"2E8B57",#SeaGreen
	"FFB6C1",#Light Pink
	"008000",#Green
	"FF0000",#red
	"808080",#Gray
	"808000",#Olive
	"FF69B4",#Hot Pink
	"FFD700",#Gold
	"DAA520",#Goldenrod
	"FFA500",#Orange
	"32CD32",#LimeGreen
	"0000FF",#Blue
	"FF8C00",#DarkOrange
	"A0522D",#Sienna
	"FF6347",#Tomato
	"0000CD",#Medium Blue
	"FF4500",#OrangeRed
	"DC143C",#Crimson	
	"9932CC",#Dark Orchid
	"800000",#marron
	"800080",#Purple
	"4B0082",#Indigo
	"FFFFFF",#white	
	"000000" #Black		
		);
	
	my $color= 	($num< scalar (@colors))? $colors[$num]: "FFFFFF";	
	return $color;
	
}





sub check_verilog_identifier_syntax {
	my $in=shift;
	my $error=0;
	my $message='';
# an Identifiers must begin with an alphabetic character or the underscore character
	if ($in =~ /^[0-9\$]/){
		return 'an Identifier must begin with an alphabetic character or the underscore character';
	}
	

#	Identifiers may contain alphabetic characters, numeric characters, the underscore, and the dollar sign (a-z A-Z 0-9 _ $ )
	if ($in =~ /[^a-zA-Z0-9_\$]+/){
		 print "use of illegal character after\n" ;
		 my @w= split /([^a-zA-Z0-9_\$]+)/, $in; 
		 return "Contain illegal character of \"$w[1]\". Identifiers may contain alphabetic characters, numeric characters, the underscore, and the dollar sign (a-z A-Z 0-9 _ \$ )\n";
		
	}


# check Verilog reserved words
	my @keys =			("always","and","assign","automatic","begin","buf","bufif0","bufif1","case","casex","casez","cell","cmos","config","deassign","default","defparam","design","disable","edge","else","end","endcase","endconfig","endfunction","endgenerate","endmodule","endprimitive","endspecify","endtable","endtask","event","for","force","forever","fork","function","generate","genvar","highz0","highz1","if","ifnone","incdir","include","initial","inout","input","instance","integer","join","large","liblist","library","localparam","macromodule","medium","module","nand","negedge","nmos","nor","noshowcancelled","not","notif0","notif1","or","output","parameter","pmos","posedge","primitive","pull0","pull1","pulldown","pullup","pulsestyle_onevent","pulsestyle_ondetect","remos","real","realtime","reg","release","repeat","rnmos","rpmos","rtran","rtranif0","rtranif1","scalared","showcancelled","signed","small","specify","specparam","strong0","strong1","supply0","supply1","table","task","time","tran","tranif0","tranif1","tri","tri0","tri1","triand","trior","trireg","unsigned","use","vectored","wait","wand","weak0","weak1","while","wire","wor","xnor","xor");
	if( grep (/^$in$/,@keys)){
		return  "$in is a Verlig reserved word.";
	}
	return undef;
	
}


sub capture_number_after {
	my ($after,$text)=@_;
	my @q =split  (/$after/,$text);
	#my $d=$q[1];
	my @d = split (/[^0-9. ]/,$q[1]);
	return $d[0]; 

}

sub capture_string_between {
	my ($start,$text,$end)=@_;
	my @q =split  (/$start/,$text);
	my @d = split (/$end/,$q[1]);
	return $d[0];
}


sub make_undef_as_string {
	foreach my $p  (@_){
		$$p= 'undef' if (! defined $$p);
		
	}	
}

sub powi{ # x^y
	my ($x,$y)=@_; # compute x to the y
	my $r=1;
	for (my $i = 0; $i < $y; ++$i ) {
    	$r *= $x;
  	}
  return $r;
}

sub sum_powi{ # x^(y-1) + x^(y-2) + ...+ 1;
	my ($x,$y)=@_; # compute x to the y
	my $r = 0;
    for (my $i = 0; $i < $y; $i++){
    	$r += powi( $x, $i );
    }
  	return $r;
}	
	
	


1
	 
