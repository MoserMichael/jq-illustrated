#!/bin/bash

set -x

function trace_on_total
{
    SCRIPT_TRACE_ON=1
    OLD_PS4=$PS4
    export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -x
}

trace_on_total

source "examples.sh"

###
# other parameters
###
OUT_DIR=dir-single-file
#LINK_ATTRIB="target=\"example\""
OFILE=content.html


function init() {
    if [ ! -d "$OUT_DIR" ]; then
      mkdir "$OUT_DIR"
    else 
      rm -f ${OUT_DIR}/*
    fi
    cp template/* ${OUT_DIR}/
    EXAMPLE=-1

    TMPFILE=$(mktemp /tmp/scr-one-file.XXXXX)

    set -x
    cat "${OUT_DIR}/content_start.html" >>${OUT_DIR}/${OFILE}
    cat "${OUT_DIR}/jscript.html" >>${OUT_DIR}/${OFILE}
    cat "${OUT_DIR}/content_end.html" >>${OUT_DIR}/${OFILE}

}

function init_step() {
    EXAMPLE=$((${EXAMPLE}+1))

    if [[ "$LINK_TEXT" != "" ]]; then
      cat >>${OUT_DIR}/${OFILE} <<EOF
$LINK_TEXT
</code>
<br/>
<br/>

EOF
        cat $TMPFILE >>${OUT_DIR}/${OFILE}
    fi

    cat >>${OUT_DIR}/${OFILE} <<EOF
<h2>${TITLES[$EXAMPLE]}<h2>
<br/>

EOF

     echo "" >${TMPFILE}

     EXAMPLE_STAGE=1
     LINK_TEXT=""
}

function eof_step() { 

    cat $TMPFILE >>${OUT_DIR}/${OFILE}
    echo "$LINK_TEXT" >>${OUT_DIR}/${OFILE}
    rm -f "$TMPFILE"
} 

function add_text() {
    LINK_TEXT="$LINK_TEXT $@"
}

function add_link() {
    local divid="$1" 
    local text="$2"
    local link_text

    link_text="<a onclick=\"show_div('${divid}')\" href=\"javascript:void(0);\"  ${LINK_ATTRIB}>${text}</a>"
    add_text "$link_text"
}

function next_step_file_name() {

    EXAMPLE_STAGE=$((${EXAMPLE_STAGE}+1))
    STEP_LINK="step_${EXAMPLE}_${EXAMPLE_STAGE}.html"
}

function add_stage_file() {
    local text="$1"
    local title="$2"

    next_step_file_name

    cat >>${TMPFILE} <<EOF
    <div id="${STEP_LINK}" style="display:none">
    <table>
        <tr>
            <th>
$title
            </th>
        </tr>
        <tr>
            <td>
    <pre>
${text}
    </pre>
            </td>
        </tr>
    </table>
    </div>
EOF
 
}

function find_jq_token {
    local arg="$1"  
    local pos=0 
    local nesting=0
    local slen=${#arg}

    while [ "$pos" -lt "$slen" ]; do

        ch=${arg:$pos:1}

        if [ "$nesting" -eq "0" ]; then 
            if [[ "$ch" = "|" ]]; then 
               echo "$pos"
               return
           fi
        fi

        if [[ $ch == "(" ]]; then
           nesting=$(($nesting+1))
        elif [[ $ch == ")" ]]; then
           nesting=$(($nesting-1))
        fi
        pos=$((pos+1))
    done
    echo "$pos"
}

function tokenize {
    local -n rarray=$1
    local pline="$2"
    local tokparser="$3"
    local slen=${#pline}


    pos=0
    rarray=()

    while [ $pos -lt $slen ]; do
        toklen=$($tokparser "${pline:${pos}}")
        rarray+=("${pline:${pos}:${toklen}}")        
        pos=$(($pos+$toklen+1))
    done
}

function make_jq_step() {
    local t="$1"
    local cmd_now="$2"
    local cmd_dat_now="$3"
    local cmd_prev="$4"
    local cmd_dat_prev="$5"

    #add_text "$t"

    next_step_file_name

    add_link "${STEP_LINK}" "$t"

    cat >>${TMPFILE} <<EOF

    <div id="${STEP_LINK}" style="display:none">
    <!-- <b>jq '$t'</b> //-->
    <table>
        <tr>
            <th>
$cmd_prev
            </th>
            <th>
$cmd_now
            </th>
        </tr>
        <tr>
            <td>
    <pre>
$cmd_dat_prev
    </pre>
            </td>
            <td>
    <pre>
$cmd_dat_now
    </pre>
            </td>
        </tr>
    </table>
    </div>
EOF
     
}

function run_it() {

    #run it all
    mystuff=$(declare | grep -E '^CMD' | sed -n 's#\([^=]*\)=.*$#\1#p')
 
    TITLES=()
    while IFS= read -r line; do 
         declare -n smsg="MSG_${line}"
         TITLES+=( "${smsg}" )
    done <<< "$mystuff"
    
    init
    
    while IFS= read -r line; do 

            init_step

            echo "<h3 style='markdown-body'>example: $line</h3>"
            declare -n sfile="SRC_${line}"

            cat "data/$sfile" | jq "${!line}"

            #IFS='|' read -ra TOKENS <<< "${!line}"
            tokenize TOKENS "${!line}" find_jq_token

#           echo "line: ${!line}"
#           for each in "${TOKENS[@]}"; do
#               echo "token: $each"
#           done
                
            ### link for source of pipline
            partial_cmd=""
            PART_JSON=`cat data/$sfile`

            add_stage_file "$PART_JSON"  "cat $sfile"

            add_text "cat "
            add_link "${STEP_LINK}" "$sfile "  
            add_text " | jq '"

            first_step="1"
            for t in "${TOKENS[@]}"; do

                prev_partial_cmd="$partial_cmd"
                PREV_PART_JSON="$PART_JSON"

                if [[ $first_step == "1" ]]; then
                    partial_cmd=$t
                else
                    add_link  "${STEP_LINK}" " | "
                    partial_cmd=$partial_cmd" | "$t
                fi

                PART_JSON=$(cat data/$sfile | jq "$partial_cmd")

                prev_cmd_title=""
                if [[ $prev_partial_cmd  != "" ]]; then
                    prev_cmd_title=" | jq '$prev_partial_cmd'"
                fi

                make_jq_step "$t" "cat data/$sfile | jq '$partial_cmd'" "$PART_JSON" "cat data/$sfile $prev_cmd_title" "$PREV_PART_JSON"
      
                add_stage_file "${PART_JSON}" "cat data/$sfile | jq \"$partial_cmd\""

                first_step="0"
            done

            add_text  "'"

            
    done <<< "$mystuff"

    eof_step
}

run_it
echo "*** eof ***"
