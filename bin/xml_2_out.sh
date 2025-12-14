#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"


USAGE="usage: ${ME} -i inputfile [-o outputfile] {-d | -l | -p | -s} [-c] [-D] [-k] [-r] [-v]"
HELP="${USAGE}
    -D debug       debug mode
    -c check       check generated dot or lout file
    -d dot         create dot docu
    -i inputfile   name of input file
    -k keep        keep temp files, do not delete at end
    -l lout        create lout docu
    -o outputfile  name of output file
    -p pdf         create pdf docu, implies dot and lout
    -r relative    use relative paths
    -s svg         create svg docu, implies dot
    -v verbose     show all steps of execution
"

check=""
dot=""
debug=""
genlout=""
gendot=""
inputfile=""
keep=""
lout=""
outputfile=""
pdf=""
relative=""
svg=""
verbose=""

while getopts "cdDf:hi:klno:psv" OPT
do
    case ${OPT} in
        c)
            check="1"
            ;;
        d)
            gendot="1"
            dot="1"
            ;;
        D)
            debug="1"
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
            genlout="1"
            lout="1"
            ;;
        o)
            outputfile="${OPTARG}"
            ;;
        p)
            gendot="1"
            genlout="1"
            pdf="1"
            ;;
        s)
            gendot="1"
            svg="1"
            ;;
        v)
            verbose="1"
            ;;
        *)
            error_exit "Invalid argument ${arg}::${OPTARG}" "${USAGE}" "1"
            ;;
    esac
done


XML_2_DOT="${LIB_DIR}/xml_2_dot.xslt"
SVG_2_SVG="${LIB_DIR}/svg_2_svg.xslt"
XML_2_LOUT="${LIB_DIR}/xml_2_lout.xslt"

all_outputs="${dot}${lout}${pdf}${svg}"
[[ -z "${all_outputs}" ]] && error_exit "at least one of -d, -l, -p or -s must be supplied" "${USAGE}" "1"

if [[ -n "${check}" ]] ; then
    [[ -n "${pdf}" ]] && error_exit "option -c cannot be used with -p" "${USAGE}" "1"
    [[ -n "${svg}" ]] && error_exit "option -c cannot be used with -s" "${USAGE}" "1"
fi


[[ -z "${inputfile}" ]] && error_exit "missing -i inputfile option" "${USAGE}" 1


input="${inputfile}"
name="${input%.*}"
name="${name##*/}"

[[ ! -r "${inputfile}" ]] && error_exit "cannot read input file '${inputfile}'" "" "1"

ret=""

