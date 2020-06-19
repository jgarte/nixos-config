import os
import subprocess

import dmenu
import redis
from libtmux import Server

hostnames = []

r = redis.Redis(host='localhost', port=6379, db=0)

with open("/etc/hosts", "r") as hosts:
    for host in hosts:
        host_list = list(reversed(host.strip(";\n").split()))
        if host_list:
            hostnames.extend(host_list[:-1])

hostnames = sorted(list(set(hostnames)))

hostname = dmenu.show(hostnames, prompt="host", case_insensitive=True, lines=10)

if hostname == "localhost":
    os.environ["DOCKER_HOST"] = "unix:///var/run/docker.sock"
else:
    os.environ["DOCKER_HOST"] = f"ssh://{hostname}"
    vpn_meta = json.loads(r.get("net/hosts_vpn"))
    host_vpn = vpn_meta.get(host, None)
    if host_vpn:
        vpn_is_up = r.get(f"vpn/{host_vpn}/is_up").decode() == "yes"
        if not vpn_is_up:
            vpn_start_task = subprocess.Popen(f"vpnctl --start {host_vpn}",
                                              shell=True, stdout=subprocess.PIPE)
            assert vpn_start_task.wait() == 0

select_container_task = subprocess.Popen("docker ps --format '{{.Names}}'", shell=True, stdout=subprocess.PIPE)
select_container_result = select_container_task.stdout.read().decode().split("\n")

selected_container = dmenu.show(select_container_result, prompt="container", case_insensitive=True, lines=10)
if not selected_container:
    sys.exit(1)

get_shell_cmd = f"export DOCKER_HOST={os.environ['DOCKER_HOST']} && docker exec -it {selected_container} @defaultContainerShell@"
tmux_server = Server()
tmux_session = tmux_server.find_where({ "session_name": "@tmuxDefaultSession@" })
docker_shell_window = tmux_session.new_window(attach=True, window_name=f"{selected_container} shell",
                                              window_shell=get_shell_cmd)
