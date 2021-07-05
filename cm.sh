#!/usr/bin/env bash
# Unofficial Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

function usage {
	cat <<TOTHIERENNIETVERDER
Usage: $0 COMMAND [FLAGS] ...

COMMAND:
	cm add FILE [...]   Add one or more files to the vault
	cm backup           Perform the backup
	cm compare          List all changed files
	cm init             Places a .config-man file in the current folder
	cm list             Shows all files in the vault
	cm restore          (not-implemented-yet)
FLAGS:
	-v, --verbose       Also print messages when something succeeds
	-dr, --dry-run      Don't actually modify the file system

You will need to run this tool from a config-man vault.

TOTHIERENNIETVERDER
	echo "$(tput bel)❗️" "$@"
	exit 1
}

function verbose_echo {
	if [[ $VERBOSE == 1 ]]; then
		echo "$@"
	fi
}

function cm_init {
	local check_path
	check_path="$(pwd)"
	# Check if current and parent-folders are not a config-man base (cm repository can't be nested)
	# Also, root-folder can't contain a .config-man file, so don't check.
	while [[ $check_path != "/" ]]; do
		if [[ -f "$check_path/.config-man" ]]; then
			if [[ $check_path == "$(pwd)" ]]; then
				echo "ERROR: this folder is already initialized (the file '.config-man' exists)"
			else
				echo "ERROR: the parent-folder '$check_path' is already initialized (the file '.config-man' exists)"
			fi
			exit 1
		fi
		check_path="$(dirname "$check_path")"
	done
	[[ $DRY_RUN == 0 ]] && touch ./.config-man
}

function cm_add {
	if [[ -f "$1" ]]; then
		if [[ -f "$CM_BASE/$1" ]]; then
			echo "WARNING: the file '$1' has already been added; skipping."
		else
			if [[ $DRY_RUN == 0 ]]; then
				mkdir -p "$CM_BASE/$(dirname "$1")"
				touch "$CM_BASE/$1"
			fi
			echo "- '$1' added"
		fi
	else
		echo "WARNING: the file '$1' does not exist; skipping."
	fi
}

function cm_list {
	find "." -type f -not -name ".config-man" -and -not -name ".DS_Store" -and -not -path '*/\.git/*' | sed 's/^\.//'
}

function cm_backup {
	local target
	for file in $(cm_list); do
		if [[ -L "$file" ]]; then
			# Symbolic link
			target="$(readlink "$file")"
			if [[ -f "$CM_BASE/$target" ]]; then
				# TODO: make symbolic link relative
				[[ $DRY_RUN == 0 ]] && ln -fs "$CM_BASE/$target" "$CM_BASE/$file"
				verbose_echo "- '$file' symbo-linked"
			else
				echo "WARNING: symbolic link '$file' has no target within vault; skipping"
			fi
		elif [[ -f "$file" ]]; then
			[[ $DRY_RUN == 0 ]] && cp -f "$file" "$CM_BASE/$file"
			verbose_echo "- '$file' copied"
		else
			echo "WARNING: file '$file' doesn't exist; skipping"
		fi
	done
}

function cm_compare {
	for file in $(cm_list); do
		if [[ -f "$file" ]]; then
			if diff --brief "$file" "$CM_BASE/$file" > /dev/null; then
				verbose_echo "- '$file' is unchanged"
			else
				echo "# '$file' is changed"
			fi
		else
			echo "WARNING: file '$file' doesn't exist; skipping"
		fi
	done
}


DRY_RUN=0
VERBOSE=0
CM_BASE="$(pwd)"

if [[ ${1:-} == "init" ]]; then
	cm_init
	exit 0
fi

if [[ ! -f ./.config-man ]]; then
	usage "The file ./.config-man not found"
fi

# Command
if [[ $# -lt 1 ]]; then
	usage "Please provide a command"
fi
case "$1" in
	add|backup|compare|init|list|restore) cmd="$1";;
	*) usage "Unknown command '$1'";;
esac
shift

while [[ $# -ge 1 ]]; do
	case "$1" in
		--dry-run|-dr) DRY_RUN=1; shift;;
		--verbose|-v) VERBOSE=1; shift;;
		--quiet|-q) VERBOSE=0; shift;;
		-*) usage "Unknown flag '$1'";;
		*) break;; # end of flags
	esac
done

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