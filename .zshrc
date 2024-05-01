zshrc_start_time=$(date +%s%N)

source /usr/share/zsh-antidote/antidote.zsh
antidote load

alias py='python'
alias tpy='time python'
alias deactivate='conda deactivate'
alias activate='conda activate'
alias prj='cd ~/Projects'
alias explorer='wslview'
alias ipconfig='ifconfig'
alias lg='lazygit'
# alias oc ='oco'
alias neofetch='fastfetch -c ~/.fastfetch-linux.jsonc'

my-clear() {
  for i in {3..$(tput lines)}
  do
    printf '\n'
  done
  zle clear-screen
}
zle -N my-clear
bindkey '^L' my-clear

#set ctrl+backspace to delete word
bindkey '^H' backward-kill-word
bindkey '5~' kill-word

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

source ~/.async.zsh
async_init
async_start_worker my_worker
async_job_callback() {
  local job=$1 ret_code=$2 output=$3
  if [[ $job == "load_nvm" ]]; then
    source $NVM_DIR/nvm.sh
  elif [[ $job == "initialize_compinit" ]]; then
    autoload -Uz compinit && compinit
  fi
}

export LS_COLORS
export PATH="$PATH:$HOME/miniconda3/bin"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
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
# <<< conda initialize <<<

LS_COLORS=$LS_COLORS:'ow=1;34:' ; export LS_COLORS

async_register_callback my_worker async_job_callback
export NVM_DIR="$HOME/.nvm"
async_job my_worker load_nvm

#alias cat="bat"
alias ls="eza --ignore-glob='NTUSER*|ntuser*'"
alias ll="eza --ignore-glob='NTUSER*|ntuser*' --long -a"
alias la="eza --ignore-glob='NTUSER*|ntuser*' -a"
alias l="eza --ignore-glob='NTUSER*|ntuser*' --long --git"
eval "$(zoxide init --cmd cd zsh)"

autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
zstyle ':bracketed-paste-magic' active-widgets '.self-*'

eval "$(fzf --zsh)"
export FZF_DEFAULT_COMMAND='fd --type f'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


# Created by `pipx` on 2023-12-28 04:44:00
export PATH="$PATH:/home/apetl/.local/bin"

async_job my_worker initialize_compinit
zstyle ':completion:*' menu select
fpath+=~/.zfunc

eval "$(starship init zsh)"

source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

zshrc_end_time=$(date +%s%N)
elapsed_time=$((($zshrc_end_time - $zshrc_start_time)/1000000))
echo "${elapsed_time}ms"
unset zshrc_start_time zshrc_end_time elapsed_time
