#!/usr/bin/env ksh
#
# This script is called by certbot to automatically update the LoadBalancer
# during renewals; it is set by: certbot renew --deploy-hook ./oci_lb_cert_renewal.ksh 
#------------------------------------------------------------------------------
# GLOBAL/DEFAULT VARS
#------------------------------------------------------------------------------
typeset -i  RC=0
typeset -r  IFS_ORIG=$IFS
typeset -rx SCRIPT_NAME="${0##*/}"
typeset -r  LE_DIR="/etc/letsencrypt"

#------------------------------------------------------------------------------
# LOCAL FUNCTIONS
#------------------------------------------------------------------------------
function usage {
	print "${SCRIPT_NAME} Usage"
	print "${SCRIPT_NAME} MUST be run by root"
	return 0
}

#------------------------------------------------------------------------------
# INIT
#------------------------------------------------------------------------------
if [[ $(whoami) != "root" ]]; then
	usage && exit 1
fi

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------
cert_number=$(ls ${LE_DIR}/csr/|tail -1|sed s/_.*//)
cert_name=$RENEWED_DOMAINS-$cert_number

print -- "Cert Name:   $cert_name"

## TODO: Lookup Dynamically
## Load Balancer OCID
OCID="ocid1.loadbalancer.oc1.uk-london-1.aaaaaaaaojkcztzk64iioz23o3esj4wp4wdqtnqj5jnfkkzau64ycw75uiea"
LIST_NAME="tickety-lb-listener-443"
BSET_NAME="tickety-lb-backend-set"

oci lb certificate create --load-balancer-id $OCID --certificate-name $cert_name \
        --public-certificate-file /etc/letsencrypt/live/$RENEWED_DOMAINS/cert.pem \
        --private-key-file /etc/letsencrypt/live/$RENEWED_DOMAINS/privkey.pem

sleep 30

oci lb listener update --force --listener-name $LIST_NAME --default-backend-set-name $BSET_NAME \
        --port 443 --protocol HTTP --load-balancer-id $OCID --ssl-certificate-name $cert_name

exit $RC