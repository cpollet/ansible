#!/bin/bash

function multiselect {
    # source: https://unix.stackexchange.com/a/673436
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()   { printf "$ESC[?25h"; }
    cursor_blink_off()  { printf "$ESC[?25l"; }
    cursor_to()         { printf "$ESC[$1;${2:-1}H"; }
    print_inactive()    { printf "$2   $1 "; }
    print_active()      { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }

    local return_value=$1
    local -n options=$2
    local -n defaults=$3

    local selected=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [[ ${defaults[i]} = "true" ]]; then
            selected+=("true")
        else
            selected+=("false")
        fi
        printf "\n"
    done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - ${#options[@]}))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = ""      ]]; then echo enter; fi;
        if [[ $key = $'\x20' ]]; then echo space; fi;
        if [[ $key = "k" ]]; then echo up; fi;
        if [[ $key = "j" ]]; then echo down; fi;
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A || $key = k ]]; then echo up;    fi;
            if [[ $key = [B || $key = j ]]; then echo down;  fi;
        fi 
    }

    toggle_option() {
        local option=$1
        if [[ ${selected[option]} == true ]]; then
            selected[option]=false
        else
            selected[option]=true
        fi
    }

    print_options() {
        # print options by overwriting the last lines
        local idx=0
        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
              prefix="[\e[38;5;46m✔\e[0m]"
            fi

            cursor_to $(($startrow + $idx))
            if [ $idx -eq $1 ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done
    }

    local active=0
    while true; do
        print_options $active

        # user key control
        case `key_input` in
            space)  toggle_option $active;;
            enter)  print_options -1; break;;
            up)     ((active--));
                    if [ $active -lt 0 ]; then active=$((${#options[@]} - 1)); fi;;
            down)   ((active++));
                    if [ $active -ge ${#options[@]} ]; then active=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    eval $return_value='("${selected[@]}")'
}

all_options=( "base"  "profile"  "gnome"  "dev")
preselection=("true"  "false"    "false"  "false")

echo "Select what to install (<j>, <k>, <up>, <down>, <space>), press <enter> to continue"
multiselect result all_options preselection

selection=""
idx=0
for option in "${all_options[@]}"; do
    if [ ${result[idx]} == "true" ]; then
        [ "$selection" != "" ] && selection="$selection,"
        selection="$selection$option"
    fi
    ((idx++))
done

[ -z "$ANSIBLE_REPO" ] && ANSIBLE_REPO=https://github.com/cpollet/ansible.git
[ -z "$DOTFILES_REPO" ] && DOTFILES_REPO=https://github.com/cpollet/dotfiles.git

echo "Will install $selection from the following repos:"
echo " * $ANSIBLE_REPO"
echo " * $DOTFILES_REPO"
echo
echo -n "Press <enter> to continue."
read

sudo apt-get --yes install software-properties-common
sudo apt-add-repository --yes ppa:ansible/ansible
sudo apt-get update
sudo apt-get --yes install ansible git

ansible-pull \
  --ask-become-pass \
  -t $selection \
  -U $ANSIBLE_REPO