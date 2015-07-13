#!/usr/bin/perl
use POSIX qw(strftime);
use DBI;

my $topdir="xx/jobout";
if ($#ARGV<0){
	printf "Please input cluster name\n";
	exit 0;
}
my $yesterday;
if (defined($ARGV[1])){
	$yesterday=$ARGV[1];
}else{
	$yesterday=sprintf strftime ("%y-%m-%d",localtime(time()-3600*24));
}
print "Analysing $yesterday\n";
my $tardir="xxx/jobsummary";
my $cname=$ARGV[0];
my $resstr;
my $total;
my $taged;
my $error;
my $dbh = DBI->connect("DBI:mysql:database=jobana;host=localhost", "root", "mysepw", {'RaiseError' => 1});
my $mailcon="/tmp/mail_wanglu";
open MAILCON, ">$mailcon" or die "can not open $mailcon\n";
$now=localtime(time());
printf MAILCON "Summary starts at $now\n";

sub sendmail(){
        my  $touser="xxx\@ihep.ac.cn";
        $sub="Summary of $yesterday of $cname";
        $noticetxt="$mailcon";

}
sub getversion(){
	my $version;
	my ($procname)=@_;
	if ($procname=~/\/afs\/ihep\.ac\.cn\/bes3\/offline\/Boss\/(.*)\/InstallArea\//){
		$version=$1;
        }	
	return $version;
}


sub clearspace(){
	my ($str)=@_;
	$str=~s/(\s+)//g;
	$str=substr($str,0,199);	
	return $str;
}
sub tagname(){
        my ($teststr)=@_;
        if ($teststr eq ""){
                return ;
        }
        my $tagres;
        my @ana=( "ana", "ANA", "analysis", "AnaScript", "dataAnalysis", "anaMcPPPiPi", "anaMcRhoPi", "anaMuSpall");
        my @anamc=( "AnaMC", "inclMcAna", "mcAna", "MCAna");
        my @cal=( "bcal", "tofcalib", "TofCalib", "cal", "calib", "calibration");
        my @sim=( "sim", "Sim", "SIM", "simch", "simcheck", "simMcPhiEta", "simPhiEta", "simu", "simulation", "bgsim", "DDstarbarsim", "DbarDstarsim");
        my @mc=( "CocktailMC", "MCggphi", "McJpsi", "psiMC", "psipMC", "SMALLJPSIPSMC", "ddbarmc", "DexMC", "dimumc", "DipigamIncliusiveMC", "exclusiveMC", "gammapsipmc", "incmc", "incMC", "qqbarmc", "Incmc", "IncMc", "jobMC", "KapiAlgMC", "kkmc", "KKMC", "mc", "MC", "sigmc", "sigMC", "SigMC", "signalmc", "signalMC", "unSkimMC", "zerowidthMC", "testMC");
        my @rec=( "rec", "Rec", "REC", "recAdScaled", "recAdSimple", "recch", "reccheck", "recDimu", "recJpsi", "recMcPhiEta", "recon", "recPhiEta", "recTXT", "reczb", "DbarDstarrec", "DDstarbarrec");
        my @skim=( "skim", "Skim", "dataSkim");
        my @scan=( "rscan", "Rscan", "scan", "Scan", "tauscan");
        my @fix=( "fix", "fixKmass", "fixP");
        my @fit=( "fit", "fitB", "fitFADC", "fitGamma", "fitLS", "fitMichel", "fitNGd", "fitSpec", "fitter", "kmfit", "bfit");


        my %keyword=(   ana =>\@ana,
                anamc=>\@anamc,
                cal=>\@cal,
                sim=>\@sim,
                mc=>\@mc,
                rec=>\@rec,
                sim=>\@sim,
                skim=>\@skim,
                scan=>\@scan,
                fix=>\@fix,
                fit=>\@fit
        );
        for $i (keys %keyword){
                my $name=$keyword{$i};
                eval{
                        if (grep (/^$teststr$/, @$name)){
                                $tagres=$tagres."$i";
                        }
                }
        }
        return $tagres;
}
sub processname{
        my ($str)=@_;
        my @tag;
        my @res=split /-|_|\.|(\/)|=|\?|\*|:|,/,$str;
        my $tagres;
        for ($i=0;$i<=$#res;$i++){
                $res[$i]=~s/(\d+)//g;
                if ($res[$i]=~/\w+/){
                        my $find=&tagname($res[$i]);
                        unless ( $find eq ""  || (grep /^$find$/, @tag )){
                                push @tag,$find;
                        }
                }
        }
        if ($#tag>=0){
                $taged++;
                $tagres=$tag[0];
                for ($j=1;$j<=$#tag;$j++){
                        $tagres=sprintf("%s_%s",$tagres,$tag[$j]);
                }
        }
        return $tagres;

}
sub getpattern(){
	my ($detail)=@_;
	my @res=split(/:/,$detail,18);
        my $index;
        my $raw;
        my $result;
        for ($index=1;$index<=$#res;$index++){
                $res[$index]=0 if ($res[$index] eq '');
                $raw=$raw.$res[$index]." ";
        }
	$result=`curl -s http://192.168.60.131/luatest/test.php?pattern="$raw"`;
	chomp($result);
	return $result;
}


