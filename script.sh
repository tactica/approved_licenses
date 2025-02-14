#!/usr/bin/env bash

# Enhanced Bash Script for License Verification

APPROVED_LICENSES_URL="https://raw.githubusercontent.com/tactica/approved_licenses/master/list.yml?$(date +%s)"

# Halt on any error and use pipefail to catch errors in pipes
set -eo pipefail

export TERM=xterm

# Define colors
RESET_COLOR='\033[0m'
HIGHLIGHT_COLOR='\033[0;35m'
SUCCESS_COLOR='\033[0;32m'
ERROR_COLOR='\033[0;31m'
REQUIRED_COMMANDS=("gem" "curl" "awk" "grep" "bundle")

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
  if ! command -v "$cmd" &> /dev/null; then
    echo -e "${ERROR_COLOR}Error: $cmd is required but not installed. Exiting...${RESET_COLOR}"
    exit 1
  fi
done

# Clear the screen
clear

# Determine if a Gemfile exists
if [[ -f "Gemfile" ]]; then
  GEMFILE_EXISTS=1
else
  GEMFILE_EXISTS=0
fi

# Ensure Bundler is installed
if ! gem list -i bundler > /dev/null 2>&1; then
  echo -e "${HIGHLIGHT_COLOR}Installing Bundler...${RESET_COLOR}"
  gem install bundler --no-document
fi

# If Gemfile exists, install missing gems from it
if [[ $GEMFILE_EXISTS -eq 1 ]]; then
  echo -e "${HIGHLIGHT_COLOR}Installing project dependencies from Gemfile...${RESET_COLOR}"
  bundle install || { echo -e "${ERROR_COLOR}Failed to install project dependencies. Exiting...${RESET_COLOR}"; exit 1; }
fi

# Install license_finder if not already installed globally
if ! gem list -i license_finder > /dev/null 2>&1; then
  echo -e "${HIGHLIGHT_COLOR}Installing license_finder gem...${RESET_COLOR}"
  gem install license_finder --no-document || { echo -e "${ERROR_COLOR}Failed to install license_finder. Exiting...${RESET_COLOR}"; exit 1; }
fi

# Define a temporary directory for the licenses list
TEMP_DIR=$(mktemp -d)
LICENSE_LIST_PATH="${TEMP_DIR}/list.yml"

# Cleanup temporary directory on exit (unless --keep-temp is set)
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

# Check project dependencies for used licenses
echo -e "${HIGHLIGHT_COLOR}Checking project dependencies for used licenses...${RESET_COLOR}"
# Temporarily disable 'exit on error'
set +e

# Determine whether to run license_finder with bundle exec:
if [[ $GEMFILE_EXISTS -eq 1 && $(grep -q "license_finder" Gemfile; echo $?) -eq 0 ]]; then
  # If the Gemfile explicitly includes license_finder, use bundle exec.
  OUTPUT=$(bundle exec license_finder --decisions-file="${LICENSE_LIST_PATH}")
else
  # Otherwise, use the globally installed license_finder.
  OUTPUT=$(license_finder --decisions-file="${LICENSE_LIST_PATH}")
fi

LICENSE_FINDER_EXIT_CODE=$?
# Re-enable 'exit on error'
set -e

# Check for license_finder success and output results
if [[ $LICENSE_FINDER_EXIT_CODE -eq 0 ]]; then
  echo -e "${SUCCESS_COLOR}SUCCESS: Project uses only approved licenses.${RESET_COLOR}"
else
  echo "$OUTPUT"
  echo -e "${HIGHLIGHT_COLOR}Generating a summary of unapproved licenses and counts...${RESET_COLOR}"
  echo "$OUTPUT" | rev | cut -d, -f1 | rev | grep -i "^ " | sort | uniq -c
  echo -e "${ERROR_COLOR}ERROR: Project uses dependencies with unapproved licenses.${RESET_COLOR}"
  exit 1
fi
