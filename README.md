# Open-Project Installation

Read the docs:

- [https://www.openproject.org/docs/installation-and-operations/installation/docker/#all-in-one-container](https://www.openproject.org/docs/installation-and-operations/installation/docker/#all-in-one-container)
- [https://computingforgeeks.com/how-to-install-openproject-community-edition-on-ubuntu/](https://computingforgeeks.com/how-to-install-openproject-community-edition-on-ubuntu/)

## All-in-one container

```sh
pwd

export ACCESSKEY=$(openssl rand -hex 64)
echo $ACCESSKEY

docker run -it -p 8080:80 \
  -e SECRET_KEY_BASE=$ACCESSKEY \
  -e OPENPROJECT_HOST__NAME=localhost:8080 \
  -e OPENPROJECT_HTTPS=false \
  -e OPENPROJECT_DEFAULT__LANGUAGE=en \
  openproject/openproject:17
```

This will take a bit of time the first time you launch it, but after a few minutes you should see a success message indicating the default administration password (login: admin, password: admin).

```console
[211] Puma starting in cluster mode...
[211] * Puma version: 7.2.0 ("On The Corner")
[211] * Ruby version: ruby 4.0.2 (2026-03-17 revision d3da9fec82) +YJIT +PRISM [x86_64-linux]
[211] *  Min threads: 4
[211] *  Max threads: 16
[211] *  Environment: production
[211] *   Master PID: 211
[211] *      Workers: 2
[211] *     Restarts: (✔) hot (✖) phased (✖) refork
[211] * Preloading application
[211] * Listening on http://0.0.0.0:8080
[211] Use Ctrl-C to stop
[211] - Worker 0 (PID: 541) booted in 0.01s, phase: 0
[211] - Worker 1 (PID: 545) booted in 0.0s, phase: 0
I, [2026-06-01T10:14:23.074392 #217]  INFO -- : [GoodJob] GoodJob started cron with 17 jobs.
I, [2026-06-01T10:14:23.109468 #217]  INFO -- : [GoodJob] Notifier subscribed with LISTEN
```

You can then launch a browser and access your new OpenProject installation at http://localhost:8080. Easy!

To stop the container, simply hit CTRL-C.

Note that the above command will not daemonize the container and will display the logs to your terminal, which helps with debugging if anything goes wrong. For normal usage you probably want to start it in the background, which can be achieved with the -d flag:

## get an API Token

Read the [doc](https://www.openproject.org/docs/api/example/#basic-auth)

## Configure SMTP Gateway


An API key can be generated on the “Access token” page within the “My account” section by clicking on the “Generate” or “Reset” (depending on whether a key already exists) link within the “API” row.

Read the [doc](https://www.openproject.org/docs/installation-and-operations/configuration/outbound-emails/#docker-installation)

Just replace SMTP_PASSWORD with the API key you’ve generated and you should be good to go). Please note that this will disable the settings in the administration UI.

```sh

export OPENPROJECT_SMTP__PASSWORD=""
echo $OPENPROJECT_SMTP__PASSWORD

sudo mkdir -p /var/lib/openproject/{pgdata,assets}
ls -al /var/lib/openproject

docker run -d -p 8080:80 \
-e SECRET_KEY_BASE=$ACCESSKEY \
-e OPENPROJECT_HOST__NAME=localhost:8080 \
-e OPENPROJECT_HTTPS=false \
-e OPENPROJECT_DEFAULT__LANGUAGE=en \
-e OPENPROJECT_EMAIL__DELIVERY__METHOD=smtp \
-e OPENPROJECT_SMTP__ADDRESS=smtp.sendgrid.net \
-e OPENPROJECT_SMTP__PORT=587 \
-e OPENPROJECT_SMTP__DOMAIN=my.domain.com \
-e OPENPROJECT_SMTP__AUTHENTICATION=login \
-e OPENPROJECT_SMTP__ENABLE__STARTTLS__AUTO=true \
-e OPENPROJECT_SMTP__USER__NAME="apikey" \
-e OPENPROJECT_SMTP__PASSWORD=$API_TOKEN \
-v /var/lib/openproject/pgdata:/var/openproject/pgdata \
-v /var/lib/openproject/assets:/var/openproject/assets \
openproject/openproject:17

# The volume exists independently of any container
docker volume ls

```


```sh
# Check container status
docker container ls
docker container inspect 232f06febc1c | grep -i Volumes
docker container inspect 232f06febc1c | grep -i Status
# mount to  "/var/openproject/assets", /var/openproject/pgdata

sudo ls /var/lib/docker/volumes/
docker container logs --tail 10 232f06febc1c

# to stop container: docker container stop 232f06febc1c
# to start container: docker container start 232f06febc1c

```

## Check persistent storage

Read [https://www.selfhostedninja.com/openproject-self-hosting-made-simple/](https://www.selfhostedninja.com/openproject-self-hosting-made-simple/)

```sh
sudo ls -al /var/lib/docker/volumes/
```

# Users Bulk Import

Read the [doc](https://www.openproject.org/docs/api/endpoints/users/#create-user)

Check the API endpoint, ex: http://localhost:8080/api/v3/users

```sh
# Set you USER and Password below
export USR_PWD=""
export API_ENDPOINT="http://localhost:8080/api/v3/users"
export API_TOKEN=""

# Read Excel file, format is: Département | NOM Prénom	| Rôle

# Count the number of users

# Loop for Eah user, Call the API with the API bearer Token with POST method

#ex:
#
#  "login": "j.sheppard",
#  "password": "foo",
#  "currentPassword": "foo",
#  "firstName": "John",
#  "lastName": "Doe",
#  "email": "bob@gmail.com",
#  "admin": false
#  "status": "active",
#  "language": "en"
#

echo "About to create users:"
echo ""
# Read user data from a CSV file
while IFS=';' read -r first_name last_name; do
    # Check if names are not empty
    if [[ ! -z "$first_name" && ! -z "$last_name" ]]; then
        # email adress must be unique otherwise API will throws error "message":"Email has already been taken."
        email="${first_name}.${last_name}@lecnam.net"
        user_payload=$(cat <<EOF
{
  "login": "${first_name:0:1}.${last_name}",
  "password": "$USR_PWD",
  "firstName": "$first_name",
  "lastName": "$last_name",
  "email": "${email}",
  "admin": false,
  "status": "active",
  "language": "en"
}
EOF
)

        # to trim whitespace: user_payload="{\"login\": \"${first_name:0:1}.${last_name//[[:space:]]/}\", \"password\": \"$USR_PWD\", \"firstName\": \"$first_name\", \"lastName\": \"${last_name//[[:space:]]/}\", \"email\": \"${email//[[:space:]]/}\", \"admin\": false, \"status\": \"active\", \"language\": \"en\"}"
        
        #echo ""
        #echo $user_payload
        #echo ""

        # Send request and capture response
        response=$(curl -X POST -k "$API_ENDPOINT" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$user_payload")
        
        # Log user creation result
        # echo "Response for user $first_name $last_name: $response"

    fi
done < users_to_import.csv


```

# Add Users to Group

read the [API doc](https://www.openproject.org/docs/api/endpoints/groups/#update-group)
read [pagination doc](https://www.openproject.org/docs/api/collections/)

```sh

# 1. Get ALL users
export API_ENDPOINT="http://localhost:8080/api/v3"
export MSP_GROUP_ID=220 # MSP
export MSP_GROUP_NAME=MSP

export CLIENT_GROUP_ID=221
export CLIENT_GROUP_NAME=Client

pageSize=20

# Fetch the first page of users
response=$(curl -s -X GET -k "$API_ENDPOINT/users?offset=$offset&pageSize=$pageSize" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json')

# Get total number of users from the response
total_users=$(echo "$response" | jq -r '.total')
echo "Total users: $total_users"

# Calculate total pages
total_pages=$(( (total_users + pageSize - 1) / pageSize ))
echo "Total pages: $total_pages"

# Collect all users from all pages
all_users=$(
    for (( i=1; i <= total_pages; i++ )); do
            # les echo de debug (ligne 221, 228) envoient du texte vers stdout qui se retrouve 
            # dans le pipeline jq. Jq reçoit donc du texte mélangé avec du JSON, 
            # Il faut rediriger les echo vers stderr avec >&2 :
            echo "Fetching page $i (offset=$i)" >&2

            # Fetch the page
            response=$(curl -s -X GET -k "$API_ENDPOINT/users?offset=$i&pageSize=$pageSize" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json')
            
            # Check if we have elements in this page
            count=$(echo "$response" | jq -r '.count')
            if [ "$count" -eq 0 ]; then
                echo "No more users, stopping pagination" >&2
                break
            fi
            
            # Get total for info
            #if [ "$i" -eq 1 ]; then
            #    total=$(echo "$response" | jq -r '.total')
            #    echo "Total users in API: $total" >&2
            #fi
            
            # Output each element (one per line)
            echo "$response" | jq -c '._embedded.elements[]'
        done | jq -s '.'  # Combine all elements into a single array
)

# Output the total users retrieved
echo "Total users retrieved: $(echo "$all_users" | jq 'length')"

# Step 2: Filter users by category

# Extract MSP users (firstName starts with 'MSP')
msp_usr_array=$(echo "$all_users" | jq '[.[] | select(.firstName | startswith("MSP"))]')
echo "MSP users count: $(echo "$msp_usr_array" | jq 'length')" >&2

# Extract Client users (firstName does NOT start with 'MSP')
client_usr_array=$(echo "$all_users" | jq '[.[] | select(.firstName | startswith("MSP") | not)]')
echo "Client users count: $(echo "$client_usr_array" | jq 'length')" >&2

# Step 3: Add MSP users to MSP group
msp_member_hrefs=$(echo "$msp_usr_array" | jq -r '.[]._links.self.href')
msp_members_json=$(echo "$msp_member_hrefs" | jq -R '.' | jq -s 'map({"href": .})')

patch_url="$API_ENDPOINT/groups/$MSP_GROUP_ID"
echo "Patching MSP group: $patch_url" >&2

msp_payload=$(jq -n --argjson members "$msp_members_json" '{
  "name": "'"$MSP_GROUP_NAME"'",
  "_links": {
    "members": $members
  }
}')

echo "MSP Payload:" >&2
echo "$msp_payload" | jq '.' >&2

msp_response=$(curl -X PATCH -k "$patch_url" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$msp_payload")
echo "Response for MSP group:" >&2
echo "$msp_response" | jq '.' >&2

# Step 4: Add Client users to Client group
client_member_hrefs=$(echo "$client_usr_array" | jq -r '.[]._links.self.href')
client_members_json=$(echo "$client_member_hrefs" | jq -R '.' | jq -s 'map({"href": .})')

patch_url="$API_ENDPOINT/groups/$CLIENT_GROUP_ID"
echo "Patching Client group: $patch_url" >&2

client_payload=$(jq -n --argjson members "$client_members_json" '{
  "name": "'"$CLIENT_GROUP_NAME"'",
  "_links": {
    "members": $members
  }
}')

echo "Client Payload:" >&2
echo "$client_payload" | jq '.' >&2

client_response=$(curl -X PATCH -k "$patch_url" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$client_payload")
echo "Response for Client group:" >&2
echo "$client_response" | jq '.' >&2

```

## To remove Users from Group


for user_id in $client_usr_array; do
    # Add Client user to the Client group
    patch_url="http://localhost:8080/api/v3/groups/$CLIENT_GROUP_ID"
    payload=$(cat <<EOF
{
  "_links": {
    "members": [
      {
        "href": "/api/v3/users/$user_id"
      }
    ]
  }
}
EOF
)


    # Step 3: Execute PATCH request
    response=$(curl -X PATCH -k "$patch_url" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$payload")

    # Log response or handle errors
    echo "Response for user ID $user_id added to group $MSP_GROUP_ID: $response"
done


        # Send request and capture response
        response=$(curl -X PATCH -k "$API_ENDPOINT" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$payload")

    done

echo ""


export PROJECT_ID=3
```






## To remove Users from Group

```sh
export MSP_GROUP_ID=220

grp_get_url="$API_ENDPOINT/groups/$MSP_GROUP_ID"
echo "Group API GET URL: $grp_get_url"

response=$(curl -s -X GET -k "$grp_get_url" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json')

# Extract members using the correct jq syntax
member_list=$(echo "$response" | jq -r '.members')
# echo "$member_href"

for user_id in $member_href; do
    curl -X DELETE -k "$URL_ENDPOINT$user_id" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json'
    #echo "User: $URL_ENDPOINT$user_id"
done

```