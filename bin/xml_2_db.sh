#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"

USAGE="usage: ${ME} -i inputfile [-r reffiles] [-d database] [-u user] [-o outputfile] [-p projectfile] [-c] [-e] [-h] [-k] [-r] [-v] [-y]"
HELP="${USAGE}
    -c check         check the xml file before generating sql code and check database version
    -d database      database, default is project name
    -e execute       generate and execute  sql script
    -g generate      generate sql script
    -h help          print this help text
    -i inputfile     filename to process
    -k keep          keep, do not delete temp files
    -o outputfile    output filename, default is input file name with xml replaced by sql
    -p projectfile   configuration file for historization, default is ${PROJECT_FILE}
    -r reffiles      referencefiles: oldfile,newfile
    -u user          dabase user, default is ${USER}
    -v verbose       show all execution steps
    -y yes           answer yes to all questions
"

check=""
database=""
execute=""
inputfile=""
keep=""
output=""
projectfile="${FULL_PROJECT_FILE}"
reffiles=""
user=""
verbose=""
yes=""

while getopts "cd:ehi:ko:p:r:u:vy" OPT
do
    case ${OPT} in
        c)
            check="1"
            ;;
        d)
            database="${OPTARG}"
          ;;
        e)
            execute="1"
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
        o)
            outputfile="${OPTARG}"
            ;;
        p)
            projectfile="${OPTARG}"
            ;;
        r)
            reffiles="${OPTARG}"
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
XML_2_XML="${LIB_DIR}/xml_2_xml.xslt"


[[ -z "${inputfile}" ]] && error_exit "missing -i inputfile option" "${USAGE}" 1
[[ ! -r "${inputfile}" ]] && error_exit "cannot read inputfile ${inputfile}" "${USAGE}" 1

#set -x

set_info "${inputfile}" "" "filetype" "project" "old_version" "new_version"
 

if [[ "${filetype}" == "delta" ]] ; then
    [[ -z "${reffiles}" ]] && error_exit "missing -r referencefile option" "${USAGE}" 1
    oldfile="${reffiles%,*}"
    newfile="${reffiles#*,}"
    oldfile="${FULL_DATA_DIR}/${oldfile##*/}"
    newfile="${FULL_DATA_DIR}/${newfile##*/}"
    [[ ! -r "${oldfile}" ]] && error_exit "cannot read old reference file ${oldfile}" "${USAGE}" 1
    [[ ! -r "${newfile}" ]] && error_exit "cannot readnew reference file ${oldfile}" "${USAGE}" 1
fi

[[ -z "${database}" ]] && database="${project}"


name="${inputfile%.*}"
name="${name##*/}"

tempchk="${TEMP_DIR}/${name}.chk.dat"

outputfile="${OUT_DIR}/${name}.sql"

[[ ! -f "${inputfile}" ]] && error_exit "input file '${inputfile}' not found" "" 1

if [[ -n "${check}" ]] ; then

    [[ -n "${verbose}" ]] && echo "${BIN_DIR}/check_rules.sh ${verbose_option} -a -i ${inputfile} -o ${tempchk}" 
    ${BIN_DIR}/check_rules.sh ${verbose_option} -a -i "${inputfile}" -o "${tempchk}" 
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${CHECK_XSLT}" "" 1
#    cat "${tempchk}"
fi


#set -x

xslt_params="--stringparam config-file ${projectfile}"
[[ -n "${oldfile}" ]] && xslt_params="${xslt_params}  --stringparam oldfile ${oldfile}"
[[ -n "${newfile}" ]] && xslt_params="${xslt_params}  --stringparam newfile ${newfile}"
xslt_params="${xslt_params}  --path ${DTD_DIR}"
xslt_params="${xslt_params}  --stringparam filetype ${filetype}"


[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_SQL} ${inputfile} ${outputfile}"
xsltproc ${xslt_params} "${XML_2_SQL}" "${inputfile}" > "${outputfile}"
ret="$?"
[[ "${ret}" != "0" ]] && error_exit "error in xslt script ${XML_2_SQL}" "" ${ret}
done="1"
#cat "${outputfile}"


psql_options="-q -A -t"
[[ -n "${database}" ]] && psql_options="${psql_options} -d ${database}"
[[ -n "${user}" ]] && psql_options="${psql_options} -U ${user}"

#set -x

if [[ -n "${execute}" || -n "${check}" ]] ; then
    SELECT="select table_name from dba.all_tables where schema_name like 'base_%' and table_name = 'metadata';"
    result="$(psql ${psql_options} -c "${SELECT}")"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "Cannot access dba.all_tables" "Is dba.sql installed?" ${ret}

    db_version=""

    if [[ "${filetype}"  == "model" ]] ; then
        version="${old_version}"
        [[ -n "${verbose}" ]] && echo "version=${version}"
 
        if [[ -z "${result}" ]] ; then
            echo "Cannot find base_${project}, assuming no old version exists"
        else
            SELECT="select version from base_${project}.metadata;"
            db_version="$(psql ${psql_options} -c "${SELECT}")"
            [[ -n "${verbose}" ]] && echo "db_version=${db_version}"
        fi

        if [[ -n "${db_version}" ]] ;then
            if [[  -n "${yes}" ]] ; then
                echo "replacing installed version ${db_version} with version ${version}"
            else
                echo "rerun script with -y option to replace installed version ${db_version} with version ${version}"
            fi
        fi
    else
        [[ -n "${verbose}" ]] && echo "old_version=${old_version}"
        [[ -n "${verbose}" ]] && echo "new_version=${new_version}"

        if [[ -z "${result}" ]] ; then
            echo "Cannot find base_${project}, assuming no old version exists"
        else
            SELECT="select version from base_${project}.metadata;"
            db_version="$(psql ${psql_options} -c "${SELECT}")"
            [[ -n "${verbose}" ]] && echo "db_version=${db_version}"
        fi

        [[ -z "${db_version}" ]] && error_exit "no db_version found for project ${project} in database" "" 1
        if [[ "${db_version}" = "${old_version}" ]] ; then
            echo "replacing installed version ${db_version} with version ${new_version}"                
        else
            error_exit "old_version ${old_version} does not match db_version ${db_version}" "" 1
        fi
    fi
fi

if [[ -n "${execute}" ]] ; then
    if [[ -n "${yes}" && "${filetype}" == "model" ]] || [[ "${filetype}" == "delta" ]] ; then
        [[ -n "${verbose}" ]] && echo "psql ${psql_options} -f ${outputfile}"
        psql ${psql_options} -f "${outputfile}"
        ret="$?"
        [[ "${ret}" != "0" ]] && error_exit "error in sql script ${outputfile}" "" "${ret}"
    fi

fi




if [[ -z "${keep}" ]] ; then
    [[ -f "${tempchk}" ]] && rm "${tempchk}"
    [[ -f "${tempprj}" ]] && rm "${tempprj}"
fi

exit 0
