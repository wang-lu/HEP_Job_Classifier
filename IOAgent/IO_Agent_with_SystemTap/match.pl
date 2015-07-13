#!/usr/bin/perl
$rawfile=$ARGV[0];
$MINENTRY=10;
$PRINTP=25;
my @res;
my $outstr;
my $totalcount;

sub sepv(){
        ($type,$start,$end)=@_;
	my @cate=("VS","S","M","L","VL");	
	my @tres;
	my $total=0;
        for ($i=$start;$i<=$end;$i++){
                if($res[$i] =~/^\s*(-)*(\d+)\s\|.*(\s+)(\d+)/){
                        $absnum=abs($2);
                        if($absnum<=10){
                                $tres[0]+=$4;
                        }
                        elsif ($absnum>10 && $absnum<4096){
                                $tres[1]+=$4;
                        }elsif($absnum>=4096 && $absnum <1048576){
                                $tres[2]+=$4;
                        }elsif($absnum>1048576 && $absnum<16777216){
                                $tres[3]+=$4;
                        }else{
                                $tres[4]+=$4;
                        }
			$total+=$4;
                }
        }
	$totalratio=$total*100/$totalcount;
	if ($total>0 && $totalratio>$PRINTP ){
		for ($i=0;$i<=4;$i++){
			$ratio=$tres[$i]*100/$total;
			if ($ratio>$PRINTP){
				$outstr=$outstr.$cate[$i].$type."-";
			}
		}
	}
}


@res=`cat $rawfile`;
for ($i=0;$i<=$#res;$i++){
        if ($res[$i]=~/Total Count:(\d+)/){
                $totalcount=$1;
		if ($totalcount<$MINENTRY){
			printf("Unknown\n");
			exit;
		}
		next;
	}
        if ($res[$i]=~/Read Size/){
                $readstart=$i+2;
		next;
        }
        if ($res[$i]=~/Read Throughput/){
                $readend=$i-2;
		next;
        }
        if ($res[$i]=~/Write Size/){
                $writestart=$i+2;
		next;
        }
        if ($res[$i]=~/Write Throughput/){
                $writeend=$i-2;
		next;
        }
        if ($res[$i]=~/Read Seek Size/){
                $rseekstart=$i+2;
		next;
        }
        if ($res[$i]=~/Read Seek End/){
                $rseekend=$i-2;
		next;
        }
        if ($res[$i]=~/Write Seek Size/){
                $wseekstart=$i+2;
		next;
        }
        if ($res[$i]=~/Write Seek End/){
                $wseekend=$i-2;
		next;
        }
}

if(defined($readstart) && defined($readend)){
        &sepv("R",$readstart,$readend);
}
if(defined($writestart) && defined($writeend)){
        &sepv("W",$writestart,$writeend);
}
if(defined($rseekstart) && defined($rseekend)){
        &sepv("RS",$rseekstart,$rseekend);
}
if(defined($wseekstart) && defined($wseekend)){
        &sepv("WS",$wseekstart,$wseekend);
}
$outstr=~s/(-)$//;
if ($outstr eq ""){
	print "is $outstr \n";
	$outstr="Unknown";
}
printf("%s\n",$outstr);

