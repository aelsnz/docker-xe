#!/bin/bash
#
# Description:
# Use the command below to build the docker image with Oracle XE
#

v_tag="21cXE"
base_image="oracle-db"

docker build -f dockerfiles/DockerfileXE -t ${base_image}:${v_tag} . 

if [ "${1}" = "-small" ];
then 
    docker rm temp21cxe
    docker run -h temp21cxe --name temp21cxe ${base_image}:${v_tag} /bin/true

    cd /tmp
    docker export --output=temp21cxe.tar temp21cxe
    # Use export/import to get smaller compact image.
    cat /tmp/temp21cxe.tar | docker import \
    -c "EXPOSE 1521 5500" \
    -c "USER oracle" \
    -c "WORKDIR /home/oracle" \
    -c "ENV ORACLE_BASE=/opt/oracle" \
    -c "ENV ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE" \
    -c "ENV NLS_DATE_FORMAT=dd/mm/yyyy:hh24:mi:ss" \
    -c "ENV ORACLE_SID=XE" \
    -c "ENV LD_LIBRARY_PATH \$ORACLE_HOME/lib:\$LD_LIBRARY_PATH" \
    -c "ENV PATH \$ORACLE_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/oracle/bin" \
    -c "ENV EDITOR vi" \
    -c "ENV PS1 '[\u@\h \w]\$ '" \
    -c "CMD /bin/bash /home/oracle/bin/manage-xe.sh -o start" \
    -m "Create base oracle 21c XE image" \
    - ${base_image}:${v_tag}

    # cleanup 
    docker rm temp21cxe
    rm /tmp/temp21cxe.tar
fi
