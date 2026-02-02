#if status is-interactive
    # Commands to run in interactive sessions can go here
#end

set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

function fish_prompt
	if set -q SSH_CONNECTION
        set_color brblack
        printf '(%s) ' (hostname -s)
    end
	
    set_color $fish_color_cwd
    printf '%s' (prompt_pwd)
    set_color normal

    if test -d .git
		set -g __fish_git_prompt_showdirtystate true
        fish_git_prompt
    end

    printf '> '
end


# Add custom paths to PATH
fish_add_path -p /usr/local/bin /usr/local/go/bin /Applications/kitty.app/Contents/MacOS
set -gx GOPATH (go env GOPATH)
fish_add_path $GOPATH/bin
fish_add_path /Users/cse/.local/bin

# set --export GOPROXY "https://goproxy.cn,direct"
set --export EDITOR "vim"
set --export TMPDIR "/tmp"

# make grep human-friendly, will be faster without searching binary files
alias grep "grep --exclude-dir={.git,.vscode} --binary-files=without-match --color=auto -i -n"
# make pgrep ignore case and print longer output
alias pgrep "pgrep -l -i"

alias vim nvim
