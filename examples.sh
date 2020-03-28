
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

MSG_CMD_CMD4a="Select a single key value pair from a json object - short form"
SRC_CMD_CMD4a="ann.json"
CMD_CMD4a='.metadata.annotations | with_entries(select(.key == "label1"))'


MSG_CMD_CMD5="Select two key value pairs from a json object"
SRC_CMD_CMD5="ann.json"
CMD_CMD5='.metadata.annotations | to_entries | map(select(.key == "label1" or .key == "label2")) | from_entries'

MSG_CMD_CMD5a="Select two key value pairs from a json object (second version)"
SRC_CMD_CMD5a="ann.json"
CMD_CMD5a='.metadata.annotations | to_entries | map(select(.key == ("label1", "label2"))) | from_entries '

MSG_CMD_CMD6='Select all key value pairs from a json object where the name contains substring "label"'
SRC_CMD_CMD6="ann.json"
CMD_CMD6='.metadata.annotations | to_entries | map(select(.key | contains("label"))) | from_entries'

MSG_CMD_CMD6aa='Select all key value pairs from a json object where the name contains substring "label" (short form)'
SRC_CMD_CMD6aa="ann.json"
CMD_CMD6aa='.metadata.annotations | with_entries(select(.key | contains("label")))'


MSG_CMD_CMD6a='Select all key value pairs from a json object where the name matches the regular expression label[1-9]'
SRC_CMD_CMD6a="ann.json"
CMD_CMD6a=' .metadata.annotations | to_entries | map(select(.key | test("label[1-9]"))) | from_entries '

MSG_CMD_CMD7='Add another key value pair to a json object'
SRC_CMD_CMD7="ann.json"
CMD_CMD7='.metadata.annotations  += { "label4" : "two" }'

MSG_CMD_CMD8='Set all values in a json object'
SRC_CMD_CMD8="ann.json"
CMD_CMD8='.metadata.annotations | to_entries | map_values(.value="override-value") | from_entries'


MSG_CMD_CMD8aa='Set all values of subset of keys in a json object'
SRC_CMD_CMD8aa="ann.json"
CMD_CMD8aa='.metadata.annotations | to_entries | map(if .key  | contains("label") then .value="kuku" else .  end) | from_entries'

