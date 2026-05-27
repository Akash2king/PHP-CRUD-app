#!/bin/bash
# Load KEY=VALUE pairs from a .env file (comments and blank lines ignored).

load_dotenv() {
    local env_file="$1"

    if [ ! -f "${env_file}" ]; then
        return 0
    fi

    echo "Loading environment from ${env_file}"

    while IFS= read -r line || [ -n "${line}" ]; do
        case "${line}" in
            ''|\#*) continue ;;
        esac

        local key="${line%%=*}"
        local value="${line#*=}"
        key="$(echo "${key}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        value="$(echo "${value}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")"
        [ -z "${key}" ] && continue
        export "${key}=${value}"
    done < "${env_file}"
}

load_dotenv_files() {
    load_dotenv /run/config/.env
    load_dotenv /var/www/html/.env
    if [ -n "${ENV_FILE}" ] && [ "${ENV_FILE}" != "/run/config/.env" ] && [ "${ENV_FILE}" != "/var/www/html/.env" ]; then
        load_dotenv "${ENV_FILE}"
    fi
}
