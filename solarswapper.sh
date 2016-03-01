cat > solarswaper.sh <<'endmsg'
#!/bin/bash
BAR="\033[38;5;148m-----------------------------------------------------------\033[39m"
echo -e "\033[38;5;148mClark's Solar Auto Swapper\033[39m"
echo -e "${BAR}"
echo -e "\033[38;5;148mFinding new drive\033[39m"
echo -e "${BAR}"
ls -l /dev > ls.beforescan
for i in /sys/class/scsi_host/*
do
    echo "- - -" > $i/scan
done
ls -l /dev > ls.afterscan
#NEWDISK=$(diff ls.beforescan ls.afterscan | grep -wo sd..)
NEWDISK=sdc1
if [ -z "${NEWDISK+xxx}" ]
then
    echo "ERROR No new disks, check your mounts"
else
	rm ls.beforescan ls.afterscan
	echo "$NEWDISK should be your new disk"
	
	sleep 2
	echo -e "\033[38;5;148mCheck if cons have dropped\033[39m"
	echo -e "${BAR}"
	COUNT=$(lsof -i | wc -l)
	while [ $count -gt 200 ]
	do
	    eecho -e "\033[38;5;148mCons above 200, sleeping for a min and then will recheck\033[39m"
	    sleep 1
	done
	echo -e "\033[38;5;148mCons clear\033[39m"
	echo -e "\033[38;5;148mKilling tomcat \033[39m"
	echo -e "${BAR}"
	service tomcat6 stop
	ps -ef | grep tomcat
	ps -ef | grep java
	if [[ -z $(ps -ef |grep tomcat) ]]
	then 
	   echo "ERROR tomcat is not stopped!"
	   exit 1
	fi
	echo -e "\033[38;5;148mUnmounting /indexes\033[39m"
	echo -e "${BAR}"
	mount
	umount /indexes
	sleep 2
	echo -e "\033[38;5;148mChanging your fstab\033[39m"
	echo -e "${BAR}"
	sed -i 's/sdb1/'$NEWDISK'/g' /etc/fstab
	cat /etc/fstab
	sleep 2
	echo -e "\033[38;5;148mMounting /indexes\033[39m"
	echo -e "${BAR}"
	mount /indexes
	if (grep -q '/dev/sdc1' /etc/mtab)
	then
	echo -e "\033[38;5;148mMount Success!\033[39m" 
	else
		echo -e "\033[38;5;148mMount Failure\033[39m" 
	    exit 1
	fi
	echo -e "\033[38;5;148mHere are your new mounts\033[39m"
	mount
	sleep 2
	echo -e "\033[38;5;148mFixing a stupid mistake in initial copy, couldnt have be me...\033[39m"
	echo -e "${BAR}"
    mv /indexes/indexes/* /indexes
    #rm -rf /indexes/indexes
	echo -e "\033[38;5;148mHere is your indexes directory\033[39m"
	ls /indexes
	sleep 2
	echo -e "\033[38;5;148mswap the schema file out\033[39m"
	echo -e "${BAR}"
	mv /var/lib/tomcat6/solr/conf/schema.xml /var/lib/tomcat6/solr/conf/schema.xml.BAK
	wget -O /var/lib/tomcat6/solr/conf/schema.xml http://prodsearch10.cco/schema.xml
	echo -e "\033[38;5;148mHere is your schema.xml\033[39m"
    ls -la /var/lib/tomcat6/solr/conf/schema.xml
	sleep 2
	echo -e "\033[38;5;148mswap the stopwords file out\033[39m"
	echo -e "${BAR}"
	mv /var/lib/tomcat6/solr/conf/stopwords.txt /var/lib/tomcat6/solr/conf/stopwords.txt.BAK
	wget -O /var/lib/tomcat6/solr/conf/stopwords.txt http://prodsearch10.cco/stopwords.txt
	echo -e "\033[38;5;148mHere is your stopwords.txt\033[39m"
    ls -la /var/lib/tomcat6/solr/conf/stopwords.txt
	sleep 2
	echo -e "\033[38;5;148mFix Permissions\033[39m"
	echo -e "${BAR}"
	chown tomcat6 /var/lib/tomcat6/solr/conf/schema.xml
	chown tomcat6 /var/lib/tomcat6/solr/conf/stopwords.txt
    chown -R tomcat6 /indexes
	echo -e "\033[38;5;148mHere are your final permies\033[39m"
    ls -la /var/lib/tomcat6/solr/conf/schema.xml
    ls -la /var/lib/tomcat6/solr/conf/stopwords.txt
    ls -la /indexes
	sleep 2
	echo -e "\033[38;5;148mStarting tomcat\033[39m"
	echo -e "${BAR}"
	service tomcat6 start
	ps -ef | grep tomcat
	ps -ef | grep java	
	if [[ -z $(ps -ef |grep tomcat) ]]
	then
	    echo "ERROR tomcat wont start!"
	    exit 1
	else
        echo -e "\033[38;5;148mDroping a tail on catalina.out\033[39m"
		echo -e "${BAR}"
		count=`grep "SEVERE" /var/log/tomcat6/catalina.out|wc -l`
		if [ $count -ne 0 ]
		then
		     echo "SEVERE ERRORS IN CATALINA.OUT"
		     tail -n 100 /var/log/tomcat6/catalina.out 
		     exit 1
		else
		     echo "no major errors in catalina.out, check it for yourself"
		     tail -n 1000 /var/log/tomcat6/catalina.out 
		fi
	fi
	echo -e "\033[38;5;148mprocess complete ready for warmup boss!\033[39m"
fi  
exit 0
endmsg
tail -n 1000 /var/log/tomcat6/catalina.out | grep SEVERE
chmod +x soloarswaper.sh ; ./soloarswaper.sh
