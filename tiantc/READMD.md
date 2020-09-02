# To start/init a usable LDAP Server

## Prerequisite

+ Pull beli/ldap image.

`docker pull beli/ldap`

+ Install ldapmodify

For Ubuntu: `apt install ldap-utils`

### Verifiy ldapmodify is installed

`ldapmodify --version`


## launch the LDAP Server

```bash
  docker run -p 3389:389 -v `pwd`/config:/config `pwd`/data:/data -e CONF_ROOTPW=passw0rd -e CONF_BASEDN=dc=example,dc=com beli/ldap
```
OR

```
  docker-compose down && docker-compose up -d
```

## Correct LDAP Server permission and init with some data

```bash
cd docker-ldapc/tiantc
./initLDAP.sh
```

## LDAP properties

+ URL: ldap://192.168.5.80:3389
+ Search baseDN for user: ou=people,dc=example,dc=com
+ Search baseDN for contact: ou=contact,dc=example,dc=com
+ Email field: mail
+ Bind DN: cn=admin,cn=config
+ Bind Credential: passw0rd


