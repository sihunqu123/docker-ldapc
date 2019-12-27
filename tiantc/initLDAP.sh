#!/usr/bin/env bash
#!/usr/bin/env bash is more portable than #!/bin/bash.

# options like
#   set -o {optionsName}
# will only take effects for it's current/child level.
# So a option set in a function won't affect it's outside environment


# Use set -o errexit (a.k.a. set -e) to make your script exit when a command fails. # Then add || true to commands that you allow to fail.
# won't fail when
#   {failedCommand} || true
#   {failedCommand} | AlwaysSucceedPipeFunction
set -o errexit

# fail when
#   {failedCommand} | AlwaysSucceedPipeFuncntion
# set -o pipefail
# Use set -o nounset (a.k.a. set -u) to exit when your script tries to use undeclared variables. # Surround your variable with " in if [ "${NAME}" = "Kevin" ], because if $NAME isn't declared, bash will throw a syntax error (also see nounset).
# [unsetVaraible][unsetParameter][undefinedParameter][defaultParameter]
# Use :- if you want to test variables that could be undeclared. For instance: if [ "${NAME:-}" = "Kevin" ] will set $NAME to be empty if it's not declared. You can also set it to noname like so if [ "${NAME:-noname}" = "Kevin" ]
set -o nounset
# Use set -o xtrace (a.k.a set -x) to trace what gets executed. Useful for debugging.
set -o xtrace

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app

arg1="${1:-}"
# Surround your variables with {}. Otherwise bash will try to access the $ENVIRONMENT_app variable in /srv/$ENVIRONMENT_app, whereas you probably intended /srv/${ENVIRONMENT}_app.
echo arg1: ${arg1} __dir: ${__dir} __file: ${__file} __base: ${__base} __root: ${__root}


# to start docker container:
#   docker run -p 3389:389 -v `pwd`/config:/config `pwd`/data:/data -e CONF_ROOTPW=passw0rd -e CONF_BASEDN=dc=example,dc=com beli/ldap
# OR
#   docker-compose down && docker-compose up -d

#
# execute some operation in given idif
# @param 1: the idif file
#
function runLDAP {
  ldapmodify ${2:-} -x -D "cn=admin,cn=config" -w passw0rd -f "${1}"
}

#
# add idif file to LDAP
# @param 1: the idif file
#
function addToLDAP {
  runLDAP "${1}" "-a"
}

function isAlreadyExists {
  # close trace only for this function
  set +o xtrace
  echo "pipe result is:"
  local result=""
  while read line; do
#     echo "${line}"
     result="${result}${line}\n"
  done
  echo -e "result is :${result}"
  echo "pipe result over"
  if [[ ${result} =~ "ldap_add: Already exists"  ]]; then
    echo "already exists"
    return 0
  else
    echo "not exists"
    return 1
  fi
}

function addIfNotExist {
  # close unset only for this function
  set +o nounset
  set +o errexit
  addToLDAP "${1}" 2>&1 | isAlreadyExists
  # fetch the pipestatus that compatible for both bash and zsh
# retVal_bash="${PIPESTATUS[0]}" retVal_zsh="${pipestatus[0]}" retPip1=$?
# echo ${retVal_bash}${retVal_zsh},  $retPip1
  pipestatus0="${PIPESTATUS[0]}${pipestatus[0]}" retPipe=$?
#  pipestatus1="${PIPESTATUS[1]}${pipestatus[1]}" # only one pipe, the the pipestatus1 doesn't exists
  echo "pipestatus: ${pipestatus0}, ${retPipe}"
  if [[ "${pipestatus0}" == "0" ]] || [[ "${retPipe}" == "0" ]]; then
    echo "addIfNotExist succeed"
  else
    echo "addIfNotExist failed, will exit 1"
    exit 1;
  fi
}

# creat a file with given content in bash script


# change some permission in LDAP
initIdif="init"
cat > ./${initIdif}.idif <<HERE
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
-
replace: olcRootDN
olcRootDN: cn=admin,dc=example,dc=com
-
replace: olcAccess
olcAccess: to *
  by * write
-
replace: olcSizeLimit
olcSizeLimit: 5000
HERE

runLDAP ./${initIdif}.idif
echo "change permission successfully"

# to verify the result
# cat ./a.txt

# create domain in LDAP
domainIdif="newDomain"
cat > ./newDomain.idif <<HERE
dn: dc=example,dc=com
dc: example
objectclass: top
objectclass: domain
HERE

addIfNotExist ./${domainIdif}.idif
echo "domain created successfully"


# create organizationalUnit in LDAP
orgIdif="newOrg"
cat > ./${orgIdif}.idif <<HERE
dn: ou=people,dc=example,dc=com
ou: people
objectClass: organizationalUnit
objectclass: top
HERE
# objectclass: domain

addIfNotExist ./${orgIdif}.idif
echo "organizationUnit created successfully"


# create type 0 user in LDAP
idifFileName="ChenTian"
cat > ./${idifFileName}.idif <<HERE
dn: cn=Chen Tian,ou=people,dc=example,dc=com
cn: Chen Tian
description: user des
telephoneNumber: 17723010088
objectClass: person
sn: Tian
HERE
# objectclass: domain

addIfNotExist ./${idifFileName}.idif
echo "User chen tian created successfully"


# create normal user in LDAP

templateName="testuserTemplate"
idifFileName="${templateName}"
cat > ./${idifFileName}.idif <<"HERE"
dn: cn=test user${i},ou=people,dc=example,dc=com
cn: test user${i}
objectClass: inetOrgPerson
sn: user${i}
displayName: testuser${i}
title: title${i}
mail: testuser${i}@example.com
userPassword: passw0rd
HERE

for i in {0..1100}
do
  echo "about to create testuser$i"
  # first copy a new file from template file
  cp -fRpv ./${templateName}.idif ./testuser.idif
  # replace with place-holder
  sed -i 's/${i}'"/${i}/g" ./testuser.idif
# cat ./testuser.idif
  addIfNotExist ./testuser.idif
  echo "User testuser${i} created successfully"
done
# objectclass: domain

echo "about add Contacts"

# create organizationalUnit in LDAP
orgIdif="newOrg"
cat > ./${orgIdif}.idif <<HERE
dn: ou=contact,dc=example,dc=com
ou: contact
objectClass: organizationalUnit
objectclass: top
HERE

addIfNotExist ./${orgIdif}.idif
echo "organizationUnit created successfully"


# create type 0 user in LDAP
idifFileName="ChenTian"
cat > ./${idifFileName}.idif <<HERE
dn: cn=Chen Tian,ou=contact,dc=example,dc=com
cn: Chen Tian
telephoneNumber: 17723010099
objectClass: person
sn: Tian
HERE
# objectclass: domain

addIfNotExist ./${idifFileName}.idif
echo "User chen tian created successfully"


templateName="contactuserTemplate"
idifFileName="${templateName}"
cat > ./${idifFileName}.idif <<"HERE"
dn: cn=contact user${i},ou=contact,dc=example,dc=com
cn: contact user${i}
objectClass: inetOrgPerson
sn: user${i}
title: title${i}
displayName: contactuser${i}
mail: contactuser${i}@example.com
userPassword: passw0rd
HERE

for i in {0..400}
do
  echo "about to create contactuser$i"
  # first copy a new file from template file
  cp -fRpv ./${templateName}.idif ./contactuser.idif
  # replace with place-holder
  sed -i 's/${i}'"/${i}/g" ./contactuser.idif
# cat ./contactuser.idif
  addIfNotExist ./contactuser.idif
  echo "User contactuser${i} created successfully"
done
