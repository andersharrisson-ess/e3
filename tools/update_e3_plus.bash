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
#   date    : Monday, February 12 11:32:01 CET 2018
#   version : 0.0.3


declare -gr SC_SCRIPT="$(realpath "$0")"
declare -gr SC_SCRIPTNAME=${0##*/}
declare -gr SC_TOP="$(dirname "$SC_SCRIPT")"
declare -gr SC_LOGDATE="$(date +%Y%b%d-%H%M-%S%Z)"
declare -gr SC_USER="$(whoami)"

function pushd { builtin pushd "$@" > /dev/null; }
function popd  { builtin popd  "$@" > /dev/null; }

ICS_GIT_URL="https://github.com/icshwi"

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



function usage
{
    {
	echo "";
	echo "Usage    : $0 [-m <mod_name> ] ";
	echo "";
	echo "Examples : ";
	echo "          -m ipmiComm ";
    } 1>&2;
    exit 1; 
}



while getopts " :m:s:h:" opt; do
    case "${opt}" in
	m)
	    MODULE_NAME=${OPTARG}
	    ;;
	*)
	    usage
	    ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${MODULE_NAME}" ] ; then
    usage
fi



git clone ${ICS_GIT_URL}/e3-${MODULE_NAME}


pushd e3-${MODULE_NAME}


git checkout -b target_path_test
git submodule deinit -f -- e3-env
rm -rf .git/modules/e3-env
git rm -f e3-env



cat > Makefile <<EOF
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
# Author  : Jeong Han Lee
# email   : jeonghan.lee@gmail.com
# Date    : ${SC_LOGDATE}
# version : 0.0.1


TOP:=\$(CURDIR)

include \$(TOP)/configure/CONFIG

include \$(TOP)/configure/RULES

EOF



mv configure configure_old


declare -g epics_module_tag=""
declare -g e3_module_version=""
declare -g epics_module_dev_tag==""
declare -g e3_module_dev_version=""


config_file=configure_old/CONFIG


if [ ! -e "$config_file" ]; then
    # doesn't exist
    epics_module_tag="master"
    e3_module_version="master"
else
    # exist
    epics_module_tag="$(read_file_get_string  "${config_file}" "export EPICS_MODULE_TAG:=")"
    e3_module_version="$(read_file_get_string "${config_file}" "export LIBVERSION:=")"
fi

config_dev_file=configure_old/CONFIG_DEV


if [ ! -e "$config_dev_file" ]; then
    # doesn't exist
    epics_module_dev_tag="master"
    e3_module_dev_version="develop"
    
else
    # exist
    epics_module_dev_tag="$(read_file_get_string  "${config_dev_file}" "export EPICS_MODULE_TAG:=")"
    e3_module_dev_version="$(read_file_get_string "${config_dev_file}" "export LIBVERSION:=")"
fi

echo ""
echo "EPICS_Module_TAG      : $epics_module_tag"
echo "E3_MODULE_VERSION     : $e3_module_version"
echo "EPICS_Module_DEV_TAG  : $epics_module_dev_tag"
echo "E3_MODULE_DEV_VERSION : $e3_module_dev_version"


mkdir -p patch/Site

pushd patch/Site

cat > README.md <<EOF
# Site Specific EPICS Module Patch Files

## Changes
The changes were tested in local environemnt, and commits to the forked repository and do pull request to the epics community module repository.

* Check the original HASH, and your own master
* feb8856 : The original HASH
* master : Changed


## How to create a p0 patch file between commits


* Show what the difference between commits


* Create p0 patch

```
$ git diff feb8856 master --no-prefix > ../patch/Site/what_ever_filename.p0.patch
```

EOF



cat > HISTORY.md <<EOF
# what_ever_filename.p0.patch

Generic Description.....

* created by Jeong Han Lee, han.lee@esss.se
* related URL or reference https://github.com/icshwi
* Tuesday, February 13 13:24:57 CET 2018
EOF



popd

mkdir -p configure/E3


pushd configure

cat > CONFIG <<EOF
VARS_EXCLUDES := \$(.VARIABLES)


