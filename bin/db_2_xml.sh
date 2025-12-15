#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"


USAGE="usage: ${ME} -p project [-d database] [-u user] [-o outputfile] [-h] [-k] [-r] [-t] [-v]"
HELP="$USAGE
    -c check       validate generated file
    -d database    database, default is ${USER}
    -h help        print this help message
    -k keep        keep, do not delete temp files
    -o outputfile  then name of the output file
    -p project     the name of the project
    -t trigger     parse trigger function
    -u user        dabase user, default is ${USER}
    -v verbose     verbose output, show all executed steps
"

check=""
database=""
keep=""
outputfile=""
project=""
trigger=""
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
        t)
            trigger="1"
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



DB_2_REF="${LIB_DIR}/db_2_ref.tpl"
DB_2_STR="${LIB_DIR}/db_2_str.tpl"
DB_2_DOM="${LIB_DIR}/db_2_dom.tpl"
DB_2_FK="${LIB_DIR}/db_2_fk.tpl"
DB_2_MD="${LIB_DIR}/db_2_md.tpl"

DB_DAT_2_XML="${LIB_DIR}/db_dat_2_xml.awk"

PROJECT_XML="${XML_DIR}/project.xml"
PROJECT_XML_2_DAT="${LIB_DIR}/project.xslt"

XML_2_DAT="${LIB_DIR}/project.xslt"




temprs="${TEMP_DIR}/${project}.ref.sql"
temprd="${TEMP_DIR}/${project}.ref.dat"

tempss="${TEMP_DIR}/${project}.str.sql"
tempst="${TEMP_DIR}/${project}.str.tmp"
tempsd="${TEMP_DIR}/${project}.str.dat"

tempds="${TEMP_DIR}/${project}.dom.sql"
tempdd="${TEMP_DIR}/${project}.dom.dat"

tempfs="${TEMP_DIR}/${project}.fk.sql"
tempfd="${TEMP_DIR}/${project}.fk.dat"

temppd="${TEMP_DIR}/${project}.prj.dat"

tempms="${TEMP_DIR}/${project}.md.sql"
tempmd="${TEMP_DIR}/${project}.md.dat"

xslt_params="--stringparam basename ${project}"

