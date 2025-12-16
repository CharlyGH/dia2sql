#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"
LINES="1"

USAGE="usage: ${ME} -i inputfile [-r referencefile] [-d database] [-u user] [-o outputfile] {-s|-t} [-l lines] [-p projectfile] [-c] [-D] [-e] [-h] [-k] [-r] [-v] [-y]"
HELP="${USAGE}
    -c check          check the xml file before generating sql code
    -d database       database, default is ${USER}
    -D delete         delete all existing rows with truncate table
    -e execute        execute generated sql script 
    -h help           print this help text
    -i inputfile      filename to process
    -k keep           keep, do not delete temp files
    -l lines          lines to insert, default is ${LINES}
    -o outputfile     output filename, default is input file name with xml replaced by sql or dat.sql
    -p projectfile    configuration file for historization, default is ${PROJECT_FILE}
    -r referencefile  rows to insert, default is ${ROWS}
    -s sql            generate sql script
    -t test           create test data
    -u user           dabase user, default is ${USER}
    -v verbose        show all execution steps
    -y yes            answer yes to all questions
"

check=""
database=""
delete=""
execute=""
inputfile=""
keep=""
lines="${LINES}"
output=""
projectfile="${FULL_PROJECT_FILE}"
referencefile=""
sql=""
test=""
user=""
verbose=""
yes=""

while getopts "cd:Dehi:kl:o:p:r:stu:vy" OPT
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
        r)
            referencefile="${OPTARG}"
            ;;
        s)
            sql="1"
            ;;
        t)
            test="1"
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


[[ -z "${inputfile}" ]] && error_exit "missing -i inputfile option" "${USAGE}" 1
[[ ! -r "${inputfile}" ]] && error_exit "cannot read inputfile ${inputfile}" "${USAGE}" 1

#set -x

filetype=""
projectname="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p "/model/@project")"
[[ -n "${projectname}" ]] && filetype="model"
[[ -z "${projectname}" ]] && projectname="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p "/delta/@project")"
[[ -n "${projectname}" && -z "${filetype}" ]] && filetype="delta"
[[ -z "${projectname}" ]] && error_exit "no project name in ${inputfile}"

if [[ "${filetype}" == "delta" ]] ; then
    [[ -z "${referencefile}" ]] && error_exit "missing -r referencefile option" "${USAGE}" 1
    referencefile="${FULL_DATA_DIR}/${referencefile##*/}"
    [[ ! -r "${referencefile}" ]] && error_exit "cannot read referencefile ${referencefile}" "${USAGE}" 1
fi
    
name="${inputfile%.*}"
name="${name##*/}"

tempchk="${TEMP_DIR}/${name}.chk.dat"
tempfmt="${TEMP_DIR}/${name}.fmt.dat"
tempprj="${FULL_TEMP_DIR}/${name}.prj.xml"

[[ -n "${sql}" ]] && outputfile="${OUT_DIR}/${name}.sql"
[[ -n "${test}" ]] && outputfile="${OUT_DIR}/${name}.dat.sql"

[[ -z "${check}${sql}${test}" ]] && error_exit "no option -c, -s or -t supplied" "${USAGE}"  1
[[ ! -f "${inputfile}" ]] && error_exit "input file '${inputfile}' not found" "" 1


if [[ -n "${check}" ]] ; then
    [[ -n "${verbose}" ]] && "echo ${BIN_DIR}/create_config.sh ${verbose_option} -i ${inputfile} -p ${projectfile} -o ${tempprj}"
    ${BIN_DIR}/create_config.sh ${verbose_option} -i "${inputfile}" -p "${projectfile}" -o "${tempprj}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script create_config.sh" "" "1"

    ${BIN_DIR}/check_rules.sh ${verbose_option} -a -i "${inputfile}" -p "${tempprj}" -o "${tempchk}" 
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${CHECK_XSLT}" "" "1"
#    cat "${tempchk}"
fi


awk_params="-v lines=${lines}"
[[ -n "${delete}" ]] && awk_params="${awk_params} -v truncate="${delete}""

#set -x

xslt_params="--stringparam projectfile ${projectfile}"
xslt_params="${xslt_params}  --stringparam projectname ${projectname}"
[[ -n "${referencefile}" ]] && xslt_params="${xslt_params}  --stringparam referencefile ${referencefile}"
xslt_params="${xslt_params}  --path ${DTD_DIR}"
xslt_params="${xslt_params}  --stringparam filetype ${filetype}"


