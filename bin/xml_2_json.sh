#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"


USAGE="usage: ${ME}  -i inputfile [-o outputfile] [-c] [-k] [-v]"
HELP="${USAGE}
    -c check         check json syntax of output file
    -i inputfile     name of input file
    -k keep          keep, do not delete temp files
    -o outputfile    name of output file, default is inputfile with xml replaced by json
    -p projectfile   configuration file for historization, default is ${PROJECT_FILE}
    -v verbose       show all steps of execution
"

check=""
inputfile=""
keep=""
outputfile=""
projectfile="${FULL_PROJECT_FILE}"
verbose=""

while getopts "chi:o:p:v" OPT
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
            verbose_option="-v"
            ;;
        *)
            error_exit "Invalid argument ${arg}::${OPTARG}" "" 1
            ;;
    esac
done

[[ -z "${inputfile}" ]] && error_exit "missing -i inputfile option" "${USAGE}" 1


XML_2_JSON="${LIB_DIR}/xml_2_json.xslt"

#set -x


input="${inputfile}"
name="${input%.*}"
name="${name##*/}"

[[ -z "${outputfile}" ]] && outputfile="${OUT_DIR}/${name}.json"

[[ "${inputfile}" = "${outputfile}" ]] && error_exit "input file '${inputfile}' and output file are identical" ""  1
[[ ! -f "${inputfile}" ]] && error_exit "input file '${inputfile}' not found"  ""  1

tempprj="${FULL_TEMP_DIR}/${name}.prj.xml"

[[ -n "${verbose}" ]] && echo "${BIN_DIR}/create_config.sh ${verbose_option} -i ${inputfile} -p ${projectfile} -o ${tempprj}"
${BIN_DIR}/create_config.sh ${verbose_option} -i "${inputfile}" -p "${projectfile}" -o "${tempprj}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in xslt script create_config.sh" "" 1



xslt_params="--path ${DTD_DIR}"
xslt_params="${xslt_params} --stringparam configfile ${tempprj}"

[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_JSON} ${inputfile} ${outputfile}"
xsltproc ${xslt_params} "${XML_2_JSON}" "${inputfile}" > "${outputfile}"
ret="$?"
[[ "${ret}" != "0" ]] && echo "error in script ${XML_2_JSON}" && exit "${ret}"

#set -x
if [[ -n "${check}" ]] ; then
    [[ -n "${verbose}" ]] && echo "jq ${outputfile}"
    cat "${outputfile}" | jq . >/dev/null
    ret="$?"
fi


[[ "${ret}" != "0" ]] && error_exit "syntax error in generated json file ${outputfile}" "" "${ret}"

#cat "${output}"

if [[ -z "${keep}" ]] ; then
    [[ -f "${tempprj}" ]] && rm "${tempprj}"
fi


exit "0"
