TARGET = mzcc

CFLAGS = -Wall -Werror -std=gnu99 -g -I.

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
CFLAGS += -no-pie
endif

SHELL_HACK := $(shell echo CBUILD=\"$(CC) $(CFLAGS)\" > .cbuild)

# Control the build verbosity
# `make V=1` is equal to `make VERBOSE=1`
ifeq ("$(origin V)", "command line")
    VERBOSE = $(V)
endif
ifeq ("$(VERBOSE)","1")
    Q :=
    VECHO = @true
else
    Q := @
    VECHO = @printf
endif

OBJS = lexer.o codegen_x64.o parser.o verbose.o main.o
deps := $(OBJS:%.o=.%.o.d)

%.o: %.c
	$(VECHO) "  CC\t$@\n"
	$(Q)$(CC) -o $@ $(CFLAGS) -c -MMD -MF .$@.d $<

$(TARGET): $(OBJS)
	$(VECHO) "  LD\t$@\n"
	$(Q)$(CC) $(CFLAGS) -o $@ $^

TESTS := $(patsubst %.c,%.bin,$(wildcard tests/*.c))

PASS_COLOR = \e[32;01m
NO_COLOR = \e[0m
pass = printf "[ $(PASS_COLOR)Passed$(NO_COLOR) ]\n"

check: nqueen $(TESTS)
	@echo
	@for test in $(TESTS); do                        \
	    printf "*** verify $$test ***\n"	;        \
	    head -n 1 `echo $$test | sed s/.bin/.c/`;    \
	    ./$$test;                                    \
	    $(call pass,$$test);                         \
	    echo;                                        \
	done
	tests/driver.sh

tests/%.s: tests/%.c $(TARGET)
	./mzcc -o $@ $<

tests/%.bin: tests/%.s $(TARGET)
	$(VECHO) "  CC\t$@\n"
	$(Q)$(CC) $(CFLAGS) -o $@ $<

nqueen: sample/nqueen.c $(TARGET)
	$(VECHO) "  MazuCC\t$<\n"
	$(Q)./mzcc -o ${<:.c=.s} $<
	$(VECHO) "  AS+LD\t\t$@\n"
	$(Q)$(CC) $(CFLAGS) -o sample/nqueen sample/nqueen.s

.PHONY: clean check
clean:
	$(RM) $(TARGET) $(TESTS) $(OBJS) $(deps) .cbuild
	$(RM) sample/*.o sample/nqueen.s sample/nqueen

-include $(deps)
