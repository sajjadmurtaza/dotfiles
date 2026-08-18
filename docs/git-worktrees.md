# Git worktrees

Worktrees are useful when two branches need independent files and dependencies. Keep the workflow explicit; the shell configuration does not hide branch creation, rebases, or deletion behind aliases.

```sh
# From the main checkout
git fetch origin
git worktree add ../my-app-feature -b feature/account-suspension origin/main

# Inspect ownership before operating
git worktree list
git -C ../my-app-feature status --short --branch
```

Run tests and commits from the worktree that owns the branch. After the branch is merged and no uncommitted work remains:

```sh
git worktree remove ../my-app-feature
git worktree prune
```

Never remove a worktree until `git status` is clean and the path has been verified.
