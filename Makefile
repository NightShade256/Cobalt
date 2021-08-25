.SUFFIXES:

################################################
#                                              #
#             CONSTANT DEFINITIONS             #
#                                              #
################################################

SRCDIR := src
BINDIR := bin
OBJDIR := obj
DEPDIR := dep

ifneq ($(OS),Windows_NT)
    RM_RF := rm -rf
    MKDIR_P := mkdir -p
else
    RM_RF := -rmdir /s /q
    MKDIR_P := -mkdir
endif

RGBASM  := rgbasm
RGBLINK := rgblink
RGBFIX  := rgbfix

ROM = $(BINDIR)/$(ROMNAME).$(ROMEXT)

INCDIRS  = $(SRCDIR)/ $(SRCDIR)/include/
WARNINGS = all extra
ASFLAGS  = -p $(PADVALUE) $(addprefix -i,$(INCDIRS)) $(addprefix -W,$(WARNINGS))
LDFLAGS  = -p $(PADVALUE)
FIXFLAGS = -p $(PADVALUE) -v -i "$(GAMEID)" -k "$(LICENSEE)" -l $(OLDLIC) -m $(MBC) -n $(VERSION) -r $(SRAMSIZE) -t $(TITLE)

SRCS = $(wildcard $(SRCDIR)/*.s)

include project.mk

################################################
#                                              #
#                    TARGETS                   #
#                                              #
################################################

all: $(ROM)
.PHONY: all

clean:
	$(RM_RF) $(BINDIR)
	$(RM_RF) $(OBJDIR)
	$(RM_RF) $(DEPDIR)
.PHONY: clean

rebuild:
	$(MAKE) clean
	$(MAKE) all
.PHONY: rebuild

###############################################
#                                             #
#                 COMPILATION                 #
#                                             #
###############################################

$(BINDIR)/%.$(ROMEXT) $(BINDIR)/%.sym $(BINDIR)/%.map: $(patsubst $(SRCDIR)/%.s,$(OBJDIR)/%.o,$(SRCS))
	@$(MKDIR_P) $(@D)
	$(RGBLINK) $(LDFLAGS) -m $(BINDIR)/$*.map -n $(BINDIR)/$*.sym -o $(BINDIR)/$*.$(ROMEXT) $^ \
	&& $(RGBFIX) -v $(FIXFLAGS) $(BINDIR)/$*.$(ROMEXT)

$(OBJDIR)/%.o $(DEPDIR)/%.mk: $(SRCDIR)/%.s
	@$(MKDIR_P) $(patsubst %/,%,$(dir $(OBJDIR)/$* $(DEPDIR)/$*))
	$(RGBASM) $(ASFLAGS) -M $(DEPDIR)/$*.mk -MG -MP -MQ $(OBJDIR)/$*.o -MQ $(DEPDIR)/$*.mk -o $(OBJDIR)/$*.o $<

ifneq ($(MAKECMDGOALS),clean)
-include $(patsubst $(SRCDIR)/%.s,$(DEPDIR)/%.mk,$(SRCS))
endif

%:
	@false
