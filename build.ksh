#!/usr/bin/env ksh
################################################################################
#
# PURPOSE
#	Zip terraform resource code for OCI Resource Manager	
# UPDATES	
#	v1.0 lathouwj - Initial Release
#
################################################################################
#------------------------------------------------------------------------------
# GLOBAL/DEFAULT VARS
#------------------------------------------------------------------------------
typeset -r ARCH_DIR=$(pwd)
typeset -r BUILD_NAME="${ARCH_DIR##*\/}.zip"
typeset -r BUILD_DIR=$(mktemp -d /tmp/${BUILD_NAME}-XXXXX)
typeset -i RC=0
#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------
print -- "#####################################################################"
print -- "# Creating ${BUILD_NAME} ${ARCH_DIR}"
print -- "#####################################################################"
# Cleanup Old Build
rm ${ARCH_DIR}/${BUILD_NAME} 2>/dev/null

print -- "--> Creating Stack in ${BUILD_DIR}"
cd ${BUILD_DIR}
print -- "--> Copying Terraform stack from ${ARCH_DIR} to ${BUILD_DIR}"
rsync --stats -apxr $ARCH_DIR/ --exclude=.git* --exclude=.terraform* --exclude=*.pem --exclude=*.zip --exclude=terraform.tfstate* .
print -- "--> Creating ZIP archive"
rm -rf ${BUILD_DIR}images
zip -r ${BUILD_DIR}/${BUILD_NAME} * --exclude build.ksh
print -- "--> Copying Build to Repository"
cp ${BUILD_DIR}/${BUILD_NAME} ${ARCH_DIR}
print -- "--> Committing the Build"
cd ${ARCH_DIR}
print -- "--> Cleaning up build directory"
rm -rf $BUILD_DIR

if [[ -f ${ARCH_DIR}/${BUILD_NAME} ]]; then
	print -- "#####################################################################"
	print -- "# ${ARCH_DIR}/${BUILD_NAME} Created"
	print -- "#####################################################################"
	#git add ${BUILD_NAME}
	#git commit -m "Updating ORM Build zip"
else
	print -- "Unable to create build"
	RC=1
fi

exit $RC
