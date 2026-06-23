#!/usr/bin/bash


#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"

USAGE="usage: ${ME} -i inputfile -o outputfile [-p projectconfig] [-c] [-h] [-k] [-t] [-v]"
HELP="${USAGE}
    -h help         print this help message
    -i inputfile    name of input file
    -k keep         keep tempfiles, do not delete at end
    -o outputfile   name of output file
    -p configfile   name of the config file
    -v verbose      list all steps of execution
"

inputfile=""
keep=""
outputfile=""
projectconfig="${FULL_PROJECT_FILE}"
verbose=""


while getopts "chi:ko:p:tv" OPT
do
    case ${OPT} in
        h)
            echo "${HELP}"
            exit 0;
            ;;
        i)
            inputfile="${OPTARG}"
            ;;
        k)
            keep="1"
            ;;
        o)
            outputfile="${OPTARG}"
            ;;
        p)
            projectconfig="${OPTARG}"
            ;;
        v)
            verbose="1"
            ;;
        *)
            error_exit "Invalid argument: ${OPTARG}" "" 1
            ;;
    esac
done

[[ -z "${inputfile}" ]] && error_exit "missing -i inputfile option" "${USAGE}"  1
[[ -z "${outputfile}" ]] && error_exit "missing -o outputfile option" "${USAGE}"  1
[[ -z "${config-file}" ]] && error_exit "missing -p projectconfig option" "${USAGE}"  1



[[ ! -f "${inputfile}" ]] && error_exit "input file ${file} does not exist" "" 1

name="${inputfile%.*}"
name="${name##*/}"

CHECK_XSLT="${LIB_DIR}/${ME%.sh}.xslt"

xmllint_params="--valid --noout --path ${DTD_DIR}"
[[ -n "${verbose}"  ]] && echo "xmllint ${xmllint_params} ${inputfile}"
xmllint ${xmllint_params} "${inputfile}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "schema validation failed" "" 1

xslt_params="--path ${DTD_DIR} --stringparam config-file ${projectconfig}"
[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${CHECK_XSLT} ${inputfile} ${outputfile}"
xsltproc ${xslt_params} "${CHECK_XSLT}" "${inputfile}" > "${outputfile}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in xslt script ${CHECK_XSLT} applied to ${inputfile}" "" "1"

found="$(grep ':ERROR:' "${outputfile}")"
[[ -n "${found}" ]] && error_exit "error(s) in xslt script ${CHECK_XSLT} applied to ${inputfile}" "" "1"


#cat "${outputfile}"
exit "0"
