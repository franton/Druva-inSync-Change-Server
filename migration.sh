#!/bin/bash

# Script to update the configuration of the Druva inSync client on an OS X computer

# Author : Richard Purves <contact@richard-purves.com>
# Version: 1.0 - 27-08-2015 - Initial Version

# Set up variables here

# InSync configuration file and partial path
insync="Library/Application Support/inSync/inSync.cfg"

# Set up log file, folder and function
LOGFOLDER="/private/var/log/organisation"
LOG=$LOGFOLDER"/Druva-inSync-Cloud-Migration.log"
error=0

if [ ! -d "$LOGFOLDER" ];
then
	mkdir $LOGFOLDER
fi

logme()
{
	# Check to see if function has been called correctly
	if [ -z "$1" ]
	then
		echo $( date )" - logme function call error: no text passed to function! Please recheck code!" >> $LOG
		exit 1
	fi

	# Log the passed details
	echo $( date )" - "$1 >> $LOG
	echo "" >> $LOG
}

# Start the change of settings
echo $( date )" - Starting change of inSync settings" > $LOG

# Get all users on the system
accounts=$( dscl . -list /Users UniqueID | awk '$2 >= 501 { print $1; }' )

# Kill the inSync client while we make the changes
killall inSync 2>&1 | tee -a ${LOG}

# Loop around each detected user account
for folder in $accounts
do

	logme "Processing user account: $folder"

# Does the Druva InSync config file exist?
	if [[ -e /Users/$folder/$insync ]];
	then
	
		logme "inSync.cfg detected. Processing"
		
# Make a backup of the cfg file first.
		logme "Backing up existing /Users/$folder/$insync file to $insync.original"
		cp "/Users/$folder/$insync" "/Users/$folder/$insync.original" 2>&1 | tee -a ${LOG}
		
# Change the server field and append a token field to the end of the file
		logme "Writing new cfg file. Changing SERVER = line to use cloud.druva.com:6061"
		cat "/Users/$folder/$insync" | sed $'s/SERVERS =.*/SERVERS = [\x27server.address:6061\x27]/' > "/Users/$folder/$insync.new"
		echo "TOKEN = ' token info goes here '" >> "/Users/$folder/$insync.new"
		echo "REPLACE_DEVICE= 'Yes'" >> "/Users/$folder/$insync.new"

# Delete the original file
		logme "Deleting original /Users/$folder/$insync file"
		rm "/Users/$folder/$insync"
		
# Rename the new file in place
		logme "Putting new file in place"
		mv "/Users/$folder/$insync.new" "/Users/$folder/$insync"

# Owner changes but group does not as we're running as root. Correct this here.
		logme "Correcting file ownership"
		chown $folder "/Users/$folder/$insync" 2>&1 | tee -a ${LOG}
	else
		logme "inSync.cfg not detected. Moving on."
	fi

# Loop around
done

# All done!
logme "Script complete!"

exit 0
