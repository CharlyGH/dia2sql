#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"


XML_2_REP="${LIB_DIR}/xml_2_rep_xml.xslt"

USAGE="usage: ${ME} -i inputfile [-c] [-o outputfile] [-p projectfile] [-s schema] [-t table] [-k] [-v]"
HELP="${USAGE}
    -c check        check the xml output file
    -i inputfile    name of input file
    -k keep         keep, do not delete temp files
    -o outputfile   name of output file, default is inputfile with extension .rep.xml 
    -p projectfile  configuration file for historization, default is ${PROJECT_FILE}
    -s schema       only this schema
    -t table        only this table
    -v verbose      show all execution steps
"


check=""
inputfile=""
keep=""
outputfile=""
projectfile="${PROJECT_FILE}"
schema="all"
table="all"
verbose=""

while getopts "chi:ko:p:s:t:v" OPT
do
    case ${OPT} in

          check="1"
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
[[ -z "${inputfile}" ]] && error_exit "missing -i inputfile option" "${USAGE}"  "1"


name="${inputfile%.*}"
name="${name##*/}"

[[ -z "${outputfile}" ]] && outputfile="${XML_DIR}/${name}.rep.xml"

[[ "${inputfile}" = "${outputfile}" ]] && error_exit "input file '${inputfile}' and output file are identical" ""  1
[[ ! -f "${inputfile}" ]] && error_exit "input file '${inputfile}' not found"  ""  1

xslt_params="--stringparam projectfile ${projectfile}  --stringparam basename ${basename}"
xslt_params="${xslt_params} --stringparam table ${table} --stringparam schema ${schema}"

[[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_REP} ${inputfile} ${outputfile}"
xsltproc ${xslt_params} "${XML_2_REP}" "${inputfile}" > "${outputfile}"
ret="$?"
[[ "${ret}" != "0" ]] && exit "${ret}"

#set -x
if [[ -n "${check}" ]] ; then
    [[ -n "${verbose}" ]] && echo "xmllint --noout --valid ${outputfile}"
    xmllint --noout --valid "${outputfile}"
    ret="$?"
fi


[[ "${ret}" != "0" ]] && error_exit "syntax error in generated json file" "" "${ret}"

cat "${outputfile}"
