#!/usr/bin/bash

function add_object()
{
    local l_list="$1"
    local l_new="$2"

    local l_found=0
    local l_obj=""
    for l_obj in ${l_list/,/ } ; do
        if [[ "${l_obj}" == "${l_new}" ]] ; then
            l_found=1
            break
        fi
    done
    if [[ "${l_found}" == "0" ]] ; then
        if [[ -z "${l_list}" ]] ; then
            l_list="${l_new}"
        else
            l_list="${l_list},${l_new}"
        fi
    fi
    echo "${l_list}"
}    


 
#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"

XSLT_SCRIPT="${LIB_DIR}/${ME%.*}.xslt"
[[ ! -f "${XSLT_SCRIPT}" ]] && error_exit "xslt script ${XSLT_SCRIPT} does not exist" "" 1


USAGE="usage: ${ME} -i inputfile [-h] [-o objectlist] [-s schema] [-t table] [-v]"
HELP="${USAGE}
    -h help         print this help text
    -i inputfile    input file name
    -o objectlist   comma separated list of objects, a,c,d,f,p,q,r,s,t
                    a=all, c=column, d=domain, f=function, m=model, p=tablespace, q=sequence, r=reference, s=schema, t=table
    -r reference    show references
    -s schema       show one schema only
    -t table        show one table only
    -v verbose      show all execution steps
"

objectlist=""
inputfile=""
schema=""
table=""
verbose=""

while getopts "hi:l:o:s:t:v" OPT ; do
    case "${OPT}" in
        h)
            echo "${HELP}"
            exit 0
            ;;
        i)
            inputfile="${OPTARG}"
            ;;
        o)
            objectcodelist="${OPTARG}"
            ;;
        s)
            schema="${OPTARG}"
            ;;
        t)
            table="${OPTARG}"
            ;;
        v)
            verbose="1"
            ;;
        *)
            error_exit "Invalid argument: ${OPTARG}" "" "1"
            ;;
    esac
done

[[ -z "${inputfile}" ]] && error_exit "missing -i inputfile argument" "${USAGE}" 1

[[ ! -f "${inputfile}" ]] && error_exit "input file ${inputfile} does not exist" "" 1

input="${inputfile}"
name="${input%.*}"
name="${name##*/}"


[[ -z "${objectcodelist}" ]] && error_exit "missing -o option" "${USAGE}" 1


for object in ${objectcodelist//,/ } ; do
    case "${object}" in
        a)
            objectlist="column,domain,function,modell,tablespace,sequence,reference,schema,table"
            ;;
        c)
            objectlist="$(add_object "$objectlist" "column")"
            ;;
        d)
            objectlist="$(add_object "$objectlist" "domain")"
            ;;
        f)
            objectlist="$(add_object "$objectlist" "function")"
            ;;
        m)
            objectlist="$(add_object "$objectlist" "model")"
            ;;
        p)
            objectlist="$(add_object "$objectlist" "tablespace")"
            ;;
        q)
            objectlist="$(add_object "$objectlist" "sequence")"
            ;;
        r)
            objectlist="$(add_object "$objectlist" "reference")"
            ;;
        s)
            objectlist="$(add_object "$objectlist" "schema")"
            ;;
        t)
            objectlist="$(add_object "$objectlist" "table")"
            ;;
        *)
            error_exit "Invalid object: ${object}" "" "1"
            ;;
    esac
done


xslt_params="--path ${DTD_DIR}"
xslt_params="${xslt_params} --stringparam objectlist ${objectlist}"
[[ -n "${schema}" ]] && xslt_params="${xslt_params} --stringparam schema ${schema}"
[[ -n "${table}" ]] && xslt_params="${xslt_params} --stringparam table ${table}"


[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XSLT_SCRIPT} ${input}"
xsltproc ${xslt_params} "${XSLT_SCRIPT}" "${input}"
ret="$?"

exit "${ret}"

