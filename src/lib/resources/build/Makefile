SHELL = bash
.PHONY: overleaf

help:
	@echo " * clean     : Delete temporary files"
	@echo " * all       : Create the PDF file (run everything needed)"
	@echo " * full      : Create the PDF file (run LaTeX and BibTeX only)"
	@echo " * quicker   : Update the PDF file (just run LaTeX twice)"
	@echo " * quick     : Update the PDF file (just run LaTeX once)"
	@echo " * deps      : Download LaTeX dependencies"
	@echo " * bib       : Update the bib file (just run BibTeX/biber once)"
	@echo " * bibchk    : Run some checks (e.g. biber, bibtex-check)"
	@echo " * verify    : Run some checks (e.g. l2tabu)"
	@echo " * spell     : Check for spelling errors (aspell)"
	@echo " * eval      : Run evaluation scripts (e.g. R)"
	@echo " * generate  : Generate images (gnuplot, R, dot/graphviz, ...)"
	@echo " * deploy    : Deploy the PDF file to a directory (e.g. for automated builds)"
	@echo " * update    : Get the latest sources (incl. latest library)"
	@echo " * open      : Opens the output file using 'open'"
	@echo " * ci        : Continuous Integration - watch for changes an rebuild everything"
	@echo " * rename    : Rename project"
	@echo " * unicode   : Find incompatible unicode characters"
	@echo " * optimize  : Optimize output (e.g. optipng)"
	@echo " * sign      : Sign the PDF using an X.509 certificate"
	@echo " * preflight : Test for PDF/A and PDF/X compatibility"
	@echo " * fix       : Try to fix some common issues (file encoding, biber cache, ...)"
	@echo " * todo      : Find open todos"
	@echo " * debug     : Compile and stop on error and show line number"
	@echo " * updating  : Keep updating in the background to avoid conflicts"
	@echo " * ieee      : Enable IEEE Transaction style"
	@echo " * llncs     : Enable LLNCS style"
	@echo " * content   : Answer basic questions to bootstrap your paper"
	@echo " * count     : Count number of words, figures, tables, captions, ..."
	@echo " * overleaf  : Open project in overleaf (if overleaf is used)"

OID = $(shell grep 'url' .git/config|grep 'overleaf'|awk -F "/" '{print $$4}')
overleaf:
ifeq ($(strip $(OID)),)
	@echo "Seems overleaf is not being used"
else
	@open https://www.overleaf.com/$(OID)
endif

count:
	@echo "Counting..."
	@command -v texcount >/dev/null 2>&1 || { echo >&2 "ERROR: run 'tlmgr install texcount' first."; exit 1; }
	@texcount -nosub -total -utf8 src/*.tex

ieee:
	@echo "Changing to IEEE Transaction style..."
	@find . -iname "*.tex" -depth 1 -exec perl -p -i -e 's/([\s])*%+([^%]*)(% enable for IEEE style)/\1\2\3/g' {} \; -exec perl -p -i -e 's/([\s])*([^%]*)(% enable for LLNCS style)/\1%\2\3/g' {} \;

llncs:
	@echo "Changing to LLNCS Transaction style..."
	@find . -iname "*.tex" -depth 1 -exec perl -p -i -e 's/([\s])*%+([^%]*)(% enable for LLNCS style)/\1\2\3/g' {} \; -exec perl -p -i -e 's/([\s])*([^%]*)(% enable for IEEE style)/\1%\2\3/g' {} \;

content:
	@read -p "Area: one sentence about the research area (which broad area are we considering?): " area; \
	read -p "Issue: one sentence about the issue (what issue is getting to get solved?): " issue; \
	read -p "Related Work: one sentence about the shortcomings of existing solutions: " related; \
	read -p "Assumptions: made in general terms. In this paper, we assume ... : " assumptions; \
	read -p "Approach: one sentence about the own approach: " approach; \
	read -p "Validation: one sentence about the validation of the results. We have validated our approach by...: " validation; \
	read -p "Result: one sentence about the main contribution. The main contribution of this paper is...: " result; \
	perl -p -i -e "s/.*%%area/$$area. %%area/g" src/00_abstract.tex; \
	perl -p -i -e "s/.*%%issue/$$issue. %%issue/g" src/00_abstract.tex; \
	perl -p -i -e "s/.*%%related/$$related. %%related/g" src/00_abstract.tex; \
	perl -p -i -e "s/.*%%assumptions/$$assumptions. %%assumptions/g" src/00_abstract.tex; \
	perl -p -i -e "s/.*%%approach/$$approach. %%approach/g" src/00_abstract.tex; \
	perl -p -i -e "s/.*%%validation/$$validation. %%validation/g" src/00_abstract.tex; \
	perl -p -i -e "s/.*%%result/$$result. %%result/g" src/00_abstract.tex; \
	perl -p -i -e "s/.*%%area/\\\todotext{$$area}%%area/g" src/01_introduction.tex; \
	perl -p -i -e "s/.*%%issue/\\\todotext{$$issue}%%issue/g" src/01_introduction.tex; \
	perl -p -i -e "s/.*%%related/\\\todotext{$$related}%%related/g" src/01_introduction.tex; \
	perl -p -i -e "s/.*%%assumptions/In this paper, we assume \\\todotext{$$assumptions}%%assumptions/g" src/01_introduction.tex; \
	perl -p -i -e "s/.*%%approach/\\\todotext{$$approach}%%approach/g" src/01_introduction.tex; \
	perl -p -i -e "s/.*%%validation/We have validated our approach by \\\todotext{$$validation}%%validation/g" src/01_introduction.tex; \
	perl -p -i -e "s/.*%%result/The main contribution of this paper is \\\todotext{$$result}%%result/g" src/01_introduction.tex

updating:
	@while true; do $(MAKE) update; sleep 30; done

fixmod:
	@chmod +x build.sh

debug: fixmod
	@./build.sh -y

todo:
	@find src -iname "*.tex" -exec sh -c "grep -Hin 'TODO{' {}|sed 's/^\(.*\):\(.*\):.*{\(.*\)}/ * TODO \"\3\" in file \1 in line \2/'" \;

clean: fixmod
	@./build.sh -c

all: generate fixmod
	@./build.sh -b

full: fixmod
	@./build.sh -b

quick: fixmod
	@./build.sh -q

quicker: fixmod
	@./build.sh -r

deps: fixmod
	@./build.sh -t

bib: fixmod
	@./build.sh -i

bibchk: fixmod
	@./build.sh -w

verify: fixmod
	@./build.sh -v

spell: fixmod
	@./build.sh -s

eval: fixmod
	@./build.sh -e

generate: fixmod
	@./build.sh -g

open: fixmod
	@./build.sh -o

deploy: fixmod
	@./build.sh -d ${DPATH}

ci: fixmod
	@./build.sh -f

unicode: fixmod
	@./build.sh -u

optimize: fixmod
	@./build.sh -z

sign: fixmod
	@./build.sh -x

preflight: fixmod
	@./build.sh -p

rename: fixmod
	@./build.sh -n

fix:
	@echo -n "Removing biber cache..."; rm -rf "$(shell biber --cache)"; echo "done"
	@echo -n "Normalizing Unicode..."; ./build.sh -m; echo "done"
	@make clean

update:
	@git submodule foreach git pull origin master
	@git pull
