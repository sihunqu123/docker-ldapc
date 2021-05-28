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

#
# execute some operation in given idif
# @param 1: the idif file
#
function runLDAP {
  ldapmodify -H ldap://localhost:3389 ${2:-} -x -D "cn=admin,cn=config" -w passw0rd -f "${1}"
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
    cat "${1}"
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


## create organizationalUnit in LDAP
#orgIdif="newOrg"
#cat > ./${orgIdif}.idif <<HERE
#dn: ou=people,dc=example,dc=com
#ou: people
#objectClass: organizationalUnit
#objectclass: top
#HERE
## objectclass: domain
#
#addIfNotExist ./${orgIdif}.idif
#echo "organizationUnit created successfully"
#
#
## create type 0 user in LDAP
#idifFileName="ChenTian"
#cat > ./${idifFileName}.idif <<HERE
#dn: cn=Chen_Tian,ou=people,dc=example,dc=com
#cn: Chen_Tian
#description: user des
#telephoneNumber: 17723010088
#objectClass: person
#sn: Tian
#HERE
## objectclass: domain
#
#addIfNotExist ./${idifFileName}.idif
#echo "User chen tian created successfully"
#
#
## create normal user in LDAP
#
#templateName="testPeopleTemplate"
#idifFileName="${templateName}"
#cat > ./${idifFileName}.idif <<"HERE"
#dn: cn=test_people${i},ou=people,dc=example,dc=com
#cn: test_people${i}
#objectClass: inetOrgPerson
#sn: people${i}
#displayName: test_people${i}
#title: title${i}
#mail: test_people${i}@example.com
#userPassword: passw0rd
#HERE
#
#for i in {0..10}
#do
#  echo "about to create test_people$i"
#  # first copy a new file from template file
#  cp -fRpv ./${templateName}.idif ./testuser.idif
#  # replace with place-holder
#  sed -i 's/${i}'"/${i}/g" ./testuser.idif
## cat ./testuser.idif
#  addIfNotExist ./testuser.idif
#  echo "User test_people${i} created successfully"
#done
## objectclass: domain
#
#echo "about add test_contacts"
#
## create organizationalUnit in LDAP
#orgIdif="newOrg"
#cat > ./${orgIdif}.idif <<HERE
#dn: ou=contact,dc=example,dc=com
#ou: contact
#objectClass: organizationalUnit
#objectclass: top
#HERE
#
#addIfNotExist ./${orgIdif}.idif
#echo "organizationUnit created successfully"
#
#
## create type 0 user in LDAP
#idifFileName="ChenTian"
#cat > ./${idifFileName}.idif <<HERE
#dn: cn=Chen_Tian,ou=contact,dc=example,dc=com
#cn: Chen_Tian
#telephoneNumber: 17723010099
#objectClass: person
#sn: Tian
#HERE
## objectclass: domain
#
#addIfNotExist ./${idifFileName}.idif
#echo "User chen tian created successfully"
#
#
#templateName="testContactTemplate"
#idifFileName="${templateName}"
#cat > ./${idifFileName}.idif <<"HERE"
#dn: cn=test_contact${i},ou=contact,dc=example,dc=com
#cn: test_contact${i}
#objectClass: inetOrgPerson
#sn: contact${i}
#title: title${i}
#displayName: contactuser${i}
#mail: test_contact${i}@example.com
#userPassword: passw0rd
#HERE
#
#for i in {0..10}
#do
#  echo "about to create test_contact$i"
#  # first copy a new file from template file
#  cp -fRpv ./${templateName}.idif ./contactuser.idif
#  # replace with place-holder
#  sed -i 's/${i}'"/${i}/g" ./contactuser.idif
## cat ./contactuser.idif
#  addIfNotExist ./contactuser.idif
#  echo "User contactuser${i} created successfully"
#done

# create group in LDAP
grpIdif="newGroup"
cat > ./${grpIdif}.idif <<HERE
dn: ou=groups,dc=example,dc=com
ou: groups
objectClass: organizationalUnit
objectclass: top

dn: ou=users,dc=example,dc=com
ou: users
objectClass: organizationalUnit
objectclass: top

dn: ou=it,ou=users,dc=example,dc=com
ou: it
objectClass: organizationalUnit
objectclass: top

dn: ou=adm,ou=users,dc=example,dc=com
ou: adm
objectClass: organizationalUnit
objectclass: top

dn: cn=admgrp,ou=groups,dc=example,dc=com
objectclass: groupOfUniqueNames
cn: admgrp
uniqueMember: uid=admin5,ou=adm,ou=users,dc=example,dc=com

dn: uid=admin5,ou=adm,ou=users,dc=example,dc=com
objectClass: top
objectClass: posixAccount
objectClass: shadowAccount
objectClass: inetOrgPerson
cn: admin5
sn: admin5
uid: admin5
uidNumber: 90005
gidNumber: 100
homeDirectory: /home/admin5
loginShell: /bin/bash
gecos: admin5
userPassword: passw0rd
shadowLastChange: 0
shadowMax: 0
shadowWarning: 0

dn: cn=aigrp,ou=groups,dc=example,dc=com
objectclass: groupOfUniqueNames
cn: aigrp
uniqueMember: uid=ai0,ou=ai,ou=users,dc=example,dc=com

dn: ou=ai,ou=users,dc=example,dc=com
ou: ai
objectClass: organizationalUnit
objectclass: top

dn: uid=ai,ou=ai,ou=users,dc=example,dc=com
objectClass: top
objectClass: posixAccount
objectClass: shadowAccount
objectClass: inetOrgPerson
cn: ai
sn: ai
uid: ai
uidNumber: 80000
gidNumber: 100
homeDirectory: /home/ai
loginShell: /bin/bash
gecos: ai
userPassword: passw0rd
shadowLastChange: 0
shadowMax: 0
shadowWarning: 0
HERE
# objectclass: domain

addIfNotExist ./${grpIdif}.idif
echo "group created successfully"


# create group2 in LDAP
#grpIdif="newGroup"
#cat > ./${grpIdif}.idif <<HERE
#dn: cn=dbagrp,ou=groups,dc=example,dc=com
#objectClass: top
#objectClass: posixGroup
#gidNumber: 900
#
#dn: cn=hrgrp,ou=groups,dc=example,dc=com
#objectclass: groupOfNames
#cn: hrgrp
#member: cn=test_user5,ou=people,dc=example,dc=com
#member: cn=test_user6,ou=people,dc=example,dc=com
#member: cn=test_user7,ou=people,dc=example,dc=com
#member: cn=test_user8,ou=people,dc=example,dc=com
#
#dn: uid=admin0,ou=users,dc=example,dc=com
#objectClass: top
#objectClass: posixAccount
#objectClass: shadowAccount
#objectClass: inetOrgPerson
#cn: admin0
#sn: adminUser0
#uid: admin0
#uidNumber: 90000
#gidNumber: 100
#homeDirectory: /home/admin0
#loginShell: /bin/bash
#gecos: admin0
#userPassword: passw0rd
#shadowLastChange: 0
#shadowMax: 0
#shadowWarning: 0
#
#dn: uid=admin1,ou=users,dc=example,dc=com
#objectClass: top
#objectClass: account
#objectClass: posixAccount
#objectClass: shadowAccount
#cn: admin1
#uid: admin1
#uidNumber: 90001
#gidNumber: 900
#homeDirectory: /home/admin1
#loginShell: /bin/bash
#gecos: admin1
#userPassword: passw0rd
#shadowLastChange: 0
#shadowMax: 0
#shadowWarning: 0
#
#dn: uid=admin2,ou=users,dc=example,dc=com
#objectClass: top
#objectClass: posixAccount
#objectClass: shadowAccount
#objectClass: inetOrgPerson
#cn: admin2
#sn: adminUser2
#uid: admin2
#uidNumber: 90002
#gidNumber: 100
#homeDirectory: /home/admin2
#loginShell: /bin/bash
#gecos: admin2
#userPassword: passw0rd
#shadowLastChange: 0
#shadowMax: 0
#shadowWarning: 0
#
#dn: cn=dbagrp,ou=groups,dc=example,dc=com
#changetype: modify
#add: memberuid
#memberuid: admin0
#
#dn: cn=dbagrp,ou=groups,dc=example,dc=com
#changetype: modify
#add: memberuid
#memberuid: admin2
#
#dn: cn=dbagrp,ou=groups,dc=example,dc=com
#changetype: modify
#add: memberuid
#memberuid: admin1
#HERE
## objectclass: domain
#
#addIfNotExist ./${grpIdif}.idif
#echo "group 2 created successfully"
#
#
#
## create user in Users of LDAP
#
#echo "about add IT users"
#
#templateName="usersTemplate"
#idifFileName="${templateName}"
#cat > ./${idifFileName}.idif <<"HERE"
#dn: cn=it_user${i},ou=it,ou=users,dc=example,dc=com
#cn: it_user${i}
#sn: iuser${i}
#displayName: it_user${i}
#title: title${i}
#mail: it_user${i}@example.com
#objectClass: top
#objectClass: inetOrgPerson
#objectClass: posixAccount
#objectClass: shadowAccount
#uid: it_user${i}
#uidNumber: 1${i}
#gidNumber: 100
#homeDirectory: /home/it_user${i}
#loginShell: /bin/bash
#gecos: it_user${i}
#userPassword: passw0rd
#shadowLastChange: 0
#shadowMax: 0
#shadowWarning: 0
#HERE
#
#for i in {0..10}
#do
#  echo "about to create it_user$i"
#  # first copy a new file from template file
#  cp -fRpv ./${templateName}.idif ./testuser.idif
#  # replace with place-holder
#  sed -i 's/${i}'"/${i}/g" ./testuser.idif
#  addIfNotExist ./testuser.idif
#  echo "User it_user${i} created successfully"
#done
## objectclass: domain
#
#echo "about add hr users"
#
#orgIdif="newOrg"
#cat > ./${orgIdif}.idif <<HERE
#dn: ou=hr,ou=users,dc=example,dc=com
#ou: hr
#objectClass: organizationalUnit
#objectclass: top
#HERE
#
#
#addIfNotExist ./${orgIdif}.idif
#echo "organizationUnit created successfully"
#
#echo "about add hr users"
#
#templateName="usersTemplate"
#idifFileName="${templateName}"
#cat > ./${idifFileName}.idif <<"HERE"
#dn: cn=hr_user${i},ou=hr,ou=users,dc=example,dc=com
#cn: hr_user${i}
#objectClass: inetOrgPerson
#sn: huser${i}
#displayName: hr_user${i}
#title: title${i}
#mail: hr_user${i}@example.com
#userPassword: passw0rd
#HERE
#
#for i in {0..10}
#do
#  echo "about to create hr_user$i"
#  # first copy a new file from template file
#  cp -fRpv ./${templateName}.idif ./testuser.idif
#  # replace with place-holder
#  sed -i 's/${i}'"/${i}/g" ./testuser.idif
#  addIfNotExist ./testuser.idif
#  echo "User hr_user${i} created successfully"
#done
## objectclass: domain
#
#echo "done with add hr users"
#
