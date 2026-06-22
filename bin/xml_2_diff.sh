#!/usr/bin/bash

function create_diff_name() {

    local oldname="$1"
    local newname="$2"
    local olddir="${oldname%/*}"
    local newdir="${newname%/*}"
    [[ "${olddir}" != "${newdir}" ]] && echo "directory name missmatch: ${olddir} != ${newdir}" && return 1
    oldname="${oldname##*/}"
    newname="${newname##*/}"
    local oldprefix="${oldname%_*}"
    local newprefix="${newname%_*}"
    [[ "${oldprefix}" != "${newprefix}" ]] && echo "file name prefix missmatch: ${oldprefix} != ${newprefix}" && return 1
    local oldsuffix="${oldname##*_}"
    local newsuffix="${newname##*_}"
    local oldext="${oldsuffix#*.}"
    local newext="${newsuffix#*.}"
    [[ "${oldext}" != "${newext}" ]] && echo "file name extension missmatch: ${oldext} != ${newext}" && return 1
    local oldsuffix="${oldsuffix%.*}"
    local newsuffix="${newsuffix%.*}"
    [[ "${oldsuffix}" == "${newsuffix}" ]] && echo "file name suffix match: ${oldsuffix} == ${newsuffix}" && return 1
    echo "${olddir}/${oldprefix}_${oldsuffix}_${newsuffix}.${oldext}"

    return 0
}




#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"

USAGE="usage: ${ME} -i oldinputfile,newinputfile [-o outputfile] [-c] [-v]"
HELP="${USAGE}
    -c check             check syntax of output file
    -h help              print this help message
    -i oldfile,newfile   names of input files, old file name and new file name separated with ,
    -o outfile           name of output file, default is project_old_new.xml
    -p projectfile       configuration file for historization, default is ${PROJECT_FILE}
    -v verbose           show all steps of execution
"

check=""
inputfiles=""
outputfile=""
projectfile="${PROJECT_FILE}"
relative=""
verbose=""

while getopts "chi:o:p:rv" OPT
do
    case ${OPT} in
        c)
            check="1"
            ;;
        h)
            echo "${HELP}"
            exit 0
            ;;
        i)
            inputfiles="${OPTARG}"
            ;;
        o)
            outputfile="${OPTARG}"
            ;;
        p)
            projectfile="${OPTARG}"
            ;;
        v)
            verbose="1"
            ;;
        *)
            error_exit "Invalid argument ${OPT}" "" 1
            ;;
    esac
done


[[ -z "${inputfiles}" ]] && error_exit "missing -i inputfiles option" "${USAGE}" 1
oldinputfile="${ROOT_DIR}/${inputfiles%,*}"
newinputfile="${ROOT_DIR}/${inputfiles#*,}"
[[ "${oldinputfile}" == "${newinputfile}" ]] && error_exit "duplicate -i inputfiles option" "${USAGE}" 1


outputfile=$(create_diff_name "${oldinputfile}" "${newinputfile}")
ret="$?"

[[ "${ret}" != "0" ]] && error_exit "error in create_diff_name" "${outputfile}" ${ret}


[[ ! -r "${oldinputfile}" ]] && error_exit "cannot read old input file ${oldinputfile}" "" 1
[[ ! -r "${newinputfile}" ]] && error_exit "cannot read new input file ${newinputfile}" "" 1


XML_2_DIFF="${LIB_DIR}/xml_2_diff.xslt"

EMPTY_DELTA="${XML_DIR}/delta.xml"

xslt_params=""
xslt_params="${xslt_params} --stringparam old-file ${oldinputfile}"
xslt_params="${xslt_params} --stringparam new-file ${newinputfile}"
xslt_params="${xslt_params} --path ${DTD_DIR}"


[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} --output ${outputfile}" ${XML_2_DIFF} ${EMPTY_DELTA} 
xsltproc ${xslt_params} --output "${outputfile}" "${XML_2_DIFF}" "${EMPTY_DELTA}"
ret="$?"
[[ "${ret}" != "0" ]] && echo "error in script ${XML_2_DIFF}" && exit "${ret}"

#set -x
if [[ -n "${check}" ]] ; then
    [[ -n "${verbose}" ]] && echo "xmllint --valid --noout --path ${DTD_DIR} ${outputfile}"
    xmllint --valid --noout --path "${DTD_DIR}" "${outputfile}"
    ret="$?"
fi
[[ "${ret}" != "0" ]] && error_exit "syntax error in generated xml file ${outputfile}" "" "${ret}"


set_info  "${outputfile}" "delta" "filetype" "project" "old_version" "new_version"
echo "migrate version ${old_version} to ${new_version}"


#cat "${output}"

exit "0"
