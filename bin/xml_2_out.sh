#!/usr/bin/bash

#set -x

ME="${BASH_SOURCE##*/}"
BIN_DIR="$(cd ${BASH_SOURCE%/*}; pwd)"

source "${BIN_DIR}/utils.lib.sh"


USAGE="usage: ${ME} -i inputfile [-o outputfile] {-d | -l | -p | -s} [-c] [-D] [-k] [-r repeat] [-v]"
HELP="${USAGE}
    -D debug       debug mode
    -c check       check generated dot or lout file
    -d dot         create dot docu
    -i inputfile   name of input file
    -k keep        keep temp files, do not delete at end
    -l lout        create lout docu
    -o outputfile  name of output file
    -p pdf         create pdf docu, implies dot and lout
    -r repeat      remoce lout index files an set repeat value 
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
repeat=""
svg=""
verbose=""

while getopts "cdDf:hi:klno:pr:sv" OPT
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
        r)
            repeat="${OPTARG}"
            ;;
        s)
            gendot="1"
            svg="1"
            ;;
        v)
            verbose="1"
            verb_opt="-v"
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

[[ "${pdf}${svg}" == "11" ]] && error_exit "either -p or -s is allowd, not both" "${USAGE}" "1"


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

if [[ -n "${repeat}" ]] ; then
    lout_cr_file="${TEMP_DIR}/${name}"
    louttempli="${lout_cr_file}.li"
    louttempld="${lout_cr_file}.lout.ld"
    for file in "${louttempli}" "${louttempld}" ; do
        if [[ -f "${file}" ]] ; then
            [[ -n "${verbose}" ]] && echo "rm  ${file}"
            rm  "${file}"
        fi
    done
else
    repeat=1
fi

if [[ -n "${gendot}" ]] ; then
    tempd="${TEMP_DIR}/${name}.dot"
    temphd="${TEMP_DIR}/${name}.hist.dot"

