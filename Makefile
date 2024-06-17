SRC = c_src/picohttpparser_nif.c c_src/picohttpparser.c
CFLAGS = -fPIC -Wall -I$(ERTS_INCLUDE_DIR) -I./c_src
KERNEL_NAME := $(shell uname -s)

PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/obj
LIB_NAME = $(PREFIX)/picohttpparser_nif.so

OBJ = $(SRC:c_src/%.c=$(BUILD)/%.o)

ifeq ($(KERNEL_NAME), Linux)
	CFLAGS += -fvisibility=hidden
	LDFLAGS += -fPIC -shared
endif
ifeq ($(KERNEL_NAME), Darwin)
	LDFLAGS += -dynamiclib -undefined dynamic_lookup
endif

ifneq ($(DEBUG),)
	CFLAGS += -g
else
	CFLAGS += -DNDEBUG=1 -O2
endif

ERL_CFLAGS ?= -I"$(ERL_EI_INCLUDE_DIR)"

all: $(PREFIX) $(BUILD) $(LIB_NAME)

$(BUILD)/%.o: c_src/%.c
	@echo " CC $(notdir $@)"
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

$(LIB_NAME): $(OBJ)
	@echo " LD $(notdir $@)"
	$(CC) -o $@ $^ $(LDFLAGS)

$(PREFIX) $(BUILD):
	mkdir -p $@

clean:
	$(RM) $(LIB_NAME) $(OBJ)

.PHONY: all clean

# Don't echo commands unless the caller exports "V=1"
${V}.SILENT:
