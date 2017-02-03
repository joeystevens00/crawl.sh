#!/bin/bash

checkIfInstalled() {
	command -v $1 >/dev/null 2>&1 || { echo "false"; }
}

checkIfInstalled "$1"