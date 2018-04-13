#!/bin/bash
#
#  Copyright (c) 2017 - Present  Jeong Han Lee
#  Copyright (c) 2017 - Present  European Spallation Source ERIC
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
#   date    : Friday, April 13 10:25:32 CEST 2018
#   version : 0.1.0


declare -gr SC_SCRIPT="$(realpath "$0")"
declare -gr SC_SCRIPTNAME=${0##*/}
declare -gr SC_TOP="$(dirname "$SC_SCRIPT")"

function pushd { builtin pushd "$@" > /dev/null; }
function popd  { builtin popd  "$@" > /dev/null; }


GIT_URL="https://github.com/icshwi"
GIT_CMD="git clone"
BOOL_GIT_CLONE="TRUE"

declare -ga require_list=("e3-base" "e3-require")
declare -ga module_list=()


function die
{
    error=${1:-1}
    ## exits with 1 if error number not given
    shift
    [ -n "$*" ] &&
	printf "%s%s: %s\n" "$scriptname" ${version:+" ($version)"} "$*" >&2
    exit "$error"
}


function checkout_e3_plus
{
    git checkout target_path_test
}

function help
{
    echo "">&2
    echo " Usage: $0 <arg>  ">&2 
    echo ""
    echo "          <arg>    : info">&2 
    echo ""
    echo "           all     : Setup and Build ALL">&2
    echo "           base    : Setup and Build Base and Require">&2
    echo "           modules : Setup and Build all modules">&2
    echo "           env     : Print all modules list">&2
    echo "">&2
    echo "">&2 	
}

function git_clone
{

    local rep_name=$1 ; shift;
    ${GIT_CMD} ${GIT_URL}/$rep_name
    
}

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



function setup_base_require
{
    local git_status=$1; shift;
    for rep in  ${require_list[@]}; do
	if [ "${BOOL_GIT_CLONE}" = "$git_status" ]; then
	    git_clone ${rep}
	fi
	pushd ${rep}
	checkout_e3_plus
	make init ||  die 1 "MAKE init ERROR at ${rep}: Please check it" ;
	make env
	if [ "${rep}" = "e3-base" ]; then
	    make pkgs
	    make patch
	fi
	popd
    done
}

function build_base_require
{

    sudo -v
    
    
    for rep in  ${require_list[@]}; do
	pushd ${rep}
	checkout_e3_plus
	make build ||  die 1 "Building Error at ${rep}: Please check the building error" ;
	if [ "${rep}" = "e3-require" ]; then
	    make install ||  die 1 "MAKE INSTALL ERROR at ${rep}: Please check it" ;
	fi
	popd
    done
}


function print_list
{
    local array=$1; shift;
    for a_list in ${array[@]}; do
	printf " %s\n" "$a_list";
    done
}

function setup_modules
{
    local git_status=$1; shift;
    local rep;
    for rep in  ${module_list[@]}; do
	if [ "${BOOL_GIT_CLONE}" = "$git_status" ]; then
	    git_clone ${rep}
	fi
	pushd ${rep}
	checkout_e3_plus
	make init ||  die 1 "MAKE init ERROR at ${rep}: Please check it" ; 
	make env
	make patch
	popd
    done

}

function build_modules
{

    for rep in  ${module_list[@]}; do
	pushd ${rep}
	checkout_e3_plus
	make build ||  die 1 "Building Error at ${rep}: Please check the building error" ;
	make install  ||  die 1 "MAKE INSTALL ERROR at ${rep}: Please check it" ;
	popd
    done
}


function clean_base_require
{

    local rep;
    for rep in  ${require_list[@]}; do
	echo "Cleaning .... $rep"
	sudo rm -rf ${SC_TOP}/${rep}
    done
}



function clean_modules
{
    local rep;
    sudo -v;
    for rep in  ${module_list[@]}; do
	echo "Cleaning .... $rep"
	pushd ${rep}
	make uninstall
	popd
	sudo rm -rf ${SC_TOP}/${rep}
    done
}



function git_pull
{
    local rep;
    for rep in  ${require_list[@]}; do
	pushd ${rep}
	git pull
	popd
    done

    for rep in  ${module_list[@]}; do
	pushd ${rep}
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
	git add ${git_add_file}
	popd
    done
}
   

function git_commit
{
    local rep;
    local git_commit_comment=$1; shift;
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	git commit -m "${git_commit_comment}"
	popd
    done
}


function git_push
{
    local rep;
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	git push
	popd
    done
}





#
# module name, configure/MODULES,
# sometimes is different in EPICS_MODULE_NAME in module/configure/CONFIG
# for example, sequencer
# module name       is sequencer
# EPICS_MODULE_NAME is seq

function module_loading_test_on_iocsh
{
    source ${SC_TOP}/e3-require/tools/setE3Env.bash

    local IOC_TEST=/tmp/module_loading_test.cmd
    
    {
	local PREFIX_MODULE="EPICS_MODULE_NAME:="
	local PREFIX_LIBVERSION="E3_MODULE_VERSION:="
	local mod=""
	local ver=""
	printf "var requireDebug 1\n";
	for rep in  ${module_list[@]}; do
	    while read line; do
		if [[ $line =~ "${PREFIX_LIBVERSION}" ]] ; then
		    ver=${line#$PREFIX_LIBVERSION}
		elif [[ $line =~ "${PREFIX_MODULE}" ]] ; then
		    mod=${line#$PREFIX_MODULE}
		fi
	    done < ${SC_TOP}/${rep}/configure/CONFIG_MODULE
	    if [ "${mod}" = "StreamDevice" ]; then
		mod="stream"
	    fi
	    printf "#\n#\n"
	    printf "# >>>>>\n";
	    printf "# >>>>> MODULE Loading ........\n";
	    printf "# >>>>> MODULE NAME ..... ${mod}\n";
	    printf "# >>>>>        VER  ..... ${ver}\n";
	    printf "# >>>>>\n";
	    printf "require ${mod}, ${ver}\n";
	    printf "# >>>>>\n";
	    printf "#\n#\n"
	done
	
    }  > ${IOC_TEST}

    exec iocsh.bash ${IOC_TEST}
}

module_list=$(get_module_list ${SC_TOP}/configure/MODULES)


case "$1" in
    all)
	setup_base_require "TRUE"
	build_base_require
	setup_modules      "TRUE"
	build_modules
	;;
    base)
    	setup_base_require "TRUE"
	build_base_require
	;;
    modules)
	setup_modules "TRUE"
	build_modules
	;;
    env)
	print_list "${module_list[@]}"
	;;
    pull)
	git_pull
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
    mod)
	build_modules
	;;
    rmod)
	clean_modules
	setup_modules  "TRUE"
	build_modules
	;;
    clean)
	clean_base_require
	clean_modules
	;;
    cmod)
	clean_modules
	;;
    db)
	install_db
	;;
    load)
	module_loading_test_on_iocsh
	;;
    *)
	help
	;;
esac

exit 0;





