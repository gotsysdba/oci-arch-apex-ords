#!/usr/bin/env ksh
#------------------------------------------------------------------------------
# GLOBAL/DEFAULT VARS
#------------------------------------------------------------------------------
typeset -i  RC=0
typeset -r  IFS_ORIG=$IFS
typeset -rx SCRIPT_NAME="${0##*/}"
# TODO: Get value from standalone.properties
typeset -r  WEB_ROOT="/opt/oracle/ords/config/ords/standalone/doc_root"

#------------------------------------------------------------------------------
# LOCAL FUNCTIONS
#------------------------------------------------------------------------------
function usage {
	print -- "${SCRIPT_NAME} Usage"
	print -- "${SCRIPT_NAME} MUST be run by root"
	print -- "\t\t${SCRIPT_NAME} -d <DOMAIN> [-e <email>] [-h]"
	return 0
}

function write_oci_config {
	typeset -r _FILE=$1
	typeset -r _USER=$2
	typeset -r _FINGERPRINT=$3
	typeset -r _TENANCY=$4
	typeset -r _REGION=$5
	typeset -r _KEY_FILE=$6

	typeset -u _NOW=$(date +%d%h%YT%H%M)
	if [[ -f ${_FILE} ]]; then
		print -- "Backing up ${_FILE} to ${_FILE}.${_NOW}"
		cp ${_FILE} ${_FILE}.${_NOW}
	fi

	cat > ${_FILE} <<- EOF
		[DEFAULT]
		user=${_USER}
		fingerprint=${_FINGERPRINT}
		tenancy=${_TENANCY}
		region=${_REGION}
		key_file=${_KEY_FILE}
	EOF
}

#------------------------------------------------------------------------------
# INIT
#------------------------------------------------------------------------------
if [[ $(whoami) != "root" ]]; then
	usage && exit 1
fi

while getopts :d:e:h args; do
	case $args in
		d) typeset -r MYDOMAIN="${OPTARG}" ;;
		e) typeset -r MYEMAIL="${OPTARG}" ;;
		h) usage ;;
	esac
done

if [[ -z ${MYDOMAIN} ]]; then
	usage && exit 1
fi

if [[ -z ${MYEMAIL} ]]; then
	typeset -r EMAIL="--register-unsafely-without-email"
else
	typeset -r EMAIL="--email ${MYEMAIL}"
fi

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------
print -- "Ensuring OCI Repo is enabled"
yum-config-manager --enable ol7_developer_EPEL
	
print -- "Updating System"
yum -y update

print -- "Installing snapd"
yum -y install snapd

print -- "Removing dependencies no longer required"
yum -y autoremove

print -- "Setting up snapd.socket"
systemctl enable --now snapd.socket
sleep 30
export PATH=$PATH:/var/lib/snapd/snap/bin

print -- "Updating snapd"
snap install core; snap refresh core

print -- "Symlinking /var/lib/snapd/snap to / for classic mode"
if [[ ! -d /snap ]]; then
	ln -s /var/lib/snapd/snap /
	print -- "Symlink'd"
else
	print -- "Symlink already exists"
fi

print -- "Installing CertBot"
snap install --classic certbot

print -- "Registering CertBot"
typeset CMD="certbot certonly --webroot --non-interactive --agree-tos"
CMD="${CMD} ${EMAIL} --webroot-path ${WEB_ROOT} --domains ${MYDOMAIN}"

print -- "Running: ${CMD}"
eval ${CMD}
RC=$?

print -- "Writing OCI Configuration"
mkdir -p ${HOME}/.oci
write_oci_config "${HOME}/.oci/config"
oci setup repair-file-permissions --file ${HOME}/.oci/config