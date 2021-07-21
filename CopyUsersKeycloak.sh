#/bin/bash
# Copy users from one group to another in Keycloak

# for run this script you need "jq" package. install it (apt install jq)
# Change this data based on your Keycloak
# Check "Direct Access Grants Enabled" is Enabled in Keycloak (in admin console > client > Security-admin-console)

baseUrl="https://localhost:8080/auth" # You can find baseUrl in Keycloak admin console > client
realms="master"
username="<username>" # change username and password
password='<password>'
maxQueryResult=200 # if users where you want to copy is more than 200, change this value


# get access token
getTokenResponse=$(curl -X POST -H "content-type: application/x-www-form-urlencoded" -d "username=$username&password=$password&client_id=security-admin-console&grant_type=password" $baseUrl/realms/$realms/protocol/openid-connect/token)
access_token=$(echo $getTokenResponse | cut -d'"' -f4)

# Fill source and destination group ids where you want copy users from/to
# You can find group ids with open group in Keycloak and copy group id from URL

sourceGroup="cdadf345-ae234-werdfe-xcvsdf-82b431c4s3324"
destinationGroup="daf3345a-fsdf2-234r-sdf2-asfdse2423f"

# Get users in source group
 getSourceUsers=$(curl -X GET -H "content-type: appliaction/json" -H "Authorization: bearer $access_token"  $baseUrl/admin/realms/$realms/groups/$sourceGroup/members?max=$maxQueryResult)

# parse username and userids from json
userids=$(echo $getSourceUsers | jq '.[]' | jq --raw-output '"\(.username),\(.id)"')

# save users in files
echo $userids > sourceGroupUser.txt
sed -i 's/ /\n/g' ./sourceGroupUser.txt

# copy users to destination group
OLDIFS=$IFS
INPUT="./sourceGroupUser.txt"
IFS=","
[ ! -f $INPUT ] && { echo "$INPUT file not found!"; exit 99; }

while read username userid
do
    curl -X PUT -H "Authorization: bearer $access_token" $baseUrl/admin/realms/$realms/users/$userid/groups/$destinationGroup
    echo ("$username ok!")
done < $INPUT

IFS=$OLDIFS

# remove users file
# if you want to save users comment this line
rm ./sourceGroupUser.txt
