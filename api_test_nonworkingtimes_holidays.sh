#!/usr/bin/env bash

export PROJECT_ID=3
export PROJECT_PROJECT_MANAGER_USR_ID=223
export API_HOST="http://localhost:8080"
export API_ENDPOINT_USR="$API_HOST/api/v3/users"
export API_ENDPOINT_DAYS_NW="$API_HOST/api/v3/days/non_working"

echo "API_HOST: $API_HOST"
echo "API_ENDPOINT_USR: $API_ENDPOINT_USR"
echo "API_TOKEN: $API_TOKEN"

echo "Setting up environment variables..."
echo "API_HOST: $API_HOST"
echo "API_ENDPOINT_USR: $API_ENDPOINT_USR"
echo "API_TOKEN: $API_TOKEN"

# Read user data from a CSV file
# Format user_id;startDate;endDate dates are in ISO 8601 format (YYYY-MM-DD)
# /!\ IMPORTANT: The date range must not overlap with an existing non-working time record for the same user.

while IFS=';' read -r user_id start_date end_date; do
    echo "Checking USER with ID $user_id, Start Date: $start_date, End Date: $end_date" >&2

    # DEBUG: Affiche les valeurs brutes et leurs longueurs
    echo "DEBUG: user_id='$user_id' (len=${#user_id})" >&2
    echo "DEBUG: start_date='$start_date' (len=${#start_date})" >&2
    echo "DEBUG: end_date='$end_date' (len=${#end_date})" >&2
    
    # Check if fields are not empty
    if [[ ! -z "$user_id" && ! -z "$start_date"  && ! -z "$end_date" ]]; then
        nwt_payload=$(cat <<EOF
{
  "startDate": "$start_date",
  "endDate": "$end_date"
}
EOF
)
        echo "Payload for user ${user_id}: $nwt_payload"  # Log payload
        echo "$nwt_payload" | jq '.'  # Check if valid JSON
        echo "Non-Working Times for user ${user_id}: ${nwt_payload}" >&2

        API_ENDPOINT_USR_NWT="$API_ENDPOINT_USR/$user_id/non_working_times"
        echo "API Endpoint: $API_ENDPOINT_USR_NWT"  # Log endpoint

        # Send request and capture response
        response=$(curl -X POST -k "$API_ENDPOINT_USR_NWT" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$nwt_payload")
        
        # Log user creation result
        echo "Response for Staff holidays: $response" >&2

    else 
        echo "CSV file has empty data user_id: $user_id" >&2
    fi
done < nonworkingtimes_holidays_to_import.csv

echo "Script execution completed."

cat nonworkingtimes_holidays_to_import.csv
echo ""

wc -l nonworkingtimes_holidays_to_import.csv
head -10 nonworkingtimes_holidays_to_import.csv | cat -A  # Pour voir les espaces/caractères spéciaux

tail -c 1 nonworkingtimes_holidays_to_import.csv | od -c
# Affichera : 5 (le dernier caractère de "15") au lieu de "\n"