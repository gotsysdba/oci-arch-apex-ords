#!/usr/bin/env ksh
#------------------------------------------------------------------------------
# GLOBAL/DEFAULT VARS
#------------------------------------------------------------------------------
typeset -i  RC=0
typeset -r  IFS_ORIG=$IFS
typeset -rx SCRIPT_NAME="${0##*/}"
typeset -rx SCRIPTDIR="/tmp/uploads"

typeset -r ORDS_USER="ORDS_PUBLIC_USER_OCI"
typeset -r ORDS_DIR="/opt/oracle/ords"
typeset -r STANDALONE_ROOT="${ORDS_DIR}/config/ords/standalone/doc_root"

#------------------------------------------------------------------------------
# LOCAL FUNCTIONS
#------------------------------------------------------------------------------
function usage {
	print -- "${SCRIPT_NAME} Usage"
	print -- "${SCRIPT_NAME} MUST be run by oracle"
	print -- "\t\t${SCRIPT_NAME} -t <DB_NAME> -p <ADMIN_PASS> -v <APEX_VERSION> [-h]"
	return 0
}

function run_sql {
	typeset -i _RC=0
	typeset -r _PASS=$1
	typeset -r _DBNAME=$2
	typeset -r _SQL=$3

	print "Connnecting to ${_DBNAME}_TP (TNS_ADMIN=$TNS_ADMIN)"
	sqlplus -s /nolog <<-EOSQL
		connect ADMIN/${_PASS}@${_DBNAME}_TP
		set serveroutput on size 99999 feedback off timing on linesize 180 echo on
		whenever sqlerror exit 1
		$_SQL
	EOSQL

	return ${_RC}
}

function obj_storage_native {
	typeset -i _RC=0
	typeset -r _PASS=$1
	typeset -r _DBNAME=$2
	typeset -r _USER=$3
	typeset -r _TENANCY=$4
	typeset -r _PRIVKEY=$5
	typeset -r _FINGER=$6

	typeset -r _SQL="
		BEGIN
			DBMS_CLOUD.CREATE_CREDENTIAL (
				 credential_name => 'OCI_NATIVE_CRED',
				,user_ocid       => ${_USER}
				,tenancy_ocid    => ${_TENANCY}
				,private_key     => ${_PRIVKEY}
				,fingerprint     => ${_FINGER}
			);
		END;
		/
		ALTER DATABASE PROPERTY SET DEFAULT_CREDENTIAL = 'ADMIN.OCI_NATIVE_CRED';
		"

	run_sql "${_PASS}" "${_DBNAME}" "${_SQL}"
	_RC=$?

	return ${_RC}
}

function set_passwords {
	typeset -i _RC=0
	typeset -r _PASS=$1
	typeset -r _DBNAME=$2

	typeset -r _SQL="
		DECLARE
			L_USER  VARCHAR2(255);
		BEGIN
			DBMS_OUTPUT.PUT_LINE('Configuring ${ORDS_USER}');
			BEGIN
				SELECT USERNAME INTO L_USER FROM DBA_USERS WHERE USERNAME='${ORDS_USER}';
				DBMS_OUTPUT.PUT_LINE('Modifying ${ORDS_USER}');
				execute immediate 'ALTER USER \"${ORDS_USER}\" IDENTIFIED BY \"${_PASS}\"';
			EXCEPTION WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('Creating ${ORDS_USER}');
				execute immediate 'CREATE USER \"${ORDS_USER}\" IDENTIFIED BY \"${_PASS}\"';
			END;
			DBMS_OUTPUT.PUT_LINE('Giving ${ORDS_USER} the Runtime Role');
			BEGIN
				ORDS_ADMIN.PROVISION_RUNTIME_ROLE (
					p_user => '${ORDS_USER}',
					p_proxy_enabled_schemas => TRUE
				);
			END;
		END;
		/
		GRANT CONNECT TO ${ORDS_USER};
		ALTER USER ${ORDS_USER} PROFILE ORA_APP_PROFILE;"

	run_sql "${_PASS}" "${_DBNAME}" "${_SQL}"
	_RC=$?

	return ${_RC}
}

function set_image_cdn {
	typeset -i _RC=0
	typeset -r _PASS=$1
	typeset -r _DBNAME=$2
	typeset -r _VERSION=$3

	typeset -r _SQL="
	    begin
    	    apex_instance_admin.set_parameter(
        	    p_parameter => 'IMAGE_PREFIX',
        	    p_value     => 'https://static.oracle.com/cdn/apex/${_VERSION}/' );      
        	commit;
    	end;
		/"

	run_sql "${_PASS}" "${_DBNAME}" "${_SQL}"
	_RC=$?

	return ${_RC}
}

function write_apex_pu {
	typeset -i _RC=0
	typeset -r _FILE="apex_pu.xml"
	typeset -r _DIR=$1
	typeset -r _PASS=$2
	typeset -r _DBNAME=$3
	typeset -r _WALLET_FILE=$4

	typeset -r _WALLET=$(cat ${_WALLET_FILE})

	mkdir -p ${_DIR}
	cat > ${_DIR}/${_FILE} <<- EOF
		<?xml version="1.0" encoding="UTF-8" standalone="no"?>
		<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
		<properties>
		<entry key="db.username">${ORDS_USER}</entry>
		<entry key="db.password">!${_PASS}</entry>
		<entry key="db.wallet.zip.service">${_DBNAME}_TP</entry>
		<entry key="plsql.gateway.enabled">true</entry>
		<entry key="db.wallet.zip"><![CDATA[${_WALLET}]]></entry>
		</properties>
	EOF
	if [[ ! -f ${_DIR}/${_FILE} ]]; then
		print -- "ERROR: Unable to write ${_DIR}/${_FILE}"
		_RC=1
	else
		print -- "Wrote ${_DIR}/${_FILE}"
	fi
	return ${_RC}
}

