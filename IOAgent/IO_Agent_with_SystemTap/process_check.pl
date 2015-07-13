#!/usr/bin/perl
# Usage: pc.pl [outputdir]

$topdir="jobout";
$modname="/root/bin/iopattern/ioagent.ko";
$samplefile="/root/bin/iopattern/totalout";
$localdir="/tmp";

if ($#ARGV>=0){
	$topdir=$ARGV[0];
}
$subdir=`date +%y-%m-%d`;
$hostname=`hostname`;
chomp($hostname);
chomp($subdir);
$outdir="$topdir/$subdir/$hostname";
printf "mkdir -p $outdir\n";
`mkdir -p $outdir`;

sub checketime(){
	my ($estr)=@_;
	my @myestr=split /:/,$estr;
	if ($#myestr<2 && $myestr[0]<15){
		return 0;
	}else{
		return 1;
	}
}
sub sendmail(){
	my ($pbsid,$pid,$hn,$status,$noticetxt,$eff)=@_;
        my  $touser="xxx\@ihep.ac.cn";
	if ($status eq "UNKNOWNLOW"){
			$sub="$status:$eff job:$pbsid pid:$pid on $hn";
	}
	if ($status eq "SYSTEMERROR"){
			 $sub="$status:job:$pbsid pid:$pid on $hn";
	}
}

sub anajob(){
	($pid,$pbsid)=@_;
	my $estr=`ps -o etime -p $pid|tail -n 1`;
	chomp($estr);
	$diff=&checketime($estr);
	if ($diff==0){
		print "$pid has start less then 15 mins ($estr)\n";
		return 0;
	}
	print ("$pid has start $estr\n");
	$rawfile="$pbsid\-$pid.raw";
	$outfile="$pbsid\-$pid.out";
	$lowfile="$pbsid\-$pid.loweff";
	if (-f "$localdir/$rawfile"){
			printf("Already got output,skip job $pbsid\-$pid\n");
			return 0;
	}else{
			print ("rawoutput is $outdir/$rawfile\n");
			
	}
	$procname=`ps -ocmd -p $pid 2>/dev/null|tail -n 1 `;
	chomp($procname);
	$eff=`ps -opcpu -p $pid 2>/dev/null|tail -n 1`;
	chomp($eff);
	$user=`ps -ouser -p $pid 2>/dev/null|tail -n 1`;
	chomp($user);
	`staprun -o $localdir/$rawfile -x $pid $modname`;
	if ($?){
       		printf "error occurred during stap runnning, check kernel name first!\n";
		`rm -rf $localfile`;
		&sendmail($pbsid,$pid,$hostname,"SYSTEMERROR");
       		return;
	}
	sleep 10;
	$pattern=`/root/bin/iopattern/match.pl $localdir/$rawfile $samplefile`;
	eval{
		open OUTFILE,">$localdir/$outfile";
		printf OUTFILE ("User:\t%s\nPid:\t%s\nPbsid:\t%s\nProcssname:\t%s\nEfficiency:\t%s\nJob Pattern:\t%s\n",$user,$pid,$pbsid,$procname,$eff,$pattern);
		close OUTFILE;
		if ($eff<80 && ($pattern =~ "Unknown" )){
			`cat $localdir/$rawfile $localdir/$outfile >$localdir/$lowfile`;
		 	$noticetxt=$localdir/$lowfile;
			&sendmail($pbsid,$pid,$hostname,"UNKNOWNLOW",$noticetxt,$eff);
			`cp $localdir/$lowfile $outdir`;
		}
	};
	if (ref $@){
		return;
	}
	`cp $localdir/$rawfile $localdir/$outfile $outdir`;
	
}
sub find_worker(){
	($worker)=@_;
	$nextworker=`ps -ef |grep $worker|grep -v grep | awk '{if (\$3==$worker)print \$2}'`;
	chomp($nextworker);
	if ($nextworker){
		$worker=&find_worker($nextworker);
	}
	return $worker;
}
sub find_workers(){
	my($parentid)=@_;
	my @workers;
	@children=`ps -ef |grep $parentid|grep -v grep | awk '{if (\$3==$parentid)print \$2}'`;
	foreach $child(@children){
		chomp($child);
		$worker=&find_worker($child);
		push @workers,$worker;		
	}
	return @workers;
}

my @res=`ps -ef |grep "pbssrv.ihep.ac.cn.SC" |grep -v root| awk '{print $2}'`;
foreach $i (@res){
	@pbsinfo=split /\s+/,$i;
	my $parentid=$pbsinfo[1];
	$pbsinfo[8]=~/.*\/(\d+).*\.ihep/;
	$pbsid=$1;
	printf("pbsid is %s\n",$pbsid);
	my @workers=&find_workers($parentid);
	foreach $w (@workers){
		&anajob($w,$pbsid);
	}
}
