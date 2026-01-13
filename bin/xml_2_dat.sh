#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"
LINES="1"

USAGE="usage: ${ME} -i inputfile [-d database] [-u user] [-o outputfile] [-l lines] [-p projectfile] [-c] [-D] {-e|-g} [-h] [-k] [-r] [-v] [-y]"
HELP="${USAGE}
    -c check         check the xml file before generating sql code
    -d database      database, default is ${USER}
    -D delete        delete all existing rows with truncate table
    -e execute       execute generated sql script
    -g generate      generate sql scripts with insert statements
    -h help          print this help text
    -i inputfile     filename to process
    -k keep          keep, do not delete temp files
    -l lines         lines to insert, default is ${LINES}
    -o outputfile    output filename, default is input file name with xml replaced by sql or dat.sql
    -p projectfile   configuration file for historization, default is ${PROJECT_FILE}
    -u user          dabase user, default is ${USER}
    -v verbose       show all execution steps
    -y yes           answer yes to all questions
"

check=""
database=""
delete=""
execute=""
generate=""
inputfile=""
keep=""
lines="${LINES}"
output=""
projectfile="${FULL_PROJECT_FILE}"
user=""
verbose=""
yes=""

while getopts "cd:Deghi:kl:o:p:u:vy" OPT
do
    case ${OPT} in
        c)
            check="1"
            ;;
        d)
            database="${OPTARG}"
            ;;
        D)
            delete="1"
            ;;
        e)
            execute="1"
            ;;
        g)
            generate="1"
            ;;
        h)
            echo "${HELP}"
            exit 0
            ;;
        i)
            inputfile="${OPTARG}"
            ;;
        k)
            keep="1"
            ;;
        l)
            lines="${OPTARG}"
            ;;
        o)
            outputfile="${OPTARG}"
            ;;
        p)
            projectfile="${OPTARG}"
            ;;
        u)
            user="${OPTARG}"
            ;;
        v)
            verbose="1"
            verbose_option="-v"
            ;;
        y)
            yes="1"
            ;;
        *)
            error_exit "Invalid argument ${OPT}" "" "1"
            ;;
    esac
done


XML_2_SQL="${LIB_DIR}/xml_2_sql.xslt"
XML_2_FMT="${LIB_DIR}/xml_2_fmt.xslt"
XML_2_XML="${LIB_DIR}/xml_2_xml.xslt"
FMT_2_DAT="${LIB_DIR}/fmt_2_dat.awk"
FMT_2_CNT="${LIB_DIR}/fmt_2_cnt.awk"

[[ -z "${execute}${generate}" ]] && error_exit "missing -g and -e option" "${USAGE}" 1

[[ -z "${inputfile}" ]] && error_exit "missing -i inputfile option" "${USAGE}" 1
[[ ! -r "${inputfile}" ]] && error_exit "cannot read inputfile ${inputfile}" "${USAGE}" 1

#set -x

filetype=""
projectname="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p "/model/@project")"
[[ -z "${projectname}" ]] && error_exit "no project name in ${inputfile}"

name="${inputfile%.*}"
name="${name##*/}"

tempchk="${TEMP_DIR}/${name}.chk.dat"
tempfmt="${TEMP_DIR}/${name}.fmt.dat"
tempprj="${FULL_TEMP_DIR}/${name}.prj.xml"
tempsrt="${FULL_TEMP_DIR}/${name}.srt.xml"
tempcnts="${TEMP_DIR}/${name}.cnt.sql"

outputfile="${OUT_DIR}/${name}.dat.sql"

inputpath="${FULL_DATA_DIR}/${inputfile##*/}"
[[ ! -f "${inputfile}" ]] && error_exit "input file '${inputfile}' not found" "" 1

[[ -n "${verbose}" ]] && echo "${BIN_DIR}/create_config.sh ${verbose_option} -i ${inputfile} -p ${projectfile} -o ${tempprj}"
${BIN_DIR}/create_config.sh ${verbose_option} -i "${inputfile}" -p "${projectfile}" -o "${tempprj}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in xslt script create_config.sh" "" "1"


if [[ -n "${check}" ]] ; then
    ${BIN_DIR}/check_rules.sh ${verbose_option} -a -i "${inputfile}" -p "${tempprj}" -o "${tempchk}" 
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${CHECK_XSLT}" "" "1"
#    cat "${tempchk}"
fi

