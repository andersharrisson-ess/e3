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
#   date    : Thursday, February 22 01:21:23 CET 2018
#   version : 0.0.1


# Example, how to use
# 
# bash mod_mt.bash pull
# copy the right file in TOP
# for example, DEFINES_FT
# bash mod_mt.bash copy "DEFINES_FT" "configure/E3"
# bash mod_mt.bash diff 
# bash mod_mt.bash add "configure/E3/DEFINES_FT"
# bash mod_mt.bash commit "add/fix DEFINES_FT to handle patch"
# bash mod_mt.bash push
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
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	echo ""
	echo ">> git add ${git_add_file} in ${rep}"
	git add ${git_add_file}
	popd
    done
}
   
function git_diff
{
    local rep;
    local git_add_file=$1; shift;
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	echo ""
	echo ">> git diff in ${rep}"
	git diff
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


module_list=$(get_module_list ${SC_TOP}/configure/MODULES)


case "$1" in
    env)
	print_list "${module_list[@]}"
	;;
    pull)
	git_pull
	;;
    diff)
	git_diff
	;;
    add)
	git_add "$2"
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
    *)
	echo "no help"
	;;
esac

exit 0;