ifneq (,\$(findstring dev,\$(MAKECMDGOALS)))
include \$(TOP)/configure/RELEASE_DEV
else
include \$(TOP)/configure/RELEASE
endif

# CONFIG=\$(EPICS_BASE)/configure
# include \$(CONFIG)/CONFIG

ifneq (,\$(findstring dev,\$(MAKECMDGOALS)))
include \$(TOP)/configure/CONFIG_MODULE_DEV
else
include \$(TOP)/configure/CONFIG_MODULE
endif

# The definitions shown below can also be placed in an untracked RELEASE.local
-include \$(TOP)/../RELEASE.local
-include \$(TOP)/configure/RELEASE.local
-include \$(TOP)/../CONFIG_MODULE.local
-include \$(TOP)/configure/CONFIG_MODULE.local


## Asyn, ADSupport may needs to define other variables

-include \$(TOP)/configure/CONFIG_OPTIONS

## It is not necessary to modify the following files in most case.
## Order is matter

include \$(TOP)/configure/E3/CONFIG_REQUIRE
include \$(TOP)/configure/E3/CONFIG_E3_PATH
include \$(TOP)/configure/E3/CONFIG_E3_MAKEFILE
include \$(TOP)/configure/E3/CONFIG_EPICS
include \$(TOP)/configure/E3/CONFIG_SUDO
include \$(TOP)/configure/E3/CONFIG_EXPORT
EOF


cat > RELEASE <<EOF
EPICS_BASE=/testing/epics/base-3.15.5

E3_REQUIRE_NAME:=require
E3_REQUIRE_VERSION:=0.0.0

EOF


cat > RELEASE_DEV <<EOF
EPICS_BASE=/testing/epics/base-3.15.5

E3_REQUIRE_NAME:=require
E3_REQUIRE_VERSION:=0.0.0

EOF


cat > CONFIG_MODULE <<EOF
#
EPICS_MODULE_NAME:=${MODULE_NAME}
EPICS_MODULE_TAG:=${epics_module_tag}
#
E3_MODULE_VERSION:=${e3_module_version}


# ONLY IF this module has the sequencer dependency. However,
# in most case, we don't need to enable the following line,
# the default - latest version will be used
#E3_SEQUENCER_NAME:=sequencer
#E3_SEQUENCER_VERSION:=2.1.21
#
# In most case, we don't need to touch the following variables.
#

E3_MODULE_NAME:=\$(EPICS_MODULE_NAME)
E3_MODULE_SRC_PATH:=\$(EPICS_MODULE_NAME)
E3_MODULE_MAKEFILE:=\$(EPICS_MODULE_NAME).Makefile

EOF


cat > CONFIG_MODULE_DEV <<EOF
#
EPICS_MODULE_NAME:=${MODULE_NAME}
EPICS_MODULE_TAG:=${epics_module_dev_tag}
#
E3_MODULE_VERSION:=${e3_module_dev_version}

# ONLY IF this module has the sequencer dependency. However,
# in most case, we don't need to enable the following line,
# the default - latest version will be used
#E3_SEQUENCER_NAME:=sequencer
#E3_SEQUENCER_VERSION:=2.1.21
#
# In most case, we don't need to touch the following variables.
#
E3_MODULE_NAME:=\$(EPICS_MODULE_NAME)
E3_MODULE_SRC_PATH:=\$(EPICS_MODULE_NAME)-dev
E3_MODULE_MAKEFILE:=\$(EPICS_MODULE_NAME).Makefile

#export DEV_GIT_URL:="https://where your git repo"
E3_MODULE_DEV_GITURL:="https://github.com/epics-modules/${MODULE_NAME}"

EOF


cat > RULES <<EOF
#CONFIG
# include \$(EPICS_BASE)/configure/RULES

include \$(TOP)/configure/E3/DEFINES_FT
-include \$(TOP)/configure/E3/RULES_PATCH
include \$(TOP)/configure/E3/RULES_E3
include \$(TOP)/configure/E3/RULES_EPICS

