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


##
# code examples of pipelines
###

MSG_CMD_CMD1="Get a single scalar values "
SRC_CMD_CMD1="s1.json "
CMD_CMD1='.spec.replicas' 

MSG_CMD_CMD1a="Get a single scalar values (different form, as a pipeline) "
SRC_CMD_CMD1a="s1.json "
CMD_CMD1a='.spec | .replicas' 

MSG_CMD_CMD1b="Get two scalar values"
SRC_CMD_CMD1b="s1.json "
CMD_CMD1b='.spec.replicas, .kind' 

MSG_CMD_CMD2="Get two scalar values and concatenate/format them into a single string"
SRC_CMD_CMD2="s1.json "
CMD_CMD2='"replicas: " + (.spec.replicas | tostring) + " kind: " + .kind' 

MSG_CMD_CMD3="Select an object from an array of object based on one of the names"
SRC_CMD_CMD3="dep.json "
CMD_CMD3='.status.conditions | map(select(.type ==  "Progressing"))' 

MSG_CMD_CMD4="Select a single key value pair from a json object"
SRC_CMD_CMD4="ann.json"
CMD_CMD4='.metadata.annotations | to_entries | map(select(.key == "label1")) | from_entries'

MSG_CMD_CMD5="Select two key value pairs from a json object"
SRC_CMD_CMD5="ann.json"
CMD_CMD5='.metadata.annotations | to_entries | map(select(.key == "label1" or .key == "label2")) | from_entries'

MSG_CMD_CMD5a="Select two key value pairs from a json object (second version)"
SRC_CMD_CMD5a="ann.json"
CMD_CMD5a='.metadata.annotations | to_entries | map(select(.key == ("label1", "label2"))) | from_entries '

MSG_CMD_CMD6='Select all key value pairs from a json object where the name contains substring "label"'
SRC_CMD_CMD6="ann.json"
CMD_CMD6='.metadata.annotations | to_entries | map(select(.key | contains("label"))) | from_entries'

MSG_CMD_CMD6a='Select all key value pairs from a json object where the name matches the regular expression label[1-9]'
SRC_CMD_CMD6a="ann.json"
CMD_CMD6a=' .metadata.annotations | to_entries | map(select(.key | test("label[1-9]"))) | from_entries '

MSG_CMD_CMD7='Add another key value pair to a json object'
SRC_CMD_CMD7="ann.json"
CMD_CMD7='.metadata.annotations  += { "label4" : "two" }'

MSG_CMD_CMD8='Set all values in a json object'
SRC_CMD_CMD8="ann.json"
CMD_CMD8='.metadata.annotations | to_entries | map_values(.value="override-value") | from_entries'

###
# other parameters
###
OUT_DIR=dir
#LINK_ATTRIB="target=\"example\""

function init() {
    if [ ! -d "$OUT_DIR" ]; then
      mkdir "$OUT_DIR"
    else 
      rm -f ${OUT_DIR}/*
    fi
    cp template/* ${OUT_DIR}/
    EXAMPLE=-1
}

function init_step() {
    EXAMPLE=$((${EXAMPLE}+1))

    if [[ "$LINK_TEXT" != "" ]]; then
      cat >>${OUT_DIR}/content.html <<EOF
$LINK_TEXT
</code>
<br/>
<br/>

EOF
    fi

    cat >>${OUT_DIR}/content.html <<EOF
<h2>${TITLES[$EXAMPLE]}<h2>
<br/>
<code>

EOF

     EXAMPLE_STAGE=1
     LINK_TEXT=""
}

function eof_step() {
    echo "$LINK_TEXT" >>${OUT_DIR}/content.html
}

function add_text() {
    LINK_TEXT="$LINK_TEXT $@"
}

function add_link() {
    local url="$1" 
    local text="$2"
    local link_text

    link_text="<a href=\"${url}\" ${LINK_ATTRIB}>${text}</a>"
    add_text "$link_text"
}

function next_step_file_name() {

    EXAMPLE_STAGE=$((${EXAMPLE_STAGE}+1))
    STEP_LINK="step_${EXAMPLE}_${EXAMPLE_STAGE}.html"
    STEP_FILE="${OUT_DIR}/${STEP_LINK}"
}

function add_stage_file() {
    local text="$1"
    local title="$2"

    next_step_file_name

    cat >${STEP_FILE} <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>title</title>
    <link rel="stylesheet" href="github-markdown.css">
  </head>
  <body class="markdown-body">
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
  </body>
</html>
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

    cat >${STEP_FILE} <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>title</title>
    <link rel="stylesheet" href="github-markdown.css">
  </head>
  <body class="markdown-body">

    <h1>jq '$t'</h1>
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
  </body>
</html>
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
