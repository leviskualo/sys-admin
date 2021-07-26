#Deploy Let's Encrypt SSL for custom list of domains

#!/bin/sh
# SSL Generator for Neofill
# Copyright Kualo Limited, 2017
# All Rights Reserved, legal@kualo.com
# Version 1.0

# Overall Flow:
# - Read domain list from file
# - Create empty vhost include dir (rename old to .bak)
# - Check to see if the domain/host resolves to the IP we require
# - If not, abort
# - If so, continue...
# - Check to see if the LE cert exists at present
# - If successful, then set the cert path/name to it
# - If not, try to generate one
# - If the generation fails, abort and don't create a cert vhost
# - If cert path/name set, then take the template vhost and copy it into place
# - replace the various variables with site-specific ones
# - test nginx configtest (nginx -t)
# - If successful, reload nginx

#
# Destination HA IP for SSL vhosts:
#
destip="50.115.22.240";

#
# Other variables
#
vhostdir="/home/websites/nginx/ssl_vhosts";
templatevhost="/home/websites/nginx/ssl_vhost.template";
domainlist="/home/websites/ssl/domain.list";
lelivecertdir="/etc/letsencrypt/live";
levalidationpath="/home/websites/ssl/le/validation";
certbotpath="/home/websites/ssl/le/bin/certbot-auto";


#
# Check for vhost template
#
if [ ! -f ${templatevhost} ];
then
    echo "Cannot locate vhost template file. Aborting.";
    exit 1;
fi

#
# Check for domain list
#
if [ ! -f ${domainlist} ];
then
    echo "Cannot locate domain list file (${domainlist}). Aborting.";
    exit 1;
fi

#
# Check for certbot existence
#
if [ ! -f ${certbotpath} ];
then
    echo "Cannot locate certbot. Aborting.";
    exit 1;
fi

#
# Clear out old SSL vhosts dir
#
if [ -d ${vhostdir}.bak ];
then
    rm -fr ${vhostdir}.bak/
fi

#
# Move current dir to .bak so we can create a fresh one
#
if [ -d ${vhostdir} ];
then
    mv ${vhostdir} ${vhostdir}.bak
    mkdir ${vhostdir};
else
    echo "Nginx SSL vhost directory not found. Aborting."
    exit 1;
fi

#
# Read in the domain list and process
#
cat ${domainlist} | while read MYDOMAIN;
do
    echo "====";
    # Get IP
    DOMAINIP=`getent hosts ${MYDOMAIN} | awk '{ print $1 }' | head -n1`;
    if [ ${destip} == ${DOMAINIP} ];
    then
        echo "Host ${MYDOMAIN} matches destination IP. Proceeding...";
    else
        echo "Host ${MYDOMAIN} does not match destination IP. Skipping.";
        continue;
    fi

    # Check if LE cert exists
    if [ -e ${lelivecertdir}/${MYDOMAIN}/cert.pem ];
    then
        echo "Found an existing LE certificate for ${MYDOMAIN}";
        mycertpath="${lelivecertdir}/${MYDOMAIN}";
    else
        echo "Cannot locate existing certificate for ${MYDOMAIN}. Attempting to generate one now...";
        ${certbotpath} certonly --force-renewal --webroot --webroot-path ${levalidationpath} -d ${MYDOMAIN}
        certresult=$?
        if [ $certresult -eq 0 ];
        then
            if [ -e ${lelivecertdir}/${MYDOMAIN}/cert.pem ];
                then
                        mycertpath="${lelivecertdir}/${MYDOMAIN}";
            else
                echo "Cert appeared to generate, but cannot be found. Please investigate. Skipping this domain.";
                continue;
            fi
        else
            echo "Certificate generation for ${MYDOMAIN} appears to have failed. Skipping this domain.";
            continue;
        fi
    fi

    echo "Proceeding to deploy Nginx SSL vhost for ${MYDOMAIN}";
    cp -pf ${templatevhost} ${vhostdir}/${MYDOMAIN}.conf
    sed -i "s/THEDOMAIN/${MYDOMAIN}/g" ${vhostdir}/${MYDOMAIN}.conf
done

echo "====";

/home/websites/ssl/le/bin/reload_nginx.sh