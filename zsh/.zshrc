# Start timing
zshrc_start_time=$(date +%s%N)

# Essential configurations first
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTORY_IGNORE=' *'
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_find_no_dups
zstyle ':completion:*' menu select

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

# Load cached brew shellenv or create cache
if [[ ! -f ~/.brew_shellenv ]] || [[ -n "$(find ~/.brew_shellenv -mtime +7 2>/dev/null)" ]]; then
  /home/linuxbrew/.linuxbrew/bin/brew shellenv > ~/.brew_shellenv
fi
source ~/.brew_shellenv

# Load cached zoxide init or create cache
if [[ ! -f ~/.zoxide_init.zsh ]] || [[ -n "$(find ~/.zoxide_init.zsh -mtime +7 2>/dev/null)" ]]; then
  zoxide init --cmd cd zsh > ~/.zoxide_init.zsh
fi
source ~/.zoxide_init.zsh

# Load cached starship init or create cache
if [[ ! -f ~/.starship_init.zsh ]] || [[ -n "$(find ~/.starship_init.zsh -mtime +7 2>/dev/null)" ]]; then
  starship init zsh > ~/.starship_init.zsh
fi
source ~/.starship_init.zsh

# Load cached atuin init or create cache
if [[ ! -f ~/.atuin_init.zsh ]] || [[ -n "$(find ~/.atuin_init.zsh -mtime +7 2>/dev/null)" ]]; then
  atuin init zsh > ~/.atuin_init.zsh
fi
source ~/.atuin_init.zsh

# Lazy load functions
function lf() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# Lazy load NVM
nvm() {
  unfunction nvm
  export NVM_DIR="$HOME/.nvm"
  source $NVM_DIR/nvm.sh
  nvm "$@"
}

# Lazy load conda
conda() {
  unfunction conda
  # Conda initialization
  __conda_setup="$('/home/apetl/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
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
  conda "$@"
}

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
    if [[ $job == "initialize_compinit" ]]; then
      # Only rebuild completion dump once a day
      autoload -Uz compinit
      if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
        compinit
      else
        compinit -C
      fi
    elif [[ $job == "load_antidote" ]]; then
      source /usr/share/zsh-antidote/antidote.zsh
      source ~/.zsh_plugins.zsh
      antidote load
    fi
  }

  # Register the callback
  async_register_callback my_worker async_job_callback
  export WORKER_STARTED=1

  # Asynchronously initialize compinit and load plugins
  async_job my_worker initialize_compinit
  async_job my_worker load_antidote
fi

# Path setup (consolidated)
export PATH="$PATH:$HOME/miniconda3/bin:$HOME/go/bin"
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
