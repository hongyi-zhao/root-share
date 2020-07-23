#!/usr/bin/env bash
# Obtain the canonicalized absolute dirname where the script resides.
# Both readlink and realpath can do the trick.
topdir=$(
cd -P -- "$(dirname -- "$(realpath -e -- "${BASH_SOURCE[0]}")")" &&
pwd -P
) 

# In the following method, the $script_dirname is equivalent to $topdir otained above in this script:
script_realpath="$(realpath -e -- "${BASH_SOURCE[0]}")"

if [[ "$(realpath -e -- "${BASH_SOURCE[0]}")" =~ ^(.*)/(.*)$ ]]; then
  script_dirname="${BASH_REMATCH[1]}"
  script_name="${BASH_REMATCH[2]}"
  #echo script_dirname="$script_dirname"
  #echo script_name="$script_name"
  # . not appeared in script_name at all.
  if [[ "$script_name"  =~ ^([^.]*)$ ]]; then
    script_basename="$script_name"
    #echo script_basename="$script_basename"
  else
    # . appeared in script_name. 
    # As far as filename is concerned, when . is used as the last character, it doesn't have any spefical meaning.
    # Including . as the beginning character.
    if [[ "$script_name"  =~ ^([.].*)$ ]]; then
      script_extname="$script_name"
      #echo script_extname="$script_extname"
    # Including . but not as the beginning/trailing character.
    elif [[ "$script_name"  =~ ^([^.].*)[.]([^.]+)$  ]]; then
      script_basename="${BASH_REMATCH[1]}"
      script_extname="${BASH_REMATCH[2]}"
      #echo script_basename="$script_basename"
      #echo script_extname="$script_extname"
    fi
  fi
fi

#https://unix.stackexchange.com/questions/18886/why-is-while-ifs-read-used-so-often-instead-of-ifs-while-read

# software/anti-gfw/not-used/vpngate-relative/ecmp-vpngate/script/ovpn-traverse.sh
# man find:
# -printf format
# %f     File's name with any leading directories removed (only the last element).
# %h     Leading directories of file's name (all but the last element).  
# If the file name contains  no  slashes
#             (since it is in the current directory) the %h specifier expands to `.'.       
# %H     Starting-point under which file was found.  
# %p     File's name.
# %P     File's name with the name of the starting-point under which it was found removed.



#https://superuser.com/questions/731425/bash-detect-execute-vs-source-in-a-script
#https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
# Only executing the cd operation when script is not being sourced.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ $script_extname == "sh" ]]; then
    if [ -d "$topdir/$script_basename" ]; then  
      ncore=$(sudo dmidecode -t 4 | grep 'Core Enabled:' | awk '{a+=$NF}END{ print a }')
      cd $topdir/$script_basename
    else
      cd $topdir  
    fi
  fi
fi



# The idea

# Use a seperated local partition/remote filesystem ( say, nfs ), for my case, $ROOTSHARE,
# to populate the corresponding stuff which its directories conform to the
# Filesystem Hierarchy Standard，FHS:
# https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard

# Based on the xdg base directory specifications, find out which directories can be completely/partially shared.
# For the former, put it into the public $HOMESHARE_WORK_TREE/ directory, for the latter, only put the corresponding partially shared
# subdirectories into the corresponding location in the $HOMESHARE_WORK_TREE/ directory.

# For the corresponding (system|user)-wide settings, restore them by git repos as following:
# system-wide:
# https://github.com/hongyi-zhao/rootshare.git
# user-wide:
# https://github.com/hongyi-zhao/homeshare.git


# Finally, use the xdg autostart script and shell profile to automate the settings.



# these scripts are sourced by lexical / dictionary order,
# when there are two or more scripts to be sourced, make sure use correct filenames to
# ensure the execute logic among these scripts.



# Some needed tools:
# sudo apt-get install git gcc netcat socat haproxy gawk uuid gedit-plugins gnome-tweak-tool copyq telegram-desktop curl apt-file

ROOTSHARE=/rootshare

# Don't use `findmnt -r`, this use the following rule which makes the regex match impossiable for
# specifial characters, say space.
#       -r, --raw
#              Use  raw  output  format.   All  potentially  unsafe  characters  are  hex-escaped
#              (\x<code>).

# Don't run this script repeatedly:
if findmnt -l -o TARGET | grep -qE "^$ROOTSHARE$"; then
  return
fi

if [ ! -d $ROOTSHARE ]; then
  sudo mkdir -p $ROOTSHARE
  #sudo chown -hR root:root $ROOTSHARE
