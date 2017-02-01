#!/bin/bash

checkIfInstalled() {
	command -v $1 >/dev/null 2>&1 || { echo "I require $1 but it's not installed.  Aborting." >&2; exit 1; }
}

checkIfInstalled "$1"