include \$(TOP)/configure/E3/RULES_DB
include \$(TOP)/configure/E3/RULES_VARS


ifneq (,\$(findstring dev,\$(MAKECMDGOALS)))
include \$(TOP)/configure/E3/RULES_DEV
endif


EOF



cat > CONFIG_OPTIONS <<EOF
# One should install libusb-1.0.0
# Debian apt-get install libusb-1.0-0-dev libusb-1.0-0
# USR_INCLUDES 
# $ pkg-config --cflags libusb-1.0
#   -I/usr/include/libusb-1.0
# USR_LDFLAGS
# $ pkg-config --libs libusb-1.0
# $ -lusb-1.0 
#
#ifeq (linux-x86_64, \$(T_A))
#  DRV_USBTMC=YES
#  export DRV_USBTMC
#endif
EOF

popd # configure 

pushd configure/E3


cat > CONFIG_SUDO <<EOF
# IF EPICS_BASE is not WRITABLE, SUDO and SUDOBASH should be used 
# SUDO_INFO 1 : SUDO is needed (NOT writable)
# SUDO_INFO 0 : SUDO is not needed
SUDO_INFO := \$(shell test -w \$(EPICS_BASE) 1>&2 2> /dev/null; echo \$\$?)

ifeq "\$(SUDO_INFO)" "1"
SUDO := sudo
SUDOBASH = \$(SUDO)
SUDOBASH += -E
SUDOBASH += bash -c
endif    


# Valid for only Development Mode, because we clone/remove them
# See RULES_DEV
# E3_MODULE_SRC_PATH_INFO 1 : the directory is not there
# E3_MODULE_SRC_PATH_INFO 0 : the directory is there
E3_MODULE_SRC_PATH_INFO := \$(shell test -d \$(E3_MODULE_SRC_PATH) 1>&2 2> /dev/null; echo \$\$?)

ifeq "\$(E3_MODULE_SRC_PATH_INFO)" "1"
INIT_E3_MODULE_SRC = 1
endif    

EOF

cat > CONFIG_REQUIRE <<EOF
E3_REQUIRE_LOCATION:=\$(EPICS_BASE)/\$(E3_REQUIRE_NAME)/\$(E3_REQUIRE_VERSION)

E3_REQUIRE_BIN:=\$(E3_REQUIRE_LOCATION)/bin
E3_REQUIRE_TOOLS:=\$(E3_REQUIRE_LOCATION)/tools
E3_REQUIRE_LIB:=\$(E3_REQUIRE_LOCATION)/lib
E3_REQUIRE_DB:=\$(E3_REQUIRE_LOCATION)/db
E3_REQUIRE_DBD:=\$(E3_REQUIRE_LOCATION)/dbd
E3_REQUIRE_INC:=\$(E3_REQUIRE_LOCATION)/include

EOF

cat > CONFIG_EPICS <<EOF
COMMUNITY_EPICS_MODULES:=\$(EPICS_BASE)/epics-modules

M_AUTOSAVE:=\$(COMMUNITY_EPICS_MODULES)/autosave
M_DEVLIB2:=\$(COMMUNITY_EPICS_MODULES)/devlib2
M_IOCSTATS:=\$(COMMUNITY_EPICS_MODULES)/iocStats
M_ASYN:=\$(COMMUNITY_EPICS_MODULES)/asyn
M_BUSY:=\$(COMMUNITY_EPICS_MODULES)/busy
M_MODBUS:=\$(COMMUNITY_EPICS_MODULES)/modbus
M_MRFIOC2:=\$(COMMUNITY_EPICS_MODULES)/mrfioc2
M_LUA:=\$(COMMUNITY_EPICS_MODULES)/lua
M_IPMICOMM:=\$(COMMUNITY_EPICS_MODULES)/ipmiComm
M_STREAM:=\$(COMMUNITY_EPICS_MODULES)/stream
M_CALC:=\$(COMMUNITY_EPICS_MODULES)/calc
M_MOTOR:=\$(COMMUNITY_EPICS_MODULES)/motor
M_SSCAN:=\$(COMMUNITY_EPICS_MODULES)/sscan
M_SNCSEQ:=\$(COMMUNITY_EPICS_MODULES)/seq
M_IP:=\$(COMMUNITY_EPICS_MODULES)/ip
M_IPAC:=\$(COMMUNITY_EPICS_MODULES)/ipac
M_ADSUPPORT:=\$(COMMUNITY_EPICS_MODULES)/adsupport
M_ADCORE:=\$(COMMUNITY_EPICS_MODULES)/adcore




