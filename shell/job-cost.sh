#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# Ignore shellcheck warnings for Jenkins environment variables
# These are always set by Jenkins and not defined in this script
# shellcheck disable=SC2154

echo "---> job-cost.sh"

# Configuration for external API calls
CURL_CONNECT_TIMEOUT=30     # seconds to wait for connection
CURL_MAX_TIME=60            # maximum time for entire operation
CURL_RETRY_COUNT=3          # number of retry attempts
CURL_RETRY_INITIAL_DELAY=10 # initial delay before first retry (seconds)
CURL_RETRY_MAX_DELAY=60     # maximum delay between retries (seconds)

# With these settings, worst-case total time for a failing API:
# Attempt 1: 60s (max time) + 10s delay = 70s
# Attempt 2: 60s (max time) + 20s delay = 80s
# Attempt 3: 60s (max time)            = 60s
# Total: ~210 seconds (~3.5 minutes)

# If true, fail the build when pricing API is unavailable
# If false, continue with default values (cost=0, resource=unknown)
# Set via environment variable to override default behavior
FAIL_ON_PRICING_ERROR="${FAIL_ON_PRICING_ERROR:-false}"

# Do NOT use 'set -e' or 'pipefail' globally - we handle errors explicitly
# to provide clear error messages and proper flow control
set -uf

##############################################################################
# Function: log_error
# Description: Print an error message with consistent formatting
# Arguments: $1 - error message
##############################################################################
log_error() {
    echo "ERROR: $1" >&2
}

##############################################################################
# Function: log_info
# Description: Print an info message with consistent formatting
# Arguments: $1 - info message
##############################################################################
log_info() {
    echo "INFO: $1"
}

##############################################################################
# Function: log_debug
# Description: Print a debug message with consistent formatting
# Arguments: $1 - debug message
##############################################################################
log_debug() {
    echo "DEBUG: $1"
}

##############################################################################
# Function: curl_with_retry
# Description: Execute curl with timeout and retry logic
# Arguments:
#   $1 - URL to fetch
#   $2 - Description of what we're fetching (for error messages)
# Returns:
#   0 on success (output in CURL_RESPONSE variable)
#   1 on failure (after all retries exhausted)
##############################################################################
curl_with_retry() {
    local url="$1"
    local description="$2"
    local attempt=1
    local curl_exit_code
    local response
    local delay

    CURL_RESPONSE=""

    while [[ ${attempt} -le ${CURL_RETRY_COUNT} ]]; do
        log_info "Fetching ${description} (attempt ${attempt} of ${CURL_RETRY_COUNT})..."
        log_debug "URL: ${url}"

        # Execute curl with timeouts
        # --connect-timeout: max time for connection phase
        # --max-time: max time for entire operation
        # -s: silent mode (no progress bar)
        # -S: show errors even in silent mode
        response=$(curl \
            --connect-timeout "${CURL_CONNECT_TIMEOUT}" \
            --max-time "${CURL_MAX_TIME}" \
            -s -S \
            "${url}" 2>&1)
        curl_exit_code=$?

        if [[ ${curl_exit_code} -eq 0 ]]; then
            CURL_RESPONSE="${response}"
            log_info "Successfully fetched ${description}"
            return 0
        fi

        # Provide clear error messages based on curl exit codes
        case ${curl_exit_code} in
        6)
            log_error "Could not resolve host for ${description}"
            ;;
        7)
            log_error "Failed to connect to server for ${description}"
            ;;
        28)
            log_error "Connection timed out after ${CURL_MAX_TIME}s for ${description}"
            ;;
        22)
            log_error "HTTP error returned for ${description}"
            ;;
        *)
            log_error "curl failed with exit code ${curl_exit_code} for ${description}"
            ;;
        esac

        if [[ -n "${response}" ]]; then
            log_error "curl output: ${response}"
        fi

        if [[ ${attempt} -lt ${CURL_RETRY_COUNT} ]]; then
            # Calculate exponential backoff delay: initial_delay * 2^(attempt-1)
            # Cap at maximum delay to avoid excessively long waits
            delay=$((CURL_RETRY_INITIAL_DELAY * (2 ** (attempt - 1))))
            if [[ ${delay} -gt ${CURL_RETRY_MAX_DELAY} ]]; then
                delay=${CURL_RETRY_MAX_DELAY}
            fi
            log_info "Retrying in ${delay} seconds (exponential backoff)..."
            sleep "${delay}"
        fi

        ((attempt++))
    done

    log_error "All ${CURL_RETRY_COUNT} attempts failed for ${description}"
    return 1
}

