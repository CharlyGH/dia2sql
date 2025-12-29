#!/usr/bin/bash

 
#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"


USAGE="usage: ${ME} -i inputfile [-a] [-c] [-k] [-t] [-v]"
HELP="${USAGE}
    -a auto         generate historization fields and tables in output file
    -c check        validate generated file
    -i inputfile    name of input file
    -k keep         keep tempfiles, dop not delete at end
    -o outputfile   name of output file, default: inputfile with dia replaced by xml
    -t trigger      generate sql-code in trigger-definition
    -v verbose      list all steps of execution
"

auto=""
check=""
inputfile=""
keep=""
outputfile=""
rela_opt=""
trigger="xml"
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
        t)
            trigger="sql"
            ;;
        v)
            verbose="1"
            verb_opt="-v"
            ;;
        *)
            error_exit "Invalid argument ${arg}::${OPTARG}" "" 1
            ;;
    esac
done

[[ -z "${inputfile}" ]] && error_exit "missing input file" "${USAGE}"  1
[[ ! -r "${inputfile}" ]] && error_exit "cannot open input file ${inputfile}" ""  1


DIA_2_STR_DAT="${LIB_DIR}/dia_2_str_dat.xslt"
DAT_2_XML="${LIB_DIR}/dat_2_xml.awk"
DAT_2_SRT="${LIB_DIR}/sort_dia_str_dat.awk"
PROJECT_XML_2_DAT="${LIB_DIR}/project_dat.xslt"
XML_2_XML="${LIB_DIR}/xml_2_xml.xslt"

name="${inputfile%.*}"
name="${name##*/}"

[[ -z "${outputfile}" ]] && outputfile="${DATA_DIR}/${name}.xml"


tempsd="${TEMP_DIR}/${name}.str.dat"
tempss="${TEMP_DIR}/${name}.str.srt"
temppd="${TEMP_DIR}/${name}.prj.dat"
tempprj="${FULL_DATA_DIR}/${name}.prj.xml"
tempchk="${TEMP_DIR}/${name}.chk.dat"
tempout="${TEMP_DIR}/${name}.out.xml"
tempqt="${TEMP_DIR}/${name}.qt.xml"
tempchk="${TEMP_DIR}/${name}.chk.dat"

[[ "${inputfile}" = "${outputfile}" ]] && error_exit "input file '${inputfile}' and output file are identical" "" 1

xslt_params="--stringparam projectfile ${PROJECT_FILE}"
xslt_params="${xslt_params} --path ${DTD_DIR}"
[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${DIA_2_STR_DAT} ${inputfile} ${tempsd}"
xsltproc ${xslt_params} "${DIA_2_STR_DAT}" "${inputfile}" > "${tempsd}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in script " "${DIA_2_STR_DAT}" ${ret}

[[ -n "${verbose}" ]] && echo "awk -F'#' -f ${DAT_2_SRT} ${tempsd} ${tempss}"
awk -F'#' -f "${DAT_2_SRT}" "${tempsd}" >"${tempss}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in script " "${DAT_2_SRT}" ${ret}

basename="$(grep '^projekt#' "${tempss}" | cut -d'#' -f2 | tr '[:upper:]' '[:lower:]')"
gen="$(grep '^version#' "${tempss}" | cut -d'#' -f2)"

xslt_params="--stringparam basename ${basename}"
xslt_params="${xslt_params} --stringparam projectfile ${FULL_PROJECT_FILE}"
xslt_params="${xslt_params} --path ${DTD_DIR}"


[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${PROJECT_XML_2_DAT} ${PROJECT_FILE} ${temppd}"
xsltproc ${xslt_params} "${PROJECT_XML_2_DAT}" "${PROJECT_FILE}" >"${temppd}"


[[ -n "${verbose}" ]] && echo "awk -F'#' -f ${DAT_2_XML} ${temppd} ${tempss} ${tempout}"
awk -F'#' -f "${DAT_2_XML}" "${temppd}" "${tempss}" >"${tempout}"

if [[ -n "${check}" ]] ; then

    [[ -n "${verbose}" ]] && echo "${BIN_DIR}/create_config.sh ${verb_opt} -i ${tempout} -p ${projectfile} -o ${tempprj}"
    ${BIN_DIR}/create_config.sh ${verb_opt} -i "${tempout}" -p "${projectfile}" -o "${tempprj}" 
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script create_config.sh" "" "1"

    [[ -n "${verbose}" ]] && echo "${BIN_DIR}/check_rules.sh ${verb_opt} -i ${tempout} -o ${tempchk} -p ${tempprj}" 
    ${BIN_DIR}/check_rules.sh ${verb_opt} -i "${tempout}" -o "${tempchk}" -p "${tempprj}" 
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in script check_rules.sh" "" 1
fi

xslt_params="--stringparam projectconfig ${tempprj}"
xslt_params="${xslt_params} --stringparam trigger ${trigger}"
xslt_params="${xslt_params} --path ${DTD_DIR}"


if [[ -n "${auto}" ]] ; then
    [[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_XML} ${tempout} ${tempqt}"
    xsltproc ${xslt_params} "${XML_2_XML}" "${tempout}" > "${tempqt}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${XML_2_XML}" "" "${ret}"

    [[ -n "${verbose}" ]] && echo "cat ${tempqt} ${outputfile}"
    cat "${tempqt}" | tr '"' "'"  > "${outputfile}"
    done="1"
    if [[ -n "${check}" ]] ; then
        [[ -n "${verbose}" ]] && echo "${BIN_DIR}/check_rules.sh ${verb_opt} -a -i ${outputfile} -o ${tempchk} -p ${tempprj}" 
        "${BIN_DIR}/check_rules.sh" ${verb_opt} -a -i "${outputfile}" -o "${tempchk}" -p "${tempprj}" 
        ret="$?"
        [[ "${ret}" != "0" ]] && error_exit "error in script check_rules.sh" "" 1
    fi
else
    [[ -n "${verbose}" ]] && echo "cp ${tempout} ${outputfile}"
    cp "${tempout}" "${outputfile}" 
fi


if [[ -z "${keep}" ]] ; then
    for file in "${tempsd}" "${tempss}" "${temppd}" "${tempchk}" "${tempout}" \
                            "${tempinfo}" "${tempqt}" "${tempprj}" "${tempchk}"  ; do
        [[ -f "${file}" ]] && rm "${file}"
    done
fi

    

#cat "${outputfile}"

exit "0"

