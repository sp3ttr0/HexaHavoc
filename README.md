# HexaHavoc

**HexaHavoc** is an automation script designed to facilitate an IPv6 DNS takeover attack. It leverages **mitm6** and **impacket-ntlmrelayx** within a **tmux** session to enable network administrators and penetration testers to conduct research and test IPv6 DNS vulnerabilities.

This script performs a man-in-the-middle attack via IPv6 rogue DNS server, allowing for NTLM relay attacks and DNS takeover simulations.


## Prerequisites

Before running this script, ensure that the following tools are installed:

- **tmux**: For managing multiple terminal sessions.
- **mitm6**: To facilitate IPv6 DNS takeover attacks.
- **impacket**: For NTLM relay and credential dumping.

Install them if they are not available in your environment.

## Usage:
```bash
./hexahavoc.sh -d <target_domain> -t <target_ip> [-i <interface>] [-v]
```

## Options
```
-d <target_domain>: Specifies the target domain for the DNS takeover.
-t <target_ip>: Specifies the target IP address to relay NTLM authentication.
-i <interface>: (Optional) Specifies the network interface to use. Defaults to eth0.
-l	(Optional) Loot output directory where captured hashes and credentials will be saved. Defaults to dumps/.
-v: (Optional) Enables verbose logging for debugging.
```

## Example
```bash
./hexahavoc.sh -d example.com -t 192.168.1.10 -i eth1 -l /tmp/loot -v
```

## Important Notes
- Use Responsibly: This script is intended solely for authorized testing and research purposes. Always ensure that you have explicit permission to perform penetration testing or security assessments on the target network.
- IPv6 Requirement: This attack only works in environments with IPv6 enabled. Ensure your target network is IPv6-enabled for successful execution.

## Disclaimer
This tool is provided for educational and authorized security testing purposes only. Unauthorized use may violate laws and regulations. The authors and contributors of this tool are not responsible for any misuse or damage. By using this script, you accept full responsibility for your actions.
