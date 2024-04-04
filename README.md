# Dotfiles
These are my personal dotfiles, containing configurations for various programs and tools I use.
## Installation
### Prerequisites
Make sure you have Git and GNU Stow installed on your system.
```bash
sudo pacman -S git stow
```
### Clone the Repository
```bash
git clone https://github.com/apetl/dotfiles.git ~/dotfiles
```
### Apply dotfiles
```bash
cd ~/dotfiles
stow *
```

