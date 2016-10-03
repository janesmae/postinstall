# postinstall

A collection of scripts for post-install server setup.

## Features

- Installs default applications (vim, sudo, git, curl, ufw)
- Configures ufw with some default rules and enables it on boot
- Configures ufw logs to be written into separate log file
- Does basic OpenSSH hardening, **disables root login by default**
- **Optional** - Adds user with sudo privileges

## Usage

For Debian 8 host quick install (with no sudo user created):
```sh
$ curl -sSL https://raw.githubusercontent.com/janesmae/postinstall/master/debian8/install.sh | sh
```

## Contributing

Do you have an improvement? More details can be found at the [Contributors Guide](https://github.com/janesmae/postinstall/blob/master/CONTRIBUTIONS.md).

#### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/janesmae/postinstall/issues) to report any bugs or file feature requests.

## Licence [![](http://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/janesmae/postinstall/blob/master/LICENSE)

Copyright (c) 2016 Jaan Janesmae. See [LICENSE](https://github.com/janesmae/postinstall/blob/master/LICENSE) for details.

Unless attributed otherwise, everything is under the MIT license.
