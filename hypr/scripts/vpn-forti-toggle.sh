#!/usr/bin/env python3
import os
import pty
import re
import select
import subprocess
import sys
import time

CONF = "/etc/openfortivpn/pssn.conf"

def notify_vpn(title, body, icon="network-vpn", timeout=3000):
    subprocess.run([
        "notify-send",
        "-t", str(timeout),
        "-i", icon,
        "-h", "boolean:transient:true",
        "-h", "string:x-canonical-private-synchronous:vpn_notif",
        title, body
    ])

# 1. If already connected -> Disconnect immediately
if subprocess.run(["pgrep", "-x", "openfortivpn"], capture_output=True).returncode == 0:
    subprocess.run(["sudo", "pkill", "-SIGTERM", "openfortivpn"])
    notify_vpn("FortiVPN", "Disconnected from PSSN.", "network-vpn", 2500)
    subprocess.run(["pkill", "-RTMIN+8", "waybar"])
    sys.exit(0)

# 2. Preflight DNS check
try:
    with open(CONF, "r") as f:
        for line in f:
            m = re.match(r"^\s*host\s*=\s*(.+)$", line)
            if m:
                host = m.group(1).strip()
                res = subprocess.run(["getent", "hosts", host], capture_output=True, timeout=2)
                if res.returncode != 0:
                    notify_vpn("FortiVPN Error", f"Cannot resolve {host}.\nDNS/network blocked.", "dialog-error", 5000)
                    sys.exit(1)
                break
except Exception:
    pass

notify_vpn("FortiVPN", "Connecting to gateway...", "network-vpn", 3000)

# 3. Create virtual PTY and spawn openfortivpn headlessly
master, slave = pty.openpty()
proc = subprocess.Popen(
    ["sudo", "openfortivpn", "-c", CONF],
    stdin=slave,
    stdout=slave,
    stderr=slave,
    close_fds=True
)
os.close(slave)

# 4. Wait for OTP dispatch
output = ""
otp_requested = False
start_time = time.time()

while time.time() - start_time < 20:
    if proc.poll() is not None:
        break
    r, _, _ = select.select([master], [], [], 0.3)
    if r:
        try:
            chunk = os.read(master, 1024).decode("utf-8", errors="ignore")
            output += chunk
            lower = output.lower()
            if "two-factor" in lower or "verification code" in lower or "otp" in lower or "token:" in lower:
                otp_requested = True
                break
        except OSError:
            break

if not otp_requested:
    proc.poll()
    err_lines = [l for l in output.strip().splitlines() if l.strip()]
    err = err_lines[-1] if err_lines else "Gateway did not trigger OTP."
    notify_vpn("FortiVPN Error", err, "dialog-error", 5000)
    subprocess.run(["sudo", "pkill", "-SIGTERM", "openfortivpn"])
    sys.exit(1)

# 5. Zenity OTP Dialog
zen = subprocess.run(
    ["zenity", "--entry", "--title=FortiVPN 2FA", "--text=Enter 2FA Code received in Gmail:", "--hide-text"],
    capture_output=True,
    text=True
)

otp_code = zen.stdout.strip()
if not otp_code or zen.returncode != 0:
    subprocess.run(["sudo", "pkill", "-SIGTERM", "openfortivpn"])
    notify_vpn("FortiVPN", "Connection cancelled.", "dialog-warning", 2500)
    sys.exit(0)

# 6. Pipe OTP code into openfortivpn
os.write(master, (otp_code + "\n").encode())

# 7. Check connection result
success = False
auth_start = time.time()

while time.time() - auth_start < 15:
    if proc.poll() is not None:
        break
    r, _, _ = select.select([master], [], [], 0.3)
    if r:
        try:
            chunk = os.read(master, 1024).decode("utf-8", errors="ignore")
            output += chunk
            lower = output.lower()
            if "tunnel is up and running" in lower or "authenticated." in lower or "interface ppp" in lower:
                success = True
                break
            if "authentication failed" in lower or "error:" in lower:
                break
        except OSError:
            break

if not success:
    err_lines = [l for l in output.strip().splitlines() if "error" in l.lower() or "failed" in l.lower()]
    err = err_lines[-1] if err_lines else "Authentication failed."
    notify_vpn("FortiVPN Failed", err, "dialog-error", 5000)
    subprocess.run(["sudo", "pkill", "-SIGTERM", "openfortivpn"])
    sys.exit(1)

# Connected
notify_vpn("FortiVPN", "Connected to PSSN.", "network-vpn", 3000)
subprocess.run(["pkill", "-RTMIN+8", "waybar"])

proc.wait()
subprocess.run(["pkill", "-RTMIN+8", "waybar"])
