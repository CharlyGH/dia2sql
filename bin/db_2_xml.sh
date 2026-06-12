#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"


USAGE="usage: ${ME} -p project [-d database] [-u user] [-o outputfile] [-h] [-k] [-r] [-v]"
HELP="$USAGE
    -c check       validate generated file
    -d database    database, default is project
    -h help        print this help message
    -k keep        keep, do not delete temp files
    -o outputfile  then name of the output file
    -p project     the name of the project
    -u user        dabase user, default is ${USER}
    -v verbose     verbose output, show all executed steps
"

check=""
database=""
keep=""
outputfile=""
project=""
user=""
verbose=""


while getopts "cd:hko:p:rtu:v" OPT
do
    case ${OPT} in
        c)
            check="1"
            ;;
        d)
            database="${OPTARG}"
            ;;
        h)
            echo "${HELP}"
            exit 0
            ;;
        k)
            keep="1"
            ;;
        o)
            outputfile="${OPTARG}"
            ;;
        p)
            project="${OPTARG}"
            ;;
        u)
            user="${OPTARG}"
            ;;
        v)
            verbose="1"
            ;;
        *)
            error_exit "Invalid argument ${OPT}" "" 1
            ;;
  esac
done

[[ -z "${project}" ]] && error_exit "missing -p project option" "" 1
[[ -z "${database}" ]] && database="${project}"

SQL="select concat('v', trim(to_char(m.version,'00')), ':', m.project) line  from base_verein.metadata m;"
[[ -n "${verbose}" ]] && echo "psql -A -t -d ${database} -c ${SQL}"
info="$(psql -A -t -d "${database}" -c "${SQL}")"

version="${info%:*}"
project="${info#*:}"



project_config_file="${FULL_XML_DIR}/project.xml"

tempsql="${TEMP_DIR}/${project}_${version}.tmp.sql"
tempxml="${TEMP_DIR}/${project}_${version}.tmp.xml"
tempqt="${TEMP_DIR}/${project}_${version}.dqt.xml"
[[ -z "${outputfile}" ]] && outputfile="${DATA_DIR}/${project}_db_${version}.xml"

DB_2_SQL="${LIB_DIR}/db_2_sql.xslt"
TMP_2_XML="${LIB_DIR}/db_tmp_2_xml.xslt"

xmllint_params="--path ${DTD_DIR}"
xslt_params="--path ${DTD_DIR}"
xslt_params="${xslt_params} --stringparam project ${project}"
xslt_params="${xslt_params} --stringparam config-file ${project_config_file}"

[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} --output ${tempsql} ${DB_2_SQL} ${XML_DIR}/empty.xml"
xsltproc ${xslt_params} --output "${tempsql}" "${DB_2_SQL}" "${XML_DIR}/empty.xml"
ret="$?"
[[ "${ret}" != "0" ]] && echo "error in script ${DB_2_SQL}" && exit 1

[[ -n "${verbose}" ]] && echo "psql -A -t -d ${project} -f ${tempsql} -o ${tempxml}"
psql -A -t -d "${database}" -f "${tempsql}" -o "${tempxml}"
ret="$?"
[[ "${ret}" != "0" ]] && echo "error in script ${tempsql}" && exit 1

if [[ -n "${check}" ]] ; then
    [[ -n "${verbose}" ]] && echo "xmllint ${xmllint_params} --valid --noout ${tempxml}"
    xmllint ${xmllint_params} --valid --noout "${tempxml}"
fi

[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} --output ${tempqt} ${TMP_2_XML} ${tempxml}"
xsltproc ${xslt_params} --output "${tempqt}" "${TMP_2_XML}" "${tempxml}"
ret="$?"
[[ "${ret}" != "0" ]] && echo "error in script ${TMP_2_XML}" && exit

[[ -n "${verbose}" ]] && echo "cat ${tempqt} | tr ' \" > ${outputfile}"
cat "${tempqt}" | tr '"' "'" > "${outputfile}"
    
if [[ -n "${check}" ]] ; then
    [[ -n "${verbose}" ]] && echo "xmllint ${xmllint_params} --valid --noout ${outputfile}"
    xmllint ${xmllint_params} --valid --noout "${outputfile}"
fi


if [[ -z "${keep}" ]] ; then
    for file in "${tempsql}" "${tempxml}" "${tempqt}"; do
        [[ -f "${file}" ]] && rm "${file}"
    done
fi


#cat "${output}"



