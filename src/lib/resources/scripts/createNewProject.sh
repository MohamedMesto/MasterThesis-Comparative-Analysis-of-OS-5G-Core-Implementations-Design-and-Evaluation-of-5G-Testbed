#!/bin/bash
###############################################################################
#
# Script to create a new project based on a template.
#
# @tested	On OS X 10.7
# @version	2012-03-21
###############################################################################


# config ######################################################################
project_name="$1"
template_type="$2" # Paper | Expose | Review | Thesis
#default_name="$3" # template | expose | review | thesis_template

#template_type="Paper" # Paper | Expose | Review | Thesis
#default_name="template" # template | expose | review | thesis_template

vcs_path="publications/"
wiki_path="Publication/"
wiki_param="?action=edit&template=Publication"

url_vcs="https://svnsrv.fokus.fraunhofer.de/svn/cc/ngni/tub-av/${vcs_path}"
url_wiki="https://svnsrv.fokus.fraunhofer.de/cc/ngni/tub-av/wiki/Guides/Research/${wiki_path}"

url_template_base="https://svn.github.com/tubav"
url_template="${url_template_base}/${template_type}"
url_lib="https://github.com/tubav/Core/trunk"
project_lib="lib"
###############################################################################


# functions ###################################################################
function checkError {
    [ "0" != "${1}" ] && echo "Command failed: ${1}." && exit ${1};
}
###############################################################################


# input #######################################################################
[ -z "${project_name}" ] && echo -n "Project name (e.g. 2012ngi): " && read project_name
[ -z "${template_type}" ] && echo -n "Template type (e.g. Review): " && read template_type
#[ -z "${default_name}" ] && echo -n "Default file name (e.g. review): " && read default_name
###############################################################################


# checks ######################################################################
[ -z "${project_name}" ] && echo "Invalid input" && exit 1
[ -e "${project_name}" ] && echo "Directory '${project_name}' already exists" && exit 2
###############################################################################


# setup #######################################################################
echo "Exporting template..."
svn export "${url_template}" "${project_name}" && cd "${project_name}"
checkError $?

echo "Cleanup files..."
source "build.sh.config"
default_name="$(basename $FILE_MAIN .tex)"
rm -f "${default_name}.pdf"
rm -f ".gitmodules"
rm -f ".gitignore"
rm -rf "${project_lib}"

echo "Renaming default files..."
mv "${default_name}.tex" "${project_name}.tex" && \
mv "${default_name}.config.tex" "${project_name}.config.tex" && \
perl -p -i -e "s/${default_name}/${project_name}/g" "build.sh.config" && \
perl -p -i -e "s/${default_name}/${project_name}/g" "${project_name}.tex" && \
perl -p -i -e "s/${default_name}/${project_name}/g" ".project" && \
perl -p -i -e "s/${default_name}/${project_name}/g" ".texlipse"
checkError $?

echo "Renaming special files..."
[ -f "src/${default_name}.tex" ] && mv "src/${default_name}.tex" "src/${project_name}.tex"
[ -f "${default_name}.acro.tex" ] && mv "${default_name}.acro.tex" "${project_name}.acro.tex"
[ -f "${default_name}.meta.tex" ] && mv "${default_name}.meta.tex" "${project_name}.meta.tex"
[ -f "${default_name}.acronyms.tex" ] && mv "${default_name}.acronyms.tex" "${project_name}.acronyms.tex"
[ -f "${default_name}.bib" ] && mv "${default_name}.bib" "${project_name}.bib"

echo "Creating new repository..."
svn import -m "new project '${project_name}' (1/2)" . "${url_vcs}/${project_name}" && \
svn co --force "${url_vcs}/${project_name}" .
checkError $?

echo "Checking out core library..."
svn propset svn:externals "${project_lib} ${url_lib}" . && \
svn propset svn:ignore "resources/images/example*.pdf" . && \
svn up
checkError $?

echo "Submitting changes..."
svn ci -m "new project '${project_name}' (2/2)"
checkError $?

echo "Creating PDF..."
make clean build

echo "Please create a new wiki page:"
echo "${url_wiki}/${project_name}${wiki_param}"
###############################################################################

exit 0
