# e3 

This is the e3 initial setup script. It is now testing while I am working on individual epics modules e3-somethings.

## Notice

* The following toolchain is needed
```
fsl-qoriq-glibc-x86_64-ppc64e6500-toolchain-2.0-libudev-libxml2.sh
```
in order to compile the ppc64e6500. If Base find the empty toolchain directory, it will skip it semi-automatically.

* One should need the ESS user name and password for tcslib, and bitbucket for ifcdaqdrv2.

* Please look at e3.bash in order to do micro-control of them.



## Support Platform Status

* Debian 8 (Jessie)  (Tested with x86_64 and ppc64e5000)
* Debian 9 (Stretch) (Tested with x86_64 and ppc64e5000)
* Raspbian Stretch   (Not Test) 
* CentOS 7.4         (Tested with x86_64 and ppc64e5000)
* Ubuntu 16.04.3 LTS (Xenial Xerus)  (Not Test)  
* Ubuntu 17.10 (Artful Aardvark)  (Not Test) 
* Fedora ....

##

The following command guides us to lead the first glimpse of E3. SUDO permission is needed to setup it.

```
$ git clone https://github.com/icshwi/e3 e3+
$ cd e3+
$ git checkout target_path_test
$ make build
```
If there is no error, please test whether compiled modules can be loaded correctly or not.
```
$ make load
```


After finishing the installation, source the dynamic environment via

```
$ source e3-require/tools/setE3Env.bash
```

The you have the E3+ in your active terminal only.



Then, one can run the example ioc through 
```
$ iocsh.bash iocStats.cmd
```

Open another terminal, set the environment via source first, then
run the caget_pvs.bash with the generated pv list file.

```
e3 (master)$ bash caget_pvs.bash E3Test_PVs.list
.............
E3Test:IocStat:GTIM_TIME       8.77333e+08
E3Test:IocStat:IOC_CPU_LOAD    0
E3Test:IocStat:LOAD            0
E3Test:IocStat:MEM_FREE        7.60112e+09
E3Test:IocStat:MEM_MAX         1.67588e+10
E3Test:IocStat:MEM_USED        6.16858e+06
E3Test:IocStat:PARENT_ID       32164
E3Test:IocStat:PROCESS_ID      32183
E3Test:IocStat:RECORD_CNT      64
E3Test:IocStat:SUSP_TASK_CNT   0
E3Test:IocStat:SYS_CPU_LOAD    29.779
jhlee@kaffee: e3 (master)$ bash caget_pvs.bash E3Test_PVs.list "LOAD"
E3Test:IocStat:LOAD_UPD_TIME   10
E3Test:IocStat:IOC_CPU_LOAD    0
E3Test:IocStat:LOAD            0
E3Test:IocStat:SYS_CPU_LOAD    33.3701
```

The useful options are

```
$ bash caget_pvs.bash E3Test_PVs.list EPICS_VERS
$ watch -n 1 "bash caget_pvs.bash E3Test_PVs.list HEARTBEAT"

```

