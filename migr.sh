#!/bin/bash
# IBM 2018 Copyright
# Key Protect Legacy Migration 
#
# Secret Key Migration
#
source utils.sh
source config.sh

# Export standard secret keys from a Legacy instance
login_legacyKP
export_secretkeys_legacyKP

# Import standard secret keys to a Key Protect instance
login_newKP
import_secretkeys_newKP
list_secretkeys_newKP
