#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"


USAGE="usage: ${ME} -i inputfile -p path [-h] [-v]"
HELP="${USAGE}
    -h help         print this help message
    -i inputfile    the xml file to read
    -p path         the path to find in file
    -v verbose      show all execution steps
"


inputfile=""
path=""
verbose=""


while getopts "hi:p:r" OPT
do
    case ${OPT} in
        h)
            echo "${HELP}"
            exit 0
            ;;
        i)
            inputfile="${OPTARG}"
            ;;
        p)
            path="${OPTARG}"
            ;;
        *)
            error_exit "Invalid argument: ${OPTARG}" "" "1"
            ;;
    esac
done

[[ -z "${inputfile}" ]] && error_exit "missing -i option" "${USAGE}" 1
[[ -z "${path}" ]] && error_exit "missing -p option" "${USAGE}" 1

[[ ! -f "${inputfile}" ]] && error_exit "cannot open input file ${inputfile}" "" 1


XSLT_SCRIPT="${LIB_DIR}/${ME%.*}.xslt"

[[ ! -f "${XSLT_SCRIPT}" ]] && error_exit "cannot open script file ${XSLT_SCRIPT}" "" 1

xsltproc --path "${DATA_DIR}" --stringparam path "${path}" "${XSLT_SCRIPT}" "${inputfile}"
ret="$?"

[[ "${ret}" != "0" ]] && error_exit "error in script ${XSLT_SCRIPT} applied to file ${inputfile}" "" 1

exit 0
