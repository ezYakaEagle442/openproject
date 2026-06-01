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