SUBDIRSWIMAKE:=$(shell for a in $$(find -mindepth 1 -type d); do if [ -e $$a/Makefile ]; then echo $$a; fi; done;)

.PHONY:		all $(SUBDIRSWIMAKE)

all: $(SUBDIRSWIMAKE)

$(SUBDIRSWIMAKE):
	$(MAKE) -C $@

clean: 
	$(foreach a,$(SUBDIRSWIMAKE), $(MAKE) -C $(a) clean;)
