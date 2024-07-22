#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
if [ -f "/home/apetl/.config/fabric/fabric-bootstrap.inc" ]; then . "/home/apetl/.config/fabric/fabric-bootstrap.inc"; fi