fi

# https://unix.stackexchange.com/questions/68694/when-is-double-quoting-necessary
# https://stackoverflow.com/questions/10067266/when-to-wrap-quotes-around-a-shell-variable

while IFS= read -r uuid; do
  if ! findmnt -l -o TARGET | grep -qE "^$ROOTSHARE$"; then
    sudo mount -U $uuid $ROOTSHARE
  fi

  if [ -d "$ROOTSHARE/rootshare.git" ]; then
    ROOTSHARE_ORIGIN_DIR=$ROOTSHARE/rootshare.git
    

    # This directory is for holding public data:
    HOMESHARE_WORK_TREE=$ROOTSHARE/homeshare
    HOMESHARE_ORIGIN_DIR=$HOMESHARE_WORK_TREE/Public/repo/github.com/hongyi-zhao/homeshare.git


    # Third party applications, say, intel's tools, are intalled in this directory for sharing:
    OPTSHARE=$ROOTSHARE/opt
    if [ ! -d $OPTSHARE ]; then
      sudo mkdir $OPTSHARE
    fi

    if ! findmnt -l -o TARGET | grep -qE "^/opt$"; then
      sudo mount -o rw,rbind $OPTSHARE /opt
    fi


    if [[ "$(realpath -e /.git 2>/dev/null)" != "$(realpath -e $ROOTSHARE_ORIGIN_DIR/.git)" ]]; then
      sudo rm -fr /.git
      sudo ln -sfr $ROOTSHARE_ORIGIN_DIR/.git /
    fi

    if ! git -C / diff --quiet; then 
      sudo git -C / reset --hard
    fi

    break
  else
    sudo umount $ROOTSHARE
  fi
done < <( lsblk -n -o type,uuid,mountpoint | awk 'NF >= 2 && $1 ~ /^part$/ && $2 ~/[0-9a-f-]{36}/ && $NF != "/" { print $2 }' )


# Based on the following conditions to do the settings:
if [ "$( id -u )" -ne 0 ] && [ -d "$ROOTSHARE_ORIGIN_DIR" ] && [ -d "$HOMESHARE_WORK_TREE" ] && [ -d "$HOMESHARE_ORIGIN_DIR" ]; then
  #https://specifications.freedesktop.org/menu-spec/latest/
  #https://wiki.archlinux.org/index.php/XDG_Base_Directory
  # XDG_DATA_DIRS
  # List of directories seperated by : (analogous to PATH).
  # Should default to /usr/local/share:/usr/share.

  #for desktop files search:

  # ref: ubuntu:
  # /etc/profile.d/xdg_dirs_desktop_session.sh
  if ! grep -Eq "$HOME/[.]local/share[/]?(:|$)" <<< $XDG_DATA_DIRS; then
    export XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS
  fi

  if ! grep -Eq '/usr/local/share[/]?(:|$)' <<< $XDG_DATA_DIRS; then
    export XDG_DATA_DIRS=/usr/local/share:$XDG_DATA_DIRS
  fi

  if ! grep -Eq '/usr/share[/]?(:|$)' <<< $XDG_DATA_DIRS; then
    export XDG_DATA_DIRS=/usr/share:$XDG_DATA_DIRS
  fi

  # attach the stuff found on $HOMESHARE_WORK_TREE/ at $HOME/:

  #https://unix.stackexchange.com/questions/18886/why-is-while-ifs-read-used-so-often-instead-of-ifs-while-read

  # software/anti-gfw/not-used/vpngate-relative/ecmp-vpngate/script/ovpn-traverse.sh
  # man find:
  # -printf format
  # %f     File's name with any leading directories removed (only the last element).
  # %h     Leading directories of file's name (all but the last element).
  # If the file name contains  no  slashes
  #             (since it is in the current directory) the %h specifier expands to `.'.
  # %H     Starting-point under which file was found.
  # %p     File's name.
  # %P     File's name with the name of the starting-point under which it was found removed.

  # Attach all top-level subdirectories found on $HOMESHARE_WORK_TREE/ at $HOME/:
  #find -L $HOMESHARE_WORK_TREE/ -mindepth 1 -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.][^/]*$" -printf '%P\n' |
  find $HOMESHARE_WORK_TREE/ -mindepth 1 -maxdepth 1 -type d -printf '%P\n' |
  while IFS= read -r line; do
    if [ ! -d $HOME/"$line" ]; then
      mkdir $HOME/"$line"
    fi

    if ! findmnt -l -o TARGET | grep -qE "^$HOME/$line$"; then
      sudo mount -o rw,rbind $HOMESHARE_WORK_TREE/"$line" $HOME/"$line"
    fi
  done

  # Initialize the settings for current user with homeshare.git.
  # If using the $HOMESHARE_ORIGIN_DIR/.git directory directly without mount it under $HOME, 
  # the following command should be issued:
  if ! git --work-tree=$HOME --git-dir=$HOMESHARE_ORIGIN_DIR/.git diff --quiet; then 
    git --work-tree=$HOME --git-dir=$HOMESHARE_ORIGIN_DIR/.git reset --hard
  fi 
