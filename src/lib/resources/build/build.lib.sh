#!/bin/bash
#===============================================================================
# * LaTeX thesis template (build library)
# * @author  : Alexander willner (alex@willner.ws)
#===============================================================================

#===============================================================================
# Defaults
#===============================================================================
[[ -z $BIN_BIB ]] && BIN_BIB=bibtex
[[ -z $BIN_GLS ]] && BIN_GLS=xindy
command -v $BIN_BIB >/dev/null 2>&1 || { echo >&2 "I require $BIN_BIB but it's not installed.  Aborting."; exit 1; }
command -v $BIN_GLS >/dev/null 2>&1 || { echo >&2 "I require $BIN_GLS but it's not installed.  Aborting."; exit 2; }
command -v qpdf >/dev/null 2>&1 && { BIN_PDF="qpdf"; }
command -v terminal-notifier >/dev/null 2>&1 && { BIN_NOT="terminal-notifier"; }

#===============================================================================
# Method declaration
#===============================================================================
function startLogging() {
    if [ "$DEBUG" -eq "0" ]; then
        touch "$FILE_LOG";
        exec 6>&1        # Saves stdout in file descriptor #6.
        exec 7>&2        # Saves stderr in file descriptor #7.
        exec 1> $FILE_LOG # stdout replaced with log file.
        exec 2> $FILE_LOG # stderr replaced with log file.
    fi;
}

function resetLogging() {
    :> "$FILE_LOG";
}

function endLogging() {
    if [ "$DEBUG" -eq "0" ]; then
        exec 1>&6 6>&-  # Restore stdout and close file descriptor #6.
        exec 2>&7 7>&-  # Restore stderr and close file descriptor #7.
    fi;
}

function doDefaultProject() {
    if [ "$verify" ] || [ "$build" ] || [ "$quick" ] || [ "$quicker" ] || [ "$dobib" ] || \
       [ "$clean" ] || [ "$spelling" ] || [ "$eval" ] || [ "$generate" ] || [ "$deploy" ] || \
       [ "$open" ] || [ "$ci" ] || [ "$unicode" ] || [ "$optimize" ] || [ "$rename" ] || \
       [ "$bibcheck" ] || [ "$sign" ] || [ "$preflight" ] || [ "$fix" ] || [ "$debug" ] || \
       [ "$deps" ]; then

        if [ "$debug" ]; then
            debug "$DIR_TMP" "$FILE_MAIN"
        fi;

        if [ "$deps" ]; then
            deps "$FILE_MAIN"
        fi;

        if [ "$rename" ]; then
            rename
        fi;

        if [ "$fix" ]; then
            fix "$FILE_BASE" "$DIR_SRC"
        fi;

        if [ "$optimize" ]; then
            optimize "$DIR_IMG"
        fi;

        if [ "$sign" ]; then
            sign "$FILE_BASE" "$FILE_CERT"
        fi;

        if [ "$preflight" ]; then
            preflight "$FILE_PDF" "$DIR_IMG"
        fi;

        if [ "$unicode" ]; then
            checkUnicode "$DIR_SRC"
        fi;

        if [ "$ci" ]; then
            checkEnvironment "$REQ_APPLICATIONS";
            checkEnvironment "fswatch";
            dirs="$DIR_SRC:$DIR_IMG:$DIR_BLD"
            echo "Waiting for changes in '$dirs'";
            export BACK=1
            fswatch "$dirs" make quick open
        	exit $?;
        fi;

        if [ "$spelling" ]; then
            checkEnvironment "$REQ_APPLICATIONS";
        	checkSpellingInteractive "$DIR_SRC" "$DIR_RES" "$LANG";
        	exit $?;
        fi;

        if [ "$eval" ]; then
            checkEnvironment "$REQ_APPLICATIONS";
        	doEvaluation "$DIR_SCR" "$DIR_ANA";
        	exit $?;
        fi;

    	doSetup "$REQ_DIRS" "$FILE_LOG";

    	if [ "$clean" ]; then
        	doCleanup "$DIR_TMP";
        fi;

        if [ "$generate" ]; then
            checkEnvironment "$REQ_APPLICATIONS";
            doPlant "$DIR_IMG";
            doGraphviz "$DIR_IMG";
            doGnuPlot "$DIR_IMG";
            doPlotR "$DIR_IMG";
        fi;

        if [ "$verify" ]; then
            checkProject "$DIR_SRC" "$DIR_TMP" "$DIR_RES" \
                 "$FILE_ABSTRACT" "$FILE_INTRO" "$FILE_CONFIG" \
                 "$FILE_MAIN" "$FILE_BIB" \
                 "$LANG"
        	exit $?;
        fi;

        if [ "$bibcheck" ]; then
            checkBib "$DIR_SRC" "$DIR_TMP" "$FILE_BIB" "$FILE_MAIN"
        	exit $?;
        fi;


        if [ "$build" ]; then
          cleanAcronyms "$FILE_ACRO"
        	doLatex "$DIR_TMP" "$FILE_MAIN" "-draftmode";
          doLatex "$DIR_TMP" "$FILE_MAIN" "-draftmode";
        	if [ "$DOINDEX" == "1" ]; then
        		doIndex "$DIR_TMP" "$DIR_LYT";
        	fi
        	if [ "$DOBIBTEX" == "1" ]; then
            	doBibtex "$DIR_TMP" "$FILE_MAIN" "$FILE_BIB" "$DIR_RES";
            fi
#        	if [ "$DOBIBTEX" == "1" ]; then
#            	doBibtex "$DIR_TMP" "$FILE_MAIN" "$FILE_BIB" "$DIR_RES";
#            fi
        	doLatex "$DIR_TMP" "$FILE_MAIN" "-draftmode";
        	doLatex "$DIR_TMP" "$FILE_MAIN" "-draftmode";
        fi;

    	if [ "$dobib" == "1" ]; then
            doBibtex "$DIR_TMP" "$FILE_MAIN" "$FILE_BIB" "$DIR_RES";
        fi

        if [ "$quicker" ]; then
        	doLatex "$DIR_TMP" "$FILE_MAIN" "-draftmode";
        fi;

        if [ "$quick" ] || [ "$quicker" ] || [ "$build" ]; then
            doLatex "$DIR_TMP" "$FILE_MAIN";
            NAME=`basename $FILE_MAIN .tex`;
            cp $DIR_TMP/$NAME.pdf $NAME.pdf
            [ "1" == "$DOOPT" ] && [ -n "$BIN_PDF" ] && ( $BIN_PDF --linearize $DIR_TMP/$NAME.pdf $NAME.pdf )
            showWarnings;
            echo "File created: $NAME.pdf";
            [ -z "$BIN_PDF" ] || ( echo -n "Pages: "; $BIN_PDF --show-npages $NAME.pdf )
            [ -z "$BIN_NOT" ] || $BIN_NOT -title "LaTeX" -message "Build ready" -open "file://$(pwd)/$NAME.pdf"
        fi;

        if [ "$deploy" ]; then
            NAME=`basename $FILE_MAIN .tex`;
            if [ "$DPATH" = "" ]; then
                echo "Set DPATH first!";
            else
              cp "$NAME.pdf" "$DPATH"
              chmod go+r "$DPATH/$NAME.pdf"
            fi
        fi

        if [ "$open" ]; then
            NAME=`basename $FILE_MAIN .tex`;
            if [ "$BACK" == "1" ]; then
                open -g "$NAME.pdf"
            else
                open "$NAME.pdf"
            fi
        fi
    else
        showHelp;
    fi;
}

