#!/usr/bin/make

all: $(patsubst %.Rmd,%.html,$(wildcard *.Rmd)) 

%.html: %.Rmd
	Rscript -e 'library(rmarkdown); rmarkdown::render("$<", output_file = "index.html")'

clean:
	rm index.html
	rm -r index_files
	rm -r *_cache

.PHONY: clean all
