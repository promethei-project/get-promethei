# Promethei Testnet - Generate

# Variables
set -a
NETWORK="testnet"
BASE_SCRIPT="https://get.archivist.storage/generate.sh"
SCRIPT_URL="https://get.archivist.storage/${NETWORK}/generate.sh"
set +a

# Help
if [[ $1 == *"help"* ]] ; then
  curl -s "${BASE_SCRIPT}" | bash -s -- help
  exit 0
fi

# Generate
curl -s "${BASE_SCRIPT}" | bash
