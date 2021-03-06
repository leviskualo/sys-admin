#!/bin/bash
ROOT_UID=0
# check that we are root
if [ "$UID" -ne "$ROOT_UID" ]; then
  echo "You are just an ordinary user (but mom loves you just the same)."
  exit 1
fi
# Get the Email:
#read -p 'Enter email: ' emailvar
emailvar=$1
# Get the Domain:
DOMAIN=$(echo "$emailvar" | cut -d@ -f2)
# Get the cP Username, check if the domain is hosted on the server:
USER=$(/scripts/whoowns "$DOMAIN") || { echo "ERROR - $DOMAIN is not hosted on this server!"; exit 0; }
# Check if the Email exists:
CHECK=$(uapi --user="$USER" Email list_pops | grep login | grep $emailvar | cut -d: -f 2 | cut -d" " -f 2)
if [ "$emailvar" != "$CHECK" ]; then
echo "No such Email $emailvar. Double check and try again...";
exit 1
else
newpassvar=$(cat /dev/urandom | tr -dc "a-zA-Z0-9-_\$\?\^" | fold -w 25 | head -n1)
: ' Some basic checks
echo
echo The domain is - $DOMAIN
echo The user is - $USER
echo
'
# Recommended method to change the pass, send the output to /dev/null:
uapi --user=$USER Email passwd_pop email=$emailvar password=$newpassvar domain=$DOMAIN &>/dev/null
echo
echo $emailvar - Password successfully changed to: $newpassvar
echo
# Restrict outgoing messages from the Email:
echo "Restricting the outgoing messages for $emailvar..."
uapi --user=$USER Email suspend_outgoing email=$emailvar &>/dev/null
echo "Suspended!"
echo
# Remove all $emailvar messages from the Exim queue:
echo "Removing all $emailvar messages from the Exim queue..."
exiqgrep -i -f $emailvar | xargs exim -Mrm &>/dev/null
# Remove Frozen (bounced) messages from the queue as well:
exim -bp | grep "*** frozen ***" | awk '{print $3}' | xargs exim -Mrm ; exim -bpr | grep '<>' | awk {'print $3'} | grep -v "<>" | xargs exim -Mrm ; &>/dev/null
echo "Removed."
echo
echo "All done. Thank you. Bye bye!"
exit 1
fi