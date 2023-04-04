#!/bin/bash

RED='\033[0;31m' # Error color
YELLOW='\033[0;33m' # Warning color
NC='\033[0m' # No Color

set -u
DIR="."
GetPathToCurrentlyExecutingScript () {
	# Absolute path of this script, e.g. /opt/corda/node/foo.sh
	set +e
	ABS_PATH=$(readlink -f "$0" 2>&1)
	if [ "$?" -ne "0" ]; then
		echo "Using macOS alternative to readlink -f command..."
		# Unfortunate MacOs issue with readlink functionality, see https://github.com/corda/corda-kubernetes-deployment/issues/4
		TARGET_FILE=$0

		cd $(dirname $TARGET_FILE)
		TARGET_FILE=$(basename $TARGET_FILE)
		ITERATIONS=0

		# Iterate down a (possible) chain of symlinks
		while [ -L "$TARGET_FILE" ]
		do
			TARGET_FILE=$(readlink $TARGET_FILE)
			cd $(dirname $TARGET_FILE)
			TARGET_FILE=$(basename $TARGET_FILE)
			ITERATIONS=$((ITERATIONS + 1))
			if [ "$ITERATIONS" -gt 1000 ]; then
				echo "symlink loop. Critical exit."
				exit 1
			fi
		done

		# Compute the canonicalized name by finding the physical path 
		# for the directory we're in and appending the target file.
		PHYS_DIR=$(pwd -P)
		ABS_PATH=$PHYS_DIR/$TARGET_FILE
	fi

	# Absolute path of the directory this script is in, thus /opt/corda/node/
	DIR=$(dirname "$ABS_PATH")
}
GetPathToCurrentlyExecutingScript
set -eu

. $DIR/docker_config.sh

PushDockerImages () {
	echo "====== Pushing Docker images next ... ====== "
	if [ "$DOCKER_REGISTRY" = "" ]; then
		echo -e "${RED}ERROR${NC}"
		echo "You must specify a valid container registry in the values.yaml file"
		exit 1
	fi



	echo "Logging in to Docker registry..."
#	$DOCKER_CMD login $DOCKER_REGISTRY --username $DOCKER_USER --password $DOCKER_PASSWORD
  gcloud auth configure-docker europe-west2-docker.pkg.dev


	echo "Tagging Docker images..."
	echo "$DOCKER_CMD image tag ${CORDA_IMAGE_PATH}:$CORDA_DOCKER_IMAGE_VERSION $DOCKER_REGISTRY/${CORDA_IMAGE_PATH}:$CORDA_DOCKER_IMAGE_VERSION"
#	$DOCKER_CMD image tag ${CORDA_IMAGE_PATH}:$CORDA_DOCKER_IMAGE_VERSION $DOCKER_REGISTRY/${CORDA_IMAGE_PATH}:$CORDA_DOCKER_IMAGE_VERSION
#	$DOCKER_CMD tag ${CORDA_FIREWALL_IMAGE_PATH}:$FIREWALL_DOCKER_IMAGE_VERSION $DOCKER_REGISTRY/${CORDA_FIREWALL_IMAGE_PATH}_$VERSION:$FIREWALL_DOCKER_IMAGE_VERSION
  docker image tag corda_image_ent:v1.00 europe-west2-docker.pkg.dev/canvas-hook-339503/corda

	echo "Pushing Docker images to Docker repository..."
	CORDA_DOCKER_REPOSITORY=$(echo  $DOCKER_REGISTRY/${CORDA_IMAGE_PATH}:$CORDA_DOCKER_IMAGE_VERSION 2>&1 | tr '[:upper:]' '[:lower:]')
	echo "$CORDA_DOCKER_REPOSITORY"
#	CORDA_FIREWALL_DOCKER_REPOSITORY=$(echo $DOCKER_REGISTRY/${CORDA_FIREWALL_IMAGE_PATH}_$VERSION:$FIREWALL_DOCKER_IMAGE_VERSION 2>&1 | tr '[:upper:]' '[:lower:]')
	echo "Push for Corda Enterprise Docker image:"
	$DOCKER_CMD push $CORDA_DOCKER_REPOSITORY
#	echo "Push for Corda Firewall Docker image:"
#	$DOCKER_CMD push $CORDA_FIREWALL_DOCKER_REPOSITORY
	echo "====== Pushing Docker images completed. ====== "
}
PushDockerImages
