#!/bin/bash

#
# generate_new_device_service.sh
#
#   Generates build tree for a newly named device service. The functionality
#    in this device service taken from the device-simple example. It is
#    expected that the user of this script will replace the code in
#    internal/driver/<servicename>driver.go with their own implementation of
#    the ProtocolDriver interface.
#
# Copyright 2019 Beechwoods Software, Inc.
#
# SPDX-License-Identifier: Apache-2.0
#

printusage() {
    echo
    echo "  Usage:"
    echo "    ${0} -n <device-name> -c [camel-case-name] -d [destination-directory]"
    echo
    echo "  Options:"
    echo "    device-name (required) - should be comprised of lower-case letters and may contain dash(-) characters"
    echo "    camel-case-name (optional) - will default to device-name with first letter converted to upper case"
    echo "    destination-directory (optional) - will default to current directory if not provided"
    echo
    echo "  Example:" 
    echo "    ${0} -n mydevice -c MyDevice -d ~/my-edgex-repositories"
    echo
    echo "    - Produces a new device service called \"device-mydevice-go\" with an example implemenation of"
    echo "      the ProtocolDriver interface called \"MyDeviceDriver\". The example implementation is functionally"
    echo "      equivalent to the \"SimpleDevice\" example in device-sdk-go. It is expected that the user of this"
    echo "      script would replace the example implementation with an implementation that works with \"MyDevice\""
    echo
    exit 1
}

#Default command line arguments
DESTINATION_DIRECTORY=.

while getopts ":n:c:d:" opt; do
    case ${opt} in
	n ) # device-name
	    if [[ ${OPTARG} =~ [A-Z] ]]; then
		echo
		echo "device-name cannot contain upper-case letters"
		printusage
	    else
		DS_NAME=${OPTARG}
	    fi
	    ;;
	c ) # camel-case-name (optional) 
	    if [[ ${OPTARG:0:1} =~ [A-Z] ]]; then
		DS_CAMEL_CASE_NAME=${OPTARG}
	    else
		echo
		echo "camel-case-name must begin with an upper case letter"
		printusage
	    fi
	    ;;
	d ) # destination-directory (optional)
	    if [ -d ${OPTARG} ]; then
		DESTINATION_DIRECTORY=${OPTARG}
	    else
	        echo
		echo "Directory \"${OPTARG}\" does not exist."
		printusage
	    fi
	    ;;
	: )
	    printusage
	    ;;
	\? )
	    printusage
	    ;;
    esac
done

# device-name is requred
if [ -z "${DS_NAME}" ]; then
    printusage
fi

# if camel-case-name is not provided, create one from device-name by upper-casing its first letter
if [ -z "${DS_CAMEL_CASE_NAME}" ]; then
    DS_CAMEL_CASE_NAME=${DS_NAME^}
fi

# Script Constants
NEW_SERVICE_NAME=device-${DS_NAME}-go
NEW_SERVICE_DIR=${DESTINATION_DIRECTORY}/${NEW_SERVICE_NAME}
NEW_BIN_DIR=${NEW_SERVICE_DIR}/bin
NEW_CMD_DIR=${NEW_SERVICE_DIR}/cmd
NEW_CMD_RES_DIR=${NEW_CMD_DIR}/res
NEW_CMD_RES_DOCKER_DIR=${NEW_CMD_RES_DIR}/docker
NEW_INTERNAL_DIR=${NEW_SERVICE_DIR}/internal
NEW_INTERNAL_DRIVER_DIR=${NEW_INTERNAL_DIR}/driver

EXAMPLE_DRIVER_SOURCE_FILE=../example/driver/simpledriver.go
EXAMPLE_MAIN_SOURCE_FILE=../example/cmd/device-simple/main.go
EXAMPLE_CONFIGURATION_FILE=../example/cmd/device-simple/res/configuration.toml
EXAMPLE_DOCKER_CONFIGURATION_FILE=../example/cmd/device-simple/res/docker/configuration.toml
EXAMPLE_DEVICE_PROFILE=../example/cmd/device-simple/res/Simple-Driver.yaml

TEMPLATE_MAKEFILE=./templates/Makefile.template
TEMPLATE_DOCKERFILE=./templates/Dockerfile.template
TEMPLATE_README_MD=./templates/README.md.template
TEMPLATE_LAUNCH_SCRIPT=./templates/edgex-launch.sh.template
TEMPLATE_VERSION_DOT_GO=./templates/version.go.template
TEMPLATE_GO_MOD=./templates/go.mod.template
LICENSE_FILE=../LICENSE

# Bail out if new service directory already exists
if [ -d ${DESTINATION_DIRECTORY}/${NEW_SERVICE_NAME} ]; then
    echo "Directory ${DESTINATION_DIRECTORY}/${NEW_SERVICE_NAME} already exists. Not creating a new device service."
    printusage
fi

# create the basic directory structure
echo
echo -n "Creating new device service tree: ${DESTINATION_DIRECTORY}/${NEW_SERVICE_NAME} ... "
mkdir ${NEW_SERVICE_DIR} ${NEW_BIN_DIR} ${NEW_CMD_DIR} ${NEW_CMD_RES_DIR} ${NEW_CMD_RES_DOCKER_DIR} ${NEW_INTERNAL_DIR} ${NEW_INTERNAL_DRIVER_DIR}

