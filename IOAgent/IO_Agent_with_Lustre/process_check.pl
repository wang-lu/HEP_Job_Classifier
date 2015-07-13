#!/usr/bin/perl
use strict;

#default top directory
my $topdir="jobout";
my $badtopdir="badjob";
if ($#ARGV>=0){
	$topdir=$ARGV[0];
}

#a path keeping date and host info
my $subdir=`date +%y-%m-%d`;
my $hostname=`hostname`;
chomp($hostname);
chomp($subdir);
my $outdir="$topdir/$subdir/$hostname";
my $badoutdir="$badtopdir/$subdir/$hostname";
printf "mkdir -p $outdir\n";
`mkdir -p $outdir`;

# if the process starts less 15 min return 0, else return 1 
sub checketime(){
	my ($estr)=@_;
	my @myestr=split /:/,$estr;
	if ($#myestr<2 && $myestr[0]<15){
		return 0;
	}else{
		return 1;
	}
}

# use this function to send warning mail
sub sendmail(){
	my ($pbsid,$pid,$hn,$status,$noticetxt,$eff)=@_;
        my $touser="xxx\@ihep.ac.cn";
	my $sub;
	if ($status eq "UNKNOWNLOW"){
			$sub="$status:$eff job:$pbsid pid:$pid on $hn";
	}
	if ($status eq "SYSTEMERROR"){
			 $sub="$status:job:$pbsid pid:$pid on $hn";
	}
	if ($status eq "NOWORKER"){
			 $sub="$status:job:$pbsid on $hn";
	}
}

# main part of job analysis
sub anajob(){
	my $noticetxt;
	my ($pid,$pbsid)=@_;
	my $estr=`ps -o etime -p $pid|tail -n 1`;
	chomp($estr);
	my $diff=&checketime($estr);
	if ($diff==0){
		print "$pid has start less then 15 mins ($estr)\n";
		return 0;
	}
	print ("$pid has start $estr\n");
	my $outfile="$pbsid\-$pid.out";
	my $rawfile="$pbsid\-$pid.raw";
	if (-f "$outdir/$outfile"){
			printf("Already got output,skip job $pbsid\-$pid\n");
			return 0;
	}else{
			print ("output is $outdir/$outfile\n");
			
	}
	my $procname=`ps -ocmd -p $pid 2>/dev/null|tail -n 1 `;
	chomp($procname);
	my $eff=`ps -opcpu -p $pid 2>/dev/null|tail -n 1`;
	chomp($eff);
	my $user=`ps -ouser -p $pid 2>/dev/null|tail -n 1`;
	chomp($user);
	my $pattern=`./match.pl $pid $outdir/$rawfile`;
	eval{
		open OUTFILE,">$outdir/$outfile";
		printf OUTFILE ("User:\t%s\nPid:\t%s\nPbsid:\t%s\nProcssname:\t%s\nEfficiency:\t%s\nDetail:\t%s\n",$user,$pid,$pbsid,$procname,$eff,$pattern);
		close OUTFILE;
		$noticetxt="$outdir/$outfile";
		if ($eff<10 && ($pattern =~ "UNKNOWN" )){
			&sendmail($pbsid,$pid,$hostname,"UNKNOWNLOW",$noticetxt,$eff);
		}
	};
	if ($@){
		&sendmail($pbsid,$pid,$hostname,"SYSTEMERROR",$noticetxt,$eff);
		return;
	}
	
}

sub find_workers(){
	my($parentid,$ptr)=@_;
	my @children=`ps -ef |grep $parentid|grep -v grep | awk '{if (\$3==$parentid)print \$2}'`;
	my $j;
	if ($#children>=0){
		for($j=0;$j<=$#children;$j++){
			my $child=$children[$j];
			chomp($child);
			push @$ptr,$child;		
			&find_workers($child,$ptr);
		}
	}
	return 0;
}

my @res=`ps -ef |grep "pbssrv.ihep.ac.cn.SC" |grep -v root`;
my $i;
foreach $i (@res){
	my @workers;
	my $ptr=\@workers;
	my @pbsinfo=split /\s+/,$i;
	my $parentid=$pbsinfo[1];
	$pbsinfo[8]=~/.*\/(\d+).*\.ihep/;
	my $pbsid=$1;
	&find_workers($parentid,$ptr);
	my $realworker;
	my $w;
	foreach $w (@workers){
		my $eff=`ps -opcpu -p $w 2>/dev/null|tail -n 1`;
        	chomp($eff);
		if ($eff>0){
			&anajob($w,$pbsid);
			$realworker++;
		}else{
			print ("Skip $w of pbsid $pbsid\n");
		}
	}
	if ($realworker==0){
		print("$pbsid does not have a real worker, sending mail\n");
		`mkdir -p $badoutdir`;
	        if (-f "$badoutdir/$pbsid.log"){
			print "Already warned\n";
		}
		else{	
			`qstat -f $pbsid > $badoutdir/$pbsid.log`;
			&sendmail($pbsid,undef,$hostname,"NOWORKER","$badoutdir/$pbsid.log",undef);
		}
	}
}
