
FONTS = $(patsubst %.ppm,font-%,$(shell ls | grep \.ppm))

.PHONY: all
all: $(FONTS)

.PHONY: font-%
font-%:
	python convert.py $(patsubst font-%,%.ppm,$@)
	rm -f $(patsubst font-%,../font_%.c,$@)
	mv $(patsubst font-%,font_%.c,$@) $(patsubst font-%,../font_%.c,$@)

