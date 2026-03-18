[[ -f /usr/share/cachyos-zsh-config/cachyos-zsh-config.zsh ]] && source /usr/share/cachyos-zsh-config/cachyos-zsh-config.zsh
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  sudo
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#
# --- Battery Aliases ---
alias bat80='echo 80 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold && echo "🔋 Limit set to 80%"'
alias bat100='echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold && echo "⚡ Limit set to 100%"'

# --- Battery Health Function ---
bathealth() {
    local design=$(cat /sys/class/power_supply/BAT0/energy_full_design)
    local current=$(cat /sys/class/power_supply/BAT0/energy_full)
    local cycles=$(cat /sys/class/power_supply/BAT0/cycle_count)
    
    # Zsh math using zcalc logic or $(( ))
    local health=$(( 100 * current / design ))
    
    echo "--- 🔋 Battery Health Report ---"
    echo "Design Capacity:  $design"
    echo "Current Max:      $current"
    echo "Health Percentage: $health%"
    echo "Cycle Count:      $cycles cycles"
    echo "--------------------------------"
    
    if [ $health -lt 80 ]; then
        echo "⚠️  Note: Battery is showing significant wear."
    else
        echo "✅ Battery is in good health."
    fi
}

# --- Power Stats ---
powerstats() {
    echo "--- CPU Governor ---"
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    echo "--- GPU Power State ---"
    nvidia-smi -q -d PERFORMANCE | grep "Performance State" || echo "GPU Sleeping or Error"
    echo "--- Battery Discharge ---"
    local microwatts=$(grep "POWER_SUPPLY_POWER_NOW" /sys/class/power_supply/BAT0/uevent | cut -d= -f2)
    if [ -n "$microwatts" ]; then
        # bc is great for floating point math in Zsh
        local watts=$(echo "scale=2; $microwatts / 1000000" | bc)
        echo "$watts Watts"
    else
        echo "Charging / AC Power"
    fi
}

# --- Hyprland / System Aliases ---
alias rb='killall waybar; waybar > /dev/null 2>&1 & disown'

alias perf='powerprofilesctl set performance && powerprofilesctl get'
alias balanced='powerprofilesctl set balanced && powerprofilesctl get'
alias low='powerprofilesctl set power-saver && powerprofilesctl get'

alias update='paru -Syu && paru -Sc'
alias pssnvpn='sudo openfortivpn -c /etc/openfortivpn/pssn.conf'


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export ANTHROPIC_BASE_URL="http://localhost:11434"
export ANTHROPIC_AUTH_TOKEN="ollama"
export ANTHROPIC_API_KEY="local-key"

# AI Aliases
alias qwen='ollama run qwen2.5:3b'
# alias local-claude='ollama launch claude --model qwen2.5:3b'
alias local-claude='ollama launch claude --model qwen-claude'
alias ai-chill='~/.config/hypr/scripts/gpu-chill.sh'
alias ai-start='sudo systemctl start ollama && local-claude'

# tmux aliases
alias ta='tmux attach -t'
alias tl='tmux ls'
