#!/usr/bin/env bash
set -e

# Install Promethei on Linux, macOS, and Windows (msys2)

# Variables
VERSION=${VERSION:-latest}
INSTALL_DIR=${INSTALL_DIR:-$HOME/.promethei/bin}
ARTIFACTS_ARCHIVE_PREFIX="promethei"
PROMETHEI_BINARY_PREFIX="promethei"
CIRDL_BINARY_PREFIX="cirdl"
SETUP_BINARY_PREFIX="setup"
WINDOWS_LIBS_LIST="libgcc_s_seh-1.dll libwinpthread-1.dll"
BASE_URL=${BASE_URL:-https://github.com/promethei-project/nim-promethei-node}
API_BASE_URL="https://api.github.com/repos/promethei-project/nim-promethei-node"
BRANCH="${BRANCH:-main}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
TEMP_DIR="${TEMP_DIR:-.}"
PROGRESS_MARK="\033[0;36m\u2022\033[0m"
PASS_MARK="\033[0;32m\u2714\033[0m"
FAIL_MARK="\033[0;31m\u2718\033[0m"
SCRIPT_URL="${SCRIPT_URL:-https://get.archivist.storage/install.sh}"

# Debug
if [[ "${DEBUG:-false}" == "true" ]]; then
  echo -e "\n \e[33mVariables:\e[0m"
  echo "  VERSION: ${VERSION}"
  echo "  INSTALL_DIR: ${INSTALL_DIR}"
  echo "  BRANCH: ${BRANCH}"
  echo "  BASE_URL: ${BASE_URL}"
  echo "  TEMP_DIR: ${TEMP_DIR}"
  echo "  SCRIPT_URL: ${SCRIPT_URL}"
fi

# Help
if [[ $1 == *"help"* ]] ; then
  COMMAND="curl -s ${SCRIPT_URL}"
  echo -e "
  \e[33mInstall Promethei\e[0m\n
  \e[33mUsage:\e[0m
    ${COMMAND} | bash
    ${COMMAND} | VERSION=0.2.0 bash
    ${COMMAND} | bash -s help

  \e[33mVariables:\e[0m
    - VERSION=0.2.0                             - promethei binaries version to install
    - INSTALL_DIR=/usr/local/bin                - directory to install binaries
    - BASE_URL=https://builds.archivist.storage - custom base URL for binaries downloading
    - BRANCH=fix/custom-branch                  - custom branch builds
    - TEMP_DIR=/tmp                             - temporary directory for download and extraction"
  exit 0
fi

# Functions
show_start() {
  echo -e "\n \e[33m${1}\e[0m\n"
}

show_progress() {
  echo -e " ${PROGRESS_MARK} ${1}"
}

show_pass() {
  echo -e "\r\e[${TRIM:-1}A\e[0K ${PASS_MARK} ${1}"
  unset TRIM
}

show_fail() {
  echo -e "\r\e[1A\e[0K ${FAIL_MARK} ${1}"
  [[ -n "${2}" ]] && echo -e "\e[31m \n Error: ${2}\e[0m\n"
  exit 1
}

show_end() {
  echo -e "\n\e[32m ${1}\e[0m\n"
}

install_path() {
  BINARY_NAME="${1}"
  if [[ "${BINARY_NAME}" == "${PROMETHEI_BINARY_PREFIX}" ]]; then
    INSTALL_PATH="${INSTALL_DIR}/${BINARY}"
  else
    INSTALL_PATH="${INSTALL_DIR}/${PROMETHEI_BINARY_PREFIX}-${BINARY}"
  fi
}

# Start
show_start "Installing Promethei..."

# Version
message="Compute version"
show_progress "${message}"
if [[ "${BASE_URL}" == *"https://github.com/"* ]]; then
  if [[ "${VERSION}" == "latest" ]]; then
    VERSION=$(curl -s "${API_BASE_URL}/releases/latest" | grep tag_name | cut -d '"' -f 4)
  else
    VERSION="v${VERSION}"
  fi
else
  if [[ "${BRANCH}" == "releases" ]]; then
    if [[ "${VERSION}" == "latest" ]]; then
      VERSION=$(curl -s "${BASE_URL}/${BRANCH}/latest")
    else
      VERSION="v${VERSION}"
    fi
  else
    VERSION="${BRANCH/\//-}"
  fi
fi
[[ $? -eq 0 ]] && show_pass "${message}" || show_fail "${message}"

# Archives and binaries
message="Compute archives and binaries names"
show_progress "${message}"
ARCHIVES=("${ARTIFACTS_ARCHIVE_PREFIX}")
BINARIES=("${PROMETHEI_BINARY_PREFIX}" "${CIRDL_BINARY_PREFIX}" "${SETUP_BINARY_PREFIX}")
show_pass "${message}"

# Get the current OS
message="Checking the current OS"
show_progress "${message}"
case "$(uname -s)" in
  Linux*)               OS="linux"                                          ;;
  Darwin*)              OS="darwin"                                         ;;
  CYGWIN*|MINGW*|MSYS*) OS="windows"                                        ;;
  *)                    show_fail "${message}" "Unsupported OS $(uname -s)" ;;
esac
[[ $? -eq 0 ]] && show_pass "${message}" || show_fail "${message}"

# Get the current architecture
message="Checking the current architecture"
show_progress "${message}"
case "$(uname -m)" in
  x86_64|amd64)  ARCHITECTURE="amd64"                                           ;;
  arm64|aarch64) ARCHITECTURE="arm64"                                           ;;
  *)             show_fail "${message}" "Unsupported architecture: $(uname -m)" ;;
