# Start timing
zshrc_start_time=$(date +%s%N)

# Essential configurations first
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTORY_IGNORE=' *'
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_find_no_dups

# Enhanced history settings
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FCNTL_LOCK
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

zstyle ':completion:*' menu select

# Initialize completion system early with performance optimizations
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit -i  # Add -i flag to ignore insecure directories
else
  compinit -C -i
fi

# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Directory navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Fast aliases
alias cat='bat'
alias py='python'
alias deactivate='conda deactivate'
alias activate='conda activate'
alias prj='cd ~/Projects'
alias explorer='wslview'
alias ipconfig='ifconfig'
alias lg='lazygit'
alias neofetch='fastfetch -c ~/.fastfetch-linux.jsonc'
alias ff='neofetch'
alias ls="eza --ignore-glob='NTUSER*|ntuser*'"
alias ll="eza --ignore-glob='NTUSER*|ntuser*' --long -a"
alias la="eza --ignore-glob='NTUSER*|ntuser*' -a"
alias l="eza --ignore-glob='NTUSER*|ntuser*' --long --git"
alias pbc="pbcopy.exe"
alias pbp="pbpaste.exe"
alias dg="/home/apetl/Projects/dataGhost/bin/dataGhost"
alias s="scratchpad.sh"
alias obs="cd /mnt/c/Users/petli/Obsidian/RAM && nvim"
alias jrnl="~/Projects/jrnl/jrnl"

# Key bindings
bindkey '^H' backward-kill-word
bindkey '^[[3~' delete-char
bindkey '^[[3;5~' kill-word

# Custom clear screen function
my-clear() {
  printf '\n%.0s' {1..$(($(tput lines)-2))}
  zle clear-screen
}

zle -N my-clear
bindkey '^L' my-clear

if [ -f "$HOME/.env" ]; then
  set -a
  source "$HOME/.env"
  set +a
fi

# More efficient lazy loading function
function lazy_load() {
  local function_name="$1"
  local load_command="$2"

  eval "$function_name() {
    unfunction $function_name
    $load_command
    $function_name \"\$@\"
  }"
}

# More robust cache checking function
check_cache() {
  local cache_file="$1"
  local command="$2"
  local max_age="${3:-7}"  # Default to 7 days

  if [[ ! -f "$cache_file" ]] || [[ -n "$(find "$cache_file" -mtime +$max_age 2>/dev/null)" ]]; then
    eval "$command" > "$cache_file"
  fi
  source "$cache_file"
}

# Use the new cache function for all cached initializations
check_cache ~/.brew_shellenv "/home/linuxbrew/.linuxbrew/bin/brew shellenv"
check_cache ~/.zoxide_init.zsh "zoxide init --cmd cd zsh"
check_cache ~/.starship_init.zsh "starship init zsh"
check_cache ~/.atuin_init.zsh "atuin init zsh"

# Lazy load functions using the new lazy_load helper
function lf() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# Lazy load NVM with the new helper
lazy_load nvm 'export NVM_DIR="$HOME/.nvm"; source $NVM_DIR/nvm.sh; nvm use --lts'

# carapace config
#export CARAPACE_BRIDGES='zsh'
#zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
#source <(carapace _carapace)

# Lazy load conda with the new helper
lazy_load conda '
  __conda_setup="$(/home/apetl/miniconda3/bin/conda shell.zsh hook 2> /dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    if [ -f "/home/apetl/miniconda3/etc/profile.d/conda.sh" ]; then
      . "/home/apetl/miniconda3/etc/profile.d/conda.sh"
    else
      export PATH="/home/apetl/miniconda3/bin:$PATH"
    fi
  fi
  unset __conda_setup
'

# Lazy load fzf
fr() {
  # Load FZF config if not already loaded
  if [[ -z "$FZF_LOADED" ]]; then
    export FZF_DEFAULT_OPTS=" \
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
    --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
    --color=selected-bg:#45475a \
    --multi \
    --preview 'bat --color=always --style=numbers {} || cat {}' \
    --preview-window=right:60% \
    --preview-window=right:40% \
    --height=40%
    "
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    eval "$(fzf --zsh)"
    export FZF_LOADED=1
  fi

  local RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
  local INITIAL_QUERY="${*:-}"
  local selected
  if selected=$(FZF_DEFAULT_COMMAND="$RG_PREFIX $(printf %q "$INITIAL_QUERY")" \
      fzf --ansi \
          --disabled --query "$INITIAL_QUERY" \
          --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
          --delimiter : \
          --preview 'bat --color=always {1} --highlight-line {2}' \
          --preview-window 'right,50%,border-bottom,+{2}+3/3,~3'); then
      local file=$(echo "$selected" | cut -d: -f1)
      local line=$(echo "$selected" | cut -d: -f2)
      [ -n "$file" ] && nvim "$file" "+${line}"
  fi
}

# Async loading for plugins and completions
if [[ -z "$ASYNC_LOADED" ]]; then
  source ~/.async.zsh
  async_init
  export ASYNC_LOADED=1
fi

if [[ -z "$WORKER_STARTED" ]]; then
  async_start_worker my_worker

  # Define a callback function for the worker
  async_job_callback() {
    local job=$1 ret_code=$2 output=$3
    if [[ $job == "load_antidote" ]]; then
      source /usr/share/zsh-antidote/antidote.zsh
      source ~/.zsh_plugins.zsh
      antidote load
    fi
  }

  # Register the callback
  async_register_callback my_worker async_job_callback
  export WORKER_STARTED=1

  # Asynchronously load plugins
  async_job my_worker load_antidote
fi

# Path setup (consolidated)
export PATH="$PATH:$HOME/miniconda3/bin:$HOME/go/bin"
export PATH="$HOME/.cargo/bin:$PATH"
export EDITOR='nvim'
fpath+=~/.zfunc

# Source additional configurations if available
[ -f "/home/apetl/.config/fabric/fabric-bootstrap.inc" ] && source "/home/apetl/.config/fabric/fabric-bootstrap.inc"

#ff and cd ~
cd ~
ff

# End timing
zshrc_end_time=$(date +%s%N)
elapsed_time=$((($zshrc_end_time - $zshrc_start_time)/1000000))
echo "${elapsed_time}ms"
unset zshrc_start_time zshrc_end_time elapsed_time


# opencode
export PATH=/home/apetl/.opencode/bin:$PATH
