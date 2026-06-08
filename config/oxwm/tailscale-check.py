import re
import subprocess
import sys

# machineName = "omarchy-itx"
machineName = sys.argv[1]
activeSystems = []
ip, name, user, opSystem, status = [], [], [], [], []
n = subprocess.run(["tailscale status"], text=True, capture_output=True, shell=True)
output = n.stdout
if n.stdout == "Tailscale is stopped.\n":
    print("Tailscale Down")
else:
    table = output.splitlines(True)
    i = 0
    for i in range(len(table)):
        text = table[i]
        if text[0] != "1":
            i += 1
        else:
            sepText = re.findall(r"\S+", text)
            ip.insert(i, sepText[0])
            name.insert(i, sepText[1])
            user.insert(i, sepText[2])
            opSystem.insert(i, sepText[3])
            status.insert(i, sepText[4])
            i += 1
    for i in range(len(status)):
        if ((status[i] == "-") or (status[i] == "active;")) and (
            name[i] != machineName
        ):
            activeSystems.append(name[i])
            i += 1
        else:
            i += 1
    print(" | ".join(activeSystems))
