#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"


XML_2_REP="${LIB_DIR}/xml_2_rep_xml.xslt"

USAGE="usage: ${ME} -b basename [-c] [-f filename] [-p projectfile] [-s schema] [-t table] [-k] [-v]"
HELP="${USAGE}
    -b basename     basename for schemas and tablespaces
    -c check        check the xml output file
    -f filename     name of input file, default is basename.xml in ${DATA_DIR}
    -k keep         keep, do not delete temp files
    -p projectfile  configuration file for historization, default is ${PROJECT_FILE}
    -s schema       only this schema
    -t table        only this table
    -v verbose      show all execution steps
"


basename=""
check=""
filename=""
keep=""
projectfile="${PROJECT_FILE}"
schema="all"
table="all"
verbose=""

while getopts "b:cf:hkp:s:t:v" OPT
do
    case ${OPT} in
      b)
          basename="${OPTARG}"
          ;;
      c)
          check="1"
          ;;
      f)
          file="${OPTARG}"
          ;;
      h)
          echo "${HELP}"
          exit 0
          ;;
      k)
          keep="1"
          ;;
      p)
          projectfile="${OPTARG}"
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
          error_exit "Invalid argument ${arg}::${OPTARG}" "" 1
          ;;
  esac
done

#set -x
[[ -z "${basename}" ]] && error_exit "missing -b basename option" "${USAGE}"  "1"

[[ -z "${file}" ]] && file="${DATA_DIR}/${basename}.xml"


input="${file}"
name="${input%.*}"
name="${name##*/}"

output="${DATA_DIR}/${name}.rep.xml"

[[ "${input}" = "${output}" ]] && error_exit "input file '${input}' and output file are identical" ""  1
[[ ! -f "${input}" ]] && error_exit "input file '${input}' not found"  ""  1

xslt_params="--stringparam projectfile ${projectfile}  --stringparam basename ${basename}"
xslt_params="${xslt_params} --stringparam table ${table} --stringparam schema ${schema}"

[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_REP} ${input} ${output}"
xsltproc ${xslt_params} "${XML_2_REP}" "${input}" > "${output}"
ret="$?"
[[ "${ret}" != "0" ]] && exit "${ret}"

#set -x
if [[ -n "${check}" ]] ; then
    [[ -n "${verbose}" ]] && echo "xmllint --noout --valid ${output}"
    xmllint --noout --valid "${output}"
    ret="$?"
fi


[[ "${ret}" != "0" ]] && error_exit "syntax error in generated json file" "" "${ret}"

cat "${output}"
