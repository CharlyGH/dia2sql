#!/usr/bin/bash

 
#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"

XSLT_SCRIPT="${LIB_DIR}/${ME%.*}.xslt"
[[ ! -f "${XSLT_SCRIPT}" ]] && error_exit "xslt script ${XSLT_SCRIPT} does not exist" "" 1


USAGE="usage: ${ME} -i inputfile [-a] [-c] [-h] [-s] [-t] [-v]"
HELP="${USAGE}
    -a all          show levels schemas/tables/columns/domains/sequences
    -c column       show levels schema/table/column
    -h help         print this help text
    -i inputfile    filename
    -s schema       show level schema
    -t table        show levels schema/table
    -v verbose      show all execution steps
"

all=""
inputfile=""
klevel=""
verbose=""


while getopts "achi:stv" OPT
do
    case ${OPT} in
        a)
            level="all"
            ;;
        c)
            level="column"
            ;;
        h)
            echo "${HELP}"
            exit 0
            ;;
        i)
            inputfile="${OPTARG}"
            ;;
        s)
            level="schema"
            ;;
        t)
            level="table"
            ;;
        v)
            verbose="1"
            ;;
        *)
            error_exit "Invalid argument: ${OPTARG}" "" "1"
            ;;
    esac
done



[[ -z "${inputfile}" ]] && error_exit "missing -i inputfile argument" "${USAGE}" 1

[[ ! -f "${inputfile}" ]] && error_exit "input file ${inputfile} does not exist" "" 1

input="${inputfile}"
name="${input%.*}"
name="${name##*/}"


[[ -z "${level}" ]] && error_exit "missing -a, -c, -t or -s option" "${USAGE}" 1


xslt_params="--stringparam level ${level} --path ${DATA_DIR}"

[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XSLT_SCRIPT} ${input}"
xsltproc ${xslt_params} "${XSLT_SCRIPT}" "${input}"
ret="$?"

exit "${ret}"

