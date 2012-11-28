COFFEE = $(shell find . -name "*.coffee" -type f)
JS = $(COFFEE:.coffee=.js)

STYL = $(shell find . -name "*.styl" -type f)
CSS = $(STYL:.styl=.css)

JADE = $(shell find . -name "*.jade" -type f)
HTML = $(JADE:.jade=.html)

all: compiled/index.html compiled/index.js compiled/index.css

run:
	http-server compiled

watch:
	watch -n 1 make

compiled/index.html: $(JADE)
	jade -p . index.jade -O compiled

compiled/index.css: $(STYL)
	stylus -I . index.styl --include-css -o compiled

compiled/index.js: $(COFFEE)
	browserify index.coffee -o compiled/index.js

clean:
	rm -f $(HTML) $(CSS) $(JS)

.PHONY: clean run watch