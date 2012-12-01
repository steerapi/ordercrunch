COFFEE = $(shell find . -name "*.coffee" -type f)
JS = $(COFFEE:.coffee=.js)
SHARED_COFFEE = $(shell find ../shared -name "*.coffee" -type f)

STYL = $(shell find . -name "*.styl" -type f)
CSS = $(STYL:.styl=.css)
SHARED_STYL = $(shell find ../shared -name "*.styl" -type f)

JADE = $(shell find . -name "*.jade" -type f)
HTML = $(JADE:.jade=.html)
SHARED_JADE = $(shell find ../shared -name "*.jade" -type f)

all: compiled/index.html compiled/index.js compiled/index.css

run:
	http-server compiled

watch:
	watch -n 1 make

compiled/index.html: $(JADE) $(SHARED_JADE)
	jade -p . index.jade -O compiled

compiled/index.css: $(STYL) $(SHARED_STYL)
	stylus -I . index.styl --include-css -o compiled

compiled/index.js: $(COFFEE) $(SHARED_COFFEE)
	browserify index.coffee -o compiled/index.js

clean:
	rm -f $(HTML) $(CSS) $(JS)

.PHONY: clean run watch