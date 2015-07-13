#!/usr/bin/perl
# This program is called by process_checking.pl

#Written by Lu Wang(Lu.Wang@ihep.ac.cn)
#ChangeLog(2014.1.8): 
# 1. Added detailed report 2. added filesystem report 3. change readseek and writeseek report threshold 4. add sigal 2 of procinfo, get rid of useless info in log.

# SMALL : 0-2^7
# MIDDLE: 2^7-2^9
# LARGE : 2^9-2^11
my $SMALLSIZE=7;  
my $MIDDLESIZE=9;  
my $LARGESIZE=11; 

# send warning email upon wired IO  pattern only when efficiency is lower than $ethredhold
my $LOWEFF=80;

my %readnum,%writenum,%rseek,%wseek;
my $totalread,$totalwrite,$totalrseek,$totalwseek;
my $username;
my $pattern;
my $usedfs;
my $pid;
my $rawfile; # file keeping all the raw information, its name is computed by process_checking.pl

# check program arguments, in case it is excecuted manually 
if ($#ARGV<1){
	print "match.pl not enough parameter\n";
	return "UNKNOWN";
}else{
	$pid=$ARGV[0];
	$rawfile=$ARGV[1];
}


# use this function to switch on/off extents_stats of all file system on current node
sub procinfo(){
	my ($sig)=@_;
	my @procres1=</proc/fs/lustre/llite/*>;
	for $i(@procres1){
		$enterp="$i/extents_stats";
		if ($sig==1){
#			print "\nReport of $i\n";
			`echo 1 > $enterp`;
		}else{
#			print "\n Turn off proc $i\n";
			$content="$i/extents_stats_per_process";
        		$content2="$i/offset_stats";
			if ($sig==2){
				`cat $content >>$rawfile`;
				`cat $content2 >>$rawfile`; 
			}
			`echo 0 > $enterp`;
		}
       }
}

# analyze current process's extent_stats and offset_stats on current file system line by line,numbers are added to sum of all file systems 
sub anafs(){
	my ($resref,$power,@offset)=@_;
	for ($i=0;$i<=$power;$i++){
		$s=$resref->[$i];
		@r=split (/\s+/,$s);
		$totalread+=$r[5];
		$totalwrite+=$r[9];
		if ($i<=$SMALLSIZE){
			$readnum{SR}+=$r[5];
			$writenum{SW}+=$r[9];
		}
		if ($i>$SMALLSIZE && $i<=$MIDDLESIZE){
			$readnum{MR}+=$r[5];
			$writenum{MW}+=$r[9];
		}
		if ($i>$MIDDLESIZE && $i<=$LARGESIZE){
			$readnum{LR}+=$r[5];
			$writenum{LW}+=$r[9];
		}
		if ($i>$LARGESIZE){
			$readnum{VLR}+=$r[5];
			$writenum{VLW}+=$r[9];
		}
	}
	for ($i=0;$i<=$#offset;$i++){
		my @res=split /\s+/,$offset[$i];
		my $num=abs($res[7]);
		my $key;
		if (($res[2]==$pid) && ($num != 0)){
			if ($num<=(2**$SMALLSIZE)*4096){
				$key="S".$res[1]."S";
			}
			if ($num>(2**$SMALLSIZE)*4096 && $num<=(2**$MIDDLESIZE)*4096){
				$key="M".$res[1]."S";
			}
			if ($num>(2**$MIDDLESIZE)*4096 && $num<=(2**$LARGESIZE)*4096){
				$key="L".$res[1]."S";
			}
			if ($num>(2**$LARGESIZE)*4096){
				$key="VL".$res[1]."S";
			}
			if ($res[1] eq "R"){	
				$totalrseek++;
				$readseek{$key}++;
			}
			if ($res[1] eq "W"){
				$totalwseek++;
				$writeseek{$key}++;	
			}
		}else{
			next;
		}
	}
}

&procinfo(0);	
&procinfo(1);
sleep 60;
my @procres=</proc/fs/lustre/llite/*>;
for $i(@procres){
	$content="$i/extents_stats_per_process";
	$content2="$i/offset_stats";
	$i=~/(.*)llite\/(.*)-/;
	$curfs=$2;
	$found=0;
	@tmp=();
	@tmp2=`cat $content2`;
	open FIN,"$content" or die "Can not open proc entry:$!\n";
	while(<FIN>){
		if ($found==1){
			unless(/^(\s*)$/){
				push (@tmp,$_);
				next;
			}
			$found=0;
			$usedfs=$usedfs.":$curfs";
			&anafs(\@tmp,$#tmp,@tmp2);
		}else{
			if (/PID:(\s+)(\d+)/){
				$mypid=$2;
				if ($mypid eq $pid){
					$found=1;
					@tmp=();
				}
			}
		}		
	}
	if ($found==1){
		$usedfs=$usedfs.":$curfs";
		&anafs(\@tmp,$#tmp,@tmp2);
	}
	close FIN;
}



$totalnum=$totalread+$totalwrite+$totalrseek+$totalwseek;
if ($totalnum<10){
	print "UNKNOWN\n";
}else{
	print "$totalnum:$readnum{SR}:$readnum{MR}:$readnum{LR}:$readnum{VLR}:$writenum{SW}:$writenum{MW}:$writenum{LW}:$writenum{VLW}:$readseek{SRS}:$readseek{MRS}:$readseek{LRS}:$readseek{VLRS}:$writeseek{SWS}:$writeseek{MWS}:$writeseek{LWS}:$writeseek{VLWS}\n";
}
print "FileSystem\t$usedfs\n";
&procinfo(2);


