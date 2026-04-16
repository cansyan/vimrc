eval (/opt/homebrew/bin/brew shellenv)

set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

# Add custom paths to PATH
fish_add_path -p /usr/local/bin /usr/local/go/bin /Applications/kitty.app/Contents/MacOS
set -gx GOPATH (go env GOPATH)
fish_add_path $GOPATH/bin
fish_add_path /Users/cse/.local/bin

set --export GOPROXY "https://goproxy.cn,direct"
set --export EDITOR "vim"
set --export TMPDIR "/tmp"

# make grep human-friendly, will be faster without searching binary files
alias grep "grep --exclude-dir={.git,.vscode} --binary-files=without-match --color=auto -i -n"
# make pgrep ignore case and print longer output
alias pgrep "pgrep -i"
alias vim nvim

# make lsof show numeric network address
alias lsof "lsof -nP"

if test -d (brew --prefix)"/share/fish/completions"
    set -p fish_complete_path (brew --prefix)/share/fish/completions
end
if test -d (brew --prefix)"/share/fish/vendor_completions.d"
    set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
end

set -x http_proxy http://127.0.0.1:8080
set -x https_proxy http://127.0.0.1:8080
#set -x all_proxy socks5://127.0.0.1:1080