#set -x

if [[ -n "${generate}" ]] ; then

    xslt_params="--stringparam projectconfig ${tempprj}"
    [[ -n "${oldfile}" ]] && xslt_params="${xslt_params}  --stringparam oldfile ${oldfile}"
    [[ -n "${newfile}" ]] && xslt_params="${xslt_params}  --stringparam newfile ${newfile}"
    xslt_params="${xslt_params}  --path ${DTD_DIR}"
    # supply full path of xml file, see comment in stylesheet
    xslt_params="${xslt_params} --stringparam xmldoc ${inputpath}"
    xslt_params="${xslt_params} --stringparam tmpsrt ${tempsrt}"

    [[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_FMT} ${inputfile} ${tempfmt}"
    xsltproc ${xslt_params} "${XML_2_FMT}" "${inputfile}" > "${tempfmt}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${XML_2_AWK}" "" "${ret}"

    awk_params=""
    [[ -n "${verbose}" ]] && echo "awk -F'#' -f ${FMT_2_CNT}  ${awk_params} ${tempfmt}  ${tempcnts}"
    awk -F'#' -f "${FMT_2_CNT}" -v pass=insert ${awk_params} "${tempfmt}" >"${tempcnts}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in awk script ${FMT_2_CNT}" "" "${ret}"
    
    awk_params="-v lines=${lines}"
    [[ -n "${delete}" ]] && awk_params="${awk_params} -v truncate="${delete}""
    export LC_NUMERIC="C"
    if [[ -n "${delete}" ]] ; then
        [[ -n "${verbose}" ]] && echo "awk -F'#' -f ${FMT_2_DAT} -v pass=truncate ${awk_params} ${tempfmt}  ${outputfile}"
        awk -F'#' -f "${FMT_2_DAT}" -v pass=truncate ${awk_params} "${tempfmt}" >"${outputfile}"
    else
        echo -n "" >"${outputfile}"
    fi
    [[ -n "${verbose}" ]] && echo "awk -F'#' -f ${FMT_2_DAT} -v pass=insert ${awk_params} ${tempfmt}  ${outputfile}"
    awk -F'#' -f "${FMT_2_DAT}" -v pass=insert ${awk_params} "${tempfmt}" >>"${outputfile}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in awk script ${FMT_2_DAT}" "" "${ret}"
    unset LC_NUMERIC

    
    psql_options="-q -A -t"
    [[ -n "${database}" ]] && psql_options="${psql_options} -d ${database}"
    [[ -n "${user}" ]] && psql_options="${psql_options} -U ${user}"
fi
#set -x

if [[ -n "${execute}" ]] ; then
    result="$(psql -q -A -t -c "select dat.table_name from dba.all_tables dat where dat.schema_name like 'base_%' and  dat.table_name = 'metadata'")"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "Cannot access dba.all_tables" "Is dba.sql installed?" "${ret}"

    db_version=""

    project="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p /model/@project)"
    if [[ -n "${project}" ]] ; then
        version="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p /model/@version)"
        [[ -z "${version}" ]] && error_exit "no version found for project ${project} in ${inputfile}" "" 1
 
        if [[ -z "${result}" ]] ; then
            echo "Cannot find base_${project}, assuming no version of ${project} installed"
        else
            db_version="$(psql ${psql_options} -c "select version from base_${project}.metadata;")"
        fi

        [[ "${db_version}" != "${version}" ]] && error_exit "DB version [${db_version}] does not match script version [${version}]" "" 1

        lines="$(psql ${psql_options} -f ${tempcnts})"
        
        if [[ "${lines}" != "0" ]] ;then
            echo "Warning: database contains a total of [${lines}] lines"
        fi
    else
        error_exit "no project found in file ${inputfile}" "" 1
    fi
fi

#set -x

if [[ -n "${yes}" ]] ; then
    [[ -n "${verbose}" ]] && echo "psql ${psql_options} -f ${outputfile}"
    psql ${psql_options} -f "${outputfile}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in sql script ${outputfile}" "" "${ret}"
fi



if [[ -z "${keep}" ]] ; then
    for file in "${tempchk}" "${tempfmt}" "${tempprj}" "${tempsrt}" "${tempcnts}"; do
        [[ -n "${verbose}" ]] && echo "rm ${file}"
        [[ -f "${file}" ]] && rm "${file}"
    done
fi

exit 0
