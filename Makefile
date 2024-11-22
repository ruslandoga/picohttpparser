KERNEL_NAME := $(shell uname -s)
PRIV = $(MIX_APP_PATH)/priv
BUILD = $(MIX_APP_PATH)/obj
SRC = c_src/picohttpparser.c c_src/picohttpparser_nif.c
OBJ = $(SRC:c_src/%.c=$(BUILD)/%.o)
LIB = $(PRIV)/picohttpparser_nif.so

PICOHTTPPARSER_NIF_CFLAGS ?=
PICOHTTPPARSER_NIF_LDFLAGS ?=

CFLAGS = -Ic_src -I"$(ERTS_INCLUDE_DIR)" -fPIC -pedantic -Wall -Wextra -Werror \
	-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function -Wno-unused-but-set-variable \
	-Wno-unused-value -Wno-unused-label -Wno-unused-result -Wno-unused-local-typedefs

ifeq ($(MIX_ENV), dev)
	CFLAGS += -g
else ifeq ($(MIX_ENV), test)
	CFLAGS += -g
else
	CFLAGS += -O3 -DNDEBUG
endif

ifeq ($(KERNEL_NAME), Darwin)
	LDFLAGS = -dynamiclib -undefined dynamic_lookup
else ifeq ($(KERNEL_NAME), Linux)
	LDFLAGS = -shared
else
	$(error Unsupported operating system $(KERNEL_NAME))
endif

all: $(PRIV) $(BUILD) $(LIB)

$(PRIV) $(BUILD):
	mkdir -p $@

$(BUILD)/%.o: c_src/%.c
	@echo " CC $(notdir $@)"
	$(CC) -c $(PICOHTTPPARSER_NIF_CFLAGS) $(CFLAGS) -o $@ $<

$(LIB): $(OBJ)
	@echo " LD $(notdir $@)"
	$(CC) -o $@ $^ $(PICOHTTPPARSER_NIF_LDFLAGS) $(LDFLAGS)

clean:
	$(RM) $(LIB) $(OBJ)

.PHONY: all clean

# Don't echo commands unless the caller exports "V=1"
${V}.SILENT:
