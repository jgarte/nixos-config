import os
import re
import subprocess
import sys
import time

from pystdlib.uishim import get_selection, notify

URL_REGEX = "(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]"


def is_valid_url(url):
    return re.search(URL_REGEX, url) is not None


def fetch_tags_cloud():
    tags_cloud_task = subprocess.Popen("buku --np --st",
                                  shell=True, stdout=subprocess.PIPE)
    result = [" ".join(tag.strip().split(" ")[1:-1])
              for tag in tags_cloud_task.stdout.read().decode().split("\n") if tag]
    assert tags_cloud_task.wait() == 0
    return result


bookmark_text_task = subprocess.Popen("xsel -o -b",
                                      shell=True, stdout=subprocess.PIPE)
bookmark_text = bookmark_text_task.stdout.read().decode().strip()
assert bookmark_text_task.wait() == 0
if bookmark_text is not None:
    if not is_valid_url(bookmark_text):
        notify("error", "URL is not valid", urgency=URGENCY_CRITICAL, timeout=5000)
        sys.exit(1)
    result = get_selection([bookmark_text], 'bookmark', font="@wmFontDmenu@")
    if not result:
        notify("OK", "Aborted adding bookmark", timeout=5000)
        sys.exit(1)
    tags_cloud = fetch_tags_cloud()
    bookmark_tags = []
    while True:
        tag = get_selection(tags_cloud, 'add tag', lines=15, font="@wmFontDmenu@")
        if tag:
           bookmark_tags.append(tag)
           tags_cloud.remove(tag)
        else:
           break
    if bookmark_tags:
        os.system(f"buku -a {bookmark_text} {','.join(bookmark_tags)}")
    else:
        os.system(f"buku -a {bookmark_text}")
    notify("Success", f"Bookmark added: {bookmark_text} ({','.join(bookmark_tags)})")
else:
    notify("Error", "No text in clipboard", urgency=URGENCY_CRITICAL)
    sys.exit(1)