#Generate Makefile
NEW_MAKEFILE=${NEW_SERVICE_DIR}/`basename ${TEMPLATE_MAKEFILE} .template`
cp ${TEMPLATE_MAKEFILE} ${NEW_MAKEFILE}
sed -i "s/<<<DS_NAME>>>/${DS_NAME}/g" ${NEW_MAKEFILE}

#Generate Dockerfile
NEW_DOCKERFILE=${NEW_SERVICE_DIR}/`basename ${TEMPLATE_DOCKERFILE} .template`
cp ${TEMPLATE_DOCKERFILE} ${NEW_DOCKERFILE}
sed -i "s/<<<DS_NAME>>>/${DS_NAME}/g" ${NEW_DOCKERFILE}

#Generate README.md
NEW_README_MD=${NEW_SERVICE_DIR}/`basename ${TEMPLATE_README_MD} .template`
cp ${TEMPLATE_README_MD} ${NEW_README_MD}
sed -i "s/<<<DS_NAME>>>/${DS_NAME}/g" ${NEW_README_MD}
sed -i "s/<<<DS_CAMEL_CASE_NAME>>>/${DS_CAMEL_CASE_NAME}/g" ${NEW_README_MD}

#Generate edgex-launch.sh
NEW_LAUNCH_SCRIPT=${NEW_BIN_DIR}/`basename ${TEMPLATE_LAUNCH_SCRIPT} .template`
cp ${TEMPLATE_LAUNCH_SCRIPT} ${NEW_LAUNCH_SCRIPT}
sed -i "s/<<<DS_NAME>>>/${DS_NAME}/g" ${NEW_LAUNCH_SCRIPT}

#Generate version.go
NEW_VERSION_DOT_GO=${NEW_SERVICE_DIR}/`basename ${TEMPLATE_VERSION_DOT_GO} .template`
cp ${TEMPLATE_VERSION_DOT_GO} ${NEW_VERSION_DOT_GO}
sed -i "s/<<<DS_NAME>>>/${DS_NAME}/g" ${NEW_VERSION_DOT_GO}

#Generate driver.go source file 
NEW_DRIVER_SOURCE_FILE=${NEW_INTERNAL_DRIVER_DIR}/${DS_NAME}driver.go
cp ${EXAMPLE_DRIVER_SOURCE_FILE} ${NEW_DRIVER_SOURCE_FILE}
sed -i "s/Simple/${DS_CAMEL_CASE_NAME}/g" ${NEW_DRIVER_SOURCE_FILE}

#Generate main.go source file
NEW_MAIN_SOURCE_FILE=${NEW_CMD_DIR}/main.go
cp ${EXAMPLE_MAIN_SOURCE_FILE} ${NEW_MAIN_SOURCE_FILE}
sed -i "s/device-simple/device-${DS_NAME}/g" ${NEW_MAIN_SOURCE_FILE}
sed -i "s/SimpleDriver/${DS_CAMEL_CASE_NAME}Driver/g" ${NEW_MAIN_SOURCE_FILE}
sed -i "s/device-sdk-go\"/device-${DS_NAME}-go\"/g" ${NEW_MAIN_SOURCE_FILE}
sed -i "s/device-sdk-go\/example\/driver/device-${DS_NAME}-go\/internal\/driver/g" ${NEW_MAIN_SOURCE_FILE}
sed -i "s/device.Version/device_${DS_NAME}.Version/g" ${NEW_MAIN_SOURCE_FILE}
sed -i "s/ a simple example of a device service/\.\./g" ${NEW_MAIN_SOURCE_FILE}

#Generate configration toml file
NEW_CONFIGURATION_FILE=${NEW_CMD_RES_DIR}/`basename ${EXAMPLE_CONFIGURATION_FILE}`
cp ${EXAMPLE_CONFIGURATION_FILE} ${NEW_CONFIGURATION_FILE}
sed -i "s/simple/${DS_NAME}/g" ${NEW_CONFIGURATION_FILE}
sed -i "s/Simple/${DS_CAMEL_CASE_NAME}/g" ${NEW_CONFIGURATION_FILE}

#Generate docker configration toml file
NEW_DOCKER_CONFIGURATION_FILE=${NEW_CMD_RES_DOCKER_DIR}/`basename ${EXAMPLE_DOCKER_CONFIGURATION_FILE}`
cp ${EXAMPLE_DOCKER_CONFIGURATION_FILE} ${NEW_DOCKER_CONFIGURATION_FILE}
sed -i "s/simple/${DS_NAME}/g" ${NEW_DOCKER_CONFIGURATION_FILE}
sed -i "s/Simple/${DS_CAMEL_CASE_NAME}/g" ${NEW_DOCKER_CONFIGURATION_FILE}

#Generate version file
echo "0.1.0" > ${NEW_SERVICE_DIR}/VERSION

#copy LICENSE file
cp ${LICENSE_FILE} ${NEW_SERVICE_DIR}

#Generate initial go.mod file
NEW_GO_MOD=${NEW_SERVICE_DIR}/`basename ${TEMPLATE_GO_MOD} .template`
cp ${TEMPLATE_GO_MOD} ${NEW_GO_MOD}
sed -i "s/<<<DS_NAME>>>/${DS_NAME}/g" ${NEW_GO_MOD}

#Copy device profile
cp ${EXAMPLE_DEVICE_PROFILE} ${NEW_CMD_RES_DIR}/${DS_NAME}-device-profile.yaml

echo "done"
echo
