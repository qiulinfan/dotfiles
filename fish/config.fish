set fish_greeting
echo "🐟 Welcome back, QL! Hail to the Elden Lord! "

function fish_prompt
    echo -n (prompt_pwd) ' ▶ '
end

if test -n "$WSL_DISTRO_NAME"
    echo "Running in WSL: $WSL_DISTRO_NAME"
end
if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -gx EDITOR nvim
set -gx VISUAL nvim


function accept_or_expand --description "Smart Tab: expand on first, accept on second"
    set cursor_pos (commandline -C)
    set current_buffer (commandline)
    set before_cursor (string sub -l $cursor_pos -- $current_buffer)

    if test "$before_cursor" = "$__last_tab_buffer"
        # 第二次 Tab，直接接受补全建议
        commandline -f accept-autosuggestion
    else
        # 第一次 Tab，显示候选项
        set -g __last_tab_buffer $before_cursor
        commandline -f complete
    end
end

# 强制 Tab 只接受自动补全，不循环候选项
bind \t accept_or_expand

# control+z -> undo
bind \c\z undo


# ===============================
# alias
# ===============================
alias ls='ls -G'


function emoji
    if test $status -ne 0
        printf "\U0001F972\n"
    else
        printf "\U0001F600\n"
    end
end


function fish_prompt
    set emoji_output (emoji)
    set_color green
    echo -n "$emoji_output" "[$USER] "
    set_color blue
    echo -n (prompt_pwd)
    set_color normal
    echo -n " \$ "
end


set -gx CXX /usr/bin/g++-13
set -gx CC /usr/bin/gcc-13
function g++ --wraps g++-13
    command g++-13 $argv
end
function gcc --wraps gcc-13
    command gcc-13 $argv
end



############################################
# Fish syntax highlighting (Nord)
############################################

# Commands
set -g fish_color_command 81A1C1

# Command options (-a, --help)
set -g fish_color_option 88C0D0

# Parameters / filenames
set -g fish_color_param D8DEE9

# Quoted strings
set -g fish_color_quote A3BE8C

# Escape sequences
set -g fish_color_escape B48EAD

# Operators (| && ;)
set -g fish_color_operator 81A1C1

# Keywords (if, for, while...)
set -g fish_color_keyword 81A1C1

# Redirections (> >> <)
set -g fish_color_redirection 88C0D0

# Valid paths
set -g fish_color_valid_path A3BE8C

# Autosuggestion
set -g fish_color_autosuggestion 616E88

# Search match
set -g fish_color_search_match --background=3B4252

# Selection
set -g fish_color_selection --background=434C5E

# Errors
set -g fish_color_error BF616A

# Comments
set -g fish_color_comment 616E88

# Current working directory
set -g fish_color_cwd 88C0D0

# Root user cwd
set -g fish_color_cwd_root BF616A

# End of line after unfinished quote
set -g fish_color_end D08770

# Normal text
set -g fish_color_normal D8DEE9