function checkParameter() {
  SYNTAX="Syntax: $0 [-c (clean)] [-b (build)] [-i (bIbtex)] [-r (quicker build)] [-q (quick build)] [-v (verify)] \
     [-w (bib checking)] [-s (spell checking)] [-e (run the evaluation)] [-g (generate images etc.)] \
     [-d (deploy)] [-o (open)] [-f (continuous integration)] [-u (unicode check)] \
     [-z (optimize)] [-x (X.509 signature)] [-p (preflight)] [-n (rename)] [-m (fix)] [-y (debug)] \
     [-t (dependencies)] [-h (help)]";
  while getopts ":qrchvsbiegdfounwzxmtyp" optname
  do
    case "$optname" in
      "t")
        deps=1;
        ;;
      "y")
        debug=1;
        ;;
      "q")
        quick=1;
        ;;
      "r")
        quicker=1;
        ;;
      "c")
        clean=1;
        ;;
      "v")
        verify=1;
        ;;
      "w")
        bibcheck=1;
        ;;
      "s")
        spelling=1;
        ;;
      "b")
        build=1;
        ;;
      "i")
        dobib=1;
        ;;
      "g")
        generate=1;
        ;;
      "e")
        eval=1;
        ;;
      "d")
        deploy=1;
        ;;
      "o")
        open=1;
        ;;
      "f")
        ci=1;
        ;;
      "u")
        unicode=1;
        ;;
      "z")
        optimize=1;
        ;;
      "x")
        sign=1;
        ;;
      "p")
        preflight=1;
        ;;
      "n")
        rename=1;
        ;;
      "m")
        fix=1;
        ;;
      "h")
        showHelp;
        exit;
        ;;
      ":")
        echo "No argument value for option $OPTARG"
        ;;
      *)
      # Should not occur
        echo "Unknown error while processing options"
        showHelp;
        exit;
        ;;
    esac
  done
}

function deps() {
	_file_main="$1";
	command -v texliveonfly >/dev/null 2>&1 || { echo "texliveonfly not found!"; exit 1; }
	texliveonfly "${_file_main}"
}

