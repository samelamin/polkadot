#!/usr/bin/env bash
set -e

if [ "$#" -ne 1 ]; then
	echo "Please provide the number of initial validators!"
	exit 1
fi

generate_account_id() {
	subkey inspect ${3:-} ${4:-} "$SECRET//$1//$2" | grep "Account ID" | awk '{ print $3 }'
}

generate_address() {
	subkey inspect ${3:-} ${4:-} "$SECRET//$1//$2" | grep "SS58 Address" | awk '{ print $3 }'
}

generate_public_key() {
	subkey inspect ${3:-} ${4:-} "$SECRET//$1//$2" | grep "Public" | awk '{ print $4 }'
}

generate_address_and_public_key() {
	ADDRESS=$(generate_address $1 $2 $3)
	PUBLIC_KEY=$(generate_public_key $1 $2 $3)

	B64=$(echo -n "\"$SECRET//$1//$2\"" | base64 | tr -d '\n')
	#beefy only
	printf "62656566${PUBLIC_KEY#'0x'}: $B64\n"
}

generate_address_and_account_id() {
	ACCOUNT=$(generate_account_id $1 $2 $3)
	ADDRESS=$(generate_address $1 $2 $3)
	if ${4:-false}; then
		INTO="unchecked_into"
	else
		INTO="into"
	fi

  PREFIX="696d6f6e" #imon
  if [[ $2 == "grandpa" ]]; then
    PREFIX="6772616e"
  elif [[ $2 == "authority_discovery" ]]; then
    PREFIX="61756469"
  elif [[ $2 == "para_assignment" ]]; then
    PREFIX="6173676e"
  elif [[ $2 == "babe" ]]; then
    PREFIX="62616265"
  elif [[ $2 == "beefy" ]]; then
    PREFIX="62656566"
  elif [[ $2 == "para_validator" ]]; then
    PREFIX="70617261"
  fi
  B64=$(echo -n "\"$SECRET//$1//$2\"" | base64 | tr -d '\n')
	printf "$PREFIX${ACCOUNT#'0x'}: $B64\n"
}

V_NUM=$1

AUTHORITIES=""

for i in $(seq 1 $V_NUM); do
	AUTHORITIES+="(\n"
	AUTHORITIES+="$(generate_address_and_account_id $i stash)\n"
	AUTHORITIES+="$(generate_address_and_account_id $i controller)\n"
	AUTHORITIES+="$(generate_address_and_account_id $i babe '--scheme sr25519' true)\n"
	AUTHORITIES+="$(generate_address_and_account_id $i grandpa '--scheme ed25519' true)\n"
	AUTHORITIES+="$(generate_address_and_account_id $i im_online '--scheme sr25519' true)\n"
	AUTHORITIES+="$(generate_address_and_account_id $i para_validator '--scheme sr25519' true)\n"
	AUTHORITIES+="$(generate_address_and_account_id $i para_assignment '--scheme sr25519' true)\n"
	AUTHORITIES+="$(generate_address_and_account_id $i authority_discovery '--scheme sr25519' true)\n"
	AUTHORITIES+="$(generate_address_and_public_key $i beefy '--scheme ecdsa' true)\n"
	AUTHORITIES+="),\n"
done

printf "$AUTHORITIES"
