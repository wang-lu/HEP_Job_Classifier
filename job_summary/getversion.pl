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
my $sth = $dbh->prepare("select procname,path from jobinfo;" );
printf "select procname from jobinfo ;\n";
$sth->execute();
my $i,$j,@id;
while( @id=$sth->fetchrow_array()){
	my $procname=$id[0];
	my $path=$id[1];
	$i++;
	if ($procname=~/\/afs\/ihep\.ac\.cn\/bes3\/offline\/Boss\/(.*)\/InstallArea\//){
		#print "$procname $1\n";
		$j++;
		my $cmd=$dbh->prepare("update jobinfo set version=\'$1\' where path=\'$path\'");
		$cmd->execute();
	}
}
printf "$i records scanned,$j taged\n";
# clean up
$dbh->disconnect();
