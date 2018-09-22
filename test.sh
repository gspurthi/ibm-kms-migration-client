#!/bin/bash
# IBM Copyright 2018
#
# Key Protect Legacy Migration
#
# Key Migration and Full Lifecycle Test 
#
source utils.sh
source testUtils.sh
source config.sh

login_legacyKP
list_secretkeys_legacyKP
delete_secretkeys_legacyKP
list_secretkeys_legacyKP
create_testkeys_legacyKP
export_secretkeys_legacyKP
delete_secretkeys_legacyKP
list_secretkeys_legacyKP

login_newKP
delete_secretkeys_newKP
list_secretkeys_newKP
import_secretkeys_newKP
list_secretkeys_newKP
delete_secretkeys_newKP
list_secretkeys_newKP

