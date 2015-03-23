DATA = data

DD = $(shell echo "$1" | cut -d'|' -f1)
DN = $(shell echo "$1" | cut -d'|' -f2)

chicago:

nyc:

# mysql_CITY_HTTP://URL
.SECONDEXPANSION: mysql_%
mysql_%: $(DATA)/$$(call DD,$$*)/$$(call DN,$$*)
	$(eval city = $(call DD,$*))
	$(eval url = $(call DN,$*))

	cat schema/$*.sql | xargs -I {} printf "{}" 

.SECONDEXPANSION: $(addsuffix /%.csv,$(addprefix $(DATA)/,$(CITIES))
$(addsuffix /%.csv,$(addprefix $(DATA)/,$(CITIES)): | $$(shell dirname $$@)
	curl 

data:
	mkdir -p $@