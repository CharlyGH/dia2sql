#!/usr/bin/bash

function error_exit()
{
    local msg1="$1"
    local msg2="$2"
    local ret="$3"
 
    echo "${msg1}" > "/dev/stderr"
    [[ -n "${msg2}" ]] && echo "${msg2}" > "/dev/stderr"
    
    exit "${ret}"
}


function format_gen()
{
    local num="$1"
    local res=""

    if [[ "${num:0:1}" == "v" ]] ;then
        res="${num}"
    else
        if [[ "${#num}" == "1" ]] ; then
            res="v0${num}"
        else
            res="v${num}"
        fi
    fi
    echo "${res}"
}


function get_info()
{
    local l_file="$1"
    local l_node="$2"
    local l_key="$3"
    local l_info="$(xsltproc --path "${DTD_DIR}" "${LIB_DIR}/get_info.xslt" ${l_file})"
    local f_node="${l_info%%:*}"
    local l_rest="${l_info#*:}"
    local project="${l_rest%%:*}"
    local l_version="${l_rest#*:}"
    local l_result=""
    if [[ "${f_node}" == "${l_node}" ]] ; then
        case "${l_key}" in
            "project")
                l_result="${project}"
                ;;
            "version")
                [[ "${f_node}" == "model" ]] && l_result="${l_version}"
                ;;
            "old-version")
                old_version="${l_version%:*}"
                [[ "${f_node}" == "delta" ]] && l_result="${old_version}"
                ;;
            "new-version")
                new_version="${l_version#*:}"
                [[ "${f_node}" == "delta" ]] && l_result="${new_version}"
                ;;
            *)
                error_exit "Invalid key ${l_key}" "" "1"
                ;;
        esac
    fi
    echo "${l_result}"
    
}

function set_info()
{
    local l_filename="$1"
    local l_expected="$2"
    local l_filetype_var="$3"
    local l_project_var="$4"
    local l_version_1_var="$5"
    local l_version_2_var="$6"
    [[ -z "${l_filename}" ]] && error_exit "no input file name for set_info" "" 1
    [[ ! -r "${l_filename}" ]] && error_exit "cannot read input file [${l_filename}] for set_info" "" 1
    [[ -z "${l_filetype_var}" ]] && error_exit "no file type variable for set_info" "" 1
    [[ -z "${l_project_var}" ]] && error_exit "no project name variable for set_info" "" 1
    [[ -z "${l_version_1_var}" ]] && error_exit "no version variable for set_info" "" 1
    
    local l_info="$(xsltproc --path "${DTD_DIR}" "${LIB_DIR}/get_info.xslt" "${l_filename}")"
    local l_filetype=${l_info%%:*}
    [[ -n "${l_expected}" && "${l_expected}" != "${l_filetype}" ]] && \
                          error_exit "expected file type [${l_expected}] but found [${l_filetype}]" "" 1
    local l_rest="${l_info#*:}"
    local l_project="${l_rest%%:*}"
    [[ -z "${l_project}" ]] && error_exit "no project name found" "" 1
    local l_version="${l_rest#*:}"
    local l_version_1="${l_version%:*}"
    [[ -z "${l_version_1}" ]] && error_exit "no version number found" "" 1
    local l_version_2=""
    [[ "${l_version_1}" != "${l_version}" ]] && local l_version_2="${l_version#*:}"
    eval "${l_filetype_var}=${l_filetype}"
    eval "${l_project_var}=${l_project}"
    eval "${l_version_1_var}=${l_version_1}"
    [[ -n "${l_version_2_var}" &&  -n "${l_version_2}" ]] && eval "${l_version_2_var}=${l_version_2}"
    [[ "${l_filetype}" == "delta" && -z "${l_version_2}" ]] && \
                                  error_exit "no old version number found for file type delta" "" 1
}

MY_DIR="$(cd ${BASH_SOURCE%/*};pwd)"

[[ -z "${BIN_DIR}" ]] && BIN_DIR="${MY_DIR}"
[[ ! -d "${BIN_DIR}" ]] && error_exit "bin_dir ${bin_dir} does not exist" "" "1"


ROOT_DIR="${BIN_DIR%/*}"
FULL_BIN_DIR="${ROOT_DIR}/bin"
FULL_DATA_DIR="${ROOT_DIR}/data"
FULL_DIA_DIR="${ROOT_DIR}/dia"
FULL_DTD_DIR="${ROOT_DIR}/dtd"
FULL_LIB_DIR="${ROOT_DIR}/lib"
FULL_OUT_DIR="${ROOT_DIR}/out"
FULL_PDF_DIR="${ROOT_DIR}/pdf"
FULL_SQL_DIR="${ROOT_DIR}/sql"
FULL_TEMP_DIR="${ROOT_DIR}/temp"
FULL_XML_DIR="${ROOT_DIR}/xml"
FULL_DBM_DIR="${ROOT_DIR}/dbm"

PWD="$(pwd)/"

BIN_DIR="${FULL_BIN_DIR/${PWD}/}"
DATA_DIR="${FULL_DATA_DIR/${PWD}/}"
DIA_DIR="${FULL_DIA_DIR/${PWD}/}"
DTD_DIR="${FULL_DTD_DIR/${PWD}/}"
LIB_DIR="${FULL_LIB_DIR/${PWD}/}"
OUT_DIR="${FULL_OUT_DIR/${PWD}/}"
PDF_DIR="${FULL_PDF_DIR/${PWD}/}"
SQL_DIR="${FULL_SQL_DIR/${PWD}/}"
TEMP_DIR="${FULL_TEMP_DIR/${PWD}/}"
XML_DIR="${FULL_XML_DIR/${PWD}/}"
DBM_DIR="${FULL_DBM_DIR/${PWD}/}"

FULL_PROJECT_FILE="${FULL_XML_DIR}/project.xml"

PROJECT_FILE="${XML_DIR}/project.xml"

file="$1"

MY_NAME="${0##*/}"
SCRIPT="${BASH_SOURCE##*/}"

if [[ "${MY_NAME}" == "${SCRIPT}" ]] ; then
    set_info "${file}" "filetype" "project" "version_1" "version_2"
    echo "filetype=${filetype}"
    echo "project=${project}"
    echo "version_1=${version_1}"
    echo "version_2=${version_2}"
fi

