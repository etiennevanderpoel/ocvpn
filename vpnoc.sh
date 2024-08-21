#!/bin/bash

# Linux VPN script using openvpn and openconnect
#   : open a VPN connection   -o
#   : close a VPN connection  -c
#   : check VPN status        -s
# 
# Etienne van der Poel
#   : 2024-08-18
#
# modified from Jeff Stern's scripts at:
#       http://www.socsci.uci.edu/~jstern/uci_vpn_ubuntu/ubuntu-openconnect-uci-instructions.html
#
#   : combined the UP and DOWN scripts and added a STATUS check
#   : uses options passed to script to choose action
#       -o open a connection
#       -c close the connection
#       -s status check
#   : made script more generic, add options to pass ID, URL, VPN group
#       -u username
#       -g VPN group name
#       -n VPN URL
#   : updated syntax: backticks to ${}, ifconfig to ip
#   : find where the executables are instead of explicitly hardcoding the location
#   : add checks for live connection to timeout
#   : add checks for existing tunnel



# --<<<START-EDIT>>>------------------------------------------------------------------
# If you want to hard-code the following  you can edit down to the <<<END-EDIT>>> lines
#   : add URL, ID, GRP here
#   : otherwise, pass as options to the script
# --<<<START-EDIT>>>------------------------------------------------------------------


# VPNURL
# where you will be connecting to for your VPN services
#VPNURL="https://vpn.site.com"
VPNURL=""

# VPNUSER
# network ID
#VPNUSER="user"
VPNUSER=""

# VPNGRP
# VPN group name
#VPNGRP="SiteVPN"
VPNGRP=""

# PW and PIN
# your network ID password and 2FA PIN
# (optional) 
#   : NOT a good idea to store the password here!!
#   : Jeff suggests using .authinfo - not done here
#   : script will expect you to type the password, but will NOT show a prompt
#       latest version of VPN also does 2FA requiring a PIN input after the PW
#           again no prompt
#   : PIN put here simply as a reminder that there is such a thing; not used
PW=""
PIN=""

# --<<<END-EDIT>>>--------------------------------------------------------------
# (you should not have to change or edit anything below here)
# --<<<END-EDIT>>>--------------------------------------------------------------



# EXECUTABLE LOCATIONS
# find where bin is located in path
OPENVPNEXE=$(command -v openvpn)
OPENCONNECTEXE=$(command -v openconnect)
IPEXE=$(command -v ip)

# find openvpn location
if [[ -z "$OPENVPNEXE" ]]; then
    echo "ERROR: openvpn is not installed or not found in the PATH." >&2
    exit 1
fi

# find openconnect location
if [[ -z "$OPENCONNECTEXE" ]]; then
    echo "ERROR: openconnect is not installed or not found in the PATH." >&2
    exit 1
fi

# find ip location
if [[ -z "$IPEXE" ]]; then
    echo "ERROR: ip is not installed or not found in the PATH." >&2
    exit 1
fi

# find vpnc-script location
if [[ -f "/usr/share/vpnc-scripts/vpnc-script" ]]; then
    VPNSCRIPT="/usr/share/vpnc-scripts/vpnc-script"
elif [[ -f "/etc/openconnect/vpnc-script" ]]; then
    VPNSCRIPT='/etc/openconnect/vpnc-script'
else
  echo "ERROR: vpnc-script is not installed or not found in the PATH." >&2
  exit 1
fi

# Interface to check
VPN_INTERFACE="tun1"

# Log file for status check
OCLOG="/tmp/oclog.txt"