function write_defaults {
	typeset -i _RC=0
	typeset -r _FILE="defaults.xml"
	typeset -r _DIR=$1

	mkdir -p ${_DIR}
	cat > ${_DIR}/${_FILE} <<- EOF
		<?xml version="1.0" encoding="UTF-8" standalone="no"?>
		<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
		<properties>
		<entry key="plsql.gateway.enabled">true</entry>
		<entry key="jdbc.InitialLimit">10</entry>
		<entry key="jdbc.MaxLimit">1200</entry>
		<entry key="security.httpsHeaderCheck">X-Forwarded-Proto: https</entry>
		<entry key="feature.sdw">false</entry>
		<entry key="restEnabledSql.active">true</entry>
		<entry key="database.api.enabled">false</entry>
		<entry key="misc.defaultPage">f?p=DEFAULT:1</entry>
		</properties>
	EOF
	if [[ ! -f ${_DIR}/${_FILE} ]]; then
		print -- "ERROR: Unable to write ${_DIR}/${_FILE}"
		_RC=1
	else
		print -- "Wrote ${_DIR}/${_FILE}"
	fi
	return ${_RC}
}

function write_standalone_properties {
	typeset -i _RC=0
	typeset -r _FILE="standalone.properties"
	typeset -r _DIR=$1
	typeset -r _APEX_VERSION=$2

	mkdir -p ${_DIR}
	cat > ${_DIR}/${_FILE} <<- EOF
		jetty.port=8080
		standalone.context.path=/ords
		standalone.doc.root=${STANDALONE_ROOT}
		standalone.scheme.do.not.prompt=true
	EOF
	if [[ ! -f ${_DIR}/${_FILE} ]]; then
		print -- "ERROR: Unable to write ${_DIR}/${_FILE}"
		_RC=1
	else
		print -- "Wrote ${_DIR}/${_FILE}"
		mkdir -p ${STANDALONE_ROOT}
		cat > ${STANDALONE_ROOT}/index.html <<- EOF
			<!DOCTYPE html>
			<html>
				<head>
					<title>No Default Application</title>
				</head>
				<body>
					<p>Sorry, a DEFAULT Application has not yet been configured.</p>
				</body>
			</html>
		EOF
	fi

	return ${_RC}
}

#------------------------------------------------------------------------------
# INIT
#------------------------------------------------------------------------------
if [[ $(whoami) != "oracle" ]]; then
	usage && exit 1
fi

while getopts :a:b:c:d:t:p:v:h args; do
	case $args in
		t) typeset -r MYTARGET=${OPTARG} ;;
		p) typeset -r MYPASSWORD=${OPTARG} ;;
		v) typeset -r MYAPEX_VERSION=${OPTARG} ;;
		a) typeset -r MYUSER=${OPTARG} ;;
		b) typeset -r MYTENANCY=${OPTARG} ;;
		c) typeset -r MYPRIVKEY=${OPTARG} ;;
		d) typeset -r MYFINGER=${OPTARG} ;;
		h) usage ;;
	esac
done

if [[ -z ${MYTARGET} || -z ${MYPASSWORD} || -z ${MYAPEX_VERSION} ]]; then
	usage && exit 1
fi

if [[ ! -d ${ORDS_DIR} ]]; then
	print -- "ERROR: Cannot find ${ORDS_DIR}; is ords installed?" && exit 1
fi
#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------
export ORACLE_HOME=${HOME}
print -- "Set ORACLE_HOME=$ORACLE_HOME"
export TNS_ADMIN=$ORACLE_HOME/network/admin
print -- "Setting up $TNS_ADMIN"

mkdir -p $TNS_ADMIN
cp ${SCRIPTDIR}/adb_wallet.zip $TNS_ADMIN/
base64 -w 0 $TNS_ADMIN/adb_wallet.zip > $TNS_ADMIN/adb_wallet.zip.b64
unzip -o ${TNS_ADMIN}/adb_wallet.zip -d ${TNS_ADMIN}

set_passwords "${MYPASSWORD}" "${MYTARGET}"
RC=$?

set_image_cdn "${MYPASSWORD}" "${MYTARGET}" "${MYAPEX_VERSION}"
RC=$(( RC + $? ))

obj_storage_native "${MYPASSWORD}" "${MYTARGET}" "${MYUSER}" "${MYTENANCY}" "${MYPRIVKEY}" "${MYFINGER}"
RC=$(( RC + $? ))

write_apex_pu "${ORDS_DIR}/config/ords/conf" "${MYPASSWORD}" "${MYTARGET}" "$TNS_ADMIN/adb_wallet.zip.b64"
RC=$(( RC + $? ))

write_defaults "${ORDS_DIR}/config/ords" 
RC=$(( RC + $? ))

write_standalone_properties "${ORDS_DIR}/config/ords/standalone" "${MYAPEX_VERSION}"
RC=$(( RC + $? ))

print -- "FINISHED: Return Code: ${RC}"
exit $RC