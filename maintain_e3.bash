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
#   date    : Monday, April 16 00:14:59 CEST 2018
#   version : 0.0.4


# Example, how to use
#
# This script is used to copy a file to all modules directory, and
# prepare all git commands together.
# 
# $ bash maintain_e3.bash pull
# copy the right file in TOP
# for example, RULES_E3
# $ scp e3-autosave/configure/E3/RULES_E3 .
# Define the target directory in each module 
# $ bash maintain_e3.bash copy "RULES_E3" "configure/E3"
# $ bash maintain_e3.bash diff "RULES_E3" "configure/E3"
# $ bash maintain_e3.bash add  "RULES_E3" "configure/E3"
# $ bash maintain_e3.bash commit "add/fix RULES_E3 to clean up the broken symlink"
# $ bash maintain_e3.bash push
#

declare -gr SC_SCRIPT="$(realpath "$0")"
declare -gr SC_SCRIPTNAME=${0##*/}
declare -gr SC_TOP="$(dirname "$SC_SCRIPT")"

function pushd { builtin pushd "$@" > /dev/null; }
function popd  { builtin popd  "$@" > /dev/null; }


declare -ga require_list=("e3-base" "e3-require")
declare -ga module_list=()


function read_file_get_string
{
    local FILENAME=$1
    local PREFIX=$2

    local val=""
    while read line; do
	if [[ $line =~ "${PREFIX}" ]] ; then
	    val=${line#$PREFIX}
	fi
    done < ${FILENAME}

    echo "$val"
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

# this function has some issue to print array, beaware it.

# function print_list
# {
#     local array=$1; shift;
#     for a_list in ${array[@]}; do
# 	printf " %s\n" "$a_list";
#     done
# }


function print_list
{
    local a_list;
    for a_list in ${module_list[@]}; do
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


function print_version_info
{
    local rep;
    local conf_mod="configure/CONFIG_MODULE";
    local epics_version=""
    local e3_version=""
    for rep in  ${module_list[@]}; do
	pushd ${rep}
	epics_version="$(read_file_get_string   "${conf_mod}" "EPICS_MODULE_TAG:=")"
	e3_version="$(read_file_get_string      "${conf_mod}" "E3_MODULE_VERSION:=")"
	echo ""
	echo ">> ${rep}"
	echo "   EPICS_MODULE_TAG  : ${epics_version}"
	echo "   E3_MODULE_VERSION : ${e3_version}"
	popd
    done
}


function usage
{
    {
	echo "";
	echo "Usage    : $0 [ -g <group_name> ] <option> ";
	echo "";
	echo " < group_name > ";
	echo ""
	echo "           common : epics modules"
	echo "           timing : mrf timing    modules";
	echo "           ifc    : ifc platform  related modules";
	echo "           ecat   : ethercat      related modules";
	echo "           area   : area detector related modules";
	echo "           test   : common, timing, ifc modules";
	echo "           jhlee  : common, timing, ifc, area modules";
	echo "           all    : common, timing, ifc, ecat, area modules";
	echo "";
	
	echo " < option > ";
	echo "";
      
	echo "           env     : Print all modules";
	echo "           version : Print all module versions";
       	echo "           pull    : git pull in all modules"           
	echo "           push    : git push in all modules"
	echo "           many others : look at source code"
	echo ""
	echo "  Examples : ";
	echo ""    
	echo "          $0 env";
	echo "   ";       
	echo "";
	
    } 1>&2;
    exit 1; 
}



while getopts " :g:" opt; do
    case "${opt}" in
	g)
	    GROUP_NAME=${OPTARG}
	    ;;
	*)
	    usage
	    ;;
    esac
done
shift $((OPTIND-1))




case "${GROUP_NAME}" in
    common)
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_COMMON)" )
	;;
    timing*)
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_TIMING)" )
	;;
    ifc)
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_IFC)" )
	;;
    ecat)
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_ECAT)" )
	;;
    area)
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_AD)" )
	;;
    test)
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_COMMON)" )
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_TIMING)" )
#	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_IFC)"    )
#	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_AD)"     )
	;;
    jhlee)
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_COMMON)" )
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_TIMING)" )
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_IFC)"    )
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_AD)"     )
	echo ""
	;;
    all)
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_COMMON)" )
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_TIMING)" )
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_IFC)"    )
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_ECAT)"   )
	module_list+=( "$(get_module_list ${SC_TOP}/configure/MODULES_AD)"     )
	;;
    * )
	module_list+=( "iocStats" )
    #  	usage
	;;
    # ;;
esac


case "$1" in
    base)
	echo ""
	;;
    req)
	echo ""
	;;
    clean)
	echo ""
	;;
    *) 
	echo ">> Selected Modules are :"
	echo ${module_list[@]}
	echo ""
	;;

esac


case "$1" in
    env)
	echo ">> Vertical display for the selected modules :"
	echo ""
	print_list
	echo ""
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
	# ./maintain_e3.bash -g area  append "update.txt" "configure/CONFIG_MODULE"
	# ./maintain_e3.bash -g area diff "CONFIG_MODULE" "configure"
	# ./maintain_e3.bash -g area add  "CONFIG_MODULE" "configure"
	# ./maintain_e3.bash -g area commit "whatever I would like to say"
	# ./maintain_e3.bash -g area push
	# The definitions shown below can also be placed in an untracked RELEASE.local
	#-include $(TOP)/../RELEASE.local
	#-include $(TOP)/configure/RELEASE.local
	# ./maintain_e3.bash -g area  append "update.txt" "configure/RELEASE"
	# ./maintain_e3.bash -g area diff "RELEASE" "configure"
	# ./maintain_e3.bash -g area add  "RELEASE" "configure"
	# ./maintain_e3.bash -g area commit "whatever I would like to say"
	# ./maintain_e3.bash -g area push
	# The definitions shown below can also be placed in an untracked RELEASE_DEV.local
	# -include $(TOP)/../RELEASE_DEV.local
	# -include $(TOP)/configure/RELEASE_DEV.local
	# ./maintain_e3.bash -g area  append "update.txt" "configure/RELEASE_DEV"
	# ./maintain_e3.bash -g area diff "RELEASE_DEV" "configure"
	# ./maintain_e3.bash -g area add  "RELEASE_DEV" "configure"
	# ./maintain_e3.bash -g area commit "whatever I would like to say"
	# ./maintain_e3.bash -g area push
	append_afile_to_bfile "$2" "$3"
	;;
    version)
	print_version_info
	;;
    *)
	usage
	;;
esac

exit 0;





