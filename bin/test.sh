#!/bin/bash

set -ex

if [ $TRAVIS_COMMIT != $(git rev-parse HEAD) ]; then
	echo "Current hash does not match commit"
	exit 1
fi


# Run the functional tests
BEHAT_TAGS=$(php utils/behat-tags.php)
behat --format progress $BEHAT_TAGS --strict

