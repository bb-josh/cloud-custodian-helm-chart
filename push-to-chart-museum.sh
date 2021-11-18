#!/usr/bin/env bash

# SHELLCHECK RESULTS
# *clean* as of 11/18/2021


# optional shellcheck options
# shellcheck enable=all


# EXPORT VARIABLES
declare -rx HELM_REPO_USERNAME="${1:-''}"
declare -rx HELM_REPO_PASSWORD="${2:-''}"

# ENV SETTINGS ##########
set -e                      # exit all shells if script fails
set -u                      # exit script if uninitialized variable is used
set -o pipefail             # exit script if anything fails in pipe
shopt -s failglob           # fail on regex expansion fail
shopt -s nullglob           # enables recursive globbing
shopt -s inherit_errexit    # persists `set -e` inside of subshells (disabled by default)
IFS=$'\n\t'


###### UTILTIES
function get_script_dirpath(){
  cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd
}


function get_script_filename(){
  basename "${0}"
}


###### INITIALIZATION
function require(){ 
  hash "${@}" || exit 127; 
}


function get_all_functions(){
  declare -F | sed 's/declare -f //g' 
}


function set_functions_readonly(){
  # prevent masking return values
  all_functions="$( get_all_functions )"; local -r all_functions
  for function in ${all_functions}; do
    readonly -f "${function}"
  done
}


function verify_dependencies(){
  local -ra dependencies=(
    helm
    # list all binary dependencies here
  )

  for dependency in "${dependencies[@]}"; do
    require "${dependency}"
  done
}


function before_start_warning(){
  local -r chartmuseum_url="${1}"
           # prevent masking return values
           script_filename="$(get_script_filename)"; local -r script_filename
           helm_filepath="$(command -v helm)"      ; local -r helm_filepath
  echo
  echo '=========== IMPORTANT ==========='
  echo "YOU MAY NEED TO AUTHENTICATE WITH ${chartmuseum_url}"
  echo '> BEFORE USING THIS SCRIPT'
  echo
  echo 'TO ONE-OFF AUTHENTICATE DO THE FOLLOWING'
  echo "./${script_filename} <HELM_REPO_USERNAME> <HELM_REPO_PASSWORD>"
  echo "OTHERWISE you can authenticate the repository permanently via ${helm_filepath}"
  echo '=========== IMPORTANT ==========='
  echo
}


function initialize(){
  local -r chartmuseum_url="${1}"
  set_functions_readonly
  verify_dependencies
  before_start_warning "${chartmuseum_url}"
}


###### LOGIC
function install_helm_plugin(){
  local -r plugin_url="${1}"
  local -r plugin_name="${2}"
  if ! helm plugin list | grep --quiet "${plugin_name}"; then
    helm plugin install "${plugin_url}"
  fi
}


function push_chart(){
  local -r chartmuseum_url="${1}"
  local -r helm_chart_dirname="${2}"
  helm cm-push --force "${helm_chart_dirname}" "${chartmuseum_url}"
}


## << MAIN >> ##
function main(){
            # prevent masking return values
           script_dirpath="$(get_script_dirpath)"; local -r script_dirpath
  local -r helm_chart_dirname="${script_dirpath}/cloud-custodian-cron/"
  local -r helm_push_plugin_url='https://github.com/chartmuseum/helm-push.git'
  local -r helm_push_plugin_name='cm-push'
  local -r chartmuseum_url='https://charts.in.bbhosted.com'

  initialize          "${chartmuseum_url}"
  install_helm_plugin "${helm_push_plugin_url}" "${helm_push_plugin_name}"
  push_chart          "${chartmuseum_url}" "${helm_chart_dirname}"

  exit 0
}
main
