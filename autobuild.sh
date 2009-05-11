#! /bin/bash
#
# This script must be executed in the folder where this script locats.
# It generates the final package from scratch. 
#
# paramters: 
#   clean: force to have a completely clean build. All the source code, intermediate files are removed.
#   email: generate email notification after the build.

function get_ip()
{
OS=`uname`
IO="" # store IP
case $OS in
   Linux) IP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`;;
   FreeBSD|OpenBSD) IP=`ifconfig  | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}'` ;;
   SunOS) IP=`ifconfig -a | grep inet | grep -v '127.0.0.1' | awk '{ print $2} '` ;;
   *) IP="Unknown";;
esac
echo "$IP"
}

generate_error_notification_email()
{
	# --- Email (all stdout will be the email)
	# Generate header
	cat <<-EOF
	From: $build_maintainer
	To: $dev_team
	Subject: [$project_name] autobuild failed! please check

	This is an automated email from the autobuild script. It was
	generated because an error encountered while building the code.
	The error can be resulted from newly updated source codes. 
	Please check the change log (if it is generated successfully) 
    and build log below and fix the error as early as possible.

	=========================== Change LOG ====================

	$(cat out/changelog.day 2>/dev/null)
	
	===========================================================

	=========================== Build LOG =====================

	$(cat $STD_LOG 2>/dev/null)
	
	===========================================================
	
	---
	$project_name	
	EOF
}

generate_success_notification_email()
{
	# --- Email (all stdout will be the email)
	# Generate header
	cat <<-EOF
	From: $build_maintainer
	To: $dev_team;$announce_list
	Subject: [$project_name] new release package is available.

	This is an automated email from the autobuild script. It was
	generated because a new package is generated successfully and
	the package is changed since last day.

	You can get the package from:
		\\\\$(get_ip)${PACKAGE_DIR//\//\\}
	or
		http://$(get_ip)${PACKAGE_DIR}
	or
		mount -t nfs $(get_ip):${PACKAGE_DIR} /mnt

	The change log since last day is:

	$(cat ${PACKAGE_DIR}/changelog.day)

	---
	$project_name	
	EOF
}

generate_build_complete_email()
{
	# --- Email (all stdout will be the email)
	# Generate header
	cat <<-EOF
	From: $build_maintainer
	To: $build_maintainer
	Subject: [$project_name] a new build is completed.

	This is an automated email from the autobuild script. It was
	generated because the autobuild is completed successfully and
	no change is found since last day.

	You can get the package from:
		\\\\$(get_ip)${PACKAGE_DIR//\//\\}
	or
		http://$(get_ip)${PACKAGE_DIR}
	or
		mount -t nfs $(get_ip):${PACKAGE_DIR} /mnt

	---
	$project_name	
	EOF
}

send_error_notification()
{
	generate_error_notification_email | /usr/sbin/sendmail -t $envelopesender
}

send_success_notification()
{
	if [ -s "${PACKAGE_DIR}/changelog.day" ]; then
		echo "    changes found since last day, notify all..."
		generate_success_notification_email | /usr/sbin/sendmail -t $envelopesender
	else
		echo "    no change since last day, notify maintainer..."
		generate_build_complete_email | /usr/sbin/sendmail -t $envelopesender
	fi

}

function print_usage()
{
	echo "Usage: $0 [clean] [publish] [email] [pkgsrc] [help]"
	echo "  clean: do a clean build. Before build starts, the source code and output directory is removed first."
	echo "  publish:if build success, copy the result to publish dir."
	echo "  email:once build is completed, either successfully or interrupted due to an error, generate an email notification."
	echo "  pkgsrc: package the source code into a tarball."
	echo "  help: print this list."
}

STD_LOG=autobuild.log

build_maintainer=$(cat maintainer)
dev_team=$(cat dev_team )
announce_list=$(cat announce_list )
project_name="Android for AVLite"
envelopesend="-f $build_maintainer"

FLAG_CLEAN=false
FLAG_PUBLISH=false
FLAG_EMAIL=false
FLAG_PKGSRC=false
for flag in $*; do
	case $flag in
		clean) FLAG_CLEAN=true;;
		email) FLAG_EMAIL=true;;
		publish)FLAG_PUBLISH=true;;
		pkgsrc)FLAG_PKGSRC=true;;
		help) print_usage; exit 2;;
		*) echo "Unknown flag: $flag"; print_usage; exit 2;;
	esac
done

#enable pipefail so that if make fail the exit of whole command is non-zero value.
set -o pipefail

echo "Starting autobuild @$(date)..." > $STD_LOG

if [ "$FLAG_CLEAN" = "true" ]; then 
	make clean 2>&1 | tee -a $STD_LOG
fi &&

make all 2>&1 | tee -a $STD_LOG &&

if [ "$FLAG_PKGSRC" = "true" ]; then
	make pkgsrc 2>&1 | tee -a $STD_LOG
fi &&

#we need get the publish_dir just before publishing, as the make may accross one day, 
#it may return different path if calling it before make all.
PACKAGE_DIR=$(make get_publish_dir) &&

if [ "$FLAG_PUBLISH" = "true" ]; then
	make publish 2>&1 | tee -a $STD_LOG 
fi

if [ $? -ne 0 ]; then #auto build fail, send an email
	echo "error encountered!" 
	if [ "$FLAG_EMAIL" = "true" ]; then
		echo "    sending email notification..."
		send_error_notification
	fi
else
	echo "build successfully. Cheers! "
	if [ "$FLAG_EMAIL" = "true" ]; then
		echo "    sending email notification..." 
		send_success_notification
	fi
fi




