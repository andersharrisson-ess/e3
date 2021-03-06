E3 : European Spallation Source EPICS Environment
======

[![Build Status](https://travis-ci.org/icshwi/e3.svg?branch=master)](https://travis-ci.org/icshwi/e3)

This is the setup and maintenance scripts for the ESS EPICS Environment (E3). 


## Tested Platforms
The following Linux distribution were tested with the physical installation. And the Virtual Image on the VirtualBox as well. However, we DO NOT support any container yet, for example Docker. Please understand our resources, since we don't have any resources on the container support. However, you are always welcome to try them with them. If one would like to contribute, please contact us. We are happy to merge any contributions.



* Debian 8 (Jessie)   (Tested)
* Debian 9 (Stretch)  (Tested)
* CentOS 7.4          (Tested) 
* Raspbian Stretch    (Tested without AD modules)
* Ubuntu 14.04.05 LTS (Tested with travis-ci)
* Ubuntu 16.04.3 LTS (Xenial Xerus) (Tested)
* Ubuntu 17.10 (Artful Aardvark) (Tested)
* LinuxMint 18.3 (sylvia) (Tested)
* Fedora 27 (Workstation Edition) (Tested)



## Procedure to duplicate E3 in your system.

NOTE that if one has the pre-existed EPICS environment, please run the following command first:
```
 e3 (master)$ source tools/unset 
```

The following command guides us to lead the first glimpse of E3. SUDO permission may be needed.

```
 e3 (master)$ make build
```

After finishing the installation, one can test all compiled modules loading via
```
 e3 (master)$ make load
```

If one see the clean ioc shell, the environment is ready to use. However, one should source the dynamic environment via

```
e3 (master)$ source tools/setenv 
```
, because it gives us more flexible way to have more than one EPICS environment in a host machine. Since then, one can run the example ioc through 
```
e3 (master)$  iocsh.bash cmds/iocStats.cmd 
```

Open another terminal, set the environment via source first, then
run the caget_pvs.bash with the generated pv list file.

```
e3 (master)$ bash caget_pvs.bash E3Test_PVs.list
.............
.............
>> Unset ... EPICS_CA_ADDR_LIST and EPICS_CA_AUTO_ADDR_LIST
Set ... EPICS_CA_ADDR_LIST and EPICS_CA_AUTO_ADDR_LIST 
>> Print ... 
EPICS_CA_ADDR_LIST      : 192.168.178.32
EPICS_CA_AUTO_ADDR_LIST : YES
>> Get PVs .... 
E3Test:IocStat:READACF         0
E3Test:IocStat:SYSRESET        0
E3Test:IocStat:SysReset        0
E3Test:IocStat:HEARTBEAT       475
E3Test:IocStat:START_CNT       1
E3Test:IocStat:CA_UPD_TIME     15
E3Test:IocStat:FD_UPD_TIME     20
E3Test:IocStat:LOAD_UPD_TIME   10
E3Test:IocStat:MEM_UPD_TIME    10
E3Test:IocStat:CA_CLNT_CNT     0
E3Test:IocStat:CA_CONN_CNT     0
E3Test:IocStat:RECORD_CNT      64
E3Test:IocStat:FD_MAX          1024
E3Test:IocStat:FD_CNT          7
E3Test:IocStat:SYS_CPU_LOAD    2.70259
E3Test:IocStat:IOC_CPU_LOAD    0.0250239
E3Test:IocStat:LOAD            0.0250239
E3Test:IocStat:CPU_CNT         4
E3Test:IocStat:SUSP_TASK_CNT   0
E3Test:IocStat:MEM_USED        6.0416e+06
E3Test:IocStat:MEM_FREE        6.07656e+09
E3Test:IocStat:MEM_MAX         8.16186e+09
E3Test:IocStat:PROCESS_ID      22653
E3Test:IocStat:PARENT_ID       22623
E3Test:IocStat:GTIM_TIME       8.93189e+08
E3Test:IocStat:ACCESS          Running
E3Test:IocStat:GTIM_RESET      Reset
E3Test:IocStat:GTIM_ERR_CNT    0
.............
.............

e3 (master)$  bash caget_pvs.bash E3Test_PVs.list "LOAD"
>> Unset ... EPICS_CA_ADDR_LIST and EPICS_CA_AUTO_ADDR_LIST
Set ... EPICS_CA_ADDR_LIST and EPICS_CA_AUTO_ADDR_LIST 
>> Print ... 
EPICS_CA_ADDR_LIST      : 192.168.178.32
EPICS_CA_AUTO_ADDR_LIST : YES
>> Get PVs .... 
E3Test:IocStat:LOAD_UPD_TIME   10
E3Test:IocStat:SYS_CPU_LOAD    4.85465
E3Test:IocStat:IOC_CPU_LOAD    0
E3Test:IocStat:LOAD            0
```

The useful options are

```
$ bash caget_pvs.bash E3Test_PVs.list EPICS_VERS
$ watch -n 1 "bash caget_pvs.bash E3Test_PVs.list HEARTBEAT"
```

## More rich options are defined in e3.bash

### Usage for e3.bash
```
e3 (master)$ ./e3.bash 


Usage    : ./e3.bash [ -ctifealo ] <option> 


           -c     : common      : epics modules
           -t     : timing      : mrf timing modules
           -i{c}  : ifc free    : ifc modules without user accounts
           -f{ci} : ifc nonfree : ifc modules with user accounts
           -e{c}  : ecat        : ethercat modules
           -a{c}  : area        : area detector modules / BI Modules
           -l{c}  : llrf        : Old LLRF modules
                    {c,ci}      : Enable by default if not defined (dependent modules)
   	   -o     : only        : ignore dependent modules
	                          Option -e is actually -ec, however,
				  -eo means only -e. 


 < option > 

           env    : Print enabled Modules

           call   : Clean all (base, require, selected module group)
           gall   : Clone all (base, require, selected module group)
           iall   : Init  all (base, require, selected module group)
           ball   : Build, Install all (base, require, selected module group)
            all   : call, gall, iall, ball

           cbase  : Clean Base
           gbase  : Clone Base
           ibase  : Init  Base 
           bbase  : Build, Install Base
            base  : cbase, gbase, ibase, bbase

           creq   : Clean Require
           greq   : Clone Require
           ireq   : Init  Require
           breq   : Build, Install Require
            req   : creq, gbase ireq, breq

           cmod   : Clean Modules (selected module group)
           gmod   : Clone Modules (selected module group)
          imod   : Init  Modules (selected module group)
           bmod   : Build, Install Modules (selected module group)
            mod   : cmod, mod, imod, bmod

        co_base "_check_out_name_" : Checkout Base
         co_req "_check_out_name_" : Checkout Require
         co_mod "_check_out_name_" : Checkout Modules  (selected module group)
         co_all "_check_out_name_" : co_base, co_req, co_mod

          vbase   : Print BASE    Version Information in e3-*
           vreq   : Print REQUIRE Version Information in e3-*
           vmod   : Print MODULES Version Information in e3-*
           vall   : Print ALL     Version Information in e3-*

         allall   : Print ALL Version Information in e3-* by using "make vars"

           load   : Load all installed Modules into iocsh.bash


```

### SSH KEY Usage

One needs to have the ESS bitbucket/gitlab accout in order to use  *ifc nonfree* and *llrf* modules. The procedure **make init** will ask the ESS user name and its password several times. In order not to type account and password many time, one can add the ssh key in the account configurations in bitbucket and gitlab. After that, the following command should be executed in order to use the different url instead of the default one.

```
source tools/use_sshkey.sh
```

### Examples :

* 
```
$ ./e3.bash -ctifea call
$ ./e3.bash -ctifea gall
$ ./e3.bash -ctifea vall
$ ./e3.bash -ctifea iall
$ ./e3.bash -ctifea ball
$ ./e3.bash -ctifea load 
```

* 
```
$ ./e3.bash -c iall
$ ./e3.bash -c ball
$ ./e3.bash -c load
```

