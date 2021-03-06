EXE_TARGET = ocierl
LIB_TARGET = liberloci.a

ifneq ($(OS),Windows_NT)
	OS := $(shell uname -s)
endif
$(info Detected OS is $(OS))

ifeq "$(wildcard c_src)" ""
	SRC_PATH_PREFIX = 
	PRIV_DIR = ../priv
else
	SRC_PATH_PREFIX = c_src/
	PRIV_DIR = priv
endif

MKDIR_P = mkdir -p
ERLOCI_PATH = $(SRC_PATH_PREFIX)erloci_drv
ERLOCI_LIB_PATH = $(SRC_PATH_PREFIX)erloci_lib

ERLOCI_LIB_HDRS = $(wildcard $(addprefix $(ERLOCI_LIB_PATH)/, *.h))
ERLOCI_LIB_SRCS = $(wildcard $(addprefix $(ERLOCI_LIB_PATH)/, *.cpp))
ERLOCI_LIB_OBJS = $(ERLOCI_LIB_SRCS:.cpp=.o)

ERLOCI_HDRS = $(wildcard $(addprefix $(ERLOCI_PATH)/, *.h))
ERLOCI_SRCS = $(wildcard $(addprefix $(ERLOCI_PATH)/, *.cpp))
ERLOCI_OBJS = $(ERLOCI_SRCS:.cpp=.o)

ERL_INTERFACE_DIR ?= $(ERLANG_ROOT_DIR)/usr

$(info Using ERL_INTERFACE_DIR=$(ERL_INTERFACE_DIR))

# e.g. INSTANT_CLIENT_LIB_PATH     = ../../instantclient_12_1/
# e.g. INSTANT_CLIENT_INCLUDE_PATH = ../../instantclient_12_1/sdk/include/
OCI_LOCAL_FOUND := $(firstword $(wildcard ../instantclient*/libocci.* ../../*/libocci.* ../../../*/libocci.* ../../../../*/libocci.* ../../../../../*/libocci.*))
# e.g. INSTANT_CLIENT_LIB_PATH     = /usr/lib/oracle/12.1/client64/lib/
# e.g. INSTANT_CLIENT_INCLUDE_PATH = /usr/include/oracle/12.1/client64/
OCI_GLOBAL_FOUND := $(firstword $(wildcard /usr/lib/oracle/*/client64/lib/libocci.*))
# e.g. INSTANT_CLIENT_LIB_PATH     = /usr/local/Cellar/instantclient-basic/12.2.0.1.0-2/lib/
# e.g. INSTANT_CLIENT_INCLUDE_PATH = /usr/local/Cellar/instantclient-sdk/12.2.0.1.0-2/include/
OCI_BREW_FOUND := $(firstword $(wildcard /usr/local/Cellar/instantclient-basic/*/lib/libocci.*))
ifneq "$(OCI_LOCAL_FOUND)" ""
	INSTANT_CLIENT_LIB_PATH ?= $(dir $(OCI_LOCAL_FOUND))
	INSTANT_CLIENT_INCLUDE_PATH ?= $(INSTANT_CLIENT_LIB_PATH)sdk/include
endif
ifneq "$(OCI_GLOBAL_FOUND)" ""
	INSTANT_CLIENT_LIB_PATH ?= $(dir $(OCI_GLOBAL_FOUND))
	INSTANT_CLIENT_INCLUDE_PATH ?= $(subst lib/oracle,include/oracle,$(INSTANT_CLIENT_LIB_PATH:/lib/=/))
endif
ifneq "$(OCI_BREW_FOUND)" ""
	INSTANT_CLIENT_LIB_PATH ?= $(dir $(OCI_BREW_FOUND))
	INSTANT_CLIENT_INCLUDE_PATH ?= $(subst instantclient-basic,instantclient-sdk,$(INSTANT_CLIENT_LIB_PATH:/lib/=/include/))
endif
ifeq "$(INSTANT_CLIENT_LIB_PATH)" ""
	$(error Oracle Instantclient not found. Set INSTANT_CLIENT_LIB_PATH and INSTANT_CLIENT_INCLUDE_PATH)