esac
[[ $? -eq 0 ]] && show_pass "${message}" || show_fail "${message}"

# Not supported
if [[ "${OS}" == "windows" && "${ARCHITECTURE}" == "arm64" ]]; then
  show_fail "${message}" "Windows ${ARCHITECTURE} is not supported at the moment"
fi

# Prerequisites
message="Checking prerequisites"
show_progress "${message}"
if [[ ("${OS}" != "windows") ]]; then
  $(command -v tar &> /dev/null) || show_fail "${message}" "Please install tar to continue installation"
fi
show_pass "${message}"

# Archives names
SUFFIX="${VERSION}-${OS}-${ARCHITECTURE}"
if [[ "$OS" == "windows" ]]; then
  ARCHIVE_SUFFIX="${SUFFIX}.zip"
else
  ARCHIVE_SUFFIX="${SUFFIX}.tar.gz"
fi

# Download
for ARCHIVE in "${ARCHIVES[@]}"; do
  ARCHIVE_NAME="${ARCHIVE}-${ARCHIVE_SUFFIX}"

  for FILE in "${ARCHIVE_NAME}" "${ARCHIVE_NAME}.sha256"; do
    if [[ "${BASE_URL}" == *"https://github.com/"* ]]; then
      DOWNLOAD_URL="${BASE_URL}/releases/download/${VERSION}/${FILE}"
    else
      if [[ "${BRANCH}" == "releases" ]]; then
        DOWNLOAD_URL="${BASE_URL}/${BRANCH}/${VERSION}/${FILE}"
      elif [[ "${BRANCH}" == "${DEFAULT_BRANCH}" ]]; then
        DOWNLOAD_URL="${BASE_URL}/${BRANCH}/${FILE}"
      else
        DOWNLOAD_URL="${BASE_URL}/branches/${VERSION}/${FILE}"
      fi
    fi

    message="Downloading ${FILE}"
    show_progress "${message}"
    http_code=$(curl --write-out "%{http_code}" --connect-timeout 5 --retry 5 -sL "${DOWNLOAD_URL}" -o "${TEMP_DIR}/${FILE}")
    [[ "${http_code}" -eq 200 ]] && show_pass "${message}" || show_fail "${message}" "Failed to download ${DOWNLOAD_URL}"
  done
done

# Checksum
for ARCHIVE in "${ARCHIVES[@]}"; do
  ARCHIVE_NAME="${ARCHIVE}-${ARCHIVE_SUFFIX}"
  message="Verifying checksum for ${ARCHIVE_NAME}"
  show_progress "${message}"

  EXPECTED_SHA256=$(cat "${TEMP_DIR}/${ARCHIVE_NAME}.sha256" | cut -d' ' -f1)
  if [[ "${OS}" == "darwin" ]]; then
    ACTUAL_SHA256=$(shasum -a 256 "${TEMP_DIR}/${ARCHIVE_NAME}" | cut -d ' ' -f 1)
  else
    ACTUAL_SHA256=$(sha256sum "${TEMP_DIR}/${ARCHIVE_NAME}" | cut -d ' ' -f 1)
  fi

  if [[ "$ACTUAL_SHA256" == "$EXPECTED_SHA256" ]]; then
    show_pass "${message}"
  else
    show_fail "${message}" "Checksum verification failed for ${ARCHIVE_NAME}. Expected: $EXPECTED_SHA256, got: $ACTUAL_SHA256"
  fi
done

