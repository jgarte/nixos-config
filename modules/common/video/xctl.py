import argparse
import json
import os
import subprocess
import sys

from ewmh import EWMH
import dmenu

profiles = []


def get_fingerprint():
    get_edids_task = subprocess.Popen("xrandr --prop", shell=True,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    result = get_edids_task.wait()
    if result != 0:
        return None
    output = get_edids_task.stdout.read().decode().strip().split("\n")

    edids_map = {}
    head = None
    edid = None
    for i, line in enumerate(output):
        if " connected " in line:
            head = line.split(" ")[0]
        if "EDID:" in line:
            edid = "".join([s.strip() for s in output[i+1:i+9]])
        if head and edid:
            edids_map[head] = edid
            head = None
            edid = None
    return edids_map

parser = argparse.ArgumentParser(description="Manage XRandR-related activities.")
parser.add_argument("--switch", dest="switch_profile", action="store_true",
                    default=False, help="Switch autorandr profile")
parser.add_argument("--fingerprint", dest="get_fingerprint", action="store_true",
                    default=False, help="Get screens fingerprint (name + EDID)")
parser.add_argument("--apptraits", dest="get_apptraits", action="store_true",
                    default=False, help="Get screens fingerprint (name + EDID)")
# TODO: add orthogonal output format selection
# TODO: consider adding option for dmenu + yad selection/output

args = parser.parse_args()

if args.switch_profile:
    for root, dirs, files in os.walk("@autorandrProfiles@"):
        for dir in dirs:
            if not dir.endswith(".d"):
                profiles.append(dir)

    result = dmenu.show(profiles, prompt='profile', lines=5)
    if result:
        os.system("autorandr --load {0}".format(result))
elif args.get_fingerprint:
    print(json.dumps({"fingerprint": get_fingerprint()}, indent=2))
elif args.get_apptraits:
    ewmh = EWMH()
    UTF8_STRING = ewmh.display.intern_atom('UTF8_STRING')
    STRING = ewmh.display.intern_atom('STRING')
    NET_WM_NAME = ewmh.display.intern_atom('_NET_WM_NAME')
    WM_WINDOW_ROLE = ewmh.display.intern_atom('WM_WINDOW_ROLE')

    windows = ewmh.getClientList()
    for window in windows:
        meta = []
        title = window.get_full_text_property(NET_WM_NAME, UTF8_STRING)
        role = window.get_full_text_property(WM_WINDOW_ROLE, STRING)
        instance, _class = window.get_wm_class()
        meta.append("class=\"{0}\"".format(_class))
        meta.append("instance=\"{0}\"".format(instance))
        if title:
            meta.append("title=\"{0}\"".format(title))
        if role:
            meta.append("role=\"{0}\"".format(role))
        print("[{0}]".format(" ".join(meta)))
    ewmh.display.flush()