if [[ -n "${gendot}" ]] ; then
    tempd="${TEMP_DIR}/${name}.dot"

    xslt_params="--path ${DATA_DIR}"
    [[ -n "${debug}" ]] && xslt_params="${xslt_params} --stringparam debug 1"
    [[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_DOT} ${input} ${tempd}"
    xsltproc ${xslt_params} "${XML_2_DOT}" "${input}" > "${tempd}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${XML_2_DOT}" "" "${ret}"
fi


if [[ -n "${genlout}" ]] ; then
    templu="${TEMP_DIR}/${name}.lout.utf"
    templ="${TEMP_DIR}/${name}.lout"
   
    xslt_params="--path ${DATA_DIR}"
    [[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_LOUT} ${input} ${templu}"
    xsltproc ${xslt_params} "${XML_2_LOUT}" "${input}" > "${templu}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${XML_2_LOUT}" "" "${ret}"

    FROM="UTF-8"
    TO="ISO8859-15"
    [[ -n "${verbose}" ]] && echo "iconv -f ${FROM} -t ${TO} -o ${templ} ${templu}"
    iconv -f "${FROM}" -t "${TO}" -o "${templ}" "${templu}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in iconv" "" "${ret}"
    
fi


if [[ -n "${dot}" ]] ; then
    output="${OUT_DIR}/${name}.dot"
    [[ -n "${verbose}" ]] && echo "cp ${tempd} ${output}"
    cp "${tempd}" "${output}"
fi

REPEAT="4"

if [[ -n "${lout}" ]] ; then
    output="${OUT_DIR}/${name}.lout"
    [[ -n "${verbose}" ]] && echo "cp ${templ} ${output}"
    cp "${templ}" "${output}"
fi

if [[ -n "${check}" ]] ; then
    if [[ -n "${dot}" ]] ; then
        output="${TEMP_DIR}/${name}.dot.pdf"
        params="-T pdf"
        [[ -n "${verbose}" ]] && echo "dot ${params} ${tempd} ${output}"
        dot ${params}  "${tempd}" > "${output}"
        ret="$?"
        [[ "${ret}" != "0" ]] && error_exit "error in dot script ${tempd}" "" "${ret}"
    fi


    if [[ -n "${lout}" ]] ; then
        lout_cr_file="${TEMP_DIR}/${name}"
        output="${TEMP_DIR}/${name}.lout.pdf"
        params="-r${REPEAT} -c "${lout_cr_file}" -Z -I ${DATA_DIR}"
        [[ -n "${verbose}" ]] && echo "lout ${params} -o ${output} ${templ}"
        lout ${params} -o "${output}" "${templ}"
        ret="$?"
        [[ "${ret}" != "0" ]] && error_exit "error in lout script ${templ}" "" "${ret}"
    fi
fi


if [[ -n "${svg}" ]] ; then
    temps0="${TEMP_DIR}/${name}.temp0.svg"
    temps1="${TEMP_DIR}/${name}.temp1.svg"
    temps2="${TEMP_DIR}/${name}.temp2.svg"

    output="${OUT_DIR}/${name}.svg"
    params="-T svg"
    [[ -n "${verbose}" ]] && echo "dot ${params} ${tempd} ${temps0}"
    dot ${params}  "${tempd}" > "${temps0}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in dot script ${tempd}" "" "${ret}"

    [[ "${ret}" != "0" ]] && exit "${ret}"
    cat "${temps0}" | grep -v -e '//W3C//DTD' -e 'SVG/1.1/DTD' \
                    | sed -e 's/xmlns=/xmlns:svg=/'   >"${temps1}"

    [[ -n "${verbose}" ]] && echo "xsltproc --stringparam master "../${input}" ${SVG_2_SVG} ${tempsvg1} ${tempsvg2}"
    xsltproc --stringparam master "../${input}" "${SVG_2_SVG}" "${temps1}"  > "${temps2}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${SVG_2_SVG}" "" "${ret}"

    [[ -n "${verbose}" ]] && echo "sed -e 3s/ns/xmlns/ ${temps2} ${output}"
    sed -e '3s/ns/xmlns/' "${temps2}"  > "${output}"
    ret="$?"
    [[ "${ret}" != "0" ]] && exit "error in sed" "" "${ret}"
fi


if [[ -n "${pdf}" ]] ; then
    tempdp="${TEMP_DIR}/${name}.dot.pdf"
    templp="${TEMP_DIR}/${name}.lout.pdf"
    lout_cr_file="${DATA_DIR}/${name}.lout"
    output="${OUT_DIR}/${name}.pdf"
    params="-T pdf"
    [[ -n "${verbose}" ]] && echo "dot ${params} ${tempd} ${tempdp}"
    dot ${params}  "${tempd}" > "${tempdp}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in dot script ${tempd}" "" "${ret}"

    params="-r${REPEAT} -c "${lout_cr_file}" -Z -I ${DATA_DIR}"
    [[ -n "${verbose}" ]] && echo "lout ${params} -o ${templp} ${templ}"
    lout ${params} -o "${templp}" "${templ}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in lout script ${templ}" "" "${ret}"

    [[ -n "${verbose}" ]] && echo "pdfunite  ${templp} ${tempdp} ${output}"
    pdfunite "${templp}" "${tempdp}" "${output}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in pdfunite" "" "${ret}"
fi


if [[ -z "${keep}" ]] ; then
    for file in "${tempd}" "${templ}" "${templu}" "${tempdp}" "${templp}"  "${temps0}" "${temps1}" "${temps2}" ; do
        if [[ -f "${file}" ]] ; then
            [[ -n "${verbose}" ]] && echo "rm  ${file}"
            rm  "${file}"
        fi
    done
fi
    
exit "0"
