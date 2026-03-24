#!/usr/bin/bash

 
#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"


USAGE="usage: ${ME} -i inputfile [-a] [-c] [-h] [-k] [-v]"
HELP="${USAGE}
    -a auto          generate historization fields and tables in output file
    -c check         validate generated file
    -h help          print this help message
    -i inputfile     name of input file
    -k keep          keep tempfiles, dop not delete at end
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


DBM_2_XML="${LIB_DIR}/dbm_2_xml.xslt"
PROJECT_XML_2_DAT="${LIB_DIR}/project_dat.xslt"
XML_2_XML="${LIB_DIR}/xml_2_xml.xslt"
XSLT_CONFIG="${LIB_DIR}/create_config.xslt"

name="${inputfile%.*}"
name="${name##*/}"

[[ -z "${outputfile}" ]] && outputfile="${DATA_DIR}/${name}.xml"

tempprj="${FULL_DATA_DIR}/${name}.prj.xml"
tempout="${TEMP_DIR}/${name}.out.xml"
tempqt="${TEMP_DIR}/${name}.qt.xml"
temppd="${TEMP_DIR}/${name}.prj.dat"


[[ "${inputfile}" = "${outputfile}" ]] && error_exit "input file '${inputfile}' and output file are identical" "" 1

project="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p "dbmodel/database/@name")"

xslt_params="--stringparam project ${project}"
xslt_params="${xslt_params} --stringparam basename ${project}"
xslt_params="${xslt_params} --stringparam projectfile ${projectfile}"
xslt_params="${xslt_params} --path ${DTD_DIR}"


#[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${PROJECT_XML_2_DAT} ${PROJECT_FILE} ${temppd}"
#xsltproc ${xslt_params} "${PROJECT_XML_2_DAT}" "${PROJECT_FILE}" >"${temppd}"

#[[ -n "${verbose}" ]] && echo "${BIN_DIR}/create_config.sh ${verb_opt} -i ${tempout} -p ${projectfile} -o ${tempprj}"
#${BIN_DIR}/create_config.sh ${verb_opt} -i "${tempout}" -p "${projectfile}" -o "${tempprj}" 
#ret="$?"
#[[ "${ret}" != "0" ]] && error_exit "error in xslt script create_config.sh" "" "1"


[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XSLT_CONFIG} ${projectfile} ${tempprj}"
xsltproc ${xslt_params} "${XSLT_CONFIG}" "${projectfile}" >"${tempprj}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in script ${XSLT_CONFIG}" "" 1

xslt_params="${xslt_params} --stringparam configfile ${tempprj}"

[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${DBM_2_XML} ${inputfile} ${tempout}"
xsltproc ${xslt_params} "${DBM_2_XML}" "${inputfile}" > "${tempout}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in script " "${DBM_2_XML}" ${ret}


cat "${tempout}" | tr '"' "'"  > "${tempqt}"


xslt_params="--stringparam configfile ${tempprj}"
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
    for file in "${tempchk}" "${tempout}" \
                "${tempinfo}" "${tempqt}" "${tempprj}" "${tempchk}" \
                "${templld}" "${tempsi}"; do
        if [[ -f "${file}" ]] ; then
            [[ -n "${verbose}" ]] && echo "rm ${file}"
            rm "${file}"
        fi
    done
fi

    

#cat "${outputfile}"

exit "0"

