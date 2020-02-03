#!/bin/bash

######################################################## GREETING MESSAGE FUNCTION #######################################################################

GREETING()
{
	echo -e "\n\n"
echo "#####################################################################################################################################";
echo "#  _   _ ____  _____ ____       _    ____ ____ ___  _   _ _   _ _____    ____ ___  _   _ _____ ____   ___  _     _     _____ ____   #";
echo "# | | | / ___|| ____|  _ \     / \  / ___/ ___/ _ \| | | | \ | |_   _|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |   | |   | ____|  _ \  #";
echo "# | | | \___ \|  _| | |_) |   / _ \| |  | |  | | | | | | |  \| | | |   | |  | | | |  \| | | | | |_) | | | | |   | |   |  _| | |_) | #";
echo "# | |_| |___) | |___|  _ <   / ___ \ |__| |__| |_| | |_| | |\  | | |   | |__| |_| | |\  | | | |  _ <| |_| | |___| |___| |___|  _ <  #";
echo "#  \___/|____/|_____|_| \_\ /_/   \_\____\____\___/ \___/|_| \_| |_|    \____\___/|_| \_| |_| |_| \_\\\\___/|_____|_____|_____|_| \_\ #";
echo "#                                                                                                                                   #";
echo "#####################################################################################################################################";
echo "########################################################    by - rEflxzR    #########################################################";
echo "#####################################################################################################################################";
}


##########################################################################################################################################################
######################################################## USER SEARCH FUNCTION ###############################################################################

FIND_USER()
{
	cat /etc/passwd | awk -F ':' '{print $1}' | grep ${1} 1> /dev/null; local var=$(echo ${?})
	if [[ ${var} -eq 0 ]]; then
		echo -e "${1} - UserAccount Exists\n"
	else
		echo -e "${1} - UserAccount NOT Found\n"
	fi
}


LIST_USERS()
{
	cat /etc/passwd | awk -F ':' '{if($3>=1000 && $3!=65534) print $1}'
}

##########################################################################################################################################################
######################################################## USER ADD FUNCTION ###############################################################################

USERADD()
{
	if [[ userdir_make -eq 1 ]]; then
		if [[ usergroup -eq 1 ]]; then
			useradd -g ${groupname} -m ${1} &> /dev/null; local err=$(echo ${?})
		else
			useradd -m ${1} &> /dev/null; local err=$(echo ${?})
		fi
	else
		if [[ usergroup -eq 1 ]]; then
			useradd -g ${groupname} -m ${1} &> /dev/null; local err=$(echo ${?})
		else
			useradd -m ${1} &> /dev/null; local err=$(echo ${?})
		fi
	fi

	if [[ $err -eq 0 ]]; then
		trap "echo -e '\n\nKeyboard Interrupt Signal Recieved, Last UserAccount: ${1} - was not Added to the System\n'; 
		userdel -r ${1} &> /dev/null; echo '${1} - was Deleted after Keyboard Interrupt' 1>> ${HOME}/uacaccounts.log; 
		echo -e '\n--------------------------------------------------------------------------------\n' >> ${HOME}/uacaccounts.log; exit 2" SIGINT

		local password=$(echo ${RANDOM}${RANDOM}${RANDOM}$(date +%N) | sha256sum | head -c10) &> /dev/null
		echo -e "${password}\n${password}" | passwd ${1} &> /dev/null && passwd -e ${1} &> /dev/null
		echo "$(date +'%D  %T')    ${1} : ${password}" 1>> ${HOME}/uacaccounts.log && appendac=1

	elif [[ $err -eq 3 ]]; then
		echo "Invalid Username: '${1}'" 1>> ${HOME}/uacerror.log && appender=1

	elif [[ $err -eq 9 ]]; then
		echo "The Username Already Exists: '${1}'" 1>> ${HOME}/uacerror.log && appender=1

	else
		echo "There was an Error adding User to the System" 1>> ${HOME}/uacerror.log && appender=1
	fi
}

##########################################################################################################################################################
######################################################## USER DELETE FUNCTION ############################################################################

USERDEL()
{
	trap "echo -e '\n\nKeyboard Interrupt Signal Recieved\n'; exit 2" SIGINT
		if [[ ${userdir_remove} -eq 0 ]]; then
			userdel ${1} &> /dev/null
			if [[ ${?} -ne 0 ]]; then
				delerror=1
			fi

		else
			userdel -r ${1} &> /dev/null
			if [[ ${?} -ne 0 ]]; then
				delerror=1
			fi
		fi
}

