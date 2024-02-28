#!/usr/bin/env bash

# Enhanced Bash Script for License Verification

APPROVED_LICENSES_URL="https://raw.githubusercontent.com/tactica/approved_licenses/master/list.yml?$(date +%s)"

# Halt on any error (error propagation) and use pipefail to catch errors in pipes
set -eo pipefail

export TERM=xterm

# Define colours
RESET_COLOR='\033[0m'
HIGHLIGHT_COLOR='\033[0;35m'
SUCCESS_COLOR='\033[0;32m'
ERROR_COLOR='\033[0;31m'
REQUIRED_COMMANDS=("gem" "curl" "awk" "grep")

# Function to print usage
print_usage() {
  echo "Usage: $0 [-h|--help] [--keep-temp]"
  echo "  -h, --help    Show this help message."
  echo "  --keep-temp   Keep the temporary directory for debugging purposes."
}

# Command-line argument handling
KEEP_TEMP=0
for arg in "$@"; do
  case $arg in
    -h|--help)
      print_usage
      exit 0
      ;;
    --keep-temp)
      KEEP_TEMP=1
      shift
      ;;
    *)
      echo "Unknown argument: $arg"
      print_usage
      exit 1
      ;;
  esac
done

# Check for required commands
for cmd in "${REQUIRED_COMMANDS[@]}"; do
  if ! command -v $cmd &> /dev/null; then
    echo -e "${ERROR_COLOR}Error: $cmd is required but not installed. Exiting...${RESET_COLOR}"
    exit 1
  fi
done

# Clear the screen
clear

# Define a variable to check if a Gemfile exists in the current directory
GEMFILE_EXISTS=-1
if [ -f "Gemfile" ]; then
  GEMFILE_EXISTS=0
fi

# Install license_finder only if a Gemfile exists in the current directory
if [ "$GEMFILE_EXISTS" -ne 0 ]; then
  if ! gem list -i license_finder > /dev/null 2>&1; then
    echo -e "${HIGHLIGHT_COLOR}Installing license_finder gem...${RESET_COLOR}"
    gem install license_finder --no-document || { echo -e "${ERROR_COLOR}Failed to install license_finder. Exiting...${RESET_COLOR}"; exit 1; }
  fi
fi

# Define a temporary directory for the licenses list
TEMP_DIR=$(mktemp -d)
LICENSE_LIST_PATH="${TEMP_DIR}/list.yml"

# Ensure the temporary directory and file are removed on script exit or error
trap_cleanup() {
  if [[ $KEEP_TEMP -eq 0 ]]; then
    rm -rf "${TEMP_DIR}"
  else
    echo -e "${HIGHLIGHT_COLOR}Temporary files kept at: ${TEMP_DIR}${RESET_COLOR}"
  fi
}
trap trap_cleanup EXIT INT TERM ERR

# Download the list of approved licenses
echo -e "${HIGHLIGHT_COLOR}Downloading the list of approved licenses...${RESET_COLOR}"
if ! curl -sSL -o "${LICENSE_LIST_PATH}" "${APPROVED_LICENSES_URL}"; then
  echo -e "${ERROR_COLOR}Failed to download the list of approved licenses. Exiting...${RESET_COLOR}"
  exit 1
fi

# Check for license_finder success and adjust command based on Bundler usage
echo -e "${HIGHLIGHT_COLOR}Checking project dependencies for used licenses...${RESET_COLOR}"
# Temporarily disable 'exit on error'
set +e

# Adjust the license_finder command based on whether a Gemfile is present
if [ $GEMFILE_EXISTS -eq 0 ]; then
  OUTPUT=$(bundle exec license_finder --decisions-file="${LICENSE_LIST_PATH}")
else
  OUTPUT=$(license_finder --decisions-file="${LICENSE_LIST_PATH}")
fi

LICENSE_FINDER_EXIT_CODE=$?
# Re-enable 'exit on error'
set -e

# Check for license_finder success
if [[ $LICENSE_FINDER_EXIT_CODE -eq 0 ]]; then
  echo -e "${SUCCESS_COLOR}SUCCESS: Project uses only approved licenses.${RESET_COLOR}"
else
  echo "$OUTPUT"
  echo -e "${HIGHLIGHT_COLOR}Generating a summary of unapproved licenses and counts...${RESET_COLOR}"
  echo "$OUTPUT" | rev | cut -d, -f1 | rev | grep -i "^ " |sort | uniq -c
  echo -e "${ERROR_COLOR}ERROR: Project uses dependencies with unapproved licenses.${RESET_COLOR}"
  exit 1
fi