function optimize() {
	_dir_resources="$1";
  :> optimize.log

  echo "Optimizing PDFs..."
  checkEnvironment gs || exit 1
  for pdf in ${DIR_IMG}/*.optimized.pdf; do
    if [ "${pdf}" != "${DIR_IMG}/*.optimized.pdf" ]; then
      echo "ERROR: old file '${pdf}' found"
      exit 1
    fi
  done
  for pdf in ${DIR_IMG}/*.pdf; do
        echo "Optimizing $pdf..."
        gs -o "${pdf}.optimized.pdf" \
           -dBATCH -dNOPAUSE \
           -sDEVICE=pdfwrite \
           -dCompatibilityLevel=1.4 \
           -dPDFA=2 \
           -dPDFACompatibilityPolicy=1 \
           -dPDFSETTINGS=/prepress \
           -dDetectDuplicateImages=true \
           -dCompressFonts=true \
           -dSubsetFonts=true \
           -dEmbedAllFonts=true \
           -dCompressPages=true \
           -dNOINTERPOLATE \
           -dAutoFilterColorImages=false \
           -dAutoFilterGrayImages=false \
           -dColorImageFilter=/FlateEncode \
           -dGrayImageFilter=/FlateEncode \
           -dColorConversionStrategy=/LeaveColorUnchanged \
           -dDownsampleMonoImages=false \
           -dDownsampleGrayImages=false \
           -dDownsampleColorImages=false \
           ${pdf} >> optimize.log 2>&1 && \
        mv "${pdf}.optimized.pdf" ${pdf} || ( echo "ERROR: $pdf - see optimize.log"; exit 1; )
        # perl -pi -e 's/Interpolate true/Interpolate false/g' ${pdf} # can damage a file
        #           -dFastWebView # GhostScript BUG 696280
  done

  echo "Optimizing PNGs..."
  checkEnvironment optipng && find ${_dir_resources} -iname "*.png" -exec echo "Optimizing {}..." \; -exec optipng {} >> optimize.log 2>&1 \;

  echo "Optimizing JPGs..."
  checkEnvironment jpegoptim && find ${_dir_resources} -iname "*.jpg" -exec echo "Optimizing {}..." \; -exec jpegoptim -o -p {} >> optimize.log 2>&1 \;
}

function preflight() {
  _file_pdf="$1"
  _dir_img="$2"
  _count=0

  echo "Looking for incompatible PDF versions..."
  for pdf in ${_dir_img}/*.pdf; do
    version="$(pdfinfo ${pdf}|grep "PDF version"|awk '{print $3}')"
    if [ $(bc <<< "1.4 <= ${version} > 1.4") -eq 1 ]; then
      echo "WARNING: file '${pdf}' uses PDF version ${version}, which is higher than 1.4"
      _error=1
    fi
  done

  echo "Looking for interpolated PDF's'..."
  for pdf in ${_dir_img}/*.pdf; do
    interpolated="$(strings ${pdf}|grep -i "interpolate true")"
    if [ ! -z "${interpolated}" ]; then
      echo "WARNING: file '$pdf' uses interpolation"
      _error=1
    fi
  done

  echo "Looking for non-embedded fonts..."
  for pdf in ${_dir_img}/*.pdf; do
    list=$(pdffonts "${pdf}"|awk -F '[[:space:]][[:space:]]+' '{print $4}'| awk '{print $1}')
    for embedded in $list; do
      if [ "${embedded}" == "no" ]; then
        _count=$((_count+1))
      fi
    done
    if [ "${_count}" != "0" ]; then
      echo "WARNING: Found ${_count} fonts that are not embedded in '$pdf'. Run 'pdffonts ${pdf}' for details. Consider to run 'make optimize' ..."
      _error=1
    fi
  done

  echo "Looking for ICC color profiles (might result in wrong colors in PDF/A)..."
  for pdf in ${_dir_img}/*.pdf; do
    icc=$(pdfimages -list ${pdf}|grep -i icc)
    if [ ! -z "${icc}" ]; then
       echo "WARNING: Found an ICC color profile in '$pdf'. Run 'pdfimages -list ${pdf}' for details.";
       _error=1
    fi
  done

  echo "Looking transparency in PDFs (forbidden in PDF/A1-b)..."
  for pdf in ${_dir_img}/*.pdf; do
    transparent=$(grep -aE -e '/[Cc][Aa] +0?\.[0-9]' -e '/SMask' -e '/S /Transparency' ${pdf})
    if [ ! -z "$transparent" ]; then
      echo "WARNING: File ${pdf} contains transparency. Remove tranparency/shadows or include a bitmap.'"
      #mkdir -p "resources/images-vector"; if [ ! -f "resources/images-vector/$(basename ${pdf})" ]; then cp ${pdf} "resources/images-vector/$(basename ${pdf})"; fi
      #gs -r300 -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sDEVICE=pdfwrite -dCompatibilityLevel=1.3 -sOutputFile="${pdf}" "resources/images-vector/$(basename ${pdf})"
      #gs -q -dNOPAUSE -dBATCH -sDEVICE=pngalpha -r150 -dEPSCrop -sOutputFile="${pdf}.png" ${pdf}
      _error=1
    fi
  done

  echo "Generating a PDF/A2-b compatible file..."
  params="-dBATCH -dNOPAUSE -q -dNOOUTERSAVE -sDEVICE=pdfwrite -dPDFACompatibilityPolicy=1 -sColorConversionStrategy=/RGB -sProcessColorModel=DeviceCMYK -dEmbedAllFonts=true -dMaxSubsetPct=100 -dSubsetFonts=true -dPDFSETTINGS=/prepress"
  gs ${params} -dPDFA=2 -sOutputFile="pdfa2-b_${_file_pdf}" lib/resources/pdfa/PDFA_def.ps ${_file_pdf}
  #gs ${params} -dPDFA=1 -sOutputFile="pdfa1-b_${_file_pdf}" lib/resources/pdfa/PDFA_def.ps ${_file_pdf}
   #-dFastWebView=true  # Bug 696275
}

function sign() {
	_file_base="$1";
  _file_cert="$2";

  [ "" == "${_file_cert}" ] && echo "ERROR: FILE_CERT not set" && exit 1
  [ ! -f "${_file_cert}" ] && echo "ERROR: '${_file_cert}' not a file" && exit 1
  checkEnvironment java && java -jar lib/resources/scripts/PortableSigner.jar -t "${_file_base}.pdf" -o "${_file_base}-signed.pdf" -s "${_file_cert}" -n
  #[ "1" == "$DOOPT" ] && [ -n "$BIN_PDF" ] && ( $BIN_PDF --linearize "${_file_base}-signed.pdf" "${_file_base}-signed-opt.pdf" )
}

function rename() {
  old=$(grep FILE_BASE= build.config.sh|sed -n -e 's/^.*="\(.*\)";/\1/p')
  echo "Old project name: ${old}"
  echo -n "New project name: "
  read new
  TMP_FILE=`mktemp /tmp/config.XXXXXXXXXX`
  sed -e "s/BASE=\"${old}\"/BASE=\"${new}\"/" build.config.sh > $TMP_FILE
  mv $TMP_FILE build.config.sh

  TMP_FILE=`mktemp /tmp/config.XXXXXXXXXX`
  sed -e "s/${old}\./${new}./" ${FILE_BASE}.tex > $TMP_FILE
  mv $TMP_FILE ${FILE_BASE}.tex

  TMP_FILE=`mktemp /tmp/config.XXXXXXXXXX`
  sed -e "s/${old}\./${new}./" ${FILE_BASE}.config.tex > $TMP_FILE
  mv $TMP_FILE ${FILE_BASE}.config.tex

  mv ${FILE_BIB} ${new}.bib
  mv ${FILE_CONFIG} ${new}.config.tex
  mv ${FILE_ACRO} ${new}.acro.tex
  mv ${FILE_GLS} ${new}.glos.tex
  mv ${FILE_BASE}.tex ${new}.tex
  mv ${FILE_BASE}.meta.tex ${new}.meta.tex
}

function checkUnicode() {
	_dir_sources="$1";
    _pcreExists=$(command -v pcregrep >/dev/null 2>&1 && echo 1)
    if [ $_pcreExists ]; then _cmd="pcregrep"; else _cmd="grep -P"; fi

	find ${_dir_sources}  \( -iname "*.tex" -o -iname "*.txt" \)  -exec \
    $_cmd -H --color='auto' -n "^\s*[^%]+[^\x01-\x80äöüßÄÖÜÉÁÓÚúóéá€]" {} \;
	  #$_cmd -H --color='auto' -n "^\s*[^%]+[\x80-\xFF]" {} \;
}

function checkEnvironment() {
	_error="0";
    _filenames="$1";

    for filename in $_filenames; do
      if [ "`(which $filename; echo $?)|tail -n 1`" != "0" ]; then
        echo "WARNING! The package '$filename' was not found. The build might fail!!";
        _error="1";
      fi;
    done;
    #if [ "$_error" != "0" ]; then
    #   exit 1;
    #fi;
    return $_error
}

function checkError() {
    _exitcode="$1";
    if [ "$_exitcode" != "0" ]; then
        echo "WARNING: Command failed. The build might fail!! See $FILE_LOG.";
        #exit $_exitcode
    fi
}

function checkRule() {
    _list="$1";
    _filename="$2";
    _message="$3";
    _casesens="$4";
    state=0
    IFS="#";

    if [ ! -f "$_filename" ]; then
        echo "ERROR: could not find: $_filename"
        return 1
    fi

    content=`cat $_filename | perl -pe "s/%.*$//g"`;
    for word in $_list; do
      if [ "$_casesens" == "" ]; then
        found=`echo $content|perl -ne "/$word/i && print"`;
      else
        found=`echo $content|perl -ne "/$word/ && print"`;
      fi
      if [ "$found" != "" ]; then
        echo "warning: $_message '$word' in $_filename.";
        state=1
      fi
    done

    IFS=$IFS_ORG;
    return $state;
}

function checkSpelling() {
    _filename="$1";
    _dir_resources="$2";
	_language="$3";

    found=`cat $_filename | aspell \
      --home-dir=$_dir_resources \
      --lang=$_language \
      --dont-backup --encoding=utf-8 --mode=tex --dont-tex-check-comments \
      --add-tex-command="bibliographystyle po" \
      --add-tex-command="bibliography po" \
      --add-tex-command="eqref po" \
      --add-tex-command="ac po" \
      --add-tex-command="aclu po" \
      --add-tex-command="acp po" \
      --add-tex-command="acs po" \
      --add-tex-command="Cref po" \
      list`;
    if [ "$found" != "" ]; then
        echo "warning: Please add via aspell or correct in '$_filename' the word(s): $found";
        return 1
    fi
}

function checkSpellingInteractive() {
	_dir_sources="$1";
	_dir_resources="$2";
	_language="$3";


  find $_dir_sources -iname "*.tex" -exec \
      aspell --home-dir=$_dir_resources \
        --lang=$_language \
        --dont-backup --encoding=utf-8 --mode=tex --dont-tex-check-comments \
        --add-tex-command="bibliographystyle po" \
        --add-tex-command="bibliography po" \
        --add-tex-command="eqref po" \
        --add-tex-command="ac po" \
        --add-tex-command="aclu po" \
        --add-tex-command="acp po" \
        --add-tex-command="acs po" \
        --add-tex-command="Cref po" \
        check {} \;
}

function fix() {
	_file_main="$1";
	_dir_sources="$2";

	iconv -f UTF8-MAC -t UTF8 "$1.tex" > tmp.tmp && mv tmp.tmp "$1.tex"
	iconv -f UTF8-MAC -t UTF8 "$1.config.tex" > tmp.tmp && mv tmp.tmp "$1.config.tex"
	iconv -f UTF8-MAC -t UTF8 "$1.meta.tex" > tmp.tmp && mv tmp.tmp "$1.meta.tex"
	find $_dir_sources -iname "*.tex" -exec sh -c "iconv -f UTF8-MAC -t UTF8 '{}' > tmp.tmp && mv tmp.tmp '{}'" \;
}

function checkBib() {
  _dir_sources="$1";
	_dir_tmp="$2";
	_file_bib="$3";
  _file_main="$4";
  _error=0;

  echo "Checking bibtex...";
  python lib/resources/scripts/biblatex_check.py -b "${_dir_tmp}/$(basename $_file_main .tex)".bib -a "${_dir_tmp}/$(basename $_file_main .tex)".aux
  issues="$(grep -Eo 'problems: [0-9]{1,4}' biblatex_check.html|grep -Eo "[0-9]{1,4}")"
  if [ "0" -ne "$issues" ]; then
    echo "Found $issues issues in biblatex_check.html"
    _error=1
  fi
  biber -T -V "${_dir_tmp}/$(basename $_file_main .tex)" | grep -Ev "mendeley|INFO|Duplicate|junk|arxivid|Invalid field 'publisher'|Invalid field 'publisher'|Missing mandatory field 'editor'" > biber_check.txt
  issues="$(cat biber_check.txt|wc -l)"
  if [ "0" -ne "$issues" ]; then
    echo "Found $issues issues in biber_check.txt"
    _error=1
  fi

  return $_error
}

function checkProject() {
	_dir_sources="$1";
	_dir_tmp="$2";
	_dir_resources="$3";
	_file_abstract="$4";
	_file_introduction="$5";
	_file_config="$6";
	_file_main="$7";
	_file_bib="$8";
	_language="$9";
  #TODO: refactor this!
	#_dir_cfg="$10";
  _dir_cfg="$DIR_CFG";
	_error=0

  echo "Running chktex...";
  checkEnvironment chktex && chktex -q "${_file_main}"

  echo "Checking for unicode issues...";
  checkUnicode $_dir_sources/

  echo "Finding unused figures..."
  for image in $DIR_IMG/*; do
    filename=$(basename "$image")
    extension="${filename##*.}"
    filename="${filename%.*}"
    if [ "$extension" == "pdf" ] || [ "$extension" == "png" ] || [ "$extension" == "jpg" ] ; then
      found=$(grep -rE "^\s*[^%]+(includegraphics|ThisLROffsetCornerWallPaper).*$filename[\.|}]" $DIR_SRC)
      if [ -z "${found}" ]; then
        echo "WARNING: figure '$image' not included in sources"
        #mv $image resources/images-unused
        _error=1
      fi
    fi
  done

  # Helper function to find unreferenced labels, since the chkltex tool and the refcheck package do not support cleveref
  # Note: this could show false positives sometimes
  echo "Checking for unreferenced labels...";
  labels=$(grep -Eo '^[\s]*[^%]+.*label{[^}]+}' $_dir_sources/*.tex|sed -Ee "s/^.*{(.*)}/\1/g")
  for label in $labels; do
    found=$(grep -E "ref{[^}]*$label" $_dir_sources/*.tex)
    if [[ -z "$found" ]]; then
      echo "WARNING: Label '$label' not referenced?";
      _error=1
    fi
  done

  # note that this somehow shows false positives sometimes :/
  echo "Checking for duplicated/repeated words...";
  grep -rEo '\b(\w+)(\s+\1\b)+' $_dir_sources/

  echo "Checking for citations with missing space...";
  grep -rEo '[^~%]\\\cite{' $_dir_sources/

  echo "Checking config...";
  checkRule "$BAD_CONFIG" "$_file_config" "Avoid";
  if [ "$?" != "0" ]; then _error=1; fi
  checkRule "$BAD_CONFIG" "$_dir_cfg/default.tex" "Avoid";
  if [ "$?" != "0" ]; then _error=1; fi
  checkRule "$BAD_CONFIG" "$_dir_cfg/pdfmetadata.tex" "Avoid";
  if [ "$?" != "0" ]; then _error=1; fi

  echo "Checking todos...";
  for file in $_dir_sources/*.tex; do
    checkRule "$TODOS" "$file" "";
    #if [ "$?" != "0" ]; then _error=1; fi
  done

  echo "Checking orthography...";
  if [ "$DOSPELLCHECK" == "1" ]; then
    for file in $_dir_sources/*.tex; do
      checkSpelling "$file" $_dir_resources $_language;
      if [ "$?" != "0" ]; then _error=1; fi
    done
  fi

  echo "Checking abstract...";
  checkRule "$BAD_ABSTRACT" "$_file_abstract" "Avoid"
  if [ "$?" != "0" ]; then _error=1; fi
  WORDS=`cat $_filename | perl -pe "s/%.*$//g" | wc -w`;
  if [ $WORDS -lt "$MIN_ABSTRACT" ] || [ $WORDS -gt "$MAX_ABSTRACT" ]; then
    echo "warning: you've $WORDS words in your abstract [Should be: $MIN_ABSTRACT-$MAX_ABSTRACT].";
    _error=1
  fi

  echo "Checking introduction...";
  checkRule "$BAD_INTRO" "$_file_introduction" "Avoid";
  if [ "$?" != "0" ]; then _error=1; fi

  echo "Checking references...";
  for file in $_dir_sources/*.tex; do
    checkRule "$REFS" "$file" "References must be written in uppercase: " true;
    if [ "$?" != "0" ]; then _error=1; fi
  done

  echo "Checking latex (l2tabu)...";
  checkRule "$L2TABU" "$_file_config" "Avoid";
  if [ "$?" != "0" ]; then _error=1; fi
  for file in $_dir_sources/*.tex; do
    checkRule "$L2TABU" "$file" "Avoid";
    if [ "$?" != "0" ]; then _error=1; fi
  done

  echo "Checking commas...";
  for file in $_dir_sources/*.tex; do
    checkRule "$COMMAS" "$file" "I think we need a comma here: " true;
    if [ "$?" != "0" ]; then _error=1; fi
  done

  echo "Checking hyphens...";
  for file in $_dir_sources/*.tex; do
    checkRule "$HYPHENS" "$file" "These prepositions should not be written with a hyphen: ";
    if [ "$?" != "0" ]; then _error=1; fi
  done

  echo "Checking for common mistakes...";
  for file in $_dir_sources/*.tex; do
    checkRule "$MISTAKES" "$file" "Double check: ";
    if [ "$?" != "0" ]; then _error=1; fi
  done

  echo "Checking for common mistakes 2...";
  for file in $_dir_sources/*.tex; do
    checkRule "$MISTAKES_CS" "$file" "Double check: " true;
    if [ "$?" != "0" ]; then _error=1; fi
  done

  # too restrictive
  #echo "Checking for missed acronyms...";
  #grep -HIrnsE "^[^%].* [A-Z]{4,}[ |s]" $_dir_sources/|grep -v caption

  # too restrictive
  #echo "Checking general...";
  #for file in $_dir_sources/*.tex; do
  #  checkRule "$AVOID" "$file" "Avoid" true;
  #  if [ "$?" != "0" ]; then _error=1; fi
  #done

  # too restrictive
  #echo "Checking macros...";
  #for file in ls $_dir_sources/*.tex; do
  #  checkRule "$MACROS" "$file" "Use an LaTeX macro instead" true;
  #  if [ "$?" != "0" ]; then _error=1; fi
  #done

  return $_error
  #---------------------------------------------------------------------------
}

function showHelp() {
    echo $SYNTAX;
}

function showWarnings() {
    #WARNINGS=`grep -i warning $FILE_LOG|grep -v ifpdftex`;
	#WARNINGS=`grep -iE "^! |Warning|Overfull|Underfull" $FILE_LOG|grep -vE "addtolists|tocbasic|selectfont|fontenc|pickup@font|scrhack|float@listhead|minitoc|expanded"`;
  #WARNINGS=$(grep -vE "Unused label \`ac:" $FILE_LOG|grep -A2 -B2 -iE "^! |Warning"|grep -vE "addtolists|tocbasic|selectfont|fontenc|pickup@font|scrhack|float@listhead|minitoc|expanded|Unsupported");
  WARNINGS=$(grep -vE "Unused label \`ac:|Unused label \`sub|addtolists|tocbasic|selectfont|fontenc|pickup@font|scrhack|float@listhead|minitoc|expanded|Unsupported|ALPHA VERSION!" $FILE_LOG|grep -A2 -B2 -iE "^! |Warning");
    if [ "$WARNINGS" != "" ]; then
      echo "-------------";
      cat "$WARNINGS";
      echo "-------------";
      return 1
    fi
}

function doSetup() {
    _pathnames="$1";

    for pathname in $_pathnames; do
        mkdir -p "$pathname";
    done
    resetLogging;
}

function doCleanup() {
	_dir_tmp="$1";

    echo -n "Cleaning up...";
	rm -rf "$_dir_tmp" 2> /dev/null;
    if [ "$isNotGnu" == "1" ]; then
      find . -path '*.git' -prune -o -regex ".*\.\(brf\|bak\|aux\|bbl\|blg\|idx\|out\|new\|lot\|loa\|lof\|toc\|log\|ilg\|gls\|glo\|ind\|slg\|syg\|lol\|syi\|maf\|bcf\|spl\|glg\|xdy\|glsdefs\|mtc.*\|fls\|fdb_latexmk\)$" -exec rm {} \;
      find . -path '*.git' -prune -o -regex ".*-blx\.bib\|.*biblatex_check\.html\|.*biber_check.txt\|.*\.run\.xml$" -exec rm {} \;
    else
      find -E . -path '*.git' -prune -o -regex ".*\.(brf|bak|aux|bbl|blg|idx|out|new|lot|loa|lof|toc|log|ilg|ind|gls|glo|slg|syg|syi|lol|maf|spl|glg|xdy|glsdefs|bcf|mtc.*|fls|fdb_latexmk)$" -exec rm {} \;
      find -E . -path '*.git' -prune -o -regex ".*-blx\.bib|.*biblatex_check\.html|.*biber_check.txt|.*\.run\.xml$" -exec rm {} \;
    fi
    echo "done";
}


function cleanAcronyms() {
    _file_acro="$1";
    echo -n "Sorting acronyms...";
    if [ -e "$_file_acro" ]; then
        sort -f "$_file_acro"|uniq > "$_file_acro.uniq" && \
        mv "$_file_acro.uniq" "$_file_acro"
    fi
    echo "done";
}

function doLatex() {
	_dir_tmp="$1";
	_file_main="$2";
	_option="$3";
	echo -n "Running LaTeX...";
    startLogging;
    pdflatex \
      $_option \
	  -shell-escape \
	  -interaction=nonstopmode \
	  -file-line-error \
	  -output-directory $_dir_tmp \
	  $_file_main
	errorlevel=$?
	endLogging;
	checkError $errorlevel;
	echo "done";
}

function debug() {
	_dir_tmp="$1";
	_file_main="$2";
  mkdir -p "${_dir_tmp}"
	echo -n "Running LaTeX in debug mode...";
    pdflatex \
      -halt-on-error \
      -file-line-error \
      -output-directory $_dir_tmp \
	    $_file_main
	echo "done";
}

function doBibtex() {
	_dir_tmp="$1";
	_file_main="$2";
  _file_bib="$3";
  _dir_res="$4";
  _ext="$5";
  echo -n "Running BibTeX and Glossary...";

    startLogging;
    cp -r "$_dir_res" "$_dir_tmp";
    cp "$_file_bib" "$_dir_tmp";
    # TODO: refactor the next line!
    cp -R "$DIR_LIB" "$_dir_tmp";
    cp *.bib "$_dir_tmp";
    cp *.bst "$_dir_tmp";
    cp *.cls "$_dir_tmp";
    cd "$_dir_tmp" || ( echo "dir not found" ; exit 1)
    file_bibtex=`basename $_file_main .tex`"$_ext";

    makeglossaries $file_bibtex
    $BIN_BIB $file_bibtex
    errorlevel=$?
    found=`$BIN_BIB $file_bibtex | grep -iE "warn|illegal|repeated|skipping|couldn't" | grep -v junk`
    cd - || ( echo "dir not found" ; exit 1)
	endLogging;
    if [ "$found" != "" ]; then
    	echo "warning: BibTeX: $found";
    fi
	checkError $errorlevel;
	echo "done";
}

function doIndex() {
	_dir_tmp="$1";
	_dir_layout="$2";
    echo -n "Running Index...";
    startLogging;
	file_index=`basename $_file_main .tex`;
    makeindex -g -s $_dir_layout/index.ist "$_dir_tmp/$file_index";
    errorlevel=$?
	endLogging;
	checkError $errorlevel;
	echo "done";
}

function doGraphviz() {
	_dir_img="$1";
	errorlevel=0;
	echo -n "Graphviz...";
	[ "`ls $_dir_img/*.gv 2>/dev/null`" == "" ] && echo "skipped" && return
	startLogging;
	for gv in $_dir_img/*.gv; do
        file=${gv##*/}
                file=${file%%.*}
		dot -Tps2 -o $_dir_img/$file.ps $gv;
		ps2pdf $_dir_img/$file.ps $_dir_img/$file.pdf
		rm $_dir_img/$file.ps
		errorlevel=$?
		if [ "$errorlevel" != "0" ]; then break; fi
	done
	endLogging;
	checkError $errorlevel;
	echo "done";
}