#    set -x
    project="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p "/model/@project")"
    hist_schema="hist_${project}"
    hist_table="$(${BIN_DIR}/xpath.sh -i "${inputfile}" -p "//table[@schema = '${hist_schema}']/@name")"

    if [[ -n "${hist_table}" && -z "${svg}" ]] ; then
        xslt_params="--path ${DTD_DIR}"
        xslt_params="${xslt_params} --stringparam hist-schema ${hist_schema}"
        xslt_params="${xslt_params} --stringparam proc-hist-schema only"
        [[ -n "${debug}" ]] && xslt_params="${xslt_params} --stringparam debug 1"
        [[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_DOT} ${inputfile} ${temphd}"
        xsltproc ${xslt_params} "${XML_2_DOT}" "${inputfile}" > "${temphd}"
        ret="$?"
        [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${XML_2_DOT}" "" "${ret}"
    fi
        
    xslt_params="--path ${DTD_DIR}"
    xslt_params="${xslt_params} --stringparam hist-schema ${hist_schema}"
    if [[ -n "${svg}" ]] ; then
        xslt_params="${xslt_params} --stringparam proc-hist-schema all"
    else
        xslt_params="${xslt_params} --stringparam proc-hist-schema no"
    fi
    
    [[ -n "${debug}" ]] && xslt_params="${xslt_params} --stringparam debug 1"
    [[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_DOT} ${inputfile} ${tempd}"
    xsltproc ${xslt_params} "${XML_2_DOT}" "${inputfile}" > "${tempd}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in xslt script ${XML_2_DOT}" "" "${ret}"
fi


if [[ -n "${genlout}" ]] ; then
    templu="${TEMP_DIR}/${name}.lout.utf"
    templ="${TEMP_DIR}/${name}.lout"
   
    xslt_params="--path ${DTD_DIR}"
    [[ -n "${verbose}" ]] && echo "xsltproc ${xslt_params} ${XML_2_LOUT} ${inputfile} ${templu}"
    xsltproc ${xslt_params} "${XML_2_LOUT}" "${inputfile}" > "${templu}"
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
    if [[ -n "${hist_table}" ]] ; then
        hist_output="${OUT_DIR}/${name}.hist.dot"
        [[ -n "${verbose}" ]] && echo "cp ${temphd} ${hist_output}"
        cp "${temphd}" "${hist_output}"
    fi
fi


if [[ -n "${lout}" ]] ; then
    output="${OUT_DIR}/${name}.lout"
    [[ -n "${verbose}" ]] && echo "cp ${templ} ${output}"
    cp "${templ}" "${output}"
fi

if [[ -n "${check}" ]] ; then
    if [[ -n "${dot}" ]] ; then
        output="${TEMP_DIR}/${name}.dot.pdf"
        dot_params="-T pdf"
        [[ -n "${verbose}" ]] && echo "dot ${dot_params} ${tempd} ${output}"
        dot ${dot_params}  "${tempd}" > "${output}"
        ret="$?"
        [[ "${ret}" != "0" ]] && error_exit "error in dot script ${tempd}" "" "${ret}"
        if [[ -n "${hist_table}"  && -z "${svg}" ]] ; then
            hist_output="${TEMP_DIR}/${name}.hist.dot.pdf"
            dot_params="-T pdf"
            [[ -n "${verbose}" ]] && echo "dot ${dot_params} ${temphd} ${hist_output}"
            dot ${dot_params}  "${temphd}" > "${hist_output}"
            ret="$?"
            [[ "${ret}" != "0" ]] && error_exit "error in dot script ${temphd}" "" "${ret}"
       
        fi
    fi

    if [[ -n "${lout}" ]] ; then
        lout_cr_file="${TEMP_DIR}/${name}"
        output="${TEMP_DIR}/${name}.lout.pdf"
        lout_params="-r${repeat} -c "${lout_cr_file}" -Z -I ${DTD_DIR}"
        [[ -n "${verbose}" ]] && echo "lout ${lout_params} -o ${output} ${templ}"
        lout ${lout_params} -o "${output}" "${templ}"
        ret="$?"
        [[ "${ret}" != "0" ]] && error_exit "error in lout script ${templ}" "" "${ret}"
    fi
fi


if [[ -n "${svg}" ]] ; then
    temps0="${TEMP_DIR}/${name}.temp0.svg"
    temps1="${TEMP_DIR}/${name}.temp1.svg"
    temps2="${TEMP_DIR}/${name}.temp2.svg"

    output="${OUT_DIR}/${name}.svg"
    dot_params="-T svg"
    [[ -n "${verbose}" ]] && echo "dot ${dot_params} ${tempd} ${temps0}"
    dot ${dot_params}  "${tempd}" > "${temps0}"
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
    temphdp="${TEMP_DIR}/${name}.hist.dot.pdf"
    templp="${TEMP_DIR}/${name}.lout.pdf"
    lout_cr_file="${TEMP_DIR}/${name}"
    output="${PDF_DIR}/${name}.pdf"
    dot_params="-T pdf"
    
    [[ -n "${verbose}" ]] && echo "dot ${dot_params} ${tempd} ${tempdp}"
    dot ${dot_params}  "${tempd}" > "${tempdp}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in dot script ${tempd}" "" "${ret}"

    if [[ -n "${hist_table}" ]] ; then
        [[ -n "${verbose}" ]] && echo "dot ${dot_params} ${temphd} ${temphdp}"
        dot ${dot_params}  "${temphd}" > "${temphdp}"
        ret="$?"
        [[ "${ret}" != "0" ]] && error_exit "error in dot script ${temphd}" "" "${ret}"
    fi

    
    lout_params="-r${repeat} -c "${lout_cr_file}" -Z -I ${DTD_DIR}"
    [[ -n "${verbose}" ]] && echo "lout ${lout_params} -o ${templp} ${templ}"
    lout ${lout_params} -o "${templp}" "${templ}"
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in lout script ${templ}" "" "${ret}"

    [[ -n "${verbose}" ]] && echo "pdfunite  ${templp} ${tempdp} ${output}"

    
    if [[ -n "${hist_table}" ]] ; then
        pdfunite "${templp}" "${temphdp}" "${tempdp}" "${output}"
    else
        pdfunite "${templp}" "${tempdp}" "${output}"
    fi
    
    ret="$?"
    [[ "${ret}" != "0" ]] && error_exit "error in pdfunite" "" "${ret}"
fi



if [[ -z "${keep}" ]] ; then
    for file in "${tempd}" "${temphd}" "${templ}" "${templu}" "${tempdp}" "${templp}"  "${temps0}" \
                "${temps1}" "${temps2}" ; do
        if [[ -f "${file}" ]] ; then
            [[ -n "${verbose}" ]] && echo "rm  ${file}"
            rm  "${file}"
        fi
    done

fi
    
exit "0"
