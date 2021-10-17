#!/bin/bash -e
# Description: 
#   Basic sample script to manage XE database options
#
# For debugging uncomment below
# set -x

############
#  Function to echo usage
############
usage ()
{
  program=`basename $0`
cat <<EOF
Usage:
   ${program} [-o start|stop] [-h]

   Options:
     -o start or -o stop will start or stop the XE database and listener
EOF
exit 1
}


###########################################
#  Function to change database environments
###########################################
set_env ()
{
   REC=`grep "^${1}" /etc/oratab | grep -v "^#"`
   if test -z $REC
   then
     echo "Database NOT in ${v_oratab}"
     exit 1
   else
     echo "Database in ${v_oratab} - setting environment"
     export ORAENV_ASK=NO
     export ORACLE_SID=${1}
     . oraenv >> /dev/null
     export ORAENV_ASK=YES
   fi

}

####################################
#  Function to setup parameter variables
####################################
setup_parameters ()
{
  ## Set Other ENV
  set_env XE
  # note 21c you now have the orabasehome which is located outside the oracle home
  # see orabasehome command.
  ORACLE_BASE_HOME=`orabasehome`
  TNS_ADMIN=${ORACLE_BASE_HOME}/network/admin
  EDITOR=vi
  NLS_DATE_FORMAT="dd/mm/yyyy:hh24:mi:ss"

  if [ -e ${TNS_ADMIN}/listener.ora ]; then
    sed -i -e "s/^.*HOST.*/\ \ \ \ \ \ \ (ADDRESS = (PROTOCOL = TCP)(HOST = $HOSTNAME)(PORT = 1521))/" ${TNS_ADMIN}/listener.ora
  fi

  if [ -e ${TNS_ADMIN}/tnsnames.ora ]; then
    sed -i -e "s/^.*HOST.*/\ \ \ \ \ \ \ (ADDRESS = (PROTOCOL = TCP)(HOST = $HOSTNAME)(PORT = 1521))/" ${TNS_ADMIN}/tnsnames.ora
  fi
  ## Echo back the hostname and IP
  ##
  echo $HOSTNAME - $(echo $(ip addr show dev eth0 | sed -nr 's/.*inet ([^ ]+).*/\1/p') | cut -f 1 -d '/')
}

####################################
#  Function to enable DB Express
####################################
enableDBExpress ()
{
set_env XE
echo "update settings to allow DBExpress Access"
sqlplus / as sysdba << EOF
  exec dbms_xdb_config.setlistenerlocalaccess(false);
  exec dbms_xdb_config.setglobalportenabled(true);
  exit
EOF
echo ".. Done"
}


####################################
#  Function to eanble supplemental logging
####################################
enableSupplementalLogData ()
{
set_env XE
echo "Enable supplemental log data..."
sqlplus / as sysdba << EOF
  alter database add supplemental log data;
  shutdown immediate;
  startup;
EOF
echo ".. Done"
}

####################################
#  Function to enable archivelog mode
####################################
enableArchiveLog ()
{
set_env XE
echo "Enable archivelog mode..."
sqlplus / as sysdba << EOF
  shutdown immediate;
  startup mount;
  alter database archivelog;
  shutdown immediate;
  startup;
EOF
echo ".. Done"
}


###################
###################
## Main
###################
###################

if test $# -lt 2
then
  usage
fi

## Get all values
while test $# -gt 0
do
   case ${1} in
   -o)
           shift
           v_option=${1}
           ;;
   -s)     enable_supplemental_log="Y"
           ;;
   -a)     enable_archivelog="Y"
           ;;
   -h)
           usage
           ;;
   *)      usage
           ;;
   esac
   shift
done

setup_parameters 

######
######
# execute what is needed


case ${v_option} in
 "start")
          sudo /etc/init.d/oracle-xe-21c start
          enableDBExpress
          echo "Database ready for use..."
          
          if [ "${enable_supplemental_log}" = "Y" ]; then
             enableSupplementalLogData
          fi

          if [ "${enable_archivelog}" = "Y" ]; then
             enableArchiveLog
          fi

          tail -F -n 0 /opt/oracle/diag/rdbms/xe/XE/trace/alert_XE.log
          ;;
 "stop")
          sudo /etc/init.d/oracle-xe-21c stop
          tail -50 /opt/oracle/diag/rdbms/xe/XE/trace/alert_XE.log
          ;;
esac
