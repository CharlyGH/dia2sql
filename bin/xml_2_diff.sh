#!/usr/bin/bash


#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"

USAGE="usage: ${ME} -i oldinputfile,newinputfile [-o outputfile] [-c] [-v]"
HELP="${USAGE}
    -c check             check syntax of output file
    -h help              print this help message
    -i oldfile,newfile   names of input files, old file name and new file name separated with ,
    -o outfile           name of output file, default is ....
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
[[ "${oldinputfile}" == "${newinputfile}" ]] && error_exit "invalid -i inputfiles option" "${USAGE}" 1

[[ ! -r "${oldinputfile}" ]] && error_exit "cannot read old input file ${oldinputfile}" "" 1
[[ ! -r "${newinputfile}" ]] && error_exit "cannot read new input file ${newinputfile}" "" 1


DIFF_FILE_NAME="${LIB_DIR}/diff_file_name.awk"

if [[ -z "${outputfile}" ]] ; then
    outputfile="$(echo "${oldinputfile%.*}#${newinputfile%.*}" | awk -F'#' -f "${DIFF_FILE_NAME}" ).xml"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in script ${DIFF_FILE_NAME}" "" 1
fi


XML_2_DIFF="${LIB_DIR}/xml_2_diff.xslt"

EMPTY_DELTA="${DATA_DIR}/delta.xml"

xslt_params=""
xslt_params="${xslt_params} --stringparam oldfile ${oldinputfile}"
xslt_params="${xslt_params} --stringparam newfile ${newinputfile}"


[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_DIFF} ${EMPTY_DELTA} ${outputfile}"
xsltproc ${xslt_params} "${XML_2_DIFF}" "${EMPTY_DELTA}" > "${outputfile}"
ret="$?"
[[ "${ret}" != "0" ]] && echo "error in script ${XML_2_DIFF}" && exit "${ret}"

#set -x
if [[ -n "${check}" ]] ; then
    [[ -n "${verbose}" ]] && echo "xmllint --valid --noout ${outputfile}"
    xmllint --valid --noout "${outputfile}"
    ret="$?"
fi


[[ "${ret}" != "0" ]] && error_exit "syntax error in generated xml file ${output}" "" "${ret}"

#cat "${output}"

exit "0"
