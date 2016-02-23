# s="\["
# e="\]"
s=""
e=""
c_git_fg=$s"\033[38;5;15m"$e
c_git_sep=$s"\033[38;5;32m"$e
c_git_bg=$s"\033[48;5;32m"$e

c_change_fg=$s"\033[38;5;255m"$e
c_change_sep=$s"\033[38;5;166m"$e
c_change_bg=$s"\033[48;5;166m"$e

c_staged_fg=$s"\033[38;5;255m"$e
c_staged_bg=$s"\033[48;5;22m"$e

c_untracked_fg=$s"\033[38;5;255m"$e
c_untracked_bg=$s"\033[48;5;160m"$e

c_push_status_fg=$s"\033[38;5;255m"$e
c_push_status_bg=$s"\033[48;5;53m"$e

c_branch_fg=$s"\033[38;5;232m"$e
c_branch_sep=$s"\033[38;5;7m"$e
c_branch_bg=$s"\033[48;5;7m"$e
c_cls=$s"\033[0m"$e
c_bold=$s"\033[1m"$e

find_git_branch() {
    local branch
    local branch_color=$c_branch_fg
    branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    if [ ! -z "$branch" ]; then
        if [ "$branch" == "HEAD" ]; then
            branch_color="\033[38;5;160m"
            branch=$c_bold'detached ✇' #↯'
            branch_symbol=' ✇ '
        else
            # check remote branch exists
            if [ ! `git b -r --list origin/${branch}` ]; then
                branch_symbol='\033[38;5;160m ᚶ '
            else
                branch_symbol=' ᚶ '
            fi
        fi
        git_branch="$branch_color$c_bold$branch_symbol$c_cls$c_branch_bg$branch_color$branch"
        find_git_dirty
    else
        git_branch=""
    fi
}
find_git_dirty() {
    local status=$(git status --porcelain)
    local git_status=$(git status)
    local branch_pos_text=$(echo "$git_status" | grep -e ^.*"branch".*"ahead" -e ^.*"branch".*"behind")
    ff_msg=''
    if [[ ! -z "$branch_pos_text" ]]; then
        # ahead or behind
        branch_position=$(echo "$branch_pos_text" | cut -d' ' -f 8)
        if [[ ! -z `echo "$git_status" | grep -e ^.*"branch".*"behind"` ]]; then
            # behind
            branch_position=$(echo "$branch_pos_text" | cut -d' ' -f 7)
            if [[ ! -z `echo "$git_status" | grep -e ^.*"branch".*"fast-forwarded"` ]]; then
                ff_msg="\033[38;5;135m(ff)"
            fi
        fi
    fi
    local branch_diverged=$(echo "$git_status" | grep -e ^.*"branch".*"diverged")
    branch_ahead_behind=$(echo "$branch_pos_text" | cut -d' ' -f 4)
    if [[ "$branch_ahead_behind" == "ahead" ]]; then
        branch_ahead_behind='+'
    else
        if [[ "$branch_ahead_behind" == "behind" ]]; then
            branch_ahead_behind='-'
        fi
    fi
    if [[ "$status" != "" ]]; then
        staged_count=$(echo "$status" | grep ^[A-Z]." ".* | wc -l | awk '{print $1}')
        unstaged_count=$(echo "$status" | grep ^.[A-Z]" ".* | wc -l | awk '{print $1}')
        untracked_count=$(echo "$status" | grep ^??s* | wc -l | awk '{print $1}')
    else
        staged_count='0'
        unstaged_count='0'
        untracked_count='0'
    fi
}
parse_git_branch() {
    git_path=''
    find_git_branch
    if [ ! -z "$git_branch" ]; then
        echo -e -n $c_git_bg$c_git_fg" git "
        if [[ $staged_count>0 ]]; then
            echo -e -n $c_staged_bg$c_git_sep" "
            echo -e -n $c_staged_bg$c_staged_fg"${staged_count}⚑ "
        fi
        if [[ $unstaged_count>0 ]]; then
            echo -e -n $c_change_bg$c_git_sep" "
            echo -e -n $c_change_bg$c_change_fg"${unstaged_count}Δ " #ᛟ "
        fi
        if [[ $untracked_count>0 ]]; then
            echo -e -n $c_untracked_bg$c_git_sep" "
            echo -e -n $c_untracked_bg$c_untracked_fg"${untracked_count}። "
        fi
        if [[ ! -z "$branch_diverged" ]]; then
            echo -e -n $c_push_status_bg$c_push_status_fg" ⇡⇣ " # ⇡⇣ 𐠯
        fi
        if [ ! -z "$branch_ahead_behind" ]; then
            echo -e -n $c_push_status_bg$c_push_status_fg" ${branch_ahead_behind}${branch_position}⇣${ff_msg} " # ⇡⇣ 𐠯
        fi
        echo -e -n $c_branch_bg$git_branch" "
        echo -e -n $c_cls$c_branch_sep" "
        echo -e $c_cls
    fi
}