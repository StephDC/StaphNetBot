#!/bin/bash

source botapi.sh

NL=$'\n'

function processCommand {
	if [[ $2 == "/ping" || $2 == "/ping@${MYINFO}" ]]; then
		local CHAT_ID=$(echo $1 | jq -r ".chat.id")
		local MESSAGE_ID=$(echo $1 | jq -r ".message_id")
		local TEXT="Hell o'world! It took me "$(echo $1 | jq -r "$(date +%s) - .date")" seconds."
		local RESULT=$(curl -s --data-urlencode "chat_id=$CHAT_ID" --data-urlencode "reply_to_message_id=$MESSAGE_ID" --data-urlencode "text=$TEXT" "$API_TARGET/sendMessage")
		if [[ -z $RESULT ]]; then echo "ERROR: sendMessage query failed."; echo "Original query: "$1; fi
	elif [[ $2 == "/traceroute" || $2 == "/traceroute@${MYINFO}" ]]; then
		local CHAT_ID=$(echo $1 | jq -r ".chat.id")
		local MESSAGE_ID=$(echo $1 | jq -r ".message_id")
		if [[ -z $3 ]]; then
			local TEXT="Usage: <code>/traceroute HOST</code>"
		elif [[ $3 =~ ^[-.:a-zA-Z0-9]+$ ]]; then
			local TEXT="Traceroute to <code>$3</code>:${NL}<pre>$(traceroute $3)</pre>"
		else
			local TEXT="<code>$3</code> contains unsupported characters, so a traceroute cannot be accomplished."
		fi
		local RESULT=$(curl -s --data "parse_mode=HTML" --data-urlencode "chat_id=$CHAT_ID" --data-urlencode "reply_to_message_id=$MESSAGE_ID" --data-urlencode "text=$TEXT" "$API_TARGET/sendMessage")
		if [[ -z $RESULT ]]; then echo "ERROR: sendMessage query failed."; echo "Original query: "$1; fi
	fi
}

function processMessage {
	QUERYTEXT=$(echo $1 | jq -r ".text")
	if [[ $QUERYTEXT != null ]]
		then
			processCommand "$1" $QUERYTEXT
	fi
}

function processQuery {
	if [[ $(echo $1 | jq -r ".message") != null ]]
		then processMessage "$(echo $1 | jq -r ".message")"
	fi
}

API_TARGET="https://api.telegram.org/bot${BOTKEY}"

MYINFO=$(curl -s "$API_TARGET/getMe" | jq -r ".result.username")

if [[ $MYINFO == null ]]
	then echo I am not connected.; exit 1
	else echo I am connected as $MYINFO
fi

echo Starting to fetch some updates...

UPDATE=$(curl -s "$API_TARGET/getUpdates" | jq -r ".result")

while [[ $UPDATE == "[]" ]]
do
	sleep 2
	UPDATE=$(curl -s "$API_TARGET/getUpdates" | jq -r ".result")
done

echo First update obtained. Now processing...

while true
do
	while [[ $UPDATE != "[]" ]]
	do
		LASTQUERY=$(echo $UPDATE | jq -r ".[0]")
		echo Last ID: $(echo $LASTQUERY | jq -r ".update_id")
		processQuery "$LASTQUERY" &
		UPDATE=$(echo $UPDATE | jq -r ".[1:]")
	done

	LASTID=$(echo $LASTQUERY | jq -r ".update_id + 1")

	while [[ $UPDATE == "[]" ]]
	do
		UPDATE=$(curl -s --data-urlencode "offset=$LASTID" --data "timeout=10" "$API_TARGET/getUpdates" | jq -r ".result")
		if [[ $UPDATE == "[]" ]]; then sleep 2; fi
	done
done
