# ocvpn

Linux VPN client management *bash* script using OpenConnect and OpenVPN

These script(s) are wrappers to openconnect, openvpn, and vpnc-script, It handles the details in the background. Users can open, close, and check the status of a VPN connection with a few command-line options, or with another set of very simple wrapper scripts (ocvpnup and ocvpndown).

### Features:

- Open: Establish a secure VPN connection using openconnect. Works where 2FA is required as well.
- Close: Safely close an active VPN connection and restore network settings.
- Status: Check if a VPN connection is active and if the associated network interface is up.
- Customisable: All 3 scripts can be edited for a specific user, VPN group, and VPN URL. Ideally you should edit *ocvpnup* and *ocvpndown*, so that you only need to run these two         scripts. You can edit the main *ocvpn* script to hardcode the user, group and URL, and then call it with *ocvpn -o*.
- Cleanup: attempts to do a clean VPN setup and teardown.

### Note on prompts:

- The script shows some output, but will not prompt you for a password or the 2FA input. It may prompt you for your *sudo* password. 

### Usage:

    -o: Open a VPN connection
    -c: Close the VPN connection
    -s: Check the current VPN status
    -u [username]: Specify the VPN username
    -g [group]: Specify the VPN group name
    -n [url]: Specify the VPN server URL

These scripts should (hopefully) be useful to Linux users who frequently need to connect to a VPN service that requires 2FA.

(Based on a script written by Jeff Stern - [https://sites.socsci.uci.edu/~jstern/uci_vpn_ubuntu/ubuntu-openconnect-uci-instructions.html](https://sites.socsci.uci.edu/~jstern/uci_vpn_ubuntu/ubuntu-openconnect-uci-instructions.html))
