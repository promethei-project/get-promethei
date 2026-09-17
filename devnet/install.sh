# Promethei Devnet - Install

# Variables
set -a
NETWORK="devnet"
BASE_SCRIPT="https://get.archivist.storage/install.sh"
SCRIPT_URL="https://get.archivist.storage/${NETWORK}/install.sh"
BASE_URL="https://builds.archivist.storage"
BRANCH="${BRANCH:-main}"
INSTALL_DIR="${INSTALL_DIR:-.}"
set +a

# Help
if [[ $1 == *"help"* ]] ; then
  curl -s "${BASE_SCRIPT}" | bash -s -- help
  exit 0
fi

# Install
curl -s "${BASE_SCRIPT}" | bash