if [[ -n "${sql}" ]] ; then
    [[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_SQL} ${inputfile} ${outputfile}"
    xsltproc ${xslt_params} "${XML_2_SQL}" "${inputfile}" > "${outputfile}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${XML_2_SQL}" "" "${ret}"
    done="1"
    #cat "${outputfile}"
fi


if [[ -n "${test}" ]] ; then
    [[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_FMT} ${inputfile} ${tempfmt}"
    xsltproc ${xslt_params} "${XML_2_FMT}" "${inputfile}" > "${tempfmt}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${XML_2_AWK}" "" "${ret}"
    #cat "${tempfmt}"
    
    export LC_NUMERIC="C"
    if [[ -n "${delete}" ]] ; then
        [[ -n "${verbose}" ]] && echo "awk -F'#' -f ${FMT_2_DAT} -v pass=truncate ${awk_params} ${tempfmt}  ${outputfile}"
        awk -F'#' -f "${FMT_2_DAT}" -v pass=truncate ${awk_params} "${tempfmt}" >"${outputfile}"
    else
        echo -n "" >"${outputfile}"
    fi
    [[ -n "${verbose}" ]] && echo "awk -F'#' -f ${FMT_2_DAT} -v pass=insert ${awk_params} ${tempfmt}  ${outputfile}"
    awk -F'#' -f "${FMT_2_DAT}" -v pass=insert ${awk_params} "${tempfmt}" >>"${outputfile}"
    unset LC_NUMERIC
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in awk script ${FMT_2_DAT}" "" "${ret}"
    #cat "${outputfile}"
    
fi

psql_options="-q -A -t"
[[ -n "${database}" ]] && psql_options="${psql_options} -d ${database}"
[[ -n "${user}" ]] && psql_options="${psql_options} -U ${user}"

#set -x

if [[ -n "${execute}" ]] ; then
    action=""
    project="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p /model/@project)"
    if [[ -n "${project}" ]] ; then
        action="model"
        version="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p /model/@version)"
        [[ -z "${version}" ]] && error_exit "no version found for project ${project} in ${inputfile}" "" 1
        db_version="$(psql ${psql_options} -c "select version from base_${project}.metadata;")"
        if [[ -n "${db_version}" ]] ;then
            if [[  -n "${yes}" ]] ; then
                echo "replacing installed version ${db_version} with version ${version}"
            else
                echo "rerun script with -y option to replace installed version ${db_version} with version ${version}"
            fi
        fi
    else
        project="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p /delta/@project)"
        if [[ -n "${project}" ]] ; then
            action="delta"
            old_version="""$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p /delta/@old-version)"
            new_version="""$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p /delta/@new-version)"

            [[ -z "${old_version}" ]] && error_exit "no old_version found for project ${project} in ${inputfile}" "" 1
            [[ -z "${new_version}" ]] && error_exit "no new_version found for project ${project} in ${inputfile}" "" 1
            db_version="$(psql ${psql_options} -c "select version from base_${project}.metadata;")"
            [[ -z "${db_version}" ]] && error_exit "no db_version found for project ${project} in database" "" 1
            if [[ "${db_version}" = "${old_version}" ]] ; then
                echo "replacing installed version ${db_version} with version ${new_version}"                
            else
                error_exit "old_version ${old_version} does not match db_version ${db_version}" "" 1
            fi
        else
            error_exit "no project found in file ${inputfile}"
        fi
    fi
    [[ -z "${action}" ]] && error_exit "input file ${inputfile} is neither model nor delta"
fi

#set -x

if [[ -n "${yes}" && "${action}" == "model" ]] || [[ "${action}" == "delta" ]] ; then
    [[ -n "${verbose}" ]] && echo "psql ${psql_options} -f ${outputfile}"
    psql ${psql_options} -f "${outputfile}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in sql script ${outputfile}" "" "${ret}"
fi



if [[ -z "${keep}" ]] ; then
    [[ -f "${tempchk}" ]] && rm "${tempchk}"
    [[ -f "${tempfmt}" ]] && rm "${tempfmt}"
    [[ -f "${tempprj}" ]] && rm "${tempprj}"
fi

exit 0