function doPlant() {
	_dir_img="$1";
	errorlevel=0;
	echo -n "Plant...";
	[ "`ls $_dir_img/*.plant 2>/dev/null`" == "" ] && echo "skipped" && return
	startLogging;
	plantuml $_dir_img/*.plant
	errorlevel=$?
#	for plant in `ls $_dir_img/*.plant`; do
#		plantuml $plant;
#		errorlevel=$?
#		if [ "$errorlevel" != "0" ]; then break; fi
#	done
	endLogging;
	checkError $errorlevel;
	echo "done";
}

function doGnuPlot() {
	_dir_img="$1";
	errorlevel=0;
	echo -n "Gnuplot...";
	[ "`ls $_dir_img/*.gv 2>/dev/null`" == "" ] && echo "skipped" && return
	cd $_dir_img  || ( echo "dir not found" ; exit 1)
	startLogging;
	for plt in *.plt; do
		gnuplot $plt;
		errorlevel=$?
		if [ "$errorlevel" != "0" ]; then break; fi
	done
	cd - || ( echo "dir not found" ; exit 1)
	endLogging;
	checkError $errorlevel;
	echo "done";
}

function doPlotR() {
	_dir_img="$1";
	errorlevel=0;
	echo -n "R...";
	[ "`ls $_dir_img/*.R 2>/dev/null`" == "" ] && echo "skipped" && return
    startLogging;
    cd $_dir_img || ( echo "dir not found" ; exit 1)
    for r in *.R; do
    	Rscript $r;
		errorlevel=$?
		if [ "$errorlevel" != "0" ]; then break; fi
    done
    cd - || ( echo "dir not found" ; exit 1)
    endLogging;
    checkError $errorlevel;
    echo "done";
}

function doEvaluation() {
	_dir_scr=$1
	_dir_ana=$2
    startLogging;
    # shellcheck source=../scripts/workDispatcher
    source "$_dir_scr/workDispatcher"
    cd $_dir_ana || ( echo "dir not found" ; exit 1)
    _cmd='Rscript'
    for r in *.R; do
		echo $r
	done | dispatchWork
	errorlevel=$?
    cd - || ( echo "dir not found" ; exit 1)
    endLogging;
    checkError $errorlevel;
}
#===============================================================================


#===============================================================================
# Details about lints, smells, bugs, and conventions:
# * http://mirror.ctan.org/info/l2tabu/english/l2tabu.pdf
# * http://www.cs.columbia.edu/~hgs/etc/writing-style.html
# * http://www.cs.columbia.edu/~hgs/etc/writing-bugs.html
# * http://www.cs.purdue.edu/homes/dec/essay.dissertation.html
# * http://www.punctuationmadesimple.com/PMSHyphen.html
# * http://www.jr-x.de/publikationen/latex/tipps/besonderheiten.html
#===============================================================================
HYPHENS="\bpre-[^\s]+#\banti-[^\s]+#\bmacro-[^\s]+#\bmicro-[^\s]+#\bpost-[^\s]+#\bover-[^\s]+#\bsemi-[^\s]+#\bsub-[^\s]+#\bsupra-[^\s]+#\btrans-[^\s]+#\bultra-[^\s]+#\bmeta-[^\s]+#\banti-[^\s]+#\bbe-[^\s]+#\bby-[^\s]+#\bdis-[^\s]+#\bfull-[^\s]+#\bhyper-[^\s]+#\bmid-[^\s]+#\bmini-[^\s]+#\bnon-[^\s]+#\bpre-[^\s]+#\bunder-[^\s]+#\bup-[^\s]+#\bante-[^\s]+#\bmulti-[^\s]+#\binfra-[^\s]+#\binter-[^\s]+#\bintra-[^\s]+";
COMMAS="However\s+#In fact\s+#Therefore\s+#Nevertheless\s+#Moreover\s+#Furthermore\s+#Still\s+#Instead\s+[^o][^f]#Unfortunately\s+#On the one hand\s+#On the other hand\s+#[^,]\s+dass#[^.]*[^,]\s+um[^.]+zu[^.]+.";
REFS='[^\\]section[^A-Za-z\.,;\}\(]+\\#figure[^A-Za-z\.,;\}\(]+\\#equation[^A-Za-z\.,;\}\(]+\\#table[^A-Za-z\.,;\}\(]+\\';
MISTAKES='test bed#test-bed#caption.*\\[aA]c';
MISTAKES_CS='\bwebservice\b#\bweb service\b#\bMiddleware\b#\bArgon[^:]\b#\binternet\b';
#AVOID="clearly#obviously#actually#\$i-th\$#etc\.#\.e\.#e\.g\.[^,]#[^,]\s{,1}respectively#Therefore[^,]#thus[^,]#related works#following (figure\b|fig\.)#[^~](\s*)\\\ref#\bkbps#\bmbps#\bmsec#recent advances in# don't#doesn't#we've#won't#it's#That's because#optimally#Equation(~|\s*)\\\ref#\still\s#make assumption#is a function of#is an illustration#is a requirement#utilizes#had difference#\\\$[0-9]+\\\$#\\\cite{.*}\\s\\\cite#\bgut\b#\bschlecht\b#\bschön\b#\bfurchtbar\b#\bdumm\b#\bwahr\b#\bfalsch\b#\bperfekt\b#\bideal\b#\bheutzutage\b#\bmodern\b#\bbald\b#\büberrascht\b#\bscheint\b#\bbasiert\b#\bviele\b#\beinige\b#\bähnlich\b#\bwahrscheinlich\b#\bselbstverständlich\b#\bklar\b#\bwirklich\b#\beinfach\b#\bdieses\b#\bjenes\b#\bwir\b#\bhoffentlich\b#\bbekannt\b#\bberühmt\b#\bmuss\b#\bman\b#\b\bhalt\b\b#\bimmer\b#\bsollte\b#\bbeweis\b#\bzeigt\b#\bkann\b#\bsollte\b#\bmüsste\b#\bsoon\b#\bbald\b#\bperfect\b#\bperfekt\b#\bseems\b#\bscheint\b#\blots of\b#\bkind of\b#\btype of\b#\bsomethink like\b#\bprobably\b#\balong with\b#\bwould seem to show\b#\ban ideal solution\b#\bbad\b#\bnice\b#\bstupid\b#\bmodern times\b#\btoday\b#\ba famous researcher\b#\bsimple\b#z\.B\.#d\.h\.#z\.Z\.#u\.a\.#\\\caption.*\\\ac"
#MACROS="\bPreface\b#\bVorwort\b#\bReferences\b#\bLiteratur\b#\bBibliography\b#\bLiteraturverzeichnis\b#\bAppendix\b#\bAnhang\b#\bContents\b#\bInhaltsverzeichnis\b#\bList of Figures\b#\bAbbildungsverzeichnis\b#\bList of Tables\b#\bTabellenverzeichnis\b#\bFigure|Fig\.[^A-Za-z\.,;]+#\bAbbildung|Abb\.[^A-Za-z\.,;]+#\bTable|Tab\.[^A-Za-z\.,;]+#\bTabelle[^A-Za-z\.,;]+#\bEquation|Eq\.[^A-Za-z\.,;]+#\bSection|Seq\.[^A-Za-z\.,;]+#\bPart\b#\bTeil\b#\bencl\b#\bAnlage(n)\b#\bVerteiler\b#\bPage\b#\bSeite\b#\bsee also\b#\bsiehe auch\b";
BAD_ABSTRACT="\cite#\equation#in this paper";
BAD_INTRO="recent advances in#growth of the Internet";
TODOS="todo#fixme#tbd";
L2TABU='\\usepackage.*{a4#\\oddsidemargin#\\hoffset#\\voffset#\\baselinestretch#\\parindent=#\$\$#\\def\\#\\sloppy#{\\bf[^A-Za-z]}#{\\it#{\\rm[^A-Za-z]#{\\sc[^A-Za-z]#{\\sf[^A-Za-z]#{\\sl[^A-Za-z]#{\\tt[^A-Za-z]#\\over#\\centerline#\\usepackage.*{psfig}#\\psfig#\\usepackage.*{doublespace}#\\usepackage.*{fancyheadings}#\\usepackage.*{scrpage}#\\usepackage.*{caption}[^\[]#\\usepackage.*{isolatin1}#\\usepackage.*{umlaut}#\\usepackage.*{t1enc}#dinat.bst#\\usepackage.*{times}#\\usepackage.*{mathptm}#\\usepackage.*{pslatex}#\\usepackage.*{palatino}#\\usepackage.*{pifont}#\\usepackage.*{euler}#\\usepackage.*{ae}#\\usepackage.*{zefonts}#\\begin.*{appendix}#eqnarray#displaymath#\\graphicspath';
#===============================================================================


#===============================================================================
# Autoconfig
#===============================================================================
find -E . -maxdepth 1 > /dev/null 2>&1
isNotGnu=$?
IFS_ORG="$IFS";
FILE_LOG="$0.log";
if [ "$MIN_ABSTRACT" == "" ]; then
  MIN_ABSTRACT="100";
fi
if [ "$MAX_ABSTRACT" == "" ]; then
  MAX_ABSTRACT="150";
fi
if [ "$DOSPELLCHECK" == "" ]; then
  DOSPELLCHECK="1";
fi
export TEXINPUTS=$DIR_IMG:$TEXINPUTS
export LANGUAGE=$LANGEXT
export LANG=$LANGEXT
export LC_ALL=$LANGEXT
#===============================================================================