export M_AUTOSAVE
export M_DEVLIB2
export M_IOCSTATS
export M_ASYN
export M_BUSY
export M_MODBUS
export M_MRFIOC2
export M_LUA
export M_IPMICOMM
export M_STREAM
export M_CALC
export M_MOTOR
export M_SSCAN
export M_SNCSEQ
export M_IP
export M_IPAC
export M_ADSUPPORT
export M_ADCORE

### Exclude the following variables to display 
VARS_EXCLUDES+=COMMUNITY_EPICS_MODULES
VARS_EXCLUDES+=M_AUTOSAVE
VARS_EXCLUDES+=M_DEVLIB2
VARS_EXCLUDES+=M_IOCSTATS
VARS_EXCLUDES+=M_ASYN
VARS_EXCLUDES+=M_BUSY
VARS_EXCLUDES+=M_MODBUS
VARS_EXCLUDES+=M_MRFIOC2
VARS_EXCLUDES+=M_LUA
VARS_EXCLUDES+=M_IPMICOMM
VARS_EXCLUDES+=M_STREAM
VARS_EXCLUDES+=M_CALC
VARS_EXCLUDES+=M_MOTOR
VARS_EXCLUDES+=M_SSCAN
VARS_EXCLUDES+=M_SNCSEQ
VARS_EXCLUDES+=M_IP
VARS_EXCLUDES+=M_IPAC
VARS_EXCLUDES+=M_ADSUPPORT
VARS_EXCLUDES+=M_ADCORE

EOF

cat > CONFIG_E3_PATH <<EOF
E3_MODULES_PATH:=\$(E3_REQUIRE_LOCATION)/siteMods
E3_SITEMODS_PATH:=\$(E3_MODULES_PATH)
E3_SITELIBS_PATH:=\$(E3_REQUIRE_LOCATION)/siteLibs
E3_SITEAPPS_PATH:=\$(E3_REQUIRE_LOCATION)/siteApps


E3_MODULES_INSTALL_LOCATION:=\$(E3_SITEMODS_PATH)/\$(E3_MODULE_NAME)/\$(E3_MODULE_VERSION)


E3_MODULES_INSTALL_LOCATION_INC:=\$(E3_MODULES_INSTALL_LOCATION)/include
E3_MODULES_INSTALL_LOCATION_DB :=\$(E3_MODULES_INSTALL_LOCATION)/db
E3_MODULES_INSTALL_LOCATION_BIN:=\$(E3_MODULES_INSTALL_LOCATION)/bin


E3_MODULES_INSTALL_LOCATION_INC_LINK:=\$(E3_SITELIBS_PATH)/\$(E3_MODULE_NAME)_\$(E3_MODULE_VERSION)_include
E3_MODULES_INSTALL_LOCATION_DB_LINK :=\$(E3_SITELIBS_PATH)/\$(E3_MODULE_NAME)_\$(E3_MODULE_VERSION)_db
E3_MODULES_INSTALL_LOCATION_BIN_LINK:=\$(E3_SITELIBS_PATH)/\$(E3_MODULE_NAME)_\$(E3_MODULE_VERSION)_bin


E3_MODULES_INSTALL_LOCATION_DBD:=\$(E3_MODULES_INSTALL_LOCATION)/dbd/\$(E3_MODULE_NAME).dbd
E3_MODULES_INSTALL_LOCATION_DBD_LINK:=\$(E3_SITELIBS_PATH)/\$(E3_MODULE_NAME).dbd.\$(E3_MODULE_VERSION)