endif

$(info Using INSTANT_CLIENT_LIB_PATH=$(INSTANT_CLIENT_LIB_PATH))
$(info Using INSTANT_CLIENT_INCLUDE_PATH=$(INSTANT_CLIENT_INCLUDE_PATH))

ifeq "$(LIBEVENT_INCLUDE_PATH)" ""
	ifeq "$(shell command -v pkg-config 2> /dev/null)" ""
		LIBEVENT_CFLAGS :=
	else
		LIBEVENT_CFLAGS := $(shell pkg-config libevent --cflags-only-I --silence-errors)
	endif
else
	LIBEVENT_CFLAGS := -I$(LIBEVENT_INCLUDE_PATH)
endif
ifeq "$(LIBEVENT_LIB_PATH)" ""
	ifeq "$(shell command -v pkg-config 2> /dev/null)" ""
		LIBEVENT_LDFLAGS :=
	else
		LIBEVENT_LDFLAGS := $(shell pkg-config libevent --libs-only-L --silence-errors)
	endif
else
	LIBEVENT_LDFLAGS := -L$(LIBEVENT_LIB_PATH)
endif

$(info Using LIBEVENT_LIB_PATH=$(LIBEVENT_LDFLAGS))
$(info Using LIBEVENT_INCLUDE_PATH=$(LIBEVENT_CFLAGS))

CXXFLAGS = -ggdb -Wall -I$(ERL_INTERFACE_DIR)/include  -I$(ERLOCI_PATH) -I$(ERLOCI_LIB_PATH) -I$(INSTANT_CLIENT_INCLUDE_PATH) $(LIBEVENT_CFLAGS)
LINKDIRS = -L$(ERL_INTERFACE_DIR)/lib -L$(PRIV_DIR) -L$(INSTANT_CLIENT_LIB_PATH) $(LIBEVENT_LDFLAGS)
ifeq ($(OS),Darwin)
	LINKFLAGS = -levent -lpthread -lerl_interface -lei -lerloci -locci -lclntsh -lnnz12
	OCI_LIBS=lib{occi,clntsh,nnz12,ons,clntshcore,ociei}.dylib*
else
	LINKFLAGS = -levent -lpthread -lerl_interface -lei -lerloci -locci -lons -lclntshcore -lclntsh -lnnz12 -lipc1 -lmql1
	OCI_LIBS=*.so*
endif

all: $(PRIV_DIR) $(PRIV_DIR)/$(EXE_TARGET)
	@rsync -uL --progress $(INSTANT_CLIENT_LIB_PATH)/$(OCI_LIBS) $(PRIV_DIR)/
	@echo "erloci compiled."

$(PRIV_DIR):
	$(MKDIR_P) $(PRIV_DIR)

$(PRIV_DIR)/$(EXE_TARGET): $(PRIV_DIR)/$(LIB_TARGET) $(ERLOCI_OBJS)
	g++ -Wall $(LINKDIRS) $^ $(LINKFLAGS) -o $@

$(PRIV_DIR)/$(LIB_TARGET): $(ERLOCI_LIB_OBJS)
	ar rcs $(PRIV_DIR)/$(LIB_TARGET) $(ERLOCI_LIB_OBJS)

$(ERLOCI_LIB_SRCS): $(ERLOCI_LIB_HDRS)
	touch $(ERLOCI_LIB_SRCS)

$(ERLOCI_SRCS): $(ERLOCI_HDRS) $(ERLOCI_LIB_HDRS)
	touch $(ERLOCI_LIB_SRCS)
	touch $(ERLOCI_SRCS)

clean:
	rm -rf $(ERLOCI_OBJS)
	rm -rf $(ERLOCI_LIB_OBJS)
	rm -rf $(PRIV_DIR)/$(LIB_TARGET)
	rm -rf $(PRIV_DIR)/$(EXE_TARGET)
	rm -rf $(PRIV_DIR)/*.{so,dylib}*
