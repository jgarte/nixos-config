import subprocess
import sys

from libtmux import Server
from pystdlib.uishim import get_selection, notify


keyword_task = subprocess.Popen("xsel -o -b", shell=True, stdout=subprocess.PIPE)
keyword_text = keyword_task.stdout.read().decode().strip()

keyword_result = None
if keyword_text:
    keyword_result = get_selection([keyword_text], 'keyword', font="@wmFontDmenu@")
else:
    keyword_result = get_selection([], 'keyword', font="@wmFontDmenu@")

if not keyword_result:
    notify("[search repos]", "no keyword provided", urgency=URGENCY_CRITICAL, timeout=5000)
    sys.exit(1)

search_repos_task = subprocess.Popen(f"fd -t d -d 4 {keyword_result} @searchReposRoot@",
                                     shell=True, stdout=subprocess.PIPE)
search_repos_result = search_repos_task.stdout.read().decode().strip().split("\n")

selected_repo = get_selection(search_repos_result, 'repo', case_insensitive=True, lines=10, font="@wmFontDmenu@")
if not selected_repo:
    notify("[search repos]", "no repository selected", timeout=5000)
    sys.exit(0)

tmux_server = Server()
tmux_session = tmux_server.find_where({ "session_name": "@tmuxDefaultSession@" })
repo_window = tmux_session.new_window(attach=True, window_name=selected_repo.split("/")[-1],
                                      start_directory=selected_repo)

open_emacs_frame_task = subprocess.Popen(f"emacsclient -c -a '' {selected_repo}",
                                         shell=True, stdout=subprocess.PIPE)