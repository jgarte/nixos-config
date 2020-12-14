import argparse
import fnmatch
import json
import os
from datetime import datetime

from pygit2 import GIT_BRANCH_REMOTE, GIT_DIFF_STATS_FULL, GIT_RESET_HARD, GIT_STATUS_CURRENT, \
    GIT_STATUS_IGNORED, RemoteCallbacks, Repository, Signature, Tag, UserPass
import redis

from pystdlib.uishim import is_interactive, get_selection, log_info, log_error
from pystdlib.passutils import read_entry_raw, extract_specific_line, extract_by_regex
from pystdlib.git import is_repo, get_active_branch, is_main_branch_active, \
    is_main_branch_protected, resolve_remote, get_diff_size, collect_tags, \
    build_auth_callbacks
from pystdlib.xlib import is_idle_enough
from pystdlib import shell_cmd


r = redis.Redis(host='localhost', port=6379, db=0)
credentials_mapping = json.loads(r.get("git/credentials_mapping"))

parser = argparse.ArgumentParser(description="Some git automation")
subparsers = parser.add_subparsers(help="command", dest="cmd")

parser.add_argument("--respect-hooks", dest="respect_hooks", action="store_true",
                    default=False, help="respect pre-{commit/push} hooks")
parser.add_argument("--dry-run", dest="dry_run", action="store_true",
                    default=False, help="Dry run")
parser.add_argument("--remote", dest="remote",
                    default="origin", help="Git remote to work with")

# TODO: consider providing per-repo configuration
parser_wip = subparsers.add_parser("wip", help="Managing WIP")
parser_wip.add_argument("--all", dest="wip_all", action="store_true",
                        default=False, help="Stage and commit all dirty state")
parser_wip.add_argument("--push", dest="wip_push", action="store_true",
                        default=False, help="Push WIP to default upstream")
parser_wip.add_argument("--force", dest="wip_force", action="store_true",
                        default=False, help="Force saving WIP (ignore idle time)")
parser_wip.add_argument("--branch-ref", dest="wip_add_branch_name", action="store_true",
                        default=False, help="Prepend WIP commit message with current branch name")


parser_tags = subparsers.add_parser("tags", help="Working with tags")
parser_tags.add_argument("--sync", dest="tags_sync", action="store_true",
                        default=False, help="Sync tags with selected remote")
parser_tags.add_argument("--checkout", dest="tags_checkout", action="store_true",
                        default=False, help="Interactively select and checkout tag locally")
parser_tags.add_argument("--tag", dest="tags_name", # TODO: think of params restructuring
                         default="", help="Tag to checkout in non-interactive mode")

parser_update = subparsers.add_parser("update", help="Updating WIP branches")
parser_update.add_argument("--op", dest="update_op",
                           default="merge", choices=["fetch", "merge", "rebase", "push"],
                           help="Operation to perform")
parser_update.add_argument("--branch", dest="update_source_branch",
                           default="", help="Branch to get updates from")

args = parser.parse_args()

if not is_repo(os.getcwd()):
    log_error("Not a git repo")
    sys.exit(1)

repo = Repository(os.getcwd() + "/.git")
config = repo.config

remote_url = repo.remotes[args.remote].url
pass_path = None
for glob in credentials_mapping.keys():
    if fnmatch.fnmatch(remote_url, glob):
        pass_path = credentials_mapping[glob]["target"]


# FIXME: user identity (name + email) is not always set at repo level
# that said, we need a SPOT for git identities as used/implemented
# in git-identity emacs package
if args.cmd == "wip":
    if not args.wip_force and not is_idle_enough("@xprintidleBinary@"):
        sys.exit(0)
    diff_size = get_diff_size(repo)
    if diff_size == 0:
        log_info("no changes to commit")
        sys.exit(0)
    if diff_size > @gitWipChangedLinesTreshold@ or args.wip_force:
        branch = f"{repo.references['HEAD'].resolve().split('/')[-1]}: " if args.wip_add_branch_name else ""
        wip_message = f"{branch}WIP {datetime.now().strftime('%a %d/%m/%Y %H:%M:%S')}"
        index = repo.index
        index.read()
        index.add_all()
        index.write()
        # user = repo.default_signature
        name = list(config.get_multivar('user.name'))[0]
        email = list(config.get_multivar('user.email'))[0]
        author = committer = Signature(name, email)
        parents = [repo.references['HEAD'].resolve().target]
        tree = index.write_tree()
        wip_commit = repo.create_commit("HEAD", author, committer, wip_message, tree, parents)
        if args.wip_push:
            if is_main_branch_active(repo) and is_main_branch_protected():
                log_info("main branch is untouchable")
                sys.exit(1)
            else:
                remote = resolve_remote(repo, args.remote)
                remote.push(specs=["HEAD"], callbacks=build_auth_callbacks(repo, pass_path))
elif args.cmd == "tags":
    if args.tags_sync:
        remote = resolve_remote(repo, args.remote)
        if not remote:
            log_error(f"cannot find remote '{args.remote}'")
            sys.exit(1)
        remote.fetch(refspecs=["refs/tags/*:refs/tags/*"])
        remote.push(specs=collect_tags(repo), callbacks=build_auth_callbacks(repo, pass_path))
    elif args.tags_checkout:
        tag_name = args.tags_name
        if is_interactive:
            tag_name = get_selection(collect_tags(repo), "", lines=10, font="@wmFontDmenu@")
        if not tag_name:
            log_error("No tag to checkout")
            sys.exit(1)
        repo.checkout(tag_name)
elif args.cmd == "update":
    source_branch_name = args.update_source_branch if args.update_source_branch != "" else get_active_branch(repo)
    remote = resolve_remote(repo, args.remote)
    if not remote:
        log_error(f"cannot find remote '{args.remote}'")
        sys.exit(1)
    if args.update_op == "fetch":
        remote.fetch(refspecs=[f"refs/heads/*:refs/heads/*"])
    elif args.update_op == "merge":
        source_branch_head = repo.references[source_branch_name].resolve().target
        repo.merge(source_branch_head)
    elif args.update_op == "rebase":
        source_branch = repo.lookup_branch(source_branch_name, GIT_BRANCH_REMOTE)
        dest_branch = repo.lookup_branch(get_active_branch(repo))
        dest_branch.set_target(source_branch.target)
        # Fast-forwarding with set_target() leaves the index and the working tree
        # in their old state. That's why we need to checkout() and reset()
        repo.checkout(f"refs/heads/{dest_branch.name}")
        repo.reset(dest_branch.target, GIT_RESET_HARD)
    elif args.update_op == "push":
        remote.push(specs=["HEAD"], callbacks=build_auth_callbacks(repo, pass_path))
else:
    log_error("No command issued")
    sys.exit(0)
