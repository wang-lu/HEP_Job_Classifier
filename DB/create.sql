use jobana;
#drop table jobinfo;
#create table jobinfo(pid varchar(50),pbsid varchar(50), username varchar(25),hostname varchar(50),procname varchar(200),path varchar(200),efficiency float,filesystem varchar(100),mydate DATE,detail varchar(300),pattern varchar(200),keyword varchar(200),primary key(path));
desc jobinfo;
#insert into  newtest values (13617,100000446,'huanghp', ' /afs/ihep.ac.cn/bes3/offline/Boss/6.6.4.p01/InstallArea/x86_64-slc5-gcc43-opt/bin/boss.exe /besfs/groups/psipp/psippgroup/public/huanghp/wangbin/664p01/DDsPi/STag/eff_scan_20140528/pipD02/4225/rec_002.txt','/scratchfs/cc/wanglu/jobout/14-06-01/bws0456.ihep.ac.cn/10728446-13619.out',93.9,'bes3fs:besfs',NULL,NULL,curdate());
#select * from newtest;
#select keyword,trim(pattern) from  jobinfo where mydate between '2014-11-14' and '2014-11-21' and keyword ="sim"; 
#delete from jobinfo where mydate='2014-11-14';