##############################################################################
# Function: parse_json_field
# Description: Parse a field from JSON using jq
# Arguments:
#   $1 - JSON string
#   $2 - jq filter expression
#   $3 - Field name (for error messages)
# Returns:
#   0 on success (output in JSON_FIELD_VALUE variable)
#   1 on failure
##############################################################################
parse_json_field() {
    local json="$1"
    local filter="$2"
    local field_name="$3"
    local result

    JSON_FIELD_VALUE=""

    if [[ -z "${json}" ]]; then
        log_error "Cannot parse ${field_name}: empty JSON input"
        return 1
    fi

    # First validate the JSON
    if ! echo "${json}" | jq . >/dev/null 2>&1; then
        log_error "Cannot parse ${field_name}: invalid JSON"
        log_debug "JSON content: ${json}"
        return 1
    fi

    # Extract the field
    result=$(echo "${json}" | jq -r "${filter}" 2>&1)
    local jq_exit_code=$?

    if [[ ${jq_exit_code} -ne 0 ]]; then
        log_error "jq failed to extract ${field_name} with exit code ${jq_exit_code}"
        log_error "jq output: ${result}"
        return 1
    fi

    if [[ "${result}" == "null" ]]; then
        log_error "Field ${field_name} is null in JSON response"
        return 1
    fi

    JSON_FIELD_VALUE="${result}"
    return 0
}

##############################################################################
# Main Script Logic
##############################################################################

# shellcheck disable=SC1090
source ~/lf-env.sh

# Check if we're running in a cloud environment
if [[ ! -f /run/cloud-init/result.json && ! -f stack-cost ]]; then
    # Don't attempt to calculate job cost as build is not running in a
    # cloud environment
    log_info "Skipping job cost calculation - not running in cloud environment"
    exit 0
fi

# Check for AWS - job cost not supported there
if [[ -f /run/cloud-init/result.json ]]; then
    cloudtype=$(jq -r .v1.datasource /run/cloud-init/result.json 2>&1)
    jq_exit=$?
    if [[ ${jq_exit} -ne 0 ]]; then
        log_error "Failed to parse cloud-init result.json"
        log_error "jq output: ${cloudtype}"
        exit 1
    fi

    if [[ "${cloudtype}" == "DataSourceEc2Local" ]]; then
        log_info "Not able to calculate job cost on AWS"
        exit 0
    fi
fi

# Activate Python virtual environment
log_info "Activating Python virtual environment..."
if ! lf-activate-venv zipp==1.1.0 python-openstackclient urllib3~=1.26.15; then
    log_error "Failed to activate Python virtual environment"
    exit 1
fi

# Validate required environment variables
if [[ -z "${JOB_NAME:-}" ]]; then
    log_error "Required environment variable JOB_NAME is unset or empty"
    exit 1
fi

# Initialize cost variables
stack_cost=0
cost=0
resource='unknown'

# Get the cost of the OpenStack agents
# The 'stack-cost' file is created when the 'lftools openstack stack cost'
# command is called from 'openstack-stack-delete.sh' script.
if [[ -f stack-cost ]]; then
    log_debug "Contents of stack-cost file:"
    cat stack-cost
    log_info "Retrieving Stack Cost..."

    stack_cost_line=$(grep -F "total: " stack-cost 2>&1) || true
    if [[ -n "${stack_cost_line}" ]]; then
        stack_cost=$(echo "${stack_cost_line}" | awk '{print $2}')
        if [[ -z "${stack_cost}" || ! "${stack_cost}" =~ ^[0-9.]+$ ]]; then
            log_error "Unable to parse stack cost from: ${stack_cost_line}"
            stack_cost=0
        else
            log_info "Stack cost: ${stack_cost}"
        fi
    else
        log_error "Unable to find 'total:' line in stack-cost file, continuing with stack_cost=0"
    fi
