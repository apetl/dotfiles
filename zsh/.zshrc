# Start timing
zshrc_start_time=$(date +%s%N)

# Source antidote if not already sourced
if [[ -z "$ANTIDOTE_LOADED" ]]; then
  source /usr/share/zsh-antidote/antidote.zsh
  # Load plugins from static file
  source ~/.zsh_plugins.zsh
  antidote load
  export ANTIDOTE_LOADED=1
fi

# Aliases
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

#eval $(thefuck --alias)
#eval $(thefuck --alias fk)
#export THEFUCK_EXCLUDED_SEARCH_PATH_PREFIXES='/mnt'
#eval $(thefuck --alias --enable-experimental-instant-mode)
#eval $(thefuck --alias fk --enable-experimental-instant-mode)
#unsetopt correct_all

eval "$(atuin init zsh)"

# Custom clear screen function
my-clear() {
  for i in {3..$(tput lines)}; do
    printf '\n'
  done
  zle clear-screen
}
zle -N my-clear
bindkey '^L' my-clear

# Set key bindings
bindkey '^H' backward-kill-word
bindkey '^[[3~' delete-char
bindkey '^[[3;5~' kill-word

# Brew environment
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Source zsh-async if not already sourced
if [[ -z "$ASYNC_LOADED" ]]; then
  source ~/.async.zsh
  async_init
  export ASYNC_LOADED=1
fi

function lf() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Create asynchronous workers if not already created
if [[ -z "$WORKER_STARTED" ]]; then
  async_start_worker my_worker
  async_start_worker nvm_worker

  # Define a callback function for the workers
  async_job_callback() {
    local job=$1 ret_code=$2 output=$3
    if [[ $job == "load_nvm" ]]; then
      source $NVM_DIR/nvm.sh
    elif [[ $job == "initialize_compinit" ]]; then
      autoload -Uz compinit && compinit
    #elif [[ $job == "load_history_substring_search" ]]; then
      #source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh
      #bindkey "^[[A" history-substring-search-up
      #bindkey "^[[B" history-substring-search-down
    fi
  }

  # Register the callback for each worker
  async_register_callback my_worker async_job_callback
  async_register_callback nvm_worker async_job_callback
  export WORKER_STARTED=1
fi

# Asynchronously initialize compinit and load zsh-history-substring-search
async_job my_worker initialize_compinit
async_job my_worker load_history_substring_search

# Asynchronously load nvm with the lowest priority
export NVM_DIR="$HOME/.nvm"
async_job nvm_worker load_nvm

# Zsh history settings
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Other configurations
zstyle ':completion:*' menu select
fpath+=~/.zfunc
export LS_COLORS
export PATH="$PATH:$HOME/miniconda3/bin"

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

# Other initializations
eval "$(zoxide init --cmd cd zsh)"
#autoload -Uz bracketed-paste-magic
#zle -N bracketed-paste bracketed-paste-magic
#zstyle ':bracketed-paste-magic' active-widgets '.self-*'

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

export EDITOR='nvim'
fr() {
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

eval "$(fzf --zsh)"
#export FZF_DEFAULT_COMMAND='rg --files --no-ignore --follow --glob "!.git/*"'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#bindkey '^F' fzf-file-widget

eval "$(starship init zsh)"

# Source additional configurations if available
if [ -f "/home/apetl/.config/fabric/fabric-bootstrap.inc" ]; then
  . "/home/apetl/.config/fabric/fabric-bootstrap.inc"
fi

export PATH="$PATH:$HOME/go/bin"

# Custom command
ff
cd ~
# End timing
zshrc_end_time=$(date +%s%N)
elapsed_time=$((($zshrc_end_time - $zshrc_start_time)/1000000))
echo "${elapsed_time}ms"
unset zshrc_start_time zshrc_end_time elapsed_time
