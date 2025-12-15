#!/usr/bin/bash


#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"

USAGE="usage: ${ME} -i inputfile -o outputfile -p projectconfig [-a] [-c] [-k] [-t] [-v]"
HELP="${USAGE}
    -a auto         generate historization fields and tables in output file
    -i inputfile    name of input file, default is basename.dia in ${DATA_DIR}
    -k keep         keep tempfiles, dop not delete at end
    -o outputfile   name of output file, default is <<inputfile>>.chk
    -v verbose      list all steps of execution
"

auto=""
inputfile=""
keep=""
outputfile=""
projectconfig=""
verbose=""


while getopts "achi:ko:p:tv" OPT
do
    case ${OPT} in
        a)
            auto="1"
            ;;
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
[[ -z "${projectconfig}" ]] && error_exit "missing -p projectconfig option" "${USAGE}"  1



[[ ! -f "${inputfile}" ]] && error_exit "input file ${file} does not exist" "" 1

name="${inputfile%.*}"
name="${name##*/}"

CHECK_XSLT="${LIB_DIR}/${ME%.sh}.xslt"

xmllint_params="--valid --noout --path ${DTD_DIR}"
[[ -n "${verbose}"  ]] && echo "xmllint ${xmllint_params} ${inputfile}"
xmllint ${xmllint_params} "${inputfile}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "schema validation failed" "" 1

historisation="false"
[[ -n "${auto}" ]] && historisation="true"

xslt_params="--path ${DTD_DIR} --stringparam projectconfig ${projectconfig}"
xslt_params="${xslt_params} --stringparam historisation ${historisation}"
[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${CHECK_XSLT} ${inputfile} ${outputfile}"
xsltproc ${xslt_params} "${CHECK_XSLT}" "${inputfile}" > "${outputfile}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in xslt script ${CHECK_XSLT} applied to ${inputfile}" "" "1"

found="$(grep ':ERROR:' "${outputfile}")"
[[ -n "${found}" ]] && error_exit "error(s) in xslt script ${CHECK_XSLT} applied to ${inputfile}" "" "1"


#cat "${outputfile}"
exit "0"
