#!/bin/sh

usage() {
    echo "Usage: letsencrypt [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "    new            Issue a new certificate for -d|--domain DOMAIN.TLD [-d|--domain DOMAIN.TLD]..."
    echo "    revoke         Revoke the certificate for -d|--domain DOMAIN.TLD"
    echo "    register       Create a Let's Encrypt ACME account"
    echo "    certificates   Display information about certificates you have from Certbot"
    echo "    delete         Delete a certificate"
    echo "    renew          Renew all previously obtained certificates that are near expiry"
    exit 0
}

ensure_credentials_file_exists() {
    cloudflare_secret_path="/tmp/cloudflare.ini"
    if [ ! -f $cloudflare_secret_path ]; then
        echo "dns_cloudflare_api_token=${CLOUDFLARE_API_TOKEN:?}" > $cloudflare_secret_path
        chmod 0600 $cloudflare_secret_path
    fi
}

prepare_command_options() {
    while [ $# -gt 0 ]; do
        key="$1"
        case $key in
            register|new|renew|revoke|delete|certificates)
                command="$1"
                shift
                ;;
            -d|--domain)
                option="-d"
                if [ "${command}" = "revoke" ]; then
                    option="--cert-name"
                fi
                domains="${domains} ${option} $2"
                shift
                shift
                ;;
            -h|--help|help)
                usage
                ;;
            *)
                echo "[!] INVALID OPTION ${1}"
                echo
                usage
                ;;
        esac
    done
}

command=""
domains=""
prepare_command_options "$@"

if [ -z "${command}" ]; then
    usage
fi

case $command in
    register)
        eval "certbot register -m ${EMAIL_ADDRESS:?} --agree-tos --no-eff-email"
        ;;
    new)
        if [ -z "${domains}" ]; then
            usage
        fi
        ensure_credentials_file_exists
        eval "certbot certonly \
            --dns-cloudflare \
            --dns-cloudflare-credentials $cloudflare_secret_path \
            ${domains}"
        ;;
    renew)
        eval "certbot renew"
        ;;
    revoke)
        if [ -z "${domains}" ]; then
            usage
        fi

        eval "certbot revoke ${domains}"
        ;;
    delete)
        eval "certbot delete"
        ;;
    certificates)
        eval "certbot certificates"
        ;;
esac
