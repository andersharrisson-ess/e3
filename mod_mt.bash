#!/bin/bash
#
#  Copyright (c) 2018 - Present  Jeong Han Lee
#
#  The program is free software: you can redistribute
#  it and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation, either version 2 of the
#  License, or any newer version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this program. If not, see https://www.gnu.org/licenses/gpl-2.0.txt
#
#
#   author  : Jeong Han Lee
#   email   : jeonghan.lee@gmail.com
#   date    : Saturday, April 14 23:30:01 CEST 2018
#   version : 0.0.2


# Example, how to use
#
# This script is used to copy a file to all modules directory, and
# prepare all git commands together.
# 
# $ bash mod_mt.bash pull
# copy the right file in TOP
# for example, RULES_E3
# $ scp e3-autosave/configure/E3/RULES_E3 .
# Define the target directory in each module 
# $ bash mod_mt.bash copy "RULES_E3" "configure/E3"
# $ bash mod_mt.bash diff "RULES_E3" "configure/E3"
# $ bash mod_mt.bash add  "RULES_E3" "configure/E3"
# $ bash mod_mt.bash commit "add/fix RULES_E3 to clean up the broken symlink"
# $ bash mod_mt.bash push
#

declare -gr SC_SCRIPT="$(realpath "$0")"
declare -gr SC_SCRIPTNAME=${0##*/}
declare -gr SC_TOP="$(dirname "$SC_SCRIPT")"

function pushd { builtin pushd "$@" > /dev/null; }
function popd  { builtin popd  "$@" > /dev/null; }


declare -ga require_list=("e3-base" "e3-require")
declare -ga module_list=()



function get_module_list
{
    local i;
    let i=0
    while IFS= read -r line_data; do
	if [ "$line_data" ]; then
	    # Skip command #
	    [[ "$line_data" =~ ^#.*$ ]] && continue
	    entry[i]="${line_data}"
	    ((++i))
	fi
    done < $1
    echo ${entry[@]}
}


function print_list
{
    local array=$1; shift;
    for a_list in ${array[@]}; do
	printf " %s\n" "$a_list";
    done
}



function git_pull
{
    local rep;
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	echo ""
	echo ">> git pull in ${rep}"
	git pull
	popd
    done
}
   


function git_add
{
    local rep;
    local git_add_file=$1; shift;
    local target_dir=$1; shift;
    local target=${target_dir}/${git_add_file}
    
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	echo ""
	echo ">> git add ${target} in ${rep}"
	git add ${target}
	popd
    done
}
   
function git_diff
{
    local rep;
    local git_add_file=$1; shift;
    local target=$1; shift;
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	echo ""
	echo ">> git diff in ${rep}"
	git diff ${target}/${git_add_file}
	popd
    done
}


function git_commit
{
    local rep;
    local git_commit_comment=$1; shift;
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	echo ""
	echo ">> git commit -m ${git_commit_comment} in $rep"
	git commit -m "${git_commit_comment}"
	popd
    done
}


function git_push
{
    local rep;
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	echo ""
	echo ">> git push in $rep"
	git push
	popd
    done
}

# a file should be in e3 directory
# 
# bash ugly_maintain.bash copy "DEFINES_FT" "configure/E3"
function copy_a_file
{
    local rep;
    local afile=$1; shift;
    local target=$1; shift;
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	echo ""
	echo "copy ../${afile} to ${target}/ in $rep"
	cp ../${afile} ${target}/
	popd
    done
}

# afile is ${SC_TOP}/afile
# bfile is file and path, e.g.,
# bfile is configure/CONFIG_MODULE

function append_afile_to_bfile
{
    local rep;
    local afile=$1; shift;
    local bfile=$1; shift;
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	echo ""
	echo ">> append $afile to $bfile in $rep"
	cat ${SC_TOP}/$afile >> $bfile
	popd
    done  
}

module_list=$(get_module_list ${SC_TOP}/configure/MODULES)


case "$1" in
    env)
	print_list "${module_list[@]}"
	;;
    pull)
	git_pull
	;;
    diff)
	git_diff  "$2" "$3"
	;;
    add)
	git_add "$2" "$3"
	;;
    commit)
	git_commit "$2"
	;;
    push)
	git_push
	;;
    copy)
	copy_a_file "$2" "$3"
	;;
    append)
        # update.txt has the following lines :
	#
	# # The definitions shown below can also be placed in an untracked CONFIG_MODULE.local
	# -include $(TOP)/configure/CONFIG_MODULE.local
	#
	# ./mod_mt.bash append "update.txt" "configure/CONFIG_MODULE"
	# ./mod_mt.bash diff "CONFIG_MODULE" "configure"
	# ./mod_mt.bash add  "CONFIG_MODULE" "configure"
	# ./mod_mt.bash commit "whatever I would like to say"
	# ./mod_mt.bash push
	append_afile_to_bfile "$2" "$3"
	;;
    *)
	echo "no help, please look at code."
	;;
esac

exit 0;





