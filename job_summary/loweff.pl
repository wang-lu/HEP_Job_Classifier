#!/usr/bin/perl
use DBI;
use POSIX qw(strftime);
use Getopt::Long;

my $yesterday=sprintf strftime ("%Y-%m-%d",localtime(time()-3600*24));
Getopt::Long::GetOptions(              
      'from=s'    => \$from,            
      'to=s'    => \$to,           
      'fromeff=s' =>\$fromeff,
      'toeff=s' =>\$toeff	    
);
unless(defined($fromeff) && defined($toeff)){
	printf "Please specify range of efficiency\n";
	exit -1;
} 
unless(defined($from)){   
	$from=$yesterday;
}

unless(defined($to)){
	$to=$yesterday;
}


# connect
my $dbh = DBI->connect("DBI:mysql:database=jobana;host=localhost", "root", "mysepw", {'RaiseError' => 1});
printf "Result of Query:\nDate: from $from to $to, Efficiency from $fromeff to $toeff\n";
$sth= $dbh->prepare("SELECT efficiency,username,pattern FROM jobinfo where mydate between \'$from\' and \'$to\' and efficiency between $fromeff and $toeff ");
$sth->execute();
my %usercount;
my %typecount;
my @count;
my $index;
my $min=100;
my $max=0;
my $total=0;
my $sum=0;
my $avg=0;
while(@id=$sth->fetchrow_array()){
	$total++;
	$sum+=$id[0];
	$index=int($id[0]/10);
	$myuser=$id[1];
	$mytype=$id[2];
	if ($id[0]>$max){
		$max=$id[0];
	}
	if ($id[0]<$min){
		$min=$id[0];
	}
	$count[$index]++;
	$usercount{$myuser}++;
	$typecount{$mytype}++;
}
$avg=$sum/$total;
printf ("max:%.2f,min:%.2f,avg:%.2f\n",$max,$min,$avg);
printf ("Total:%d\nDistribution:\n",$total);
my $i;
my $ratio;
my $sumratio;
for ($i=0;$i<=9;$i++){
        $down=$i*10;
        $up=($i+1)*10;
        printf ("[%2d - %3d]:\t",$down,$up);
        unless (defined($count[$i])){
                $count[$i]=0;
        }
        $ratio=$count[$i]/$total;
        $sumratio=$sumratio+$ratio;
        printf ("%2d\t%.3f\t%.3f\n", $count[$i],$ratio,$sumratio);
}


printf ("Distribution of User\n");
$sumratio=0;
$ratio=0;
$last=10;
foreach (sort {$usercount{$b} <=> $usercount{$a}} keys %usercount){
	if ($last>0){
	$ratio=$usercount{$_}/$total;
	$sumratio+=$ratio;
	printf("%15s:%2d\t%.3f\t%.3f\n", $_,$usercount{$_},$ratio,$sumratio);
	}
	$last--;
}


printf ("Distribution of Type\n");
$sumratio=0;
$ratio=0;
$last=10;
foreach (sort {$typecount{$b} <=> $typecount{$a}} keys %typecount){
	if ($last>0){
	$ratio=$typecount{$_}/$total;
	$sumratio+=$ratio;
	printf("%15s:%2d\t%.3f\t%.3f\n", $_,$typecount{$_},$ratio,$sumratio);
	}
	$last--;
}

# clean up
$dbh->disconnect();
