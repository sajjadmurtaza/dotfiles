#region functions
fzf_git_switch() {
  if [ $# -eq 0 ]; then
    local ref
    ref="$(
      git for-each-ref --format='%(refname:short)' refs/heads refs/remotes |
        rg -v '^origin/HEAD$' |
        fzf
    )" || return 1

    case "$ref" in
      origin/*)
        git switch --track "${ref#origin/}" 2>/dev/null || git switch "${ref#origin/}" 2>/dev/null || git switch -c "${ref#origin/}" --track "$ref"
        ;;
      *)
        git switch "$ref"
        ;;
    esac
  else
    git switch "$@"
  fi
}
#endregion

#region homebrew provided stuff: zsh completions, libs
if command_exists brew; then
  brew_prefix="$(brew --prefix)"

  FPATH="$brew_prefix/share/zsh/site-functions:$FPATH"

  export PATH="$brew_prefix/opt/libpq/bin:$PATH"

  if [ -f "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi
fi

FPATH="$HOME/.completions:$FPATH"
#endregion

#region shell setup with sourcing and evals

source ~/.profile

# Activate the version manager only when it is installed. Project-local
# mise.toml files override the workstation defaults in ~/.mise.toml.
if command_exists mise; then
  eval "$(mise activate zsh)"
fi

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi


# setup starship
if command_exists starship; then
  eval "$(starship init zsh)"
fi

# setup fzf
if command_exists fzf; then
  eval "$(fzf --zsh)"
fi

# setup zoxide
if command_exists zoxide; then
  eval "$(zoxide init --cmd cd zsh)"
fi

#region completion optimizations
# Minimal completion setup
mkdir -p ~/.zsh/cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
# zstyle ':completion:*' menu select
# zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# setup carapace
if command_exists carapace; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
  zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
  source <(carapace _carapace)
fi
#endregion


# Fuzzy brew functions
brew-search() {
  brew search --formula | fzf --multi --reverse --prompt="brew> " | xargs -r brew install
}

brew-remove() {
  brew list --formula | fzf --multi --reverse --prompt="remove> " | xargs -r brew uninstall
}

#endregion

# source ~/.zshrc.local
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

#endregion

#region aliases

#region# git related (some found in @holman's dotfiles)
glog() {
  git log --abbrev-commit --date=short --decorate=short --decorate-refs='refs/heads/*' --decorate-refs='refs/tags/*' --pretty=format:'%C(red)%h%Creset %C(bold blue)%an%Creset: %s %C(yellow)%d%Creset %C(green)(%ad)%Creset'
}

alias gb='git branch'
alias gc='git commit'
alias gca='git commit --amend'
alias gco='fzf_git_switch'
alias gcp='git cherry-pick -x'
alias gd='git diff'
alias gfix='git commit --fixup'
alias gmain='gco $(git_default_branch)'
alias gpf='git push --force-with-lease'
alias gpu='git push -u origin HEAD'
alias gria='git rebase -i --autostash --autosquash'
alias gs='tig status -sb'
alias gup="git pull --rebase --autostash"
alias gundo="git reset --soft HEAD~1"

lag() {
  lazygit --use-config-file ~/.config/lazygit/config.yml -p "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" "$@"
}

# git_default_branch: get the default branch of the current git repository (assumes remote is named 'origin')
function git_default_branch() {
  git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' && return
  git show-ref --verify --quiet refs/heads/main && echo main && return
  git show-ref --verify --quiet refs/heads/master && echo master && return
  echo "git_default_branch: no origin HEAD, main, or master branch" >&2
  return 1
}

gnew() {
  local new_branch="$1"
  local default_branch stash_name had_stash=0

  if [ -z "$new_branch" ]; then
    echo "usage: gnew <branch-name>" >&2
    return 1
  fi

  default_branch="$(git_default_branch)" || return 1
  stash_name="gnew: $(date +%Y-%m-%dT%H:%M:%S)"

  if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    git stash push -u -m "$stash_name" || return 1
    had_stash=1
  fi

  git fetch --all --prune || return 1

  if git show-ref --verify --quiet "refs/heads/$new_branch"; then
    git switch "$new_branch" || return 1
  else
    git switch -c "$new_branch" "origin/$default_branch" || return 1
  fi

  if [ "$had_stash" -eq 1 ]; then
    if git stash apply "stash^{/$stash_name}"; then
      git stash drop "stash^{/$stash_name}" >/dev/null
    else
      echo "stash kept due to conflicts: $stash_name" >&2
      return 1
    fi
  fi
}

# git_changed: show files changed in the current branch, compared to the default branch
function git_changed() {
  local branch=${1:-$(git_default_branch)}
  git diff --name-only --diff-filter=AM "$branch...HEAD"
}

alias git-changed="git_changed"
alias git-staged="git diff --name-only --cached"

#endregion

#region# ruby & rails aliases
alias be='bundle exec'
alias berd='RAILS_ENV=${RAILS_ENV:-test} bundle exec rspec --format documentation'
alias ber='RAILS_ENV=${RAILS_ENV:-test} bundle exec rspec'
alias fs='overmind start'

rails_project() {
  [[ -f config/application.rb && -x bin/rails ]]
}

rdbm() {
  rails_project || { echo "rdbm: run inside a Rails application" >&2; return 1; }
  bin/rails db:migrate "$@"
}

rdbr() {
  rails_project || { echo "rdbr: run inside a Rails application" >&2; return 1; }
  bin/rails db:rollback "$@"
}

rr() {
  rails_project || { echo "rr: run inside a Rails application" >&2; return 1; }
  bin/rails routes | fzf
}

rt() {
  if ! rails_project; then
    echo "rt: run inside a Rails application" >&2
    return 1
  elif [[ -d spec ]]; then
    bundle exec rspec "$@"
  else
    bin/rails test "$@"
  fi
}

rci() {
  if ! rails_project; then
    echo "rci: run inside a Rails application" >&2
    return 1
  elif [[ -x bin/ci ]]; then
    bin/ci "$@"
  else
    echo "rci: this app has no bin/ci; use its documented test and lint commands" >&2
    return 1
  fi
}
#endregion

#region# start GUI applications
alias subl="open -a 'Sublime Text'"
alias marta="open -a Marta"
alias vsc="open -a 'Visual Studio Code'"
#endregion

#region# grepping code
alias todo-rg="rg '(TODO|FIXME|XXX|NOTE|OPTIMIZE|HACK|REVIEW)'"
alias ag="rg"
#endregion

#region# pleasent path traversal
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
#endregion

#region# magic folder commands
alias pg="playground"
alias dothelp="dotfiles help"
#endregion

#region# better cat and "imagec" (icat)
if command_exists bat; then
  # use bat for cat, and let it behave like cat
  alias cat="bat --style=plain --paging=never"
fi

if command_exists wezterm; then
  alias icat="wezterm imgcat"
fi
#endregion

#region# likewise powerful aliases beginning with 'l'
alias less="less -R"

if command_exists lsd; then
  alias ls='lsd'
  alias ll='lsd -la'
  alias la='lsd -a'
fi

if [ "$(uname)" = "Darwin" ]; then
  # we are on macosx
  alias lsusb="system_profiler SPUSBDataType"
fi

clipcopy() {
  if command_exists pbcopy; then
    pbcopy
  elif command_exists wl-copy; then
    wl-copy
  elif command_exists xclip; then
    xclip -selection clipboard
  else
    echo "clipcopy: install pbcopy, wl-clipboard, or xclip" >&2
    return 1
  fi
}

clippaste() {
  if command_exists pbpaste; then
    pbpaste
  elif command_exists wl-paste; then
    wl-paste --no-newline
  elif command_exists xclip; then
    xclip -selection clipboard -o
  else
    echo "clippaste: install pbpaste, wl-clipboard, or xclip" >&2
    return 1
  fi
}

if command_exists lazydocker; then
  alias lad="lazydocker"
fi

#endregion

#region# powerful aliases beginning with 'p'
alias psgrep="ps aux | grep"
alias p8="ping 8.8.8.8"
alias p6="ping6 2606:4700:4700::1111"
#endregion

#endregion

#region sweetened history
# Some settings taken from various sources to enhance Zsh history:
# - https://www.soberkoder.com/better-zsh-history/
# - https://github.com/oleander/dotfiles
# - https://hassek.github.io/zsh-history-tweaking/
# Thanks! <3
setopt HIST_VERIFY            # Allow editing before executing commands retrieved from history.
setopt SHARE_HISTORY          # Share history between sessions.
setopt EXTENDED_HISTORY       # Write history in ":start:elapsed;command" format.
setopt HIST_FIND_NO_DUPS      # Prevent duplicate matching entries.
setopt INC_APPEND_HISTORY     # Immediately append to history file.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicated entries first.
setopt HIST_IGNORE_DUPS       # Ignore consecutive duplicate entries.
setopt HIST_IGNORE_ALL_DUPS   # Delete old entry if a duplicate is recorded.
setopt HIST_IGNORE_SPACE      # Exclude entries that start with a space.
setopt HIST_SAVE_NO_DUPS      # Do not save duplicate entries.
setopt HIST_REDUCE_BLANKS     # Remove extra blanks.

export HISTFILE="$HOME/.zsh_history"
export HISTFILESIZE=1000000000
export HISTSIZE=1000000000
export HISTTIMEFORMAT="[%F %T] "

alias hgrep="history 0 | grep"
alias h="history 0 | fzf"
#endregion

#region key bindings

# jumping words with Alt and left/right arrow
bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word
#endregion

#region Completions
autoload -U compinit && compinit
