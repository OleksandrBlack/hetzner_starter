#!/bin/bash

API_TOKEN=`cat hetzner_project_api_key.txt`
AUTH_HEADER="Authorization: Bearer ${API_TOKEN}"
CONTENT_TYPE="Content-Type: application/json"

curl -s -X POST -H "${CONTENT_TYPE}" -H "${AUTH_HEADER}" -d @server_params.json https://api.hetzner.cloud/v1/servers -o curl_out.txt
SERVER_ID=`cat curl_out.txt | jq '.server.id'`
SERVER_IP=`cat curl_out.txt | jq -r '.server.public_net.ipv4.ip'`

for i in {1..10}
do
	sleep 5s
	STATUS=`curl -s -H "${AUTH_HEADER}" https://api.hetzner.cloud/v1/servers/${SERVER_ID} | jq -r '.server.status'`
	READY_STATUS='running'

	echo "Server status: ${STATUS}"

	if [ "$STATUS" == "$READY_STATUS" ]; then
		break
	fi
done

echo "SUCCESS"

echo "Writing server IP to ssh config"
sed -i '/Host znodes-tester/!b;n;c\ \ HostName '"$SERVER_IP" ~/.ssh/config

echo "Waiting for sshd to run"
sleep 20

echo "Triggering ansible playbook"
ansible-playbook -i hosts crawler-prepare.yml