fi






#https://bytefreaks.net/gnulinux/bash/how-to-execute-find-that-ignores-git-directories
#Example 1: Ignore all .git folders no matter where they are in the search path

#For find to ignore all .git folders, even if they appear on the first level of directories or any in-between until the last one, add -not -path '*/\.git*' to your command as in the example below.
#This parameter will instruct find to filter out any file that has anywhere in its path the folder .git. This is very helpful in case a project has dependencies in other projects (repositories) that are part of the internal structure.
#1
#
#find . -type f -not -path '*/\.git/*';

#Note, if you are using svn use:
#1
#
#find . -type f -not -path '*/\.svn/*';
#Example 2: Ignore all hidden files and folders

#To ignore all hidden files and folders from your find results add -not -path '*/\.*' to your command.
#1
#
#find . -not -path '*/\.*';

#This parameter instructs find to ignore any file that has anywhere in its path the string /. which is any hidden file or folder in the search path!


#http://mywiki.wooledge.org/UsingFind
#-path looks at the entire pathname, which includes the filename (in other words, what you see in find's output of -print) in order to match things.
#(At this point, I must point out that -path is not available on every version of find. In particular, Solaris lacks it. But it's pretty common on everything else.)




  # Some other tests which also can to the job:
  #find -L $PWD/.*  -maxdepth 0 -type d ! -path '*/.local' -regextype posix-extended -regex ".*/[.][^.][^/]*$"
  #find -L $PWD/ -mindepth 1 -maxdepth 1 -type d ! -path '*/.local' -path "$PWD/.*"
  #find -L $PWD/ -mindepth 1 -maxdepth 1 -type d ! -path '*/.local' -regextype posix-extended -regex ".*/[.][^/]*$"
  #find -L $PWD/ $PWD/.local $PWD/.local/share -mindepth 1  -maxdepth 1 -type d ! -path '*/.local' ! -path '*/.local/share' -path "$PWD/.*"

  #https://askubuntu.com/questions/76808/how-do-i-use-variables-in-a-sed-command


  # Dealing with hidden directories via one find command:
  #find -L $HOMESHARE_WORK_TREE/ $HOMESHARE_WORK_TREE/.local $HOMESHARE_WORK_TREE/.local/share \
  #     -mindepth 1  -maxdepth 1 -type d ! -path "$HOMESHARE_WORK_TREE/.local" ! -path "$HOMESHARE_WORK_TREE/.local/share" -path "$HOMESHARE_WORK_TREE/.*" 2>/dev/null |
  #sed -E "s|^$HOMESHARE_WORK_TREE/||" |
  #while IFS= read -r line; do
  #  if [ ! -d $HOME/"$line" ]; then
  #    mkdir -p $HOME/"$line"
  #  fi

  #  if ! findmnt -l -o TARGET | grep -qE "^$HOME/$line$"; then
  #    sudo mount -o rw,rbind $HOMESHARE_WORK_TREE/"$line" $HOME/"$line"
  #  fi
  #done
  
  
  




# ref：
# https://unix.stackexchange.com/questions/348321/purpose-of-the-autostart-scripts-directory
#https://specifications.freedesktop.org/autostart-spec/autostart-spec-latest.html
#https://wiki.archlinux.org/index.php/XDG_Base_Directory
#https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

#     XDG_CONFIG_HOME
#
#         Where user-specific configurations should be written (analogous to /etc).
#
#         Should default to $HOME/.config.
#
#
#
#     XDG_CACHE_HOME
#
#         Where user-specific non-essential (cached) data should be written (analogous to /var/cache).
#
#         Should default to $HOME/.cache.
#
#
#
#     XDG_DATA_HOME
#
#         Where user-specific data files should be written (analogous to /usr/share).
#
#         Should default to $HOME/.local/share.









