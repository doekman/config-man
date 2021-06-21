# config-man
Helping manager for your configuration files.

Functionality and reasons behind it are described in [what if][what-if]-issues:

* [What if you could backup configuration files without an explicit configuration][issue-1]

[what-if]: https://github.com/doekman/config-man/issues?q=is%3Aissue+label%3Aenhancement+
[issue-1]: https://github.com/doekman/config-man/issues/1


## Installation

	./config.sh          # shows help and installation status
	./config.sh install  # installs symbolic link into /usr/local/bin


## Usage


	# Initialise a config-man vault
	touch .config-man
	
	# Add files to the vault
	cm add ~/.ssh/config ~/.gitconfig ~/.gitignore_global
	
	# Show all files in vault
	cm list