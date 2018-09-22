#!/bin/bash
# IBM 2018 Copyright
# Key Protect Legacy Migration
#
# Create Test Keys
#
source utils.sh
source testUtils.sh 
source config.sh

login_legacyKP
create_testkeys_legacyKP
list_secretkeys_legacyKP

