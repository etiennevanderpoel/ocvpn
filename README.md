# ocvpn

Linux VPN client management *bash* script using OpenConnect and OpenVPN

These script(s) are wrappers to openconnect, openvpn, and vpnc-script, It handles the details in the background. Users can open, close, and check the status of a VPN connection with a few command-line options, or with another set of very simple wrapper scripts (ocvpnup and ocvpndown) that you only need edit once for each VPN, so that you can run these without having to use options.

### Features:

- Open: Establish a secure VPN connection using openconnect. Works where 2FA is required as well.
- Close: Safely close an active VPN connection and restore network settings.
- Status: Check if a VPN connection is active and if the associated network interface is up.
- Customisable: All 3 scripts can be edited for a specific user, VPN group, and VPN URL. Ideally you should edit *ocvpnup* and *ocvpndown*, so that you only need to run these two         scripts. You can edit the main *ocvpn* script to hardcode the user, group and URL, and then call it with *ocvpn -o*.
- Cleanup: attempts to do a clean VPN setup and teardown.

### Note on prompts:

- The script shows some output, but will not prompt you for a password or the 2FA input. It may prompt you for your *sudo* password. 

### Usage:

ocvpn 
    -o: Open a VPN connection
    -c: Close the VPN connection
    -s: Check the current VPN status
    -u [username]: Specify the VPN username
    -g [group]: Specify the VPN group name
    -n [url]: Specify the VPN server URL

These scripts should (hopefully) be useful to Linux users who frequently need to connect to a VPN service that requires 2FA.

(Based on a script written by Jeff Stern - [https://sites.socsci.uci.edu/~jstern/uci_vpn_ubuntu/ubuntu-openconnect-uci-instructions.html](https://sites.socsci.uci.edu/~jstern/uci_vpn_ubuntu/ubuntu-openconnect-uci-instructions.html))

## For novice Linux users

You need to place these scripts somewhere in your $PATH (such as ~/.local/bin). Rename (or copy) them to ocvpn, ocpnup, ocvpndown (without the .sh extension). Do the following in a terminal:

	chmod +x ocvpn
	chmod +x ocvpnup
	chmod +x ocvpndown

or change the *permissions* via the *File Properties* window to make these executable.

Edit the ocvpnup script:

    USER should be your network username
    VPNGROUP should be the VPN group name - ask your IT/ICT people
    VPNURL should be VPN url - often something like "https://vpn.company.com" - ask your IT/ICT people

In a terminal run:

    ocvpnup

This may prompt you for your sudo password. After that you won't see any prompts. Type (or copy-paste) your password. Wait for the 2FA PIN (if there is one). Type that. After 30 seconds max, you should get a response to show you are connected.

To close the VPN, run:

    ocvpndown



