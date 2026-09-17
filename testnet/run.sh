# Promethei Testnet - Run

# Variables
set -a
NETWORK="testnet"
BASE_SCRIPT="https://get.archivist.storage/run.sh"
SCRIPT_URL="https://get.archivist.storage/${NETWORK}/run.sh"
PROMETHEI_BINARY="${PROMETHEI_BINARY:-./promethei}"
PROMETHEI_ETH_PROVIDER="${PROMETHEI_ETH_PROVIDER:-https://rpc.${NETWORK}.archivist.storage}"
set +a

# Help
if [[ $1 == *"help"* ]] ; then
  curl -s "${BASE_SCRIPT}" | bash -s -- help
  exit 0
fi

# Run
curl -s "${BASE_SCRIPT}" | bash -s -- $@