# Extract
for ARCHIVE in "${ARCHIVES[@]}"; do
  ARCHIVE_NAME="${ARCHIVE}-${ARCHIVE_SUFFIX}"

  message="Extracting ${ARCHIVE_NAME}"
  show_progress "${message}"

  if [[ "${OS}" == "windows" ]]; then
    if unzip -v &> /dev/null; then
      unzip -q -o "${TEMP_DIR}/${ARCHIVE_NAME}" -d "${TEMP_DIR}"
      [[ $? -ne 0 ]] && show_fail "${message}"
    else
      C:/Windows/system32/tar.exe -xzf "${TEMP_DIR}/${ARCHIVE_NAME}" -C "${TEMP_DIR}"
      [[ $? -ne 0 ]] && show_fail "${message}"
    fi
  else
    tar -xzf "${TEMP_DIR}/${ARCHIVE_NAME}" -C "${TEMP_DIR}"
    [[ $? -ne 0 ]] && show_fail "${message}"
  fi
  show_pass "${message}"
done

# Install
for BINARY in "${BINARIES[@]}"; do
  BINARY_NAME="${BINARY}"
  install_path "${BINARY_NAME}"

  # Install
  message="Installing ${BINARY_NAME} to ${INSTALL_PATH}"
  show_progress "${message}"
  [[ -d "${INSTALL_PATH}" ]] && show_fail "${message}" "Installation path ${INSTALL_PATH} is a directory"
  if [[ "${TEMP_DIR}/${BINARY_NAME}" != "${INSTALL_PATH}" ]]; then
    if ! (mkdir -p "${INSTALL_DIR}" && install -C -m 755 "${TEMP_DIR}/${BINARY_NAME}" "${INSTALL_PATH}") 2> /dev/null; then
      $(sudo -n true 2>/dev/null) || TRIM=2
      sudo mkdir -p "${INSTALL_DIR}" && sudo install -C -m 755 "${TEMP_DIR}/${BINARY_NAME}" "${INSTALL_PATH}"
      [[ $? -ne 0 ]] && show_fail "${message}"
    fi
  fi
  show_pass "${message}"
done

# Windows libs
if [[ "${OS}" == "windows" ]]; then
  message="Copy libs to ${MINGW_PREFIX}/bin"
  show_progress "${message}"
  for LIB in ${WINDOWS_LIBS_LIST}; do
    mv "${TEMP_DIR}/${LIB}" "${MINGW_PREFIX}/bin"
  done
  [[ $? -eq 0 ]] && show_pass "${message}" || show_fail "${message}"
fi

# Cleanup
message="Cleanup"
show_progress "${message}"
for BINARY in "${BINARIES[@]}"; do
  BINARY_NAME="${BINARY}"
  install_path "${BINARY_NAME}"

  if [[ "${TEMP_DIR}/${BINARY_NAME}" != "${INSTALL_PATH}" ]]; then
    rm -f "${TEMP_DIR}/${BINARY_NAME}"
    [[ $? -ne 0 ]] && show_fail "${message}"
  fi
done
for ARCHIVE in "${ARCHIVES[@]}"; do
  ARCHIVE_NAME="${ARCHIVE}-${ARCHIVE_SUFFIX}"
  rm -f "${TEMP_DIR}/${ARCHIVE_NAME}"*
  [[ $? -ne 0 ]] && show_fail "${message}"
done
show_pass "${message}"

# End
show_end "Setup completed successfully!"

# Dependencies
dependencies=()
for BINARY in "${BINARIES[@]}"; do
  BINARY_NAME="${BINARY}"
  install_path "${BINARY_NAME}"

  case "${OS}" in
    linux)  dependencies+=($(ldd "${INSTALL_PATH}" | awk '/not found/ {print $1}'))      ;;
    darwin) dependencies+=($(otool -L "${INSTALL_PATH}" | awk '/not found/ {print $1}')) ;;
  esac
done

if [[ ${#dependencies[@]} -ne 0 ]]; then
  echo -e " Please inatall the following dpependencies:
  ${dependencies[@]}\n"
fi

# Path
case ${SHELL} in
  */bash) SHELL_PROFILE_FILE="$HOME/.bashrc"                  ;;
  */zsh)  SHELL_PROFILE_FILE="$HOME/.zshrc"                   ;;
  */fish) SHELL_PROFILE_FILE="$HOME/.config/fish/config.fish" ;;
  *)      SHELL_PROFILE_FILE="$HOME/.profile"                 ;;
esac

if [[ "${INSTALL_DIR}" != "." && "${PATH}" != *"${INSTALL_DIR}"* ]]; then
  echo -e " \e[33mNote: Please add install directory to your PATH\e[0m"
  echo -e "   Permanently to your shell profile:
          \e[0m\e[94mecho 'export PATH=\"\$PATH:${INSTALL_DIR}\"' >> ${SHELL_PROFILE_FILE}\e[0m\n"
  echo -e "   Current session only:
          \e[0m\e[94mexport PATH=\"\$PATH:${INSTALL_DIR}\"\e[0m\n"
fi
