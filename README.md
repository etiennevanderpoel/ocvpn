# ocvpn
Linux VPN client management script using OpenConnect and OpenVPN

These script(s) are wrappers to openconnect, openvpn, and vpnc-script, It handles the details in the background. Users can open, close, and check the status of a VPN connection with a few command-line options, or with another set of very simple wrapper scripts (ocvpnup and ocvpndown).

Features:

    Open VPN Connection: Establish a secure VPN connection using openconnect, with 'support' for two-factor authentication (2FA).
    Close VPN Connection: Safely close an active VPN connection and restore network settings.
    Check VPN Status: Check if a VPN connection is active and if the associated network interface is up.
    Customisable: the scripts *ocvpnup* and *ocvpndown* can be edited for a specific user, VPN group, and VPN URL, so that you only need to call these scripts (without options) open and close the VPN connection.
    Network interface management: attempts to do a clean VPN setup and teardown.
    The latest (2023+) versions of VPN servers also use 2FA. This script handles this as far as it could be tested.

Note on prompts:

    The script shows some output, but will not prompt you for a password or the 2FA input. It may prompt you for your *sudo* password. 

Usage:

    -o: Open a VPN connection
    -c: Close the VPN connection
    -s: Check the current VPN status
    -u [username]: Specify the VPN username
    -g [group]: Specify the VPN group name
    -n [url]: Specify the VPN server URL

These script should (hopefully) be useful to Linux users who frequently need to connect to a VPN service that requires 2FA.
