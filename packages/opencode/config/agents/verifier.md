---
description: Runs project-standard tests, lint, type checks, and builds without editing code
mode: subagent
model: openai/gpt-5.6-luna
reasoningEffort: max
permission:
  edit: deny
  task: deny
  question: deny
  webfetch: deny
  websearch: deny
  read:
    "*": allow
    "*.env": ask
    "*.env.*": ask
    "*.env.example": allow
  glob: allow
  grep: allow
  list: allow
  lsp: allow
  bash:
    "git commit*": deny
    "git add*": deny
    "git push*": deny
    "git pull*": deny
    "git fetch*": deny
    "git remote set-head* -d*": deny
    "git remote set-head* --delete*": deny
    "git remote prune*": deny
    "git remote update*--prune*": deny
    "git remote update* -p*": deny
    "git remote remove*": deny
    "git remote rm*": deny
    "git fetch*--prune*": deny
    "git fetch* -p*": deny
    "git prune*": deny
    "git gc*--prune*": deny
    "git gc*": deny
    "git maintenance*gc*": deny
    "git notes remove*": deny
    "git notes prune*": deny
    "git merge*": deny
    "git reset*": deny
    "git clean*": deny
    "git checkout*": deny
    "git switch*": deny
    "git rebase*": deny
    "git filter-branch*": deny
    "git reflog expire*": deny
    "git reflog delete*": deny
    "git update-ref*": deny
    "git fsck --lost-found*": deny
    "gh repo clone*": deny
    "git push*--mirror*": deny
    "git push* -f*": deny
    "git push*-f*": deny
    "git push* -d*": deny
    "git push*-d*": deny
    "git push* +*:*": deny
    "git push*+*:*": deny
    "git branch -d*": deny
    "git branch -D*": deny
    "git branch --delete*": deny
    "git tag -d*": deny
    "git tag --delete*": deny
    "git stash drop*": deny
    "git stash clear*": deny
    "git worktree remove*": deny
    "git worktree prune*": deny
    "gh pr merge*--delete-branch*": deny
    "* git commit*": deny
    "* git add*": deny
    "* git push*": deny
    "* git pull*": deny
    "* git fetch*": deny
    "* git merge*": deny
    "* git reset*": deny
    "* git clean*": deny
    "* git checkout*": deny
    "* git switch*": deny
    "* git rebase*": deny
    "* git filter-branch*": deny
    "* git reflog expire*": deny
    "* git reflog delete*": deny
    "* git branch -d*": deny
    "* git branch -D*": deny
    "* git tag -d*": deny
    "* git stash drop*": deny
    "* git stash clear*": deny
    "* git worktree remove*": deny
    "* git worktree prune*": deny
    "* gh pr merge*--delete-branch*": deny
    "git*reset*": deny
    "git*clean*": deny
    "git*push*--force*": deny
    "git*push*--mirror*": deny
    "git*push*--delete*": deny
    "git*branch*--delete*": deny
    "git*branch* -d*": deny
    "git*branch* -D*": deny
    "git*tag*--delete*": deny
    "git*tag* -d*": deny
    "git*stash*drop*": deny
    "git*stash*clear*": deny
    "git*worktree*remove*": deny
    "git*worktree*prune*": deny
    "git*reflog*expire*": deny
    "git*reflog*delete*": deny
    "*git*reset*": deny
    "*git*clean*": deny
    "*git*push*--force*": deny
    "*git*push*--mirror*": deny
    "*git*push*--delete*": deny
    "*git*branch*--delete*": deny
    "*git*branch* -d*": deny
    "*git*branch* -D*": deny
    "*git*tag*--delete*": deny
    "*git*tag* -d*": deny
    "*git*stash*drop*": deny
    "*git*stash*clear*": deny
    "*git*worktree*remove*": deny
    "*git*worktree*prune*": deny
    "*git*reflog*expire*": deny
    "*git*reflog*delete*": deny
    "*git*update-ref*": deny
    "* git remote set-head* -d*": deny
    "*/git remote set-head* -d*": deny
    "*git\tremote\tset-head*\t-d*": deny
    "*git${IFS}remote${IFS}set-head*${IFS}-d*": deny
    "*git$IFSremote$IFSset-head*$IFS-d*": deny
    "* git remote set-head* --delete*": deny
    "*/git remote set-head* --delete*": deny
    "*git\tremote\tset-head*\t--delete*": deny
    "*git${IFS}remote${IFS}set-head*${IFS}--delete*": deny
    "*git$IFSremote$IFSset-head*$IFS--delete*": deny
    "* git remote prune*": deny
    "*/git remote prune*": deny
    "*git\tremote\tprune*": deny
    "*git${IFS}remote${IFS}prune*": deny
    "*git$IFSremote$IFSprune*": deny
    "* git remote update*--prune*": deny
    "*/git remote update*--prune*": deny
    "*git\tremote\tupdate*\t--prune*": deny
    "*git${IFS}remote${IFS}update*${IFS}--prune*": deny
    "*git$IFSremote$IFSupdate*$IFS--prune*": deny
    "* git remote update* -p*": deny
    "*/git remote update* -p*": deny
    "*git\tremote\tupdate*\t-p*": deny
    "*git${IFS}remote${IFS}update*${IFS}-p*": deny
    "*git$IFSremote$IFSupdate*$IFS-p*": deny
    "* git remote remove*": deny
    "*/git remote remove*": deny
    "*git\tremote\tremove*": deny
    "*git${IFS}remote${IFS}remove*": deny
    "*git$IFSremote$IFSremove*": deny
    "* git remote rm*": deny
    "*/git remote rm*": deny
    "*git\tremote\trm*": deny
    "*git${IFS}remote${IFS}rm*": deny
    "*git$IFSremote$IFSrm*": deny
    "* git fetch*--prune*": deny
    "*/git fetch*--prune*": deny
    "*git\tfetch\t--prune*": deny
    "*git${IFS}fetch${IFS}--prune*": deny
    "*git$IFSfetch$IFS--prune*": deny
    "* git fetch* -p*": deny
    "*/git fetch* -p*": deny
    "*git\tfetch\t-p*": deny
    "*git${IFS}fetch${IFS}-p*": deny
    "*git$IFSfetch$IFS-p*": deny
    "* git prune*": deny
    "*/git prune*": deny
    "*git\tprune*": deny
    "*git${IFS}prune*": deny
    "*git$IFSprune*": deny
    "* git gc*": deny
    "*/git gc*": deny
    "*git\tgc*": deny
    "*git${IFS}gc*": deny
    "*git$IFSgc*": deny
    "* git maintenance*--task=gc*": deny
    "*/git maintenance*--task=gc*": deny
    "*git\tmaintenance*\t--task=gc*": deny
    "*git${IFS}maintenance*${IFS}--task=gc*": deny
    "*git$IFSmaintenance*$IFS--task=gc*": deny
    "* git notes remove*": deny
    "*/git notes remove*": deny
    "*git\tnotes\tremove*": deny
    "*git${IFS}notes${IFS}remove*": deny
    "*git$IFSnotes$IFSremove*": deny
    "* git notes prune*": deny
    "*/git notes prune*": deny
    "*git\tnotes\tprune*": deny
    "*git${IFS}notes${IFS}prune*": deny
    "*git$IFSnotes$IFSprune*": deny
    "git remote *$*": deny
    "* git remote *$*": deny
    "*/git remote *$*": deny
    "*git\tremote\t*$*": deny
    "*git${IFS}remote${IFS}*$*": deny
    "*git$IFSremote$IFS*$*": deny
    "git maintenance*--task=*$*": deny
    "* git maintenance*--task=*$*": deny
    "*/git maintenance*--task=*$*": deny
    "*git\tmaintenance*\t--task=*$*": deny
    "*git${IFS}maintenance*${IFS}--task=*$*": deny
    "*git$IFSmaintenance*$IFS--task=*$*": deny
    "git notes *$*": deny
    "* git notes *$*": deny
    "*/git notes *$*": deny
    "*git\tnotes\t*$*": deny
    "*git${IFS}notes${IFS}*$*": deny
    "*git$IFSnotes$IFS*$*": deny
    "*git*remote*set-head*-d*": deny
    "*git*remote*set-head*--delete*": deny
    "*git*remote*prune*": deny
    "*git*remote*update*--prune*": deny
    "*git*remote*update*-p*": deny
    "*git*remote*remove*": deny
    "*git*remote*rm*": deny
    "*git\tremote *$*": deny
    "*git remote\t*$*": deny
    "*git${IFS}remote *$*": deny
    "*git remote${IFS}*$*": deny
    "*git\tremote${IFS}*$*": deny
    "*git*fetch*--prune*": deny
    "*git*fetch*-p *": deny
    "*git*fetch*-qpf*": deny
    "*git*fetch*-P*": deny
    "*git*fetch*-q*p*": deny
    "*git*fetch*-f*p*": deny
    "*git*fetch*-q*P*": deny
    "*git*fetch*-f*P*": deny
    "*git*fetch*-?p*": deny
    "*git*maintenance*--task=gc*": deny
    "*git*maintenance*--task=*$*": deny
    "*git*notes*remove*": deny
    "*git*notes*prune*": deny
    "*git*notes*$*": deny
    "*git*push* -f*": deny
    "*git*push*-f*": deny
    "*git*push* -d*": deny
    "*git*push*-d*": deny
    "*git*push* +*:*": deny
    "*git*push*+*:*": deny
    "*/git*push* -f*": deny
    "*/git*push*-f*": deny
    "*/git*push* -d*": deny
    "*/git*push*-d*": deny
    "*/git*branch*-d*": deny
    "*/git*branch*-D*": deny
    "*/git*branch*--delete*": deny
    "*/git*tag*-d*": deny
    "*/git*tag*--delete*": deny
    "*/git*update-ref*": deny
    "*git*branch* -vv *": deny
    "*git*branch*-vv*": deny
    "*git*branch*-d*": deny
    "*git*branch*-D*": deny
    "*git*branch*--force*": deny
    "*git*branch*--move*": deny
    "*git*branch*--copy*": deny
    "*git*branch*-f *": deny
    "*git*branch*-f\t*": deny
    "*git*branch*-f${IFS}*": deny
    "*git*branch*-f$IFS*": deny
    "*git*branch*-m *": deny
    "*git*branch*-m\t*": deny
    "*git*branch*-m${IFS}*": deny
    "*git*branch*-m$IFS*": deny
    "*git*branch*-M*": deny
    "*git*branch*-c *": deny
    "*git*branch*-c\t*": deny
    "*git*branch*-c${IFS}*": deny
    "*git*branch*-c$IFS*": deny
    "*git*branch*-C*": deny
    "*git*branch*\"-f\"*": deny
    "*git*branch*'-f'*": deny
    "*git*branch*\"-m\"*": deny
    "*git*branch*'-m'*": deny
    "*git*branch*\"-M\"*": deny
    "*git*branch*'-M'*": deny
    "*git*branch*\"-c\"*": deny
    "*git*branch*'-c'*": deny
    "*git*branch*\"-C\"*": deny
    "*git*branch*'-C'*": deny
    "*git*push* :*": deny
    "*git*push*\t:*": deny
    "*git*push*${IFS}:*": deny
    "*git*push*$IFS:*": deny
    "* gh issue delete*": deny
    "* gh repo delete*": deny
    "* gh release delete*": deny
    "*gh*pr*merge*--delete-branch*": deny
    "*gh*issue*delete*": deny
    "*gh*repo*delete*": deny
    "*gh*release*delete*": deny
    "rm*": deny
    "* rm*": deny
    "* rmdir*": deny
    "*rm *": deny
    "*rmdir *": deny
    "*rm\t*": deny
    "*rmdir\t*": deny
    "*rm*${IFS}*": deny
    "*rmdir*${IFS}*": deny
    "*rm*$IFS*": deny
    "*rmdir*$IFS*": deny
    "*rm*${IFS*": deny
    "*rmdir*${IFS*": deny
    "*rm*.git*": deny
    "*rmdir*.git*": deny
    "*rm*\"/*": deny
    "*rmdir*\"/*": deny
    "*rm*'/*": deny
    "*rmdir*'/*": deny
    "sudo*": deny
    "* sudo*": deny
    "*sudo*": deny
    "nix store delete*": deny
    "nix store gc*": deny
    "* nix store delete*": deny
    "* nix store gc*": deny
    "nix-collect-garbage*": deny
    "*nix-collect-garbage*": deny
    "nix*store*delete*": deny
    "nix*store*gc*": deny
    "*nix*store*delete*": deny
    "*nix*store*gc*": deny
    "* env *": deny
    "* bash -c*": deny
    "* sh -c*": deny
    "* zsh -c*": deny
    "*bash* -c*": deny
    "*sh* -c*": deny
    "*zsh* -c*": deny
    "* eval*": deny
    "* exec*": deny
    "git config --get remote.*": allow
    "git config --get*": allow
    "git show refs/remotes/origin/prune": allow
    "git diff remote-prune": allow
    "git rev-parse refs/remotes/origin/prune": allow
    "git log --grep*": allow
    "git --work-tree=* log --grep*": allow
    "git --work-tree * log --grep*": allow
    "*;*": deny
    "*&*": deny
    "*|*": deny
    "*>*": deny
    "*<*": deny
    "*$(*": deny
    "*`*": deny
    "*\n*": deny
    "env *": deny
    "bash -c*": deny
    "sh -c*": deny
    "zsh -c*": deny
    "command *": deny
    "eval*": deny
    "exec*": deny
    "git diff*--output*": deny
    "git*diff*--output*": deny
    "git*diff* -o*": deny
    "git*diff*-o*": deny
    "git diff-tree*--output*": deny
    "git diff-index*--output*": deny
    "git log*--output*": deny
    "git*log*--output*": deny
    "git*log* -o*": deny
    "git*log*-o*": deny
    "git show*--output*": deny
    "git*show*--output*": deny
    "git*show* -o*": deny
    "git*show*-o*": deny
    "git stash list*--output*": deny
    "git*stash list*--output*": deny
    "git*stash list* -o*": deny
    "git*stash list*-o*": deny
    "git stash show*--output*": deny
    "git*stash show*--output*": deny
    "git*stash show* -o*": deny
    "git*stash show*-o*": deny
    "git reflog show*--output*": deny
    "git*reflog show*--output*": deny
    "git*reflog show* -o*": deny
    "git*reflog show*-o*": deny
    "git log --grep*--output*": deny
    "git log --grep* -o*": deny
    "git log --grep*-o*": deny
    "git --work-tree=* log*--output*": deny
    "git --work-tree * log*--output*": deny
    "git --work-tree=* log* -o*": deny
    "git --work-tree * log* -o*": deny
    "git --work-tree=* log*-o*": deny
    "git --work-tree * log*-o*": deny
    "git log --grep='--output'": allow
    "git --work-tree=. log --grep='-o'": allow
    "git log --grep='--output=/tmp'": allow
    "git --work-tree=. log --grep='--output'": allow
---
Start the final response with exactly one of: status: COMPLETED, status: BLOCKED, status: NEEDS_APPROVAL, status: NEEDS_DECISION.

Do not ask the user, call `question`, delegate, broaden permissions, attempt denied operations, or bypass repository policy. Never report an unexecuted command or check as PASS. Return approval and decision needs to the parent with exact evidence and safe alternatives.

Then define evidence expectations: list every command requested and executed, include outputs, and clearly separate observed results from constraints that prevented execution.

Discover the project's supported verification workflow from repository guidance, manifests, CI configuration, and existing tests. Run the relevant tests, lint, type checks, and builds requested by the parent. Do not modify code or configuration. Do not infer success from an unexecuted command, and use `INCOMPLETE` when tools, dependencies, credentials, time, or permissions prevent adequate verification.

Execution is mandatory when the required verification command is available and permitted.
Do not return only a verification plan when the command can actually be executed.
Do not claim success for commands that were not run.

Return exactly this structure:

## Verification

### Detected project workflow
- ...

### Commands executed
- `<command>`: PASS / FAIL / SKIPPED (never mark PASS without actual execution)

### Failures
- ...

### Unverified areas
- ...

### Verdict
PASS / FAIL / INCOMPLETE
