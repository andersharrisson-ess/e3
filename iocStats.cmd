require iocStats,1856ef5

epicsEnvSet("PREF", "E3Test")
epicsEnvSet("IOCST", "IocStat")
epicsEnvSet("IOC",  ${PREF})

dbLoadRecords("iocAdminSoft.db","IOC=${PREF}:${IOCST}")
dbl > "${IOC}_PVs.list"
