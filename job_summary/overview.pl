#!/usr/bin/perl
use DBI;
use POSIX qw(strftime);
use Getopt::Long;

my $yesterday=sprintf strftime ("%Y-%m-%d",localtime(time()-3600*24));
Getopt::Long::GetOptions(              
      'from=s'    => \$from,            
       'to=s'    => \$to,           
          'username=s'      => \$username,           
       'type=s'    => \$type,           
       'hostname=s' => \$hostname);  

unless(defined($from)){   
	$from=$yesterday;
}

unless(defined($to)){
	$to=$yesterday;
}

# connect
my $dbh = DBI->connect("DBI:mysql:database=jobana;host=localhost", "root", "mysepw", {'RaiseError' => 1});

# execute SELECT query
if (defined($username)){
	if (defined ($type)){
		if (defined($hostname)){
           		printf "Result of Query:\nDate: from $from to $to, Username: $username, Type: $type, Hostname: $hostname\n";
			$sth= $dbh->prepare("SELECT efficiency FROM jobinfo where mydate between \'$from\' and \'$to\' and username=\'$username\' and pattern like'%$type%\' and hostname=\'$hostname\'");
		}else{
           		printf "Result of Query:\nDate: from $from to $to, Username: $username, Type: $type\n";
			$sth= $dbh->prepare("SELECT efficiency FROM jobinfo where mydate between \'$from\' and \'$to\' and username=\'$username\' and pattern like \'%$type%\'");
		}
	}else{
           	printf "Result of Query:\nDate: from $from to $to, Username: $username\n";
		$sth= $dbh->prepare("SELECT efficiency FROM jobinfo where mydate between \'$from\' and \'$to\' and username=\'$username\'");
	}
}else{
	 if (defined ($type)){
                if (defined($hostname)){
                        printf "Result of Query:\nDate: from $from to $to, Type: $type, Hostname: $hostname\n";
                        $sth= $dbh->prepare("SELECT efficiency FROM jobinfo where mydate between \'$from\' and \'$to\'and pattern like '%$type%\' and hostname=\'$hostname\'");
                }else{
                        printf "Result of Query:\nDate: from $from to $to, Type: $type\n";
                        $sth= $dbh->prepare("SELECT efficiency FROM jobinfo where mydate between \'$from\' and \'$to\'  and pattern like \'%$type%\'");
                }
        }else{
		if (defined($hostname)){
                        printf "Result of Query:\nDate: from $from to $to, Hostname: $hostname\n";
                        $sth= $dbh->prepare("SELECT efficiency FROM jobinfo where mydate between \'$from\' and \'$to\' and hostname=\'$hostname\'");
                }else{
        		printf "Result of Query:\nDate: from $from to $to\n";
			$sth= $dbh->prepare("SELECT efficiency FROM jobinfo where mydate between \'$from\' and \'$to\'");
		}
	}
}

#my $sth = $dbh->prepare("SELECT avg(efficiency) FROM jobinfo where mydate between '2014-05-01' and '2014-10-22'");
#my $sth = $dbh->prepare("SELECT count(*) FROM jobinfo where mydate between '2014-10-22' and '2014-10-22' and username='liujie' and efficiency between 90 and 100");
#my $sth= $dbh->prepare(	"SELECT efficiency FROM jobinfo where mydate between '2014-10-22' and '2014-10-22' and username='liujie' and pattern='rec' and hostname='bws0600\.ihep\.ac\.cn'");
#my $sth= $dbh->prepare(	"SELECT efficiency FROM jobinfo where mydate between '2014-10-22' and '2014-10-22' and username='liujie' and pattern='rec' ");
#my $sth = $dbh->prepare("SELECT efficiency,hostname,path,username FROM jobinfo where mydate between '2014-10-01' and '2014-10-22' and username='liujie'" );
#my $sth=$dbh->prepare($cmd);
$sth->execute();
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
	if ($id[0]>$max){
		$max=$id[0];
	}
	if ($id[0]<$min){
		$min=$id[0];
	}
	$count[$index]++;
}
$avg=$sum/$total;
printf ("max:%.2f,min:%.2f,avg:%.2f\n",$max,$min,$avg);
printf ("Total:%d\nDistribution:\n",$total);
my $i;
my $ratio;
my $sumratio;
my $sumcount;
for ($i=9;$i>=0;$i--){
	$down=$i*10;
	$up=($i+1)*10;
	printf ("[%2d - %3d]:\t",$down,$up);
	unless (defined($count[$i])){
		$count[$i]=0;
	}
	$ratio=$count[$i]/$total;
	$sumcount=$sumcount+$count[$i];
	$sumratio=$sumratio+$ratio;
	printf ("%2d\t%2d\t%.3f\t%.3f\n", $count[$i],$sumcount,$ratio,$sumratio);
}

# clean up
$dbh->disconnect();
