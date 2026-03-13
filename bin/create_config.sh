#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"
LINES="1"
XSLT_SCRIPT="${LIB_DIR}/${ME%.*}.xslt"

USAGE="usage: ${ME} -i inputfile [-p projectfile] [-o outputfile] [-h] [-v] "
HELP="${USAGE}
    -h help          print this help text
    -i inputfile     name of the inputfile
    -o outputfile    name of output file
    -p projectfile   configuration file for historization, default is ${PROJECT_FILE}
    -v verbose       show all execution steps
"

inputfile=""
projectfile=""
outputfile=""


while getopts hi:o:p:rv OPT
do
    case ${OPT} in
        h)
            echo "${HELP}"
            exit 0
            ;;
        i)
            inputfile="${OPTARG}"
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
            error_exit "Invalid argument ${arg}::${OPTARG}" "" 1
            ;;
    esac
done

[[ -z "${inputfile}" ]] && error_exit "missing -i inputfile option"  "${USAGE}" 1
[[ ! -r "${inputfile}" ]] && error_exit "cannot open inputfile ${inputfile}"  "" 1


[[ -z "${projectfile}" ]] && projectfile="${XML_DIR}/project.xml"
[[ ! -r "${projectfile}" ]] && error_exit "cannot open projectfile ${projectfile}"  "" 1

temp="${inputfile##*/}"
temp="${temp%.*}"
[[ -z "${outputfile}" ]] && outputfile="${TEMP_DIR}/${temp}.prj.xml"

basename="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p "/model/@project")"
[[ -z "${basename}" ]] && basename="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p "/delta/@project")"
[[ -z "${basename}" ]] && error_exit "no project name in ${inputfile}"

xslt_params="--stringparam basename ${basename}" 
xslt_params="${xslt_params} --path ${DTD_DIR}"

[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XSLT_SCRIPT} ${projectfile} ${outputfile}"
xsltproc ${xslt_params} "${XSLT_SCRIPT}" "${projectfile}" >"${outputfile}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in script ${XSLT_SCRIPT}" "" 1


exit "${ret}"


