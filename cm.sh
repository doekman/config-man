#!/usr/bin/env bash
# Unofficial Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

function usage {
	cat <<TOTHIERENNIETVERDER
Usage: $0 COMMAND

cm add FILE [...]   Add one or more files to the vault
cm backup           Perform the backup
cm compare          List all changed files
cm list             Shows all files in the vault
cm restore          (not-implemented-yet)

You will need to run this tool from a config-man vault.

TOTHIERENNIETVERDER
	echo "$(tput bel)❗️" "$@"
	exit 1
}

function cm_add {
	if [[ -f "$1" ]]; then
		if [[ -f "$CM_BASE/$1" ]]; then
			echo "WARNING: the file '$1' has already been added; skipping."
		else
			mkdir -p "$CM_BASE/$(dirname "$1")"
			touch "$CM_BASE/$1"
			echo "- '$CM_BASE/$1' added"
		fi
	else
		echo "WARNING: the file '$1' does not exist; skipping."
	fi
}

function cm_list {
	find "." -type f -not -name ".config-man" -and -not -name ".DS_Store" -and -not -path '*/\.git/*' | sed 's/^\.//'
}

function cm_backup {
	for file in $(cm_list); do
		if [[ -f "$file" ]]; then
			cp -f "$file" "$CM_BASE/$file"
			echo "- '$file' copied"
		else
			echo "WARNING: file '$file' doesn't exist; skipping"
		fi
	done
}

function cm_compare {
	for file in $(cm_list); do
		if [[ -f "$file" ]]; then
			if diff --brief "$file" "$CM_BASE/$file" > /dev/null; then
				echo "- '$file' is unchanged"
			else
				echo "# '$file' HAS BEEN changed"
			fi
		else
			echo "WARNING: file '$file' doesn't exist; skipping"
		fi
	done
}

if [[ ! -f ./.config-man ]]; then
	usage "The file ./.config-man not found"
fi

CM_BASE="$(pwd)"

# Command
if [[ $# -lt 1 ]]; then
	usage "Please provide a command"
fi
case "$1" in
	add|backup|compare|list|restore) cmd="$1";;
	*) usage "Unknown command '$1'";;
esac
shift


if [[ $cmd == "add" ]]; then
	# Handle all FILES arguments
	if [[ $# -lt 1 ]]; then
		usage "You need to specify at least one file"
	else
		while [[ $# -ge 1 ]]; do
			cm_add "$1"
			shift
		done
	fi
elif [[ $cmd == "list" ]]; then
	cm_list
elif [[ $cmd == "backup" ]]; then
	cm_backup
elif [[ $cmd == "restore" ]]; then
	echo "Not implemented yet"
elif [[ $cmd == "compare" ]]; then
	cm_compare
fi