# become root if not already
if [ ${EUID} != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi


# timestamp
echo "$(date): Script ${0} starting." >> "${OCLOG}" 2>&1

# Clean up any existing VPN interfaces
if ${IPEXE} link show ${VPN_INTERFACE} > /dev/null 2>&1; then
    echo "$(date): Removing existing ${VPN_INTERFACE} interface." >> "${OCLOG}" 2>&1
    ${OPENVPNEXE} --rmtun --dev ${VPN_INTERFACE} >> "${OCLOG}" 2>&1
fi

# Get PID of openconnect process if it is running
pidofoc=$(pidof openconnect)


# Function to open the VPN connection
open_vpn() {
    echo "Opening ${VPNGRP} connection..."
    if [ -z "$pidofoc" ]; then
        echo "$(date): No openconnect process found. Proceeding to create VPN connection." | tee -a ${OCLOG}
    
        # first job: make a copy of /etc/resolv.conf since this file gets
        # replaced by vpnc-script and needs to be restored by close_vpn
        # when vpn is shut back down
        cp /etc/resolv.conf /tmp/resolv.conf.tmp
    
        # Check if tun1 interface exists and remove it if it does
        numtuns=$(${IPEXE} link show ${VPN_INTERFACE} 2> /dev/null | wc -l)
        if [ "${numtuns}" -gt 0 ]; then
            echo "$(date): ${VPN_INTERFACE} interface exists without an openconnect process. Removing existing interface." | tee -a ${OCLOG}
            ${OPENVPNEXE} --rmtun --dev ${VPN_INTERFACE} >> "${OCLOG}" 2>&1
        fi
    
        # Create the tunnel interface
        numtuns=$(${IPEXE} link show ${VPN_INTERFACE} 2> /dev/null | wc -l)
        if [ "${numtuns}" -eq 0 ]; then
            echo "$(date): Creating ${VPN_INTERFACE} openvpn interface." >> "${OCLOG}" 2>&1
            ${OPENVPNEXE} --mktun --dev ${VPN_INTERFACE} >> "${OCLOG}" 2>&1
            # check successful, else quit
            if [ $? -eq 0 ]; then
                echo "$(date): ${VPN_INTERFACE} openvpn interface created successfully." >> "${OCLOG}" 2>&1
                cp /tmp/resolv.conf.tmp /tmp/resolv.conf
            else
                echo "$(date): Problems creating ${VPN_INTERFACE} openvpn interface. Exiting 1." >> "${OCLOG}" 2>&1
                exit 1
            fi
        else
            echo "$(date): ${VPN_INTERFACE} openvpn interface already exists. Exiting." >> "${OCLOG}" 2>&1
            exit 0
        fi
    
        # Turn on the VPN interface. 
        # If it is already on, it won't do harm.
        echo "$(date): Turning ${VPN_INTERFACE} on." >> "${OCLOG}" 2>&1
        ${IPEXE} link set ${VPN_INTERFACE} up >> "${OCLOG}" 2>&1
        if [ $? -eq 0 ]; then
            echo "$(date): ${VPN_INTERFACE} on." >> "${OCLOG}" 2>&1
        else
            echo "$(date): Problems turning ${VPN_INTERFACE} on. Exiting 1." >> "${OCLOG}" 2>&1
            exit 1
        fi
    
        # Start openconnect if it's not already running
        echo "$(date): Running openconnect." >> "${OCLOG}" 2>&1
        if [ -z "$PW" ]; then
            ${OPENCONNECTEXE} -b -s "${VPNSCRIPT}" \
                            --user="${VPNUSER}" \
                            --authgroup="${VPNGRP}" \
                            --interface="${VPN_INTERFACE}" \
                            "${VPNURL}" >> "${OCLOG}" 2>&1
        else
            echo "${PW}" | ${OPENCONNECTEXE} -b -s "${VPNSCRIPT}" \
                                --user="${VPNUSER}" \
                                --passwd-on-stdin \
                                --authgroup="${VPNGRP}" \
                                --interface="${VPN_INTERFACE}" \
                                "${VPNURL}" >> "${OCLOG}" 2>&1
        fi

        # give a bit of time for the connection to establish
        sleep 3
    else
        echo "$(date): openconnect process is already running with PID: ${pidofoc}. Not initiating a new session." | tee -a ${OCLOG}
    fi

    # Recheck if openconnect process is running
    pidofoc=$(pidof openconnect)
    if [ -z "$pidofoc" ]; then
        echo "$(date): openconnect process failed to start or has exited unexpectedly." >> "${OCLOG}" 2>&1
        exit 1
    fi
    
    # Check for NO-CARRIER state and ensure interface is up
    timeout=10
    while [[ ${timeout} -gt 0 ]]; do
        carrier_state=$(${IPEXE} link show ${VPN_INTERFACE} | grep "state UP")
        if ${IPEXE} address show ${VPN_INTERFACE} | grep -q "inet" && [ -n "$carrier_state" ]; then
            echo "$(date): ${VPN_INTERFACE} is up and carrier state is good." >> "${OCLOG}" 2>&1
            break
        fi
        sleep 1
        timeout=$((timeout - 1))
    done

    if [[ $timeout -eq 0 ]]; then
        echo "$(date): VPN interface ${VPN_INTERFACE} did not come up or is in NO-CARRIER state within the timeout." >> "${OCLOG}" 2>&1
        exit 1
    fi

    # Show connected
    echo "${VPNGRP} connected"
    ${IPEXE} address show ${VPN_INTERFACE}
    
    # and log same info
    ${IPEXE} address show ${VPN_INTERFACE} &>> "${OCLOG}"

    # end script
    echo "$(date): ${0} script ending successfully." >> "${OCLOG}" 2>&1
}




# Function to close the VPN connection
close_vpn() {
    echo "Closing ${VPNGRP} connection..."
    # Shut down openconnect process if one (or more) exists
    # use OC PIDs to kill them
    if [ "${pidofoc}" != "" ]; then
        echo "$(date): Stopping openconnect PID ${pidofoc}." >> "${OCLOG}" 2>&1
        kill -9 ${pidofoc} >> "${OCLOG}" 2>&1
    else
        echo "$(date): No openconnect found. (That's okay.) Continuing." >> "${OCLOG}" 2>&1
    fi
    
    # Close down the tun1 openvpn tunnel
    ${OPENVPNEXE} --rmtun --dev ${VPN_INTERFACE} &>> "${OCLOG}"
    
    # finally, restore the /tmp/resolv.conf
    if [[ -f /tmp/resolv.conf ]]; then
        cp /tmp/resolv.conf /etc
    fi
    
    # Show disconnected
    echo "${VPNGRP} disconnected"

    # end script
    echo "$(date): ${0} script ending successfully." >> "${OCLOG}" 2>&1
}




# Function to check the VPN connection status
check_vpn() {
    echo "Checking ${VPNGRP} connection status..."
    if [ -z "$pidofoc" ]; then
        echo "$(date): openconnect process is not running." | tee -a ${OCLOG}
        exit 1
    else
        echo "$(date): openconnect process is running with PID: ${pidofoc}." | tee -a ${OCLOG}
    fi
    
    # Check if the interface is up
    ${IPEXE} link show ${VPN_INTERFACE} > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "$(date): ${VPNGRP} interface ${VPN_INTERFACE} is up." | tee -a ${OCLOG}
    else
        echo "$(date): ${VPNGRP} interface ${VPN_INTERFACE} is down." | tee -a ${OCLOG}
        exit 1
    fi
    
    echo "${VPNGRP} status check completed successfully."

    # end script
    echo "$(date): ${0} script ending successfully." >> "${OCLOG}" 2>&1
}




# Use basename to get only the script name without the full path
SCRIPT_NAME=$(basename "$0")

# Parsing command-line options
while getopts ":ocsu:g:n:w:" option; do
    case $option in
        o) 
            ACTION="open"
            ;;
        c)
            ACTION="close"
            ;;
        s)
            ACTION="status"
            ;;
        u) 
            VPNUSER=$OPTARG
            ;;
        g)
            VPNGRP=$OPTARG
            ;;
        n)
            VPNURL=$OPTARG
            ;;
        \?)
        echo "No action specified or invalid option used."
        echo "Usage: ${SCRIPT_NAME} [-o open] [-c close] [-s status] [-u user] [-g group] [-n url]"            ;;
    esac