[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${PROJECT_XML_2_DAT} ${PROJECT_XML} ${temppd}"
xsltproc ${xslt_params} "${PROJECT_XML_2_DAT}" "${PROJECT_XML}" >"${temppd}"


schemas="$(cat "${temppd}" \
               | grep '^schemaconf#' \
               | cut -d'#' -f3 \
               | sed -e "s/^/'/" -e "s/$/',/" \
               | tr -d '\n' \
               | sed -e "s/,$//" )"

[[ -n "${verbose}" ]] && echo "schemas=[${schemas}]"


base="$(cat ${temppd} | grep '#base#' | cut -d'#' -f3)"

sed_options="-e s/{base}/${base}/ -e s/{schemas}/${schemas}/ -e s/{user}/${USER}/"
[[ -n "${verbose}" ]] && echo "sed ${sed_options} ${DB_2_DOM} ${tempds}"
sed ${sed_options} "${DB_2_DOM}" >"${tempds}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in sed execution" "" 1

psql_options="-q -A -t"
[[ -n "${database}" ]] && psql_options="${psql_options} -d ${database}"
[[ -n "${user}" ]] && psql_options="${psql_options} -U ${user}"

[[ -n "${verbose}" ]] && echo "psql ${psql_options} -f ${tempds} ${tempdd}"
psql ${psql_options} -f "${tempds}" >"${tempdd}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in sql script ${tempds}" "" 1


[[ -n "${verbose}" ]] && echo "sed -e s/{schemas}/${schemas}/ -e s/{user}/${USER}/ ${DB_2_REF} ${temprs}"
sed -e "s/{schemas}/${schemas}/" -e "s/{user}/${USER}/" "${DB_2_REF}" >"${temprs}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in sed execution" "" 1

#cat "${temprd}"

[[ -n "${verbose}" ]] && echo "psql ${psql_options} -f ${temprs} ${temprd}"
psql ${psql_options} -f "${temprs}" >"${temprd}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in sql script ${temprs}" "" 1


[[ -n "${verbose}" ]] && echo "sed -e s/{schemas}/${schemas}/ -e s/{user}/${USER}/ ${DB_2_FK} ${tempfs}"
sed -e "s/{schemas}/${schemas}/" -e "s/{user}/${USER}/" "${DB_2_FK}" >"${tempfs}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in sed execution" "" 1


[[ -n "${verbose}" ]] && echo "psql ${psql_options} -f ${tempfs} ${tempfd}"
psql ${psql_options}  -f "${tempfs}" >"${tempfd}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in sql script ${tempfs}" "" 1


#cat "${tempsd}"

ref_dat="$(cat "${temprd}")"


echo "select 'tables';" >"${tempss}"
for line in ${ref_dat}; do
    schema=${line%#*}
    table=${line#*#}
    [[ "${table}" = "metadata" ]] && continue
    [[ -n "${verbose}" ]] && echo "sed -e s/{user}/${USER}/ -e s/{schema}/${schema}/ -e s/{table}/${table}/ ${DB_2_STR} ${tempss}"
    sed -e "s/{user}/${USER}/" -e "s/{schema}/${schema}/"  -e "s/{table}/${table}/" "${DB_2_STR}" >>"${tempss}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in sed execution" "" 1

done

[[ -n "${verbose}" ]] && echo "psql ${psql_options}  -f ${tempss} ${tempst}"
psql ${psql_options}  -f "${tempss}" >"${tempst}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in sql script ${tempss}" "" 1

[[ -n "${verbose}" ]] && echo "sed ${tempst} ${tempsd}"
cat "${tempst}" | grep '.' \
                | sed -e '/^definition#/,/^###/ s/^/def#/' \
                | sed -e 's/^def#definition#/definition#/' \
                | sed -e 's/^def####/###/'                 >"${tempsd}" 
echo "end" >>"${tempsd}" 

#cat "${tempsd}"

line=$(echo "${ref_dat}" | grep 'metadata')
schema=${line%#*}
table=${line#*#}

[[ -n "${verbose}" ]] && echo "sed -e s/{user}/${USER}/ -e s/{schema}/${schema}/ -e s/{table}/${table}/ ${DB_2_MD} ${tempms}"
sed -e "s/{user}/${USER}/" -e "s/{schema}/${schema}/"  -e "s/{table}/${table}/" "${DB_2_MD}" >"${tempms}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in sed execution" "" 1

[[ -n "${verbose}" ]] && echo "psql ${psql_options}  -f ${tempms} ${tempmd}"
psql ${psql_options}  -f "${tempms}" >"${tempmd}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in sql script ${tempss}" "" 1

#cat "${tempmd}"

infoline="$(cat "${tempmd}" | grep '^data#' | cut -d'#' -f2-3 | tr '#' ':')"

#set -x
db_project="${infoline%:*}"
db_version="v${infoline#*:}"
[[ "${#db_version}" == 2 ]] && db_version="${db_version/v/v0}"

[[ "${db_project}" != "${project}" ]] && error_exit "project name missmatch, expected: ${project}, found: ${db_project}" "" 1

echo "exporting version ${db_version} of project ${db_project}"

[[ -z "${outputfile}" ]] && outputfile="${XML_DIR}/${project}_db_${db_version}.xml"


awk_params=""
[[ -n "${trigger}" ]] && awk_params="${awk_params} -v trigger=${trigger}"
[[ -n "${verbose}" ]] && echo "awk -F'#' -f ${DB_DAT_2_XML} ${awk_params} ${temppd} ${tempdd} ${tempsd} ${tempfd} ${tempmd} ${outputfile}"
awk -F'#' -f "${DB_DAT_2_XML}" ${awk_params} "${temppd}" "${tempdd}" "${tempsd}" "${tempfd}" "${tempmd}" >"${outputfile}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in awk script ${DB_DAT_2_XML}" "" 1



if [[ -n "${check}" ]] ; then
    [[ -n "${verbose}"  ]] && echo "xmllint --valid --noout ${output}"
    xmllint --valid --noout "${output}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "schema validation failed" "1"
fi

if [[ -z "${keep}" ]] ; then
    for file in "${temprs}" "${temprd}" "${tempss}" "${tempsd}" "${tempds}" "${tempdd}" "${temppd}" \
                            "${tempfd}" "${tempms}" "${tempmd}" ; do
        [[ -f "${file}" ]] && rm "${file}"
    done
fi


#cat "${output}"



