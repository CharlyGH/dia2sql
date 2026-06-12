#!/usr/bin/bash

 
#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"


USAGE="usage: ${ME} -i inputfile [-a] [-c] [-h] [-k] [-v]"
HELP="${USAGE}
    -a auto          generate historization fields and tables in output file
    -c check         validate generated file
    -h help          print this help text
    -i inputfile     name of input file
    -k keep          keep tempfiles, do not delete at end
    -o outputfile    name of output file, default: inputfile with dia replaced by xml
    -v verbose       list all steps of execution
"

auto=""
check=""
inputfile=""
keep=""
outputfile=""
projectfile="${FULL_PROJECT_FILE}"
verbose=""
verb_opt=""

while getopts "achi:ko:tv" OPT
do
    case ${OPT} in
        a)
            auto="1"
            ;;
        c)
            check="1"
            ;;
        g)
            gen="${OPTARG}"
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
        v)
            verbose="1"
            verb_opt="-v"
            ;;
        *)
            error_exit "Invalid argument ${OPT}" "" 1
            ;;
    esac
done

[[ -z "${inputfile}" ]] && error_exit "missing input file" "${USAGE}"  1
[[ ! -r "${inputfile}" ]] && error_exit "cannot open input file ${inputfile}" ""  1


DIA_2_TMP="${LIB_DIR}/dia_2_tmp.xslt"
TMP_2_XML="${LIB_DIR}/tmp_2_xml.xslt"
CHECK_TMP="${LIB_DIR}/check_tmp.xslt"
XML_2_XML="${LIB_DIR}/xml_2_xml.xslt"


name="${inputfile%.*}"
name="${name##*/}"

[[ -z "${outputfile}" ]] && outputfile="${DATA_DIR}/${name}.xml"

tempxml="${TEMP_DIR}/${name}.tmp.xml"
tempqt="${TEMP_DIR}/${name}.qt.xml"
tempsrt="${FULL_TEMP_DIR}/${name}.srt.xml"
tempchk="${TEMP_DIR}/${name}.chk"
tempout="${TEMP_DIR}/${name}.xml"

[[ "${inputfile}" = "${outputfile}" ]] && error_exit "input file '${inputfile}' and output file are identical" "" 1


xslt_params="--path ${DTD_DIR}"
xslt_params="${xslt_params} --stringparam config-file ${FULL_PROJECT_FILE}"

[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${DIA_2_TMP} ${inputfile} ${tempxml}"
xsltproc ${xslt_params} "${DIA_2_TMP}" "${inputfile}" > "${tempxml}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in script ${DIA_2_TMP}" "" "${ret}"
#cat "${tempxml}"


if [[ -n "${check}" ]] ; then
    [[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} --output ${tempchk} ${CHECK_TMP} ${tempxml}"
    xsltproc ${xslt_params} --output "${tempchk}" "${CHECK_TMP}" "${tempxml}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in script ${CHECK_TMP}" "" "${ret}"
    [[ -n "${verbose}" ]] && cat "${tempchk}"
fi



xslt_params="${xslt_params} --stringparam sort-file ${tempsrt}"
[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} --output ${tempqt} ${TMP_2_XML} ${tempxml}"
xsltproc ${xslt_params} --output "${tempqt}" "${TMP_2_XML}" "${tempxml}"
ret="$?"
#[[ "${ret}" == "0" ]] && cat "${tempqt}"

cat "${tempqt}" | tr '"' "'" > "${tempout}"



if [[ -n "${auto}" ]] ; then
    [[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} --output ${tempqt}" ${XML_2_XML} ${tempout} 
    xsltproc ${xslt_params} --output "${tempqt}" "${XML_2_XML}" "${tempout}" 
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${XML_2_XML}" "" "${ret}"

    [[ -n "${verbose}" ]] && echo "cat ${tempqt} ${outputfile}"
    cat "${tempqt}" | tr '"' "'"  > "${outputfile}"
    done="1"
else
    [[ -n "${verbose}" ]] && echo "cp ${tempout} ${outputfile}"
    cp "${tempout}" "${outputfile}" 
fi

if [[ -z "${keep}" ]] ; then
    for file in "${tempxml}" "${tempqt}" "${tempchk}" "${tempout}" "${tempsrt}" ; do
        if [[ -f "${file}" ]] ; then
            [[ -n "${verbose}" ]] && echo "rm ${file}"
            rm "${file}"
        fi
    done
fi

    

#cat "${outputfile}"

exit "0"

