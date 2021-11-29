#!/bin/bash


#  Params:

#  IKIDIR=/path/to/this/ikiwiki (PWDDIR)

#  IKINAME="ikiwiki name"
#  ADMIN_USER= <user admin>
#  ADMIN_EMAIL= <my@email.com>

#  DESTDIR= </var/www/path/public_html>
#  URL= <http://www.example.com>

#  GIT_REMOTE= <git@github.com:Bibliohack/bibliohack.org-contents.git>

#  MAILGUN=path/to/mailgun.yaml

#  RCLONE_DRIVE=<rclone drive name> (without ':')

# ToDo
# 0) check if ikiwiki installeds (and plugins)
     # libyaml-perl (dependencia de ymlfront)
     # libimage-magick-perl (dependencia de uploadmedia)
     # libsort-naturally-perl (dependencia de field)
     # libxml-writer-perl (dependencia de ?)
     # libtext-multimarkdown-perl (para usar por ej markdown=1 en el html)
     
# 1) if param not defined ask the user values with read

# 2) clone GIT_REMOTE git repo in src/

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
# (nota: 'post' pareciera que esta de mas?)

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

# copiar send_mail.pl de send_mail.pl.template directamente a ${DESTDIR}/send_mail.pl 
# agregando la ruta a la configuracion en ${MAILGUN}
# chmod a+x ${DESTDIR}/send_mail.pl 

# 6) media files
#    draft debera clonar la carpeta en /media_underlay/uploads usando rclone (hay que configurar 
#    previamente rclone con la unidad del drive)
#    prod puede clonar del drive o directamente haciendo rsync del media_underlay/uploads desde draft (?)


