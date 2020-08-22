import json
import os
import subprocess
import sys

from pystdlib.uishim import get_selection, notify
import redis
from libtmux import Server


service_modes = [
    "status",
    "logs"
]


r = redis.Redis(host='localhost', port=6379, db=0)
extra_hosts_data = json.loads(r.get("net/extra_hosts"))

swarm_meta = json.loads(r.get("virt/swarm_meta"))
swarm = get_selection(swarm_meta.keys(), "swarm", case_insensitive=True, lines=5, font="@wmFontDmenu@")
if not swarm:
    notify("[virt]", "No swarm selected")
    sys.exit(0)

swarm_host = swarm_meta[swarm]
os.environ["DOCKER_HOST"] = f"ssh://{swarm_host}"
host_meta = extra_hosts_data.get(swarm_host, None)
if not host_meta:
    notify("[docker]", f"Host '{swarm_host}' not found", urgency=URGENCY_CRITICAL, timeout=5000)
    sys.exit(1)

host_vpn = host_meta.get("vpn", None)
if host_vpn:
    vpn_start_task = subprocess.Popen(f"vpnctl --start {host_vpn}",
                                      shell=True, stdout=subprocess.PIPE)
    assert vpn_start_task.wait() == 0

select_service_task = subprocess.Popen("docker service ls --format '{{.Name}} | {{.Mode}} | {{.Replicas}} | {{.Image}}'",
                                       shell=True, stdout=subprocess.PIPE)
select_service_result = select_service_task.stdout.read().decode().split("\n")

selected_service_meta = get_selection(select_service_result, "service", case_insensitive=True, lines=10, font="@wmFontDmenu@")
selected_service_name = selected_service_meta.split("|")[0].strip()
selected_mode = get_selection(service_modes, "show", case_insensitive=True, lines=5, font="@wmFontDmenu@")

get_service_status_task = subprocess.Popen(f"docker service ps {selected_service_name}",
                                           shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
get_service_status_result = get_service_status_task.stdout.read().decode()

if selected_mode == "status":
    with open("/tmp/docker_swarm_service_info", "w") as f:
        f.write(get_service_status_result)
    show_dialog_task = subprocess.Popen("yad --filename /tmp/docker_swarm_service_info --text-info",
                                        shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    show_dialog_task.wait()
    os.remove("/tmp/docker_swarm_service_info")
elif selected_mode == "logs":
    service_running_tasks_items = [task.split() for task in get_service_status_result.split("\n")
                                   if "Running" in task]
    task_mappings = dict([(task_meta[1], task_meta[0]) for task_meta in service_running_tasks_items])
    selected_task = get_selection(list(task_mappings.keys()) + [selected_service_name], "task", case_insensitive=True, lines=10, font="@wmFontDmenu@")
    if not selected_task:
        sys.exit(1)

    session_name =  host_meta.get("tmux", "@tmuxDefaultSession@")
    task_or_service = task_mappings.get(selected_task) if selected_task in task_mappings else selected_service_name
    show_log_cmd = f"DOCKER_HOST={os.environ['DOCKER_HOST']} docker service logs --follow {task_or_service}"
    tmux_server = Server()
    tmux_session = tmux_server.find_where({ "session_name": session_name })
    docker_task_log_window = tmux_session.new_window(attach=True, window_name=f"{selected_task} logs",
                                                     window_shell=show_log_cmd)