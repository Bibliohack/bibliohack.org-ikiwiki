#!/bin/bash


#  Params:

#  IKIDIR </path/to/this/ikiwiki> (PWDDIR)

#  IKINAME=<ikiwiki name>
#  ADMIN_USER <user admin>
#  ADMIN_EMAIL <my@email.com>

#  DESTDIR </var/www/path/public_html>
#  URL <http://www.example.com>

#  SRCURL <https:/github.com/user/mkdn-content-repo>

# ToDo
# 0) check if ikiwiki installeds (and plugins)
# 1) if param not defined read value from user
# 2) clone SRCURL git repo in src/
# 3) replace values in wiki.setup.yaml.template and create wiki.setup.yaml
# 4) ikiwiki --setup wiki.setup.yaml (hace falta crear manualmente el src.git repo?)
