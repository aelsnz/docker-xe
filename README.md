# Description

Creating a Docker setup for running Oracle 21c Express Edition in a Docker container.

There are two Dockerfiles provided:

**dockerfiles/Dockerfile**
* This one allow you to create a custom Oracle XE database called XE - you can adjust the name.

**dockerfiles/DockerfileXE**
* This file will use the default setup and create the default XE database which is a CDB with a pluggable database

# Notes:

1.  This docker image does not make use of persistent storage, the database is located in the image and is useful for testing/development.  You should however be able to easily modify this to make use of docker volumes for persistance if you need the database long term.  These exapmles are just to help you quickly get an XE database to test with.

2.  You must download the Oracle 21c XE database software RPM and place it in the software folder

Exampmle: 

```
tree .
.
├── build.sh
├── dockerfiles
│   └── Dockerfile
    └── DockerfileXE
├── scripts
│   └── manage-xe.sh
└── software
    └── oracle-database-xe-21c-1.0-1.ol7.x86_64.rpm
```

3.  Once you have the software in this location, you can use the build.sh script to build the docker image, or you can just run the command from the base folder:

```
docker build -f dockerfiles/Dockerfile -t oracle-db:21cXE . 
```

4.  Once built, you can run the container example:

```
docker run -it -p 1521:1521 -p 5500:5500 -h devXE --name devXE oracle-db:21cXE
```

