#!/bin/bash

script_dir=`dirname $0`
my_token=`cat dirname $script_dir/my_token`
echo $my_token

resource_url="http://localhost:41184/resources?token=$my_token"
note_url="http://localhost:41184/notes?token=$my_token"
# resource_url='http://localhost:41184/resources?token=1c8a32e6698985751466e787f64576c787321494dbdf53e463e752d27756012d6642dbead44bd191e63a7dac1536d03a2032c7d53c1ed1133dc3a4fcf0620377'
# note_url='http://localhost:41184/notes?token=1c8a32e6698985751466e787f64576c787321494dbdf53e463e752d27756012d6642dbead44bd191e63a7dac1536d03a2032c7d53c1ed1133dc3a4fcf0620377'

path="$1"
filename_pdf="$2"
filename_txt="$3.txt"

echo "filename_pdf= $filename_pdf"
echo "filename = $filename_txt"

# Change working directory to $path
cd "$path"

# Extract the text from the PDF
echo "---Exctracting text from PDF"
pdf2txt.py "$filename_pdf" >"$filename_txt"

# upload PDF to Joplin
echo "---Uploading $filename_pdf to Joplin"
output=`curl -X POST --url $resource_url \
-F "data=@$filename_pdf" \
-F "props={\"title\":\"$filename_pdf\"}"`

resource_id=`echo "$output"|cut -d, -f1|cut -d: -f2|sed 's/"//g'`

echo "---Output"
echo "$output"
echo "  "
echo "resource id: $resource_id"

# Create associated note in Joplin
echo "---Creating note with resource and text in Joplin"
read -r -d '' payload << EOM
{
    "title": "$filename_pdf",
    "body": "[$filename_pdf](:/$resource_id)\n# File content\n `jq -Rs . "$filename_txt"|sed 's/"//g'`"
}
EOM

output=`curl -X POST --url $note_url \
--data "$payload"`

echo "---Output"
echo "$output"

# Cleanup (delete files)
echo "---Cleanup uploaded files"
rm "$path/$filename_pdf" "$path/$filename_txt"