sub anahost(){
	my ($host,$dir,$mydate)=@_;
	opendir (MYDIR,"$dir") or die "can not opendir $dir\n";
	while (my $outfile =readdir (MYDIR)){
		if ($outfile =~/out$/){
			#my $newline=$host;
			my $newline;
			my $i;
			my $procname;
			my $eff;
			my $detail;
			my $user;
			my $pid;
			my $pbsid;
			my $filesystem;
			my $pattern;
			my $keyword;
			my $version;
			$total++;
			open FILE, "$dir/$outfile" or next;
			while (<FILE>)
			{
				if ($_ =~/^Procssname:(.*)$/){
					$procname=$1;
					$keyword=&processname($procname);
					$version=&getversion($procname);
					$procname=&clearspace($procname);
                                } 
				if ($_ =~/Efficiency:(.*)$/){
					$eff=$1;
					$eff=&clearspace($eff);
				}
				if ($_ =~/^Detail:(.*)$/){
					$detail=$1;
					if ($detail =~/UNKNOWN/){
						 $pattern="UNKNOWN";
					}else{
						 $pattern=&getpattern($detail);
						 $pattern=&clearspace($pattern);
					}
					$detail=&clearspace($detail);
				}
				if ($_ =~/^User:(.*)$/){
					$user=$1;
					$user=&clearspace($user);
                                }
                                if ($_ =~/^Pid:(.*)$/){
					$pid=$1;
					$pid=&clearspace($pid);
					
                                }
                                if ($_ =~/^Pbsid:(.*)$/){
					$pbsid=$1;
					$pbsid=&clearspace($pbsid);
                                }
				if ($_=~/^FileSystem(\s+):(.*)$/){
					$filesystem=$2;
					$filesystem=&clearspace($filesystem);
				}
			}
			my $cmd="insert into jobinfo values(\"$pid\",\"$pbsid\",\"$user\",\"$host\",\"$procname\",\"$dir/$outfile\",$eff,\"$filesystem\",\"$mydate\",\"$detail\",\"$pattern\",\"$keyword\", \"$version\")";
			if (defined($host)){
				eval{
					my $rows = $dbh->do($cmd);
				};
				if (ref $@){
					$error++;	
					printf MAILCON "$cmd,error\n";
        			}
			}else{
				printf MAILCON  "host $host is empty, error\n";
				$error++;
			}
			close FILE;
		}
	}
	closedir MYDIR;
}

my $datedir;
my $hostdir;
opendir (DIR,  "$topdir/$yesterday") or die "can not opendir $topdir/$yesterday \n";
while (my $host = readdir(DIR)) {
        unless($host =~/^\./){
                if ($host =~/^$cname/){
                &anahost($host,"$topdir/$yesterday/$host","$yesterday");
                }   
        }   
}
closedir DIR;
$dbh->disconnect();

if ($cname eq "bws"){
#	`tar  -cvf $tardir/$yesterday.tar $topdir/$yesterday`;
}
printf MAILCON "total:$total,taged:$taged\n";
$now=localtime(time());
printf MAILCON "Summary ends at $now\n";
close MAILCON;
&sendmail();