done

# Shift off the options and optional --.
shift $((OPTIND - 1))

# Validate required options only if the action is "open"
if [[ "$ACTION" == "open" ]]; then
    if [[ -z "$VPNUSER" || -z "$VPNGRP" || -z "$VPNURL" ]]; then
        echo "ERROR: Missing required options for opening the VPN connection."
        echo "The following options must be provided when using -o:"
        echo "  -u \"user\" = network ID"
        echo "  -g \"group\" = VPN group name"
        echo "  -n \"url\" = VPN connection URL"
        echo "Usage: ${SCRIPT_NAME} [-s] [-c] [-o -u \"user\" -g \"group\" -n \"url\"]"
        exit 1
    fi
fi

# Execute the action specified by the options
case $ACTION in
    "open")
        open_vpn
        ;;
    "close")
        close_vpn
        ;;
    "status")
        check_vpn
        ;;
    *)
        echo "No action specified or invalid option used."
        echo "Usage: ${SCRIPT_NAME} [-s] [-c] [-o -u \"user\" -g \"group\" -n \"url\"]"
        echo "  -o = open VPN connection"
        echo "  -c = close VPN connection"
        echo "  -s = check VPN status"
        echo "  -u \"user\" = network ID"
        echo "  -g \"group\" = VPN group name"
        echo "  -n \"url\" = VPN connection URL"
        exit 1
        ;;
esac


# END SCRIPT
