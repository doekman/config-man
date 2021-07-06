#!/usr/bin/env bash
# Unofficial Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

function usage {
	cat <<TOTHIERENNIETVERDER
Usage: $0 COMMAND [FLAGS] ...

COMMAND:
	cm init             Places a .config-man file in the current folder
	cm add FILE [...]   Add one or more files to the vault
	cm backup           Perform the backup
	cm list             Shows all files in the vault
	cm compare          List all changed files
	cm restore          (not-implemented-yet)
	cm help             Show this page
FLAGS:
	-v, --verbose       Also print messages when something succeeds
	-dr, --dry-run      Don't actually modify the file system

You will need to run this tool from a config-man vault.

TOTHIERENNIETVERDER
	if [[ $# -gt 0 ]]; then
		echo "$(tput bel)❗️" "$@"
		exit 1
	fi
}

function verbose_echo {
	if [[ $VERBOSE == 1 ]]; then
		echo "$@"
	fi
}

function cm_init {
	local check_path children
	check_path="$(pwd)"
	# Check if current and parent-folders are not a config-man base (cm repository can't be nested)
	# Also, root-folder can't contain a .config-man file, so don't check.
	while [[ $check_path != "/" ]]; do
		if [[ -f "$check_path/$CONFIG_FILE" ]]; then
			if [[ $check_path == "$(pwd)" ]]; then
				echo "ERROR: this folder is already initialized."
			else
				echo "ERROR: a parent-folder is already initialized, folder:"
				echo "$check_path"
			fi
			exit 1
		fi
		check_path="$(dirname "$check_path")"
	done
	# also check child-folders
	set -f
	# shellcheck disable=SC2207
	children=( $(find . -name "$CONFIG_FILE" -type f) )
	set +f
	if [[ ${#children} -gt 0 ]]; then
		echo "ERROR: at least one child-folder is already initialized, folder(s):"
		echo "${children[*]}"
		exit 2
	fi
	[[ $DRY_RUN == 0 ]] && touch "./$CONFIG_FILE"
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
	find "." -type f -not -name "$CONFIG_FILE" -and -not -name ".DS_Store" -and -not -path '*/\.git/*' | sed 's/^\.//'
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


CONFIG_FILE=".config-man"
DRY_RUN=0
VERBOSE=0
CM_BASE="$(pwd)"

if [[ ${1:-} == "init" ]]; then
	cm_init
	exit 0
fi

if [[ ! -f ./$CONFIG_FILE ]]; then
	usage "The file ./$CONFIG_FILE not found"
fi

# Command
if [[ $# -lt 1 ]]; then
	usage "Please provide a command"
fi
case "$1" in
	add|backup|compare|help|init|list|restore) cmd="$1";;
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

if [[ $cmd == "help" ]]; then
	usage
elif [[ $cmd == "add" ]]; then
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
