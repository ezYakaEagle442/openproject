#!/usr/bin/env bash

export USR_EMAIL=''
export USR_PWD=''
export API_ENDPOINT='http://localhost:8080/api/v3/users'
export API_TOKEN=''

# Read user data from a CSV file
while IFS=';' read -r first_name last_name; do
    # Check if names are not empty
    if [[ ! -z "$first_name" && ! -z "$last_name" ]]; then

        user_payload="\"login\": \"${first_name:0:1}.${last_name}\", \"password\": \"$USR_PWD\", \"firstName\": \"$first_name\", \"lastName\": \"$last_name\", \"email\": \"${USR_EMAIL}\", \"admin\": false, \"status\": \"active\", \"language\": \"en\""
        curl -X POST -k $API_EDNPOINT -H Authorization:Bearer ${API_TOKEN} -H 'Content-Type: application/json' -d 
    fi
done < users_to_import.csv

