#!/bin/bash


#  Params:

#  IKIDIR </path/to/this/ikiwiki> (PWDDIR)

#  IKINAME=<ikiwiki name>
#  ADMIN_USER <user admin>
#  ADMIN_EMAIL <my@email.com>

#  DESTDIR </var/www/path/public_html>
#  URL <http://www.example.com>

#  GIT_REMOTE <git@github.com:Bibliohack/bibliohack.org-contents.git>


#  SRCURL <https:/github.com/user/mkdn-content-repo>

# ToDo
# 0) check if ikiwiki installeds (and plugins)
     # git-lfs (git large file storage)
     # libyaml-perl (dependencia de ymlfront)
     # libimage-magick-perl (dependencia de uploadmedia)
     # libsort-naturally-perl (dependencia de field)
     # libxml-writer-perl (dependencia de ?)
     # libtext-multimarkdown-perl (para usar por ej markdown=1 en el html)
# 1) if param not defined read value from user
# 2) clone SRCURL git repo in src/
#       cd ${IKIDIR}
# 		git clone ${GIT_REMOTE} src

# 	 !importante, configurar src/.git/config para que apunte al bare local de ikiwiki y no a github!

# [core]
# 	repositoryformatversion = 0
# 	filemode = true
# 	bare = false
# 	logallrefupdates = true
# [user]
# 	name = ${ADMIN_USER}
# 	email = ${ADMIN_EMAIL}
# [remote "origin"]
# 	url = ${IKIDIR}/src.git
# 	fetch = +refs/heads/*:refs/remotes/origin/*
# [branch "master"]
# 	merge = refs/heads/master
# 	remote = origin
# [remote "github"]
# 	url = ${GIT_REMOTE}
# 	fetch = +refs/heads/*:refs/remotes/origin/*


# 2b) crear bare en src.git (ToDo probar si es necesario hacer esto o lo crea solo ikiwiki!)

#      git init --bare src.git

#   checkear src.git/config 
#   [core]
#   	repositoryformatversion = 0
#   	filemode = true
#   	bare = true
#   	sharedrepository = 1
#   [receive]
#  	denyNonFastforwards = true

# 3) replace values in wiki.setup.yaml.template and create wiki.setup.yaml

# para lenguajes
# 	translate_master_language: es|Español
# 	translate_slave_languages:
# 	  - en|English
# 	translate_translatable_pages: "posts or field_item(translatable yes) or index

# para habilitar edicion web verificar que esten comentados:
# 	#lockedit plugin
# 	#PageSpec controlling which pages are locked
# 	#locked_pages: '* and !postcomment(*)'

   
# 4) ikiwiki --setup wiki.setup.yaml
#    ó
#    ikiwiki --rebuild --verbose --setup wiki.setup.yaml
#
#  ToDo: checkear error inicial de git que da ikiwiki en la primera ejecucion (despues desaparece al volver a ejecutarlo)

# 5) para send_mail.pl: 
      # sudo apt-get install cpanm build-essential
      # sudo cpanm Capture::Tiny 
      # sudo cpanm JSON::Parse
      # sudo cpanm Email::Valid
