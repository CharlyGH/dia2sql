#!/usr/bin/bash

function error_exit()
{
    local msg1="$1"
    local msg2="$2"
    local ret="$3"
 
    echo "${msg1}"
    [[ -n "${msg2}" ]] && echo "${msg2}"
    
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




[[ -z "${BIN_DIR}" ]] && error_exit "bin_dir is undefined" "" "1"
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

FULL_PROJECT_FILE="${FULL_XML_DIR}/project.xml"

PROJECT_FILE="${XML_DIR}/project.xml"

