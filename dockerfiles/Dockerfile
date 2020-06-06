##
#  Description:
#  This is a basic Dockerfile that can be used to build an Oracle XE database.
#  You have to download the Oracle XE software rpm and place it in the software sub folder.
#  This Dockerfile is used to create a custom XE database as a nonCDB and can easily 
#  be modified to use an alternative name to XE for the database.
#

##
#  First we select our base image we will use to build from.
#  in this case we will use Oracle Linux 7.8 
#
FROM oraclelinux:7.8

MAINTAINER anton.els@aelsnz.com

##
#  We are now switching to the root user as the next steps will require root permission
#
USER root

##
#  First we add the “oracle”  Unix user and groups and assign a password to the user
#  note - you will have to make this password more complex in production configurations
#
RUN groupadd -g 501 oinstall \
  && groupadd -g 502 dba \
  && groupadd -g 503 oper \
  && useradd -m -g oinstall -G oinstall,dba,oper -u 501 oracle \
  && echo 'oracle:Demo123!' | chpasswd 

## 
#  As Pre-requisite for the Oracle 18c XE Install
#  a few extra packages is required - and as I use tools like tree, which and sysstat we add them here as well.  
#  You can customise this, but “file” and “openssl” must be installed before you can install Oracle 18c XE.
#  We also want to keep the image small, to do this we cleanup after the install and remove
#  all temporary files and caches used during installation
#
RUN rpm --rebuilddb \
  && yum -y install file openssl lsof sudo sysstat tree wget which  \
  && yum clean all \
  && rm -rf /var/cache/yum/*

## 
#  Update sudoers to allow the oracle Unix user to run commands as the root user.  
#  In this example I keep it simple and allow the user to execute any command without a password
#  but for production configurations you might want to look at locking this down more.
#  We also create a few directories and make sure the oracle Unix user own them.
#  First the directory /opt/oracle in which Oracle 18c XE will be installed into
#  Second we create the /install folder which will be a temporary location from where we will install files
#  Third we create a bin directory in the oracle user home folder location - where we can place scripts
#
RUN echo "oracle ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
  && echo "Defaults !requiretty"  >> /etc/sudoers \
  && mkdir -p /opt/oracle \
  && mkdir -p /install \
  && mkdir -p /home/oracle/bin \
  && chown -R oracle:oinstall /opt/oracle \
  && chown -R oracle:oinstall /home/oracle/bin

## 
#  Next, we copy the Oracle 18c XE software to the install directory followed by 
#  setting the ORACLE_DOCKER_INSTALL=true environment variable before we install
#  the Oracle 18c XE software with “yum -y localinstall” command.  
#  In the git repository does not include the oracle XE software, download and copy it into
#  the software/ sub folder
#
#  The ORACLE_DOCKER_INSTALL variable is used to indicate we are installing into Docker
#  and as part of the pre/post install scripts Oracle will use to remove/unset settings
#  which is not required when using docker
#  on the last part we cleanup the install folder and any temporary files
#
COPY software/oracle-database-preinstall-18c-1.0-1.el7.x86_64.rpm /install
COPY software/oracle-database-xe-18c-1.0-1.x86_64.rpm /install/
ENV ORACLE_DOCKER_INSTALL=true
RUN cd /install \
  && yum -y localinstall oracle-database-*18c*  \
  && yum clean all \
  && rm -rf /var/cache/yum/*

## Set the default ports to be exposed for Oracle XE, exmaple 1521 is default listener port 
#
EXPOSE 1521 5500 

##  Setting ORACLE_DOCKER_INSTALL=true, you should not have to remove memlock options below
#   but I found I still had to do this.
RUN sed -i -e "s/^.*memlock.*//g" /etc/security/limits.d/oracle-database-preinstall-18c.conf 

## 
#  We now add an entrypoint script.  There is a lot of information on Entrypoint 
#  and CMD options in the docker documentation for more reference.  But in This example
#  We will copy a script called “manage-xe.sh” to the /home/oracle/bin folder which is
#  executable by the oracle Unix account and this will be used to start the Oracle 18c XE
#  database on launch of the container
#
COPY scripts/manage-xe.sh /home/oracle/bin
RUN chown oracle:oinstall /home/oracle/bin/manage-xe.sh \
  && chmod 775 /home/oracle/bin/manage-xe.sh

##
#  We now switch to the “oracle” user, up to this point all operations were performed as 
#  the root user.  We also specify the work directory - which in this case is the default
#  oracle user home folder location
#
USER oracle
WORKDIR /home/oracle

## 
#  Something really useful is to set current environment for the oracle user.
#  This is done using the ENV command. With this we specify the core parameters that will 
#  make things simpler for the “oracle” unix account, example setting the PATH, ORACLE_HOME
#  ORACLE_SID etc.
#
ENV ORACLE_DOCKER_INSTALL=true \
  ORACLE_BASE=/opt/oracle \
  ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE \
  PATH=/home/oracle/bin:/opt/oracle/product/18c/dbhomeXE/bin:$PATH \
  NLS_DATE_FORMAT="dd/mm/yyyy:hh24:mi:ss" \
  ORACLE_SID=XE

#  Creating a Custom Oracle XE database called XE using the DBCA 
#  - Note that this example creates a NON CDB, no multitenant XE database
#  - You can always modify this to name the database someting else 
#    Just modify -sid XE to example -sid XYZ    
#
RUN netca /orahome $ORACLE_HOME /instype typical /inscomp client,oraclenet,javavm,server,ano /insprtcl tcp /cfg local /authadp NO_VALUE /responseFile $ORACLE_HOME/network/install/netca_typ.rsp /silent /listenerparameters DEFAULT_SERVICE=XE  /lisport 1521 \
  && dbca -silent -createDatabase -gdbName XE \
  -templateName XE_Database.dbc \
  -createAsContainerDatabase false \
  -sid XE \
  -emConfiguration DBEXPRESS \
  -emExpressPort 5500 \
  -J-Doracle.assistants.dbca.validate.DBCredentials=false \
  -sampleSchema false \
  -initParams sga_target=600M,pga_aggregate_target=50M \
  -storageType FS \
  -datafileDestination /opt/oracle/oradata \
  -useOMF true \
  -enableArchive true \
  -systemPassword Demo123 \
  -sysPassword Demo123 \
  -recoveryAreaDestination /opt/oracle/fast_recovery_area \
  -recoveryAreaSize 5120 \
  -redoLogFileSize 50 

#  We clear bash history to keep things clean - this is optional
#
RUN history -c

## 
#  The last instruction is to specify what will be executed when the container is created 
#  from the image.  There is a few options, you could just start a bash shell and then 
#  manually start the Oracle 18c XE database, or, you could call the custom manage-xe.sh
#  script with the “start” parameter to start the listener and XE database on container 
#  creation (run time)
#
# CMD ["/bin/bash”]
#
CMD ["/home/oracle/bin/manage-xe.sh", "-o", "start"]