else
    log_info "No stack-cost file found"
fi

# Retrieve the current uptime (in seconds)
# Convert to integer by truncating fractional part and round up by one
if [[ ! -f /proc/uptime ]]; then
    log_error "/proc/uptime not found - cannot determine instance uptime"
    exit 1
fi

uptime=$(awk '{print int($1 + 1)}' /proc/uptime)
if [[ -z "${uptime}" || ! "${uptime}" =~ ^[0-9]+$ ]]; then
    log_error "Failed to parse uptime from /proc/uptime"
    exit 1
fi
log_info "Instance uptime: ${uptime}s"

# Retrieve instance type from metadata service
# EC2 and OpenStack have similar instance metadata APIs at this IP
# AWS docs: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
# Nova docs: https://docs.openstack.org/nova/latest/user/metadata.html
METADATA_URL="http://169.254.169.254/latest/meta-data/instance-type"

if ! curl_with_retry "${METADATA_URL}" "instance metadata"; then
    log_info "Unable to retrieve instance type from metadata service"
    log_info "Skipping job cost calculation"
    exit 0
fi
instance_type="${CURL_RESPONSE}"

if [[ -z "${instance_type}" ]]; then
    log_error "Instance type returned from metadata service is empty"
    exit 1
fi
log_info "Instance type: ${instance_type}"

# Retrieve pricing information from Vexxhost pricing API
PRICING_URL="https://pricing.vexxhost.net/v1/pricing/${instance_type}/cost?seconds=${uptime}"

log_info "Retrieving pricing info for: ${instance_type}"
if curl_with_retry "${PRICING_URL}" "Vexxhost pricing API"; then
    json_block="${CURL_RESPONSE}"

    # Parse cost from JSON response
    if parse_json_field "${json_block}" ".cost" "cost"; then
        cost="${JSON_FIELD_VALUE}"
        log_info "Retrieved cost: ${cost}"
    else
        log_error "Failed to parse cost from pricing API response, using default: 0"
        cost=0
    fi

    # Parse resource from JSON response
    if parse_json_field "${json_block}" ".resource" "resource"; then
        resource="${JSON_FIELD_VALUE}"
        log_info "Retrieved resource: ${resource}"
    else
        log_error "Failed to parse resource from pricing API response, using default: unknown"
        resource='unknown'
    fi
else
    log_error "Failed to retrieve pricing information after ${CURL_RETRY_COUNT} attempts"
    if [[ "${FAIL_ON_PRICING_ERROR}" == "true" ]]; then
        log_error "FAIL_ON_PRICING_ERROR is set - failing the build"
        exit 1
    fi
    log_info "Continuing with default values: cost=0, resource=unknown"
    cost=0
    resource='unknown'
fi

# Archive the cost data
archive_dir="${WORKSPACE}/archives/cost"
log_info "Creating archive directory: ${archive_dir}"
if ! mkdir -p "${archive_dir}"; then
    log_error "Failed to create archive directory: ${archive_dir}"
    exit 1
fi

# Set the timestamp in GMT
# This format is readable by spreadsheet and is easily sortable
timestamp=$(TZ=GMT date +'%Y-%m-%d %H:%M:%S')

cost_file="${WORKSPACE}/archives/cost.csv"
log_info "Archiving costs to: ${cost_file}"

# Format and write the cost data
# Fields: JOB_NAME, BUILD_NUMBER, timestamp, resource, uptime, cost, stack_cost, BUILD_RESULT
cost_line=$(printf "%s,%s,%s,%s,%d,%.2f,%.2f,%s\n" \
    "${JOB_NAME:-}" \
    "${BUILD_NUMBER:-}" \
    "${timestamp}" \
    "${resource}" \
    "${uptime}" \
    "${cost}" \
    "${stack_cost}" \
    "${BUILD_RESULT:-}")

if ! echo "${cost_line}" >"${cost_file}"; then
    log_error "Failed to write cost data to: ${cost_file}"
    exit 1
fi

log_info "Successfully archived job cost data"
log_debug "Cost data: ${cost_line}"

exit 0