# It is a bit weird, it would be better to implement within driver.makefile later
# Assumption : we are using the same lib name from driver.makefile 
E3_MODULES_LIBNAME:=lib\$(E3_MODULE_NAME).so

INSTALLED_EPICS_BASE_ARCHS_PATHS=\$(sort \$(dir \$(wildcard \$(EPICS_BASE)/bin/*/)))
TEMP_INSTALLED_EPICS_BASE_ARCHS=\$(INSTALLED_EPICS_BASE_ARCHS_PATHS:\$(EPICS_BASE)/bin/%=%)
INSTALLED_EPICS_BASE_ARCHS=\$(TEMP_INSTALLED_EPICS_BASE_ARCHS:/=)



### Exclude the following variables to display 
VARS_EXCLUDES+=TEMP_INSTALLED_EPICS_BASE_ARCHS
VARS_EXCLUDES+=INSTALLED_EPICS_BASE_ARCHS_PATHS

EOF

cat > CONFIG_E3_MAKEFILE <<EOF
# Pass necessary driver.makefile variables through makefile options
#

E3_REQUIRE_MAKEFILE_INPUT_OPTIONS := -C \$(E3_MODULE_SRC_PATH)
E3_REQUIRE_MAKEFILE_INPUT_OPTIONS += -f \$(E3_MODULE_MAKEFILE)
E3_REQUIRE_MAKEFILE_INPUT_OPTIONS += LIBVERSION="\$(E3_MODULE_VERSION)"
E3_REQUIRE_MAKEFILE_INPUT_OPTIONS += PROJECT="\$(E3_MODULE_NAME)"
E3_REQUIRE_MAKEFILE_INPUT_OPTIONS += EPICS_MODULES="\$(E3_MODULES_PATH)"
E3_REQUIRE_MAKEFILE_INPUT_OPTIONS += EPICS_LOCATION="\$(EPICS_BASE)"
E3_REQUIRE_MAKEFILE_INPUT_OPTIONS += BUILDCLASSES="Linux"
E3_REQUIRE_MAKEFILE_INPUT_OPTIONS += E3_SITEMODS_PATH="\$(E3_SITEMODS_PATH)"
E3_REQUIRE_MAKEFILE_INPUT_OPTIONS += E3_SITEAPPS_PATH="\$(E3_SITEAPPS_PATH)"
E3_REQUIRE_MAKEFILE_INPUT_OPTIONS += E3_SITELIBS_PATH="\$(E3_SITELIBS_PATH)"
E3_REQUIRE_MAKEFILE_INPUT_OPTIONS += E3_SEQUENCER_NAME="\$(E3_SEQUENCER_NAME)"
E3_REQUIRE_MAKEFILE_INPUT_OPTIONS += E3_SEQUENCER_VERSION="\$(E3_SEQUENCER_VERSION)"

E3_MODULE_MAKE_CMDS:=make \$(E3_REQUIRE_MAKEFILE_INPUT_OPTIONS)


VARS_EXCLUDES+=E3_REQUIRE_MAKEFILE_INPUT_OPTIONS

EOF

cat > CONFIG_EXPORT <<EOF
# Variables should be transferred to module_name.makefile

EPICS_HOST_ARCH:=\$(shell \$(EPICS_BASE)/startup/EpicsHostArch.pl)

export EPICS_BASE
export EPICS_HOST_ARCH
export E3_REQUIRE_TOOLS
export E3_MODULE_VERSION
#export E3_SITEMODS_PATH
#export E3_SITEAPPS_PATH
#export E3_SITELIBS_PATH
#export E3_SEQUENCER_NAME
#export E3_SEQUENCER_VERSION

EOF



cat > DEFINES_FT <<EOF
# Keep always the module up-to-date
define git_update =
git submodule deinit -f \$@/
sed -i '/submodule/,24465d'  \$(TOP)/.git/config
rm -rf \$(TOP)/.git/modules/\$@
git submodule init \$@/
git submodule update --init --recursive \$@/.
git submodule update --remote --merge \$@/
endef

define patch_site
for i in \$(wildcard \$(TOP)/patch/Site/*p0.patch); do\
	printf "\nPatching %s with the file : %s\n" "\$(E3_MODULE_SRC_PATH)" "$$i"; \
	patch -d \$(E3_MODULE_SRC_PATH) --ignore-whitespace -p0 < $$i;\
done
endef


define patch_revert_site
for i in \$(wildcard \$(TOP)/patch/Site/*p0.patch); do\
	printf "\nPatching %s with the file : %s\n" "\$(E3_MODULE_SRC_PATH)" "$$i"; \
	patch -R -d \$(E3_MODULE_SRC_PATH) --ignore-whitespace -p0 < $$i;\
done

endef


ifndef VERBOSE
  QUIET := @
endif

ifdef DEBUG_SHELL
  SHELL = /bin/sh -x
endif


### Exclude the following variables to display 
VARS_EXCLUDES+=git_update
VARS_EXCLUDES+=patch_site
VARS_EXCLUDES+=patch_revert_site
VARS_EXCLUDES+=QUIET
VARS_EXCLUDES+=SHELL

EOF

cat > RULES_PATCH <<EOF

.PHONY: patch patchrevert


## Apply Patch Files 
patch:
	\$(QUIET) \$(call patch_site)

## Revert Patch Files 
patchrevert:
	\$(QUIET) \$(call patch_revert_site)

EOF
	


cat  > RULES_VARS <<EOF

E3_MODULES_VARIABLES:=\$(sort \$(filter-out \$(VARS_EXCLUDES) VARS_EXCLUDES,\$(.VARIABLES)))

.PHONY : env vars header


## Print interesting VARIABLES
env: vars

vars: header
	\$(foreach v, \$(E3_MODULES_VARIABLES), \$(info \$(v) = \$(\$(v)))) @#noop

header:
	\$(QUIET)echo ""
	\$(QUIET)echo "------------------------------------------------------------"
	\$(QUIET)echo ">>>>     Current EPICS and E3 Envrionment Variables     <<<<"
	\$(QUIET)echo "------------------------------------------------------------"
	\$(QUIET)echo ""


EOF

cat > RULES_EPICS <<EOF
# One should define the any dependency modules and EPICS base path
# in the following directory

.PHONY: epics epics-clean

epics:
#	\$(QUIET)echo "ASYN=\$(M_ASYN)"                  > \$(TOP)/\$(E3_MODULE_SRC_PATH)/configure/RELEASE
#	\$(QUIET)echo "SSCAN=\$(M_SSCAN)"               >> \$(TOP)/\$(E3_MODULE_SRC_PATH)/configure/RELEASE
#	\$(QUIET)echo "SNCSEQ=\$(M_SNCSEQ)"             >> \$(TOP)/\$(E3_MODULE_SRC_PATH)/configure/RELEASE
	\$(QUIET)echo "EPICS_BASE=\$(EPICS_BASE)"       >> \$(TOP)/\$(E3_MODULE_SRC_PATH)/configure/RELEASE
	\$(QUIET)echo "CHECK_RELEASE = YES"              > \$(TOP)/\$(E3_MODULE_SRC_PATH)/configure/CONFIG_SITE
#	\$(QUIET)echo "INSTALL_LOCATION=\$(M_DEVLIB2)"  >> \$(TOP)/\$(E3_MODULE_SRC_PATH)/configure/CONFIG_SITE
	\$(SUDOBASH) "\$(MAKE) -C \$(E3_MODULE_SRC_PATH)"

epics-clean:
	\$(SUDOBASH) "\$(MAKE) -C \$(E3_MODULE_SRC_PATH) clean"


EOF

cat > RULES_E3 <<EOF

.PHONY: help default install uninstall build rebuild clean conf

default: help


# # help is defined in 
# # https://gist.github.com/rcmachado/af3db315e31383502660
help:
	\$(info --------------------------------------- )	
	\$(info Available targets)
	\$(info --------------------------------------- )
	\$(QUIET) awk '/^[a-zA-Z\-\_0-9]+:/ {            \\
	  nb = sub( /^## /, "", helpMsg );              \\
	  if(nb == 0) {                                 \\
	    helpMsg = \$\$0;                              \\
	    nb = sub( /^[^:]*:.* ## /, "", helpMsg );   \\
	  }                                             \\
	  if (nb)                                       \\
	    print  \$\$1 "\t" helpMsg;                    \\
	}                                               \\
	{ helpMsg = \$\$0 }'                              \\
	\$(MAKEFILE_LIST) | column -ts:	



## Install : \$(E3_MODULE_NAME)
install: install_module install_links

#install_module: uninstall 
install_module: uninstall db
	\$(QUIET) \$(SUDOBASH) '\$(E3_MODULE_MAKE_CMDS) install'

## Uninstall : \$(E3_MODULE_NAME)
uninstall: conf
	\$(QUIET) \$(SUDOBASH) '\$(E3_MODULE_MAKE_CMDS) uninstall'

## Build the EPICS Module : \$(E3_MODULE_NAME)
# Build always the Module with the EPICS_MODULES_TAG
build: conf checkout
	\$(QUIET) \$(E3_MODULE_MAKE_CMDS) build


## Clean, build, and install the EPICS Module : \$(E3_MODULE_NAME)
rebuild: clean build install


## Clean : \$(E3_MODULE_NAME)
clean: conf
	\$(QUIET) \$(E3_MODULE_MAKE_CMDS) clean


## Copy \$(E3_MODULE_MAKEFILE) into \$(E3_MODULE_SRC_PATH)
conf: 
	\$(QUIET) install -m 644 \$(TOP)/\$(E3_MODULE_MAKEFILE)  \$(E3_MODULE_SRC_PATH)/


.PHONY: init git-submodule-sync \$(E3_MODULE_SRC_PATH)  checkout

## Initialize : \$(E3_MODULE_SRC_PATH) 
init: git-submodule-sync \$(E3_MODULE_SRC_PATH)  checkout

git-submodule-sync:
	\$(QUIET) git submodule sync


\$(E3_MODULE_SRC_PATH): 
	\$(QUIET) \$(git_update)

checkout: 
	cd \$(E3_MODULE_SRC_PATH) && git checkout \$(EPICS_MODULE_TAG)



# Create symbolic links in siteLibs

.PHONY: install_links \$(INSTALLED_EPICS_BASE_ARCHS)


install_links: \$(INSTALLED_EPICS_BASE_ARCHS)
	\$(SUDO) ln -snf \$(E3_MODULES_INSTALL_LOCATION_INC) \$(E3_MODULES_INSTALL_LOCATION_INC_LINK)
	\$(SUDO) ln -snf \$(E3_MODULES_INSTALL_LOCATION_DB)  \$(E3_MODULES_INSTALL_LOCATION_DB_LINK)
	\$(SUDO) ln -snf \$(E3_MODULES_INSTALL_LOCATION_BIN) \$(E3_MODULES_INSTALL_LOCATION_BIN_LINK)
	\$(SUDO) ln -sf  \$(E3_MODULES_INSTALL_LOCATION_DBD) \$(E3_MODULES_INSTALL_LOCATION_DBD_LINK)


\$(INSTALLED_EPICS_BASE_ARCHS):
	\$(SUDO) mkdir -p \$(E3_SITELIBS_PATH)/\$@
	\$(SUDO) ln -sf \$(E3_MODULES_INSTALL_LOCATION)/lib/\$@/\$(E3_MODULES_LIBNAME) \$(E3_SITELIBS_PATH)/\$@/\$(E3_MODULE_NAME).lib.\$(E3_MODULE_VERSION)


EOF

cat > RULES_DEV <<EOF
# -*- mode: Makefile;-*-

.PHONY: devvars devenv devinit devbuild devclean devinstall devrebuild devuninstall devdistclean devepics devepics-clean devpatch devpatchrevert

devvars: vars

devenv: devvars

devinit: git-submodule-sync
	git clone \$(E3_MODULE_DEV_GITURL) \$(E3_MODULE_SRC_PATH)
	cd \$(E3_MODULE_SRC_PATH) && git checkout \$(EPICS_MODULE_TAG)


ifeq "\$(INIT_E3_MODULE_SRC)" "1"

devbuild: nonexists
devclean: nonexists
devinstall: nonexists
devrebuild: nonexists
devuninstall: nonexists
devdistclean: nonexists
devepics: nonexists
devepics-clean: nonexists
devpatch: nonexists
devpatchrevert: nonexists
nonexists:
	\$(QUIET)echo ""
	\$(QUIET)echo "------------------------------------------------------------"
	\$(QUIET)echo "          Could not find \$(E3_MODULE_SRC_PATH) "
	\$(QUIET)echo "          Please make devinit first !          "
	\$(QUIET)echo "------------------------------------------------------------"
	\$(QUIET)echo ""
else

devbuild: build
devclean: clean
devinstall: install
devrebuild: rebuild
devuninstall: uninstall
devdistclean: clean
	\$(QUIET)echo "Removing \$(E3_MODULE_SRC_PATH) ......... "
	rm -rf \$(E3_MODULE_SRC_PATH)
devepics: epics
devepics-clean: epics-clean
devpatch: patch
devpatchrevert: patchrevert
endif


EOF

## module.makefile should have db: rule

cat > RULES_DB <<EOF

## This RULE should be used in case of inflating DB files
## In this case, one should add db: rule in \$(EPICS_MODULE_NAME).makefile
## And add db in RULES_E3 also as follows:
## install_module: uninstall db


.PHONY: db

###   ..... 

db: conf
	#install -m 644 \$(TOP)/template/cpci-evg230-ess.substitutions   \$(E3_MODULE_SRC_PATH)/evgMrmApp/Db/
	\$(QUIET) \$(E3_MODULE_MAKE_CMDS) db


EOF


popd # configure/E3


# db is the default in RULES_E3, so add the empty db in ${MODULE_NAME}.Makefile
#

sed -i 's/REQUIRE_TOOLS/E3_REQUIRE_TOOLS/g' ${MODULE_NAME}.Makefile
echo ""       >> ${MODULE_NAME}.Makefile
echo "# db rule is the default in RULES_E3, so add the empty one" >>  ${MODULE_NAME}.Makefile
echo ""       >> ${MODULE_NAME}.Makefile
echo "db:"    >> ${MODULE_NAME}.Makefile

#
#
echo ""        >> .gitignore
echo "*.local" >> .gitignore
echo "*~"      >> .gitignore
echo "\#*"     >> .gitignore
echo "*-dev"   >> .gitignore
echo ".cvsignore" >> .gitignore
echo "*_old/"   >> .gitignore
echo ".\#*"   >> .gitignore




git add .gitignore
git add ${MODULE_NAME}.Makefile
git add Makefile
git add configure/CONFIG
git add configure/E3/*
git add configure/RELEASE
git add configure/RELEASE_DEV
git add configure/RULES
git add configure/CONFIG_MODULE
git add configure/CONFIG_MODULE_DEV
git add configure/CONFIG_OPTIONS

if [ -e "configure/BUILD_DB" ]; then
    git rm configure/BUILD_DB
fi

if [ -e "configure/BUILD_DEV" ]; then
    git rm configure/BUILD_DEV
fi

if [ -e "configure/BUILD_E3" ]; then
    git rm configure/BUILD_E3
fi

if [ -e "configure/BUILD_EPICS" ]; then
    git rm configure/BUILD_EPICS
fi

if [ -e "configure/CONFIG_DEV" ]; then
    git rm configure/CONFIG_DEV
fi

if [ -e "configure/MK_DEFINES" ]; then
    git rm configure/MK_DEFINES
fi



echo ""
echo "Please modify the following files : "
echo "           configure/CONFIG_MODULE"
echo "           configure/CONFIG_MODULE_DEV"
echo "           configure/E3/RULES_EPICS"


popd # e3-${MODULE_NAME}



