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

# Create Bulk-Users

Read the [doc](https://www.openproject.org/docs/api/endpoints/users/#create-user)

Check the API endpoint, ex: http://localhost:8080/api/v3/users

```sh
# Set you USER and Password below
export USR_EMAIL=""
export USR_PWD=""
export API_EDNPOINT="http://localhost:8080/api/v3/users"
export API_TOKEN=""

# Read Excel file, format is: Département | NOM Prénom	| Rôle

# Count the number of users

# Loop for Eah user, Call the API with the API bearer Token with POST method

#ex:
#
#  "login": "j.sheppard",
##  "password": "foo",
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

        user_payload="{\"login\": \"${first_name:0:1}.${last_name}\", \"password\": \"$USR_PWD\", \"firstName\": \"$first_name\", \"lastName\": \"$last_name\", \"email\": \"${USR_EMAIL}\", \"admin\": false, \"status\": \"active\", \"language\": \"en\"}"

        echo ""
        echo $user_payload
        echo ""

        curl -X POST -k "$API_EDNPOINT" -H "Authorization:Bearer ${API_TOKEN}" -H 'Content-Type: application/json' -d "$user_payload"
    fi
done < users_to_import.csv


for index in ${!users[@]}
    do
        echo $((index+1))/${#users[@]} = "${users[index]}"
        ........ ${users[index]}
    done

echo ""


curl -k $API_EDNPOINT -H "Authorization: Bearer $API_TOKEN" -H 'Accept: application/json'
curl -k $API_EDNPOINT -H "Authorization: Bearer $API_TOKEN" -H 'Accept: application/json'



```