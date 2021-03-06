import re
import sys
from urllib.request import urlopen

from bs4 import BeautifulSoup

from pystdlib.uishim import get_selection, notify
from pystdlib import shell_cmd


def is_valid_url(url):
    return re.search("@urlRegexPy@", url) is not None

page_url = shell_cmd("xsel -o -b")
if page_url is not None:
    if is_valid_url(page_url):
        session_name = get_selection([], "save as", lines=1, font="@wmFontDmenu@")
        if not session_name:
            sys.exit(1)

        page_content = urlopen(page_url)
        soup = BeautifulSoup(page_content, "html.parser")
        tags = soup.findAll("a", attrs={"href": re.compile("^https?://")})
        org_content = [f"#+TITLE: {soup.title.string}\n", f"#+PROPERTY: url {page_url}\n"]
        for tag in tags:
            org_content.append(f"* {tag.get('href')}\n")
        with open(f"@firefoxSessionsPath@/{session_name}.org", "w") as f:
            f.writelines(org_content)
        notify("[scrape]", f"Scraped {len(org_content) - 2} links", timeout=5000)
        for line in org_content:
            print(line)
    else:
        print(page_url)
        notify("[scrape]", "Non-URL content in clipboard, skipping", timeout=5000)

# TODO: add fallback/primary option of checking current window title for url regexp and treat any (first)
# match as url to process
