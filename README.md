# erloci - An Erlang driver for the Oracle Call Interface

[![Build Status](https://travis-ci.org/K2InformaticsGmbH/erloci.svg?branch=master)](https://travis-ci.org/K2InformaticsGmbH/erloci) [![Coverage Status](https://coveralls.io/repos/github/K2InformaticsGmbH/erloci/badge.svg?branch=master)](https://coveralls.io/github/K2InformaticsGmbH/erloci?branch=master)

### Users

<a href="http://www.k2informatics.ch/">
  <img src="http://www.k2informatics.ch/logo.gif" alt="K2 Informatics GmbH">
</a>
<a href="http://privatbank.ua/">
  <img src="http://privatbank.ua/img/logo.png?v=2828" alt="Privat Bank, Ukraine">
</a>

## Setup the development system

Download the following libraries and header files from [Oracle](http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html) (with matching platform and OS to the development system)

  1. instantclient-basic
  2. instantclient-sdk

Setup the paths (see below) if needed and compile with
```
rebar3 compile
```

### Useful environment variables

```
ERL_INTERFACE_DIR           = path to erl_interface or erlang installation
INSTANT_CLIENT_LIB_PATH     = path to oci libraries
INSTANT_CLIENT_INCLUDE_PATH = path to oci headers
LIBEVENT_LIB_PATH           = path to libevent libraries (optional, s.a. `pkg-config libevent --libs`)
LIBEVENT_INCLUDE_PATH       = path to libevent headers (optional, s.a. `pkg-config libevent --cflags`)
```

### Windows

Unzip both downloads into the same a directory,
i.e. if your instant client library version is 12.1 and you have unzipped 'instantclient-basic-windows*.zip' to C:\Oracle\instantclient\instantclient_12_1 then the sdk should be at C:\Oracle\instantclient\instantclient_12_1\sdk\
The include headers will be at C:\Oracle\instantclient\instantclient_12_1\sdk\include and static libraries at C:\Oracle\instantclient\instantclient_12_1\sdk\lib\msvc (note the path for VS project configuration later)

E.g. for Windows 7 (x64):
```
ERL_INTERFACE_DIR           = C:\Program Files\erlang\erl5.10.4\lib\erl_interface-3.7.15
INSTANT_CLIENT_LIB_PATH     = C:\Oracle\instantclient\instantclient_12_1\
INSTANT_CLIENT_INCLUDE_PATH = C:\Oracle\instantclient\instantclient_12_1\sdk\include
```

#### Compile ERLOCI in Windows command line

Make sure you have `MSbuild.exe` in path. After that `rebar3 compile` will take care the rest. Currently erloci can only be build with VS2008.

### Linux / Mac OS X

Required system libraries
```
libevent
libevent-devel
```
Use RPMs (recommended) to install basic and sdk. The default install path will be detected, usually (for x86_64 architecture)
```
OCI Headers     : /usr/include/oracle/12.1/client64/
OCI Libraries   : /usr/lib/oracle/12.1/client64/lib/
```
For Mac you may use Homebrew (http://brew.sh) as package manager to install them.

#### With Homebrew

1. [Download](http://www.oracle.com/technetwork/topics/intel-macsoft-096467.html) latest instantclient-basic / sdk
2. Copy both files to ~/Library/Caches/Homebrew  
3. Install the InstantClient via HomeBrew
```
$ brew tap InstantClientTap/instantclient
$ brew install instantclient-basic
$ brew install instantclient-sqlplus
```
4. Environment variables, the default paths will be detected, otherwise
```
export ERL_INTERFACE_DIR=/usr/local/Cellar/erlang/20.3.6/lib/erlang/lib/erl_interface-3.10.2
export INSTANT_CLIENT_LIB_PATH=/usr/local/Cellar/instantclient-basic/12.2.0.1.0-2/lib/
export INSTANT_CLIENT_INCLUDE_PATH=/usr/local/Cellar/instantclient-sdk/12.2.0.1.0-2/include/
```

### Environment variables for Fedora (x64)

The default paths will be detected, otherwise e.g.
```
ERL_INTERFACE_DIR           = /usr/lib64/erlang/lib/erl_interface-3.7.15
INSTANT_CLIENT_LIB_PATH     = /usr/lib/oracle/12.1/client64/lib/
INSTANT_CLIENT_INCLUDE_PATH = /usr/include/oracle/12.1/client64/
```

### Environment variables for Ubuntu (14.04.2 LTS 'trusty')

```
sudo apt-get install libevent-dev
sudo apt-get install alien dpkg-dev debhelper build-essential
sudo alien oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
sudo alien oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm
sudo dpkg -i oracle-instantclient12.1-basic_12.1.0.2.0-2_amd64.deb
sudo dpkg -i oracle-instantclient12.1-devel_12.1.0.2.0-2_amd64.deb
```
The default paths will be detected, otherwise e.g.
```
export ERL_INTERFACE_DIR=/usr/lib/erlang/lib/erl_interface-3.8.2
export INSTANT_CLIENT_LIB_PATH=/usr/lib/oracle/12.1/client64/lib/
export INSTANT_CLIENT_INCLUDE_PATH=/usr/include/oracle/12.1/client64/
```

### Compiling

We assume you have [rebar3](https://www.rebar3.org/) somewhere on your path. Rebar3 will take care of the Erlang and C++ sources.
<code>rebar3 compile</code>
Please check the rebar3 documentation for how to add erloci as a dependency to your project.

**DEPRICATION WARNING** Visual Studio 2008 and Visual Studio 2013 are no longer supported please build with Visual Studio 2017 (Community Edition) instead

Issue `rebar3 compile` as usual; then don't forget to revert temporarily changed vcxproj files: `git reset --hard`.

__NOTE__: Setting the environment variables for the comand line tools might be needed: ``"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" x64``

### 3rd party dependencies

#### Threadpool

The threadpool code (threadpool.cpp/h) is developed by Mathias Brossard mathias@brossard.org. His threadpool library is hosted at https://github.com/mbrossard/threadpool.
This library is unused (not linked) in a Windows environment. For an easier installation process we include the required threadpool files in the erloci repo. So this is NOT a dependency you have to resolve by yourself.

#### Oracle Call Interface (OCI)

OCI provides a high performance, native 'C' language based interface to the Oracle Database. There is no ODBC layer between your application and the database. Since we don't want to distribute the Oracle Code you MUST download the OCI Packages (basic and devel) from the Oracle Website: http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html.


### Erlang to/from Oracle datatype mapping (currently)

oracle|erlang
---|---
SQLT_INT|integer()
SQLT_CHR,SQLT_AFC|binary()
SQLT_FLT|float()
SQLT_IBDOUBLE|float()
SQLT_BIN|binary()
SQLT_DAT|binary()
SQLT_TIMESTAMP|binary()
SQLT_TIMESTAMP_LTZ|binary()
SQLT_INTERVAL_YM|binary()
SQLT_INTERVAL_DS|binary()
SQLT_IBFLOAT|float()

### Eunit test

The database user `<<db_user>>` must have at least the following privileges:

	-- Roles
	GRANT CONNECT TO <<db_user>>;
	GRANT RESOURCE TO <<db_user>>;
	ALTER USER <<db_user>> DEFAULT ROLE ALL;
	-- System Privileges
	GRANT ALTER SESSION TO <<db_user>>;
	GRANT ALTER SYSTEM TO <<db_user>>;
	GRANT CREATE ANY DIRECTORY TO <<db_user>>;
	GRANT CREATE DATABASE LINK TO <<db_user>>;
	GRANT CREATE SEQUENCE TO <<db_user>>;
	GRANT CREATE SESSION TO <<db_user>>;
	GRANT CREATE SYNONYM TO <<db_user>>;
	GRANT CREATE VIEW TO <<db_user>>;
	GRANT DROP ANY DIRECTORY TO <<db_user>>;
	-- Object Privileges
	GRANT EXECUTE ON SYS.DBMS_STATS TO <<db_user>>;
	GRANT SELECT ON SYS.GV_$PROCESS TO <<db_user>>;
	GRANT SELECT ON SYS.GV_$SESSION TO <<db_user>>;

The Oracle connection information are taken from the file `connect.config` in directory `test`. Please change it to point to your database before executing the steps below:

  1. <code>rebar3 compile</code>
  2. <code>rebar3 eunit</code>

### CHANGE LOG

#### 0.0.2

1. STL term class for wrapping erlang term
1. Native process redesigned to OO
1. Support Variable binding for Input
1. Concurrent connection and statements
1. Common test for load testing

#### 0.1.0

1. Compiled with rebar3
1. CommonTests restructured

#### 0.1.1

1. Compile with Visual Studio 2017 Community Edition tool chain

### Work-In-Progess

1. Testing and stabilization
2. Wiki

### TODOs

1. In/Out bind variables and arrays
