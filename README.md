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
export API_HOST="http://localhost:8080"
export API_ENDPOINT_USR="$API_HOST/api/v3/users"
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

        # si last_name a un espace alors OpenPoject ne va pas valider l'adresse email ,
        # ex: Caroline.Von Zimmer@lecnam.net

        last_name_clean="${last_name// /-}"        # remplace espaces par tirets
        email="${first_name,,}.${last_name_clean,,}@lecnam.net"  # tout en minuscules

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
        response=$(curl -X POST -k "$API_ENDPOINT_USR" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$user_payload")
        
        # Log user creation result
        # echo "Response for user $first_name $last_name: $response"

    fi
done < users_to_import.csv

wc -l users_to_import.csv
head -185 users_to_import.csv | cat -A  # Pour voir les espaces/caractères spéciaux
```

# Add Users to Groups

read the [API doc](https://www.openproject.org/docs/api/endpoints/groups/#update-group)
read [pagination doc](https://www.openproject.org/docs/api/collections/)

```sh

# 1. Get ALL users
export MSP_GROUP_ID=220 # MSP
export MSP_GROUP_NAME=MSP

export CLIENT_GROUP_ID=221
export CLIENT_GROUP_NAME=Client

pageSize=20

# Fetch the first page of users
response=$(curl -s -X GET -k "$API_ENDPOINT_USR?offset=$offset&pageSize=$pageSize" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json')

# Get total number of users from the response
total_users=$(echo "$response" | jq -r '.total')
echo "Total users: $total_users"

# Calculate total pages
total_pages=$(( (total_users + pageSize + 1) / pageSize ))
echo "Total pages: $total_pages"

# Collect all users from all pages
all_users=$(
    for (( i=1; i <= total_pages; i++ )); do
            # les echo de debug (ligne 221, 228) envoient du texte vers stdout qui se retrouve 
            # dans le pipeline jq. Jq reçoit donc du texte mélangé avec du JSON, 
            # Il faut rediriger les echo vers stderr avec >&2 :
            echo "Fetching page $i (offset=$i)" >&2

            # Fetch the page
            response=$(curl -s -X GET -k "$API_ENDPOINT_USR?offset=$i&pageSize=$pageSize" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json')
            
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

echo "$all_users" | jq '.[] | .firstName' | head -20
echo "$all_users" | jq -r '.[] | .firstName' | grep -i "^msp" | wc -l
echo "$all_users" | jq -r '.[] | .firstName' | grep -i "^msp " | wc -l

# check: sed -n '36,186p' users_to_import.csv | head -20

# Extract MSP users (firstName starts with 'MSP')
msp_usr_array=$(echo "$all_users" | jq '[.[] | select(.firstName | startswith("MSP"))]')
echo "MSP users count: $(echo "$msp_usr_array" | jq 'length')"

# Extract Client users (firstName does NOT start with 'MSP')
client_usr_array=$(echo "$all_users" | jq '[.[] | select(.firstName | startswith("MSP") | not)]')
echo "Client users count: $(echo "$client_usr_array" | jq 'length')"

# Step 3: Add MSP users to MSP group
msp_member_hrefs=$(echo "$msp_usr_array" | jq -r '.[]._links.self.href')
msp_members_json=$(echo "$msp_member_hrefs" | jq -R '.' | jq -s 'map({"href": .})')

export API_ENDPOINT_GRP="$API_HOST/api/v3/groups"
patch_url="$API_ENDPOINT_GRP/$MSP_GROUP_ID"

echo "Patching MSP group: $patch_url"

msp_payload=$(jq -n --argjson members "$msp_members_json" '{
  "name": "'"$MSP_GROUP_NAME"'",
  "_links": {
    "members": $members
  }
}')

echo "MSP Payload:"
echo "$msp_payload" | jq '.'

# Add MSP users to Group MSP
msp_response=$(curl -X PATCH -k "$patch_url" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$msp_payload")
echo "Response for MSP group:"
echo "$msp_response" | jq '.'

# Add Client users to Client group
client_member_hrefs=$(echo "$client_usr_array" | jq -r '.[]._links.self.href')
client_members_json=$(echo "$client_member_hrefs" | jq -R '.' | jq -s 'map({"href": .})')

patch_url=$API_ENDPOINT_GRP/$CLIENT_GROUP_ID

client_payload=$(jq -n --argjson members "$client_members_json" '{
  "name": "'"$CLIENT_GROUP_NAME"'",
  "_links": {
    "members": $members
  }
}')

echo "Client Payload:"
echo "$client_payload" | jq '.' >&2
echo "Response for Client group with URL: $patch_url"

client_response=$(curl -X PATCH -k "$patch_url" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$client_payload")
echo "$client_response" | jq '.'

```


## To Add Team members to Project

Read the [API doc](https://www.openproject.org/docs/api/endpoints/projects/#update-project)

Go to the [UI](http://localhost:8080/projects/stargate/members?status=all) and add MSP & Client Groups to members of the Project

```sh
export PROJECT_ID=3


```

# Set labor Cost and set budget

## Set Reference Cost

Go to [UI](http://localhost:8080/admin/cost_types/new)

Create "MSP standard COST" with code "WU_MSP" with RATE=400€
Create "Client standard COST" with code "WU_CLIENT" with RATE=500€

## Set budget

Go to the [UI](http://localhost:8080/projects/stargate/budgets/new)

Read:
- [Budget API](https://www.openproject.org/docs/api/endpoints/budgets/)
- 

## Set Working days and hours

Go to [http://localhost:8080/admin/settings/working_days_and_hours](http://localhost:8080/admin/settings/working_days_and_hours)

Set 8 Hours per day
Duration format: Date and hours


### Set Working Times constraints


Check [List personal non-working times for a user](http://localhost:8080/api/v3/users/4/non_working_times)


Read the :
- [API doc](https://www.openproject.org/docs/api/endpoints/user-working-times/#usernonworkingtime-local-properties)
- [nonworkingday-actions API doc](https://www.openproject.org/docs/api/endpoints/work-schedule/#nonworkingday-actions)  (not implemented)
- ["Create a personal non-working day for a user" API doc](https://www.openproject.org/docs/api/endpoints/user-working-times/#create-a-personal-non-working-day-for-a-user)


/!\ IMPORTANT: The date range must not overlap with an existing non-working time record for the same user.

Le fichier CSV doit avoir un newline \n à la fin !

Required permissions:

    Administrators can create non-working days for any user.
    Users with the global manage_own_working_times permission can create records for themselves.
    Users with the global manage_working_times permission can create non-working days for any user.
Go to [http://localhost:8080/admin/roles/12/edit](http://localhost:8080/admin/roles/12/edit)

Check the box for : 
- Manage own working times: Allows users to manage their own working times, and personal non-working days. 
- Manage working times for all users: Allows users to manage working times for all users, including personal non-working days. 

Check 
- [API doc](https://github.com/opf/openproject/blob/dev/docs/api/apiv3/paths/user_non_working_times.yml#L81)
- [sample request](https://github.com/opf/openproject/blob/dev/docs/api/apiv3/components/schemas/non_working_day_model.yml#L35)


/!\ IMPORTANT: the Endpoint is NOT yet implemented in v17.4.0, you can check version using the [API](http://localhost:8080/api/v3/)


```sh
export PROJECT_ID=3
export PROJECT_PROJECT_MANAGER_USR_ID=223
export API_ENDPOINT_DAYS_NW="$API_HOST/api/v3/days/non_working"

# Read user data from a CSV file
# Format user_id;startDate;endDate dates are in ISO 8601 format (YYYY-MM-DD)


while IFS=';' read -r user_id start_date end_date; do

    nwt_id=1
    echo "Checking USER with ID $user_id, Start Date: $start_date, End Date: $end_date"
    # Check if fields are not empty
    if [[ ! -z "$user_id" && ! -z "$start_date"  && ! -z "$end_date" ]]; then
        nwt_payload=$(cat <<EOF
{
  "startDate": "$start_date",
  "endDate": "$end_date",
}
EOF
)
        echo "Payload for user ${user_id}: $nwt_payload"  # Log payload
        echo "$nwt_payload" | jq '.'  # Check if valid JSON
        echo "Non-Working Times for user ${user_id}: ${nwt_payload}"

        API_ENDPOINT_USR_NWT="$API_ENDPOINT_USR/$user_id/non_working_times"
        echo "API Endpoint: $API_ENDPOINT_USR_NWT"
        echo ""

        # Send request and capture response
        response=$(curl -X POST -k "$API_ENDPOINT_USR_NWT" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$nwt_payload")
        
        # Log user creation result
        echo "Response for Staff holidays: $response"

    else 
        echo "CSV file has empty data user_id: $user_id" >&2
    fi
    nwt_id++
done < nonworkingtimes_holidays_to_import.csv

wc -l nonworkingtimes_holidays_to_import.csv
head -10 nonworkingtimes_holidays_to_import.csv | cat -A  # Pour voir les espaces/caractères spéciaux




# Read user data from a CSV file
# Le fichier CSV n'a PAS de newline \n à la fin ! ==> il doit en avoir
while IFS=';' read -r nwd_type nwd_date nwd_name; do
    # Check if fields are not empty
    if [[ ! -z "$nwd_type" && ! -z "$nwd_date"  && ! -z "$nwd_name" ]]; then
        nwd_payload=$(cat <<EOF
{
  "_type": "${nwd_type}",
  "date": "${nwd_date}",
  "name": "${nwd_name}"
}
EOF
)
        echo "NWD: ${nwd_payload}" >&2

        # Send request and capture response
        response=$(curl -X POST -k "$API_ENDPOINT_DAYS_NW" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$nwd_payload")
        
        # Log user creation result
        echo "Response for Public holidays: $response" >&2

    else echo "CSV file has empty data" >&2
    fi
done < nonworkingday_to_import.csv



```


Check at [http://localhost:8080/admin/settings/working_days_and_hours](http://localhost:8080/admin/settings/working_days_and_hours) 

Jour de l'an			01/01/2026	
Lundi de pâques			06/04/2026	
Fête du travail			01/05/2026	
Le 08 Mai 45			08/05/2026	
Jeudi de l'ascension	14/05/2026	
Lundi de pentecôte		25/05/2026	
Fête nationale			14/07/2026	
Assomption			    15/08/2026	
La Toussaint			01/11/2026	
Armistice			    11/11/2026	
Noël			        25/12/2026	

Vacances scolaires – zone C:			
21/02/2026	au	09/03/2026	
18/04/2026	au	04/05/2026	
05/07/2026	au	31/08/2026	
17/10/2026	au	02/11/2026	
19/12/2026	au	04/01/2027	

TODO: rajouté 25 jours de vancances + 10 RTT


# Import Work-Packages

A WP can be a unit task or a Task Summary (that includes several Tasks)

Read the [API doc](https://www.openproject.org/docs/api/endpoints/work-packages/#list-work-packages)


## List WP

```sh
export API_ENDPOINT_WP="$API_HOST/api/v3/work_packages"

pageSize=20
# offset=1

# Fetch the first page of users
response=$(curl -s -X GET -k "$API_ENDPOINT_WP?offset=$offset&pageSize=$pageSize" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json')

# Get total number of WP from the response
total_wp=$(echo "$response" | jq -r '.total')
echo "Total Work Packages: $total_wp"

# Calculate total pages
total_pages=$(( (total_wp + pageSize + 1) / pageSize ))
echo "Total pages: $total_pages"

# Collect all users from all pages
all_wp=$(
    for (( i=1; i <= total_wp; i++ )); do
            # les echo de debug envoient du texte vers stdout qui se retrouve 
            # dans le pipeline jq. Jq reçoit donc du texte mélangé avec du JSON, 
            # Il faut rediriger les echo vers stderr avec >&2 :
            echo "Fetching page $i (offset=$i)" >&2

            # Fetch the page
            response=$(curl -s -X GET -k "$API_ENDPOINT_WP?offset=$i&pageSize=$pageSize" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json')
            
            # Check if we have elements in this page
            count=$(echo "$response" | jq -r '.count')
            if [ "$count" -eq 0 ]; then
                echo "No more WP, stopping pagination" >&2
                break
            fi
            
            # Get total for info
            if [ "$i" -eq 1 ]; then
                total=$(echo "$response" | jq -r '.total')
                echo "Total WP in API: $total" >&2
            fi
            
            # Output each element (one per line)
            echo "$response" | jq -c '._embedded.elements[]'
        done | jq -s '.'  # Combine all elements into a single array
)

# Output the total WP retrieved
echo "Total Work Packages retrieved: $(echo "$all_wp" | jq 'length')"


wp_id_array=$(echo "$all_wp" | jq '[.[] | select(.firstName | startswith("MSP"))]')

wp_id=$(echo "$all_wp" | jq '.[].id')
wp_task_name=$(echo "$all_wp" | jq '.[].subject' )
echo $wp_id | more
echo $wp_task_name | more

```

## Import WP

Read [API doc](https://www.openproject.org/docs/api/endpoints/work-packages/#create-work-package)

```sh
export API_ENDPOINT_WP="$API_HOST/api/v3/work_packages"
export API_ENDPOINT_RELATIONS="$API_HOST/api/v3/relations"
export API_ENDPOINT_PRIORITIES="$API_HOST/api/v3/priorities"
export API_ENDPOINT_PORTFOLIO="$API_HOST/api/v3/portfolio"
export API_ENDPOINT_STATUSES="$API_HOST/api/v3/statuses"
export API_ENDPOINT_types="$API_HOST/api/v3/types"
export API_ENDPOINT_VERSIONS="$API_HOST/api/v3/versions"

export PROJECT_ID=3
pageSize=20

# Yopu can check projectPhase	
# at http://localhost:8080/api/v3/project_phases/8 , ex: http://localhost:8080/api/v3/work_packages/37
# id 5 ==> "Initiating"
# id 6 ==> "Planning"
# id 7 ==> Executing
# id 8 ==> Closing
# http://localhost:8080/api/v3/project_phase_definitions/4

# Budgets: http://localhost:8080/api/v3/budgets/1
# 1: Budget Licences
# 2: Etude d’opportunité
# 3: RFP
# 4: Contractualisation
# 5: Formations Azure - 2026
# 6: Formations Azure - 2027
# 7: Formations Azure - 2028
# 8: Formations Standards - 2026
# 9: Formations Standards - 2027
# 10: Formations Standards - 2028
# 11: Formation Sans Institute - 2026
# 12: Formation Sans Institute - 2027
# 13: Formation Sans Institute - 2028
# 14: Coûts Infras / an - 2026
# 15: Coûts Infras / an - 2027
# 16: Coûts Infras / an - 2028
# 17: Augmentation du CA
# 18: Cost avoidance - Serveurs physiques
# 19: Gains - Excellence Opérationnelle 
# 20: Etude détaillée Cadrage
# 21: Project Cost - External MSP
# 22: Project Cost - Internal Staff

# CSV file format TASK_NAME;TASK_PHASE;BUDGET_ID;ASSIGNEE_ID;TASK_TYPE;DUE_DATE;PARENT_ID;RELATION_ID;
# Le fichier CSV doit  avoir newline \n à la fin !
while IFS=';' read -r task_name task_phase budget_id assigned_id task_type start_date due_date parent_id relation_id; do
    # Check if fields are not empty
    if [[ ! -z "$task_name" && ! -z "$assigned_id"  && ! -z "$parent_id" && ! -z "$start_date" && ! -z "$due_date" ]]; then

        # normalisation des dates : 2026-06-4 ==> devient 2026-06-04
        start_date=$(date -d "$start_date" +"%Y-%m-%d")
        due_date=$(date -d "$due_date" +"%Y-%m-%d")

        wp_payload=$(cat <<EOF
{
  "_type": "WorkPackage",
  "_links": {
    "responsible": {
      "href": "/api/v3/users/${assigned_id}"
    },
    "relations": {
      "href": "/api/v3/work_packages/${relation_id}/relations"
    },
    "assignee": {
      "href": "/api/v3/users/${assigned_id}"
    },
    "priority": {
      "href": "/api/v3/priorities/8"
    },
    "project": {
      "href": "/api/v3/projects/${PROJECT_ID}"
    },
    "budget": {
      "href": "/api/v3/budgets/${budget_id}"
    },
    "projectPhase": {
      "href": "/api/v3/project_phases/${task_phase}"
    }, 
    "status": {
      "href": "/api/v3/statuses/1"
    },
    "type": {
      "href": "/api/v3/types/${task_type}"
    },
    "parent": {
      "href": "/api/v3/work_packages/${parent_id}"
    }
  },
  "subject": "${task_name}",
  "description": {},
  "scheduleManually": true,
  "readonly": false,
  "startDate": "${start_date}",
  "dueDate": "${due_date}",
  "estimatedTime": "PT8H",
  "percentageDone": 0,
  "customField1": "Foo",
  "customField2": 42
}
EOF
)
        echo "Work-Package: ${wp_payload}" >&2

        # Send request and capture response
        response=$(curl -X POST -k "$API_ENDPOINT_WP" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$wp_payload")
        
        # echo "Response for Work Packages: $response" >&2
        # echo ${budget_id} >&2
        # echo ""

    else echo "CSV file has empty data" >&2
    fi
done < wp_to_import.csv

```








# Troubleshoot

## Get ProjectPhaseDefinition

Read [API doc](https://www.openproject.org/docs/api/endpoints/project-phase-definitions/#list-project-phase-definitions)

http://localhost:8080/api/v3/project_phase_definitions


## To remove Users from Group

```sh
export MSP_GROUP_ID=220

grp_get_url="$API_ENDPOINT/groups/$MSP_GROUP_ID"
echo "Group API GET URL: $grp_get_url"

response=$(curl -s -X GET -k "$grp_get_url" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json')

# Extract members using the correct jq syntax
member_list=$(echo "$response" | jq '._embedded.members[]')
echo "member_list="$member_list

for user in $member_list; do
    user_id=$(echo "$member_list" | jq '.id')
done

patch_url="$API_ENDPOINT/groups/$MSP_GROUP_ID"
echo "Patching MSP group: $patch_url"

msp_payload=$(cat <<EOF
{
    "name": "$MSP_GROUP_NAME",
    "_links": {
        "members": []
    }
}
EOF
)

data=$(echo "$msp_payload" | jq '.')
echo "MSP Payload:" $data

msp_response=$(curl -X PATCH -k "$patch_url" -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$data")
echo "Response for MSP group:" 
echo "$msp_response" | jq '.'
```