##########################################################################################################################################################
######################################################## USER PASSWORD UPDATE FUNCTION ###################################################################

PASSWORDUPDATE()
{
	trap "echo -e '\n\nKeyboard Interrupt Signal Recieved'; local password=$(echo ${RANDOM}${RANDOM}${RANDOM}$(date +%N) | sha256sum | head -c10) &> /dev/null; 
	echo -e '${password}\n${password}' | passwd ${1} &> /dev/null && passwd -e ${1} &> /dev/null; 
	echo 'Updated on $(date +'%D  %T')  -  ${1} : ${password}  Before Interrupt Signal' 1>> /root/uacpassupdate.log; 
	echo -e '\n-----------------------------------------------------------------------\n' 1>> /root/uacpassupdate.log; 
	echo -e '\nLast Username: ${1} - Password Updated Successfully\n'; exit 2" SIGINT

	getent passwd ${1} &> /dev/null
	if [[ ${?} -eq 0 ]]; then
		local password=$(echo ${RANDOM}${RANDOM}${RANDOM}$(date +%N) | sha256sum | head -c10) &> /dev/null
		echo -e "${password}\n${password}" | passwd ${1} &> /dev/null && passwd -e ${1} &> /dev/null
		echo "Updated on $(date +'%D  %T')  -  ${1} : ${password}" 1>> /root/uacpassupdate.log && appendpu=1
	else
		echo "Username Does not Exists: '${1}'" >> /root/uacerror.log && appender=1
	fi
}

################################################################# MAIN ACTION MENU ############################################################################
#############################################################################################################################################################

if [[ $(id -u) -eq 0 ]]; then

	action=0
	while getopts a:d:p:f:g:lhrm OPTION 2> /dev/null; do
		case ${OPTION} in
			a)
				action=1
				usernamea=${OPTARG}
				;;
			d)
				action=2
				usernamed=${OPTARG}
				;;
			p)
				action=3
				usernamep=${OPTARG}
				;;

			f)
				action=4
				usernamef=${OPTARG}
				;;

			l)
				action=5
				;;

			h)
				echo -e '\n\n    Usage: uac [OPTIONS] ["username1 username2 username 3 ..............username n"]'
				echo -e "\n\tOptions: \n"
				echo -e "\t\t-a\tAdd User Accounts of Following Usernames\n"
				echo -e "\t\t-d\tDelete User Accounts of Following Usernames\n"
				echo -e "\t\t-r\tDelete the Home directories of the Accounts, Used with -d flag\n"
				echo -e "\t\t-p\tUpdate Passwords of following User Accounts\n"

				exit 0
				;;

			r)
				userdir_remove=1
				;;

			m)
				userdir_make=1
				;;

			g)
				usergroup=1
				groupname=${OPTARG}
				;;

			?)
				echo -e "\nUse '-h', You Need HELP!!!\n"
				exit 5
				;;
		esac
	done

##########################################################---------FUNCTION CALLS---------###################################################################
#############################################################################################################################################################
###################################################################   USERADD   #############################################################################
if [[ ${action} -eq 0 ]]; then
		echo -e "\nUse '-h', You Need HELP!!!\n"
		exit 5
fi

appender=0; appendac=0; appendpu=0; delerror=0

if [[ ${action} -eq 1 ]]; then

	GREETING

	for uname in ${usernamea}; do
		USERADD ${uname}
	done


	if [[ ${appendac} -eq 1 ]] && [[ ${appender} -eq 0 ]]; then
		echo -e "\n--------------------------------------------------------------------------------\n" >> ${HOME}/uacaccounts.log
		echo -e "\n\nPROCESS COMPLETED SUCCESSFULLY !!!"
		echo "    - No Errors Were Encountered in the Process"; echo "    - Details are stored in ${HOME}/uacaccounts.log"
		echo -e "    - Passwords are Temporary and will expire on First Login\n\n"
		exit 0

	elif [[ ${appendac} -eq 1 ]] && [[ ${appender} -eq 1 ]]; then
		echo -e "\n\nPROCESS COMPLETED !!!"
		echo -e "\n--------------------------------------------------------------------------------\n" >> ${HOME}/uacaccounts.log
		echo -e "\n--------------------------------------USER ADDITION ERROR------------------------------------------\n" >> ${HOME}/uacerror.log
		echo "    - Some Errors were Encountered , Please check the ${HOME}/uacerror.log for more Details"
		echo "    - Details are stored in ${HOME}/uacaccounts.log"
		echo -e "    - Passwords are Temporary and will expire on First Login\n\n"
		exit 3

	elif [[ ${appendac} -eq 0 ]] && [[ ${appender} -eq 1 ]]; then
		echo -e "\n--------------------------------------USER ADDITION ERROR------------------------------------------\n" >> ${HOME}/uacerror.log
		echo -e "\n\nPROCESS FAILED !!!"
		echo -e "    - None of the UserAccounts were added, Please check the ${HOME}/uacerror.log for more Details\n\n"
		exit 4
	fi

################################################################   USERDEL   ################################################################################
elif [[ ${action} -eq 2 ]]; then

	GREETING

	for uname in ${usernamed}; do
		USERDEL ${uname}
	done

	if [[ delerror -eq 0 ]]; then
		echo -e "\n\nPROCESS COMPLETED SUCCESSFULLY!!!"; echo -e "    - User Account(s) Deleted\n\n"
		exit 0
	else
		echo -e "\n\nPROCESS COMPLETED !!!"; echo -e "    - Some Usernames were Incorrect or Didn't Existed\n"
		exit 3
	fi

##############################################################   USERPASSWORDUPDATE   ########################################################################
elif [[ ${action} -eq 3 ]]; then

	GREETING

	for uname in ${usernamep}; do
		PASSWORDUPDATE ${uname}
	done

	if [[ ${appendpu} -eq 1 ]] && [[ ${appender} -eq 0 ]]; then
		echo -e "\n-----------------------------------------------------------------------\n" 1>> /root/uacpassupdate.log
		echo -e "\n\nPROCESS COMPLETED SUCCESSFULLY!!!"; echo "    - Updated Passwords are stored in /root/uacpassupdate.log"
		echo -e "    - Passwords are Temporary and will expire on First Login\n\n"
		exit 0
	elif [[ ${appendpu} -eq 1 ]] && [[ ${appender} -eq 1 ]]; then
		echo -e "\n-----------------------------------------------------------------------\n" 1>> /root/uacpassupdate.log
		echo -e "\n--------------------------------------PASSWORD UPDATE ERROR------------------------------------------\n" >> ${HOME}/uacerror.log
		echo -e "\n\nPROCESS COMPLETED !!!"; echo "    - Some Errors Were Encountered"; echo "    - Updated Passwords are stored in /root/uacpassupdate.log"
		echo -e "    - Passwords are Temporary and will expire on First Login\n\n"
		exit 3
	elif [[ ${appendpu} -eq 0 ]] && [[ ${appender} -eq 1 ]]; then
		echo -e "\n--------------------------------------PASSWORD UPDATE ERROR------------------------------------------\n" >> ${HOME}/uacerror.log
		echo -e "\n\nPROCESS FAILED !!!"; echo "    - None of the Account Passwords were Updated"; echo -e "    - Check ${HOME}/uacerror.log for more details\n"
		exit 4
	fi

##############################################################   FINDUSERACCOUNT   ########################################################################
elif [[ ${action} -eq 4 ]]; then

	GREETING;echo

	for uname in ${usernamef}; do
		FIND_USER ${uname}
	done

	exit 0

##############################################################   LISTUSERACCOUNT   ########################################################################
elif [[ ${action} -eq 5 ]]; then

	GREETING
	echo -e "\nUser Accounts on the System except ROOT are listed below\n"

	LIST_USERS; echo; exit 0

fi

#############################################################################################################################################################
######################################################    IN CASE OF LOL !!! YOU ARE NOT ROOT    ############################################################

else
	echo -e "\nRoot Escalation Required\n"
	exit 1
fi

##########################################################################################################################################################
##########################################################################################################################################################


# EXIT CODES AND REASONS

# 0 - Script Executed with NO Errors
# 1 - Need Root Privileges
# 2 - Keyboard Interrupt
# 3 - Some Usernames were not Correct
# 4 - Script Failed Completely
# 5 - Incorrect Parameters provided
