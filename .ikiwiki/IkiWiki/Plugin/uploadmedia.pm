#!/usr/bin/perl
package IkiWiki::Plugin::uploadmedia;

use warnings;
use strict;
use File::Path qw(make_path);
use File::Basename;
use IkiWiki 3.00;
use Image::Magick;

sub import {
	hook(type => "getsetup", id => "uploadmedia", call => \&getsetup);
	hook(type => "formbuilder_setup", id => "uploadmedia", call => \&formbuilder_setup);
	hook(type => "formbuilder", id => "uploadmedia", call => \&formbuilder);
	hook(type => "sessioncgi", id => "uploadmedia", call => \&sessioncgi);
	# hook(type => "rename", id => "uploadmedia", call => \&rename_subpages);
}

sub getsetup () {
	return 
		plugin => {
			safe => 1,
			rebuild => 0,
			section => "web",
		},
}

sub check_canrename ($$$$$$) {
	my $src=shift;
	my $srcfile=shift;
	my $dest=shift;
	my $destfile=shift;
	my $q=shift;
	my $session=shift;

	my $attachment=! defined pagetype($pagesources{$src});

	# Must be a known source file.
	#if (! exists $pagesources{$src}) {
	#	error(sprintf(gettext("%s does not exist"),
	#		htmllink("", "", $src, noimageinline => 1)));
	#}
	
	# Must exist on disk, and be a regular file.
	if (! -e "$config{srcdir}/$srcfile") {
		error(sprintf(gettext("%s is not in the srcdir, so it cannot be renamed"), $srcfile));
	}
	elsif (-l "$config{srcdir}/$srcfile" && ! -f _) {
		error(sprintf(gettext("%s is not a file"), $srcfile));
	}

	# Must be editable.
	IkiWiki::check_canedit($src, $q, $session);
	if ($attachment) {
		if (IkiWiki::Plugin::attachment->can("check_canattach")) {
			IkiWiki::Plugin::attachment::check_canattach($session, $src, "$config{srcdir}/$srcfile");
		}
		else {
			error("renaming of attachments is not allowed");
		}
	}
	
	# Dest checks can be omitted by passing undef.
	if (defined $dest) {
		if ($srcfile eq $destfile) {
			error(gettext("no change to the file name was specified"));
		}

		# Must be a legal filename.
		if (IkiWiki::file_pruned($destfile)) {
			error(sprintf(gettext("illegal name")));
		}

		# Must not be a known source file.
		if ($src ne $dest && exists $pagesources{$dest}) {
			error(sprintf(gettext("%s already exists"),
				htmllink("", "", $dest, noimageinline => 1)));
		}
	
		# Must not exist on disk already.
		if (-l "$config{srcdir}/$destfile" || -e _) {
			error(sprintf(gettext("%s already exists on disk"), $destfile));
		}
	
		# Must be editable.
		IkiWiki::check_canedit($dest, $q, $session);
		if ($attachment) {
			# Note that $srcfile is used here, not $destfile,
			# because it wants the current file, to check it.
			IkiWiki::Plugin::attachment::check_canattach($session, $dest, "$config{srcdir}/$srcfile");
		}
	}

	my $canrename;
	IkiWiki::run_hooks(canrename => sub {
		return if defined $canrename;
		my $ret=shift->(cgi => $q, session => $session,
			src => $src, srcfile => $srcfile,
			dest => $dest, destfile => $destfile);
		if (defined $ret) {
			if ($ret eq "") {
				$canrename=1;
			}
			elsif (ref $ret eq 'CODE') {
				$ret->();
				$canrename=0;
			}
			elsif (defined $ret) {
				error($ret);
				$canrename=0;
			}
		}
	});
	return defined $canrename ? $canrename : 1;
}

sub uploadmedia_form ($$$) {
	my $q=shift;
	my $session=shift;
	my $page=shift;

	eval q{use CGI::FormBuilder};
	error($@) if $@;
	my $f = CGI::FormBuilder->new(
		name => "uploadmedia",
		title => sprintf(gettext("uploadmedia %s"), pagetitle($page)),
		header => 0,
		charset => "utf-8",
		method => 'POST',
		javascript => 0,
		params => $q,
		action => IkiWiki::cgiurl(),
		stylesheet => 1,
		fields => [qw{do page new_name attachment}],
	);
	
	$f->field(name => "do", type => "hidden", value => "uploadmedia", force => 1);
	$f->field(name => "sid", type => "hidden", value => $session->id,
		force => 1);
	$f->field(name => "page", type => "hidden", value => $page, force => 1);
	$f->field(name => "new_name", value => pagetitle($page, 1), size => 60);
	if (!$q->param("attachment")) {
		# insert the standard extensions
		my @page_types;
		if (exists $IkiWiki::hooks{htmlize}) {
			foreach my $key (grep { !/^_/ } keys %{$IkiWiki::hooks{htmlize}}) {
				push @page_types, [$key, $IkiWiki::hooks{htmlize}{$key}{longname} || $key]
					unless $IkiWiki::hooks{htmlize}{$key}{nocreate};
			}
		}
		@page_types=sort @page_types;
	
		# make sure the current extension is in the list
		my ($ext) = $pagesources{$page}=~/\.([^.]+)$/;
		if (! $IkiWiki::hooks{htmlize}{$ext}) {
			unshift(@page_types, [$ext, $ext]);
		}
	
		$f->field(name => "type", type => 'select',
			options => \@page_types,
			value => $ext, force => 1);
		
		foreach my $p (keys %pagesources) {
			if ($pagesources{$p}=~m/^\Q$page\E\//) {
				$f->field(name => "subpages",
					label => "",
					type => "checkbox",
					options => [ [ 1 => gettext("Also rename SubPages and attachments") ] ],
					value => 1,
					force => 1);
				last;
			}
		}
	}
	$f->field(name => "attachment", type => "hidden");

	return $f, ["Upload", "Cancel"];
}

sub rename_start ($$$$) {
	my $q=shift;
	my $session=shift;
	my $attachment=shift;
	my $page=shift;

	# Special case for renaming held attachments; normal checks
	# don't apply.
	my $a=IkiWiki::Plugin::attachment->can("is_held_attachment");
	my $b=IkiWiki::Plugin::attachment::is_held_attachment($page);

	my $held=$attachment &&
		IkiWiki::Plugin::attachment->can("is_held_attachment") &&
		IkiWiki::Plugin::attachment::is_held_attachment($page);
	if (! $held) {	
	# TODO esto hay q descomentarlo
	# ver porque no da true si es held!
		#check_canrename($page, $pagesources{$page}, undef, undef,
		#	$q, $session);
	}
	#error("attachment='$attachment' a='$a' b='$b' page: '$page'");
   	# Save current form state to allow returning to it later
	# without losing any edits.
	# (But don't save what button was submitted, to avoid
	# looping back to here.)
	# Note: "_submit" is CGI::FormBuilder internals.
	$q->param(-name => "_submit", -value => "");
	$session->param(postuploadmedia => scalar $q->Vars);
	IkiWiki::cgi_savesession($session);
	
	if (defined $attachment) {
		$q->param(-name => "attachment", -value => $attachment);
	} else {
		error("algo salio mal");
	}
	if($page eq ""){
		#page todavia no existe!
		$page=Encode::decode_utf8(scalar $q->param("page"));
	}
	my ($f, $buttons)=uploadmedia_form($q, $session, $page); # $page
	IkiWiki::showform($f, $buttons, $session, $q);
	exit 0;
}

sub postrename ($$$;$$) {
	my $cgi=shift;
	my $session=shift;
	my $src=shift;
	my $dest=shift;
	my $attachment=shift;

	# Load saved form state and return to edit page, using stored old
	# cgi state. Or, if the rename was not started on the edit page, 
	# return to the renamed page.
	my $postrename=$session->param("postuploadmedia");
	if (! defined $postrename) {
	   error("algo salio mal");
		#IkiWiki::redirect($cgi, urlto(defined $dest ? $dest : $src));
		exit;
	}
	my $oldcgi=CGI->new($postrename);
	$session->clear("postuploadmedia");
	IkiWiki::cgi_savesession($session);

	if (defined $dest) {
		if (! $attachment) {
			# They renamed the page they were editing. This requires
			# fixups to the edit form state.
			# Tweak the edit form to be editing the new page.
			error("el attachment deberia existir!");
			$oldcgi->param("page", $dest);
		}

		# Update edit form content to fix any links present
		# on it.
		#$oldcgi->param("editcontent",
		#	renamepage_hook($dest, $src, $dest,
		#		scalar $oldcgi->param("editcontent")));

		# Get a new edit token; old was likely invalidated.
		$oldcgi->param("rcsinfo",
			IkiWiki::rcs_prepedit($pagesources{$dest}));
	}

	IkiWiki::cgi_editpage($oldcgi, $session);
}

sub formbuilder (@) {
	my %params=@_;
	my $form=$params{form};

	if (defined $form->field("do") && ($form->field("do") eq "edit" ||
	    $form->field("do") eq "create")) {
    		IkiWiki::decode_form_utf8($form);
		my $q=$params{cgi};
		my $session=$params{session};

		#if ($form->submitted eq "Rename" && $form->field("do") eq "edit") {
		#	error("submitted es Rename!");
		#	rename_start($q, $session, 0, scalar $form->field("page"));
		#} 
		#elsif
		if($form->submitted eq "Upload Media") {
			my @selected=map { Encode::decode_utf8($_) } $q->param("attachment_select");
			if (@selected > 1) {
				error(gettext("Only one attachment can be uploaded to media at a time."));
			}
			elsif (! @selected) {
				error(gettext("Please select the attachment to upload to media."))
			}
		#error("form->field(page): '".scalar $form->field("page")."' selected: '".$selected[0]."'"); 
			rename_start($q, $session, 1, scalar $form->field("page").'/'.$selected[0]);
		}
	}
}

my $uploadsummary;

sub formbuilder_setup (@) {
	my %params=@_;
	my $form=$params{form};
	my $q=$params{cgi};

	if (defined $form->field("do") && ($form->field("do") eq "edit" ||
	    $form->field("do") eq "create")) {
		# Rename button for the page, and also for attachments.
		#push @{$params{buttons}}, "Rename" if $form->field("do") eq "edit";
		$form->tmpl_param("field-uploadmedia" => '<input name="_submit" type="submit" value="Upload Media" />');

		if (defined $uploadsummary) {
			$form->tmpl_param(message => $uploadsummary);
		}
	}
}

sub sessioncgi ($$) {
        my $q=shift;

	if ($q->param("do") eq 'uploadmedia') {
        	my $session=shift;
		my ($form, $buttons)=uploadmedia_form($q, $session, Encode::decode_utf8(scalar $q->param("page")));
		IkiWiki::decode_form_utf8($form);
		my $src=$form->field("page");

		if ($form->submitted eq 'Cancel') {
			postrename($q, $session, $src);
		}
		elsif ($form->submitted eq 'Upload' && $form->validate) {
			IkiWiki::checksessionexpiry($q, $session);

			# These untaints are safe because of the checks
			# performed in check_canrename later.
			my $srcfile=IkiWiki::possibly_foolish_untaint($pagesources{$src})
				if exists $pagesources{$src};
			my $dest=IkiWiki::possibly_foolish_untaint(titlepage(scalar $form->field("new_name")));
			my $destfile=$dest;
			if (! $q->param("attachment")) {
				   error("no deberiamos estar aca !attachment");
				my $type=$q->param('type');
				if (defined $type && length $type && $IkiWiki::hooks{htmlize}{$type}) {
					$type=IkiWiki::possibly_foolish_untaint($type);
				}
				else {
					my ($ext)=$srcfile=~/\.([^.]+)$/;
					$type=$ext;
				}
				
				$destfile=newpagefile($dest, $type);
			}

			my $absdest = $config{uploadmedia_dir}.$destfile;
	      my $absdir = dirname( $absdest);
	      if ( -f $absdir) {
	      	error(sprintf("el directorio '%s' es un archivo que ya existe"), dirname($destfile));
	      } elsif ( ! -d $absdir ){
	          make_path($absdir, { chmod => 0755 }) 
	          	or die(sprintf("no se puedo crear la ruta '%s'"), dirname($destfile));
	      }
			# Special case for renaming held attachments.
			my $held=$q->param("attachment") &&
				IkiWiki::Plugin::attachment->can("is_held_attachment") &&
				IkiWiki::Plugin::attachment::is_held_attachment($src);
			if ($held) {
				rename($held, $absdest) 
					or die(sprintf("no se pudo mover el archivo desde held %s hasta %s", $held, $destfile));
				#die(sprintf("nos quedamos aca: desde %s hasta %s / mediadir %s", $held, $absdest, $config{uploadmedia_dir}));

				# resizear aca
	      	if ( -f $absdest) {
					my $im = new Image::Magick;
					my $status;
					$status = $im->Read($absdest);
					warn "$status" if "$status";
	
					my $im_default = $absdest.'_default.jpg';
				   $status = $im->Resize(geometry=>'768x543^', extent=>'768x543', gravity=>'center');
					warn "$status" if "$status";
					$status = $im->Write(filename=>$im_default, quality=>'75');
	
					my $im_small = $absdest.'_small.jpg';
				   $status = $im->Resize(geometry=>'300');
					warn "$status" if "$status";
					$status = $im->Write(filename=>$im_small, quality=>'75');
					undef $im;
		      	# die(sprintf("debug: '%s' '%s' '%s'"), $absdest, $im_small, $im_default);				
				} else {
		      	die(sprintf("no se pudo copiar la imagen a '%s'"), $absdest);
		      }

				my $template=template("uploadsummary.tmpl");
				$uploadsummary="";
				$template->param(src => $src);
				$template->param(dest => $dest);
		 		$template->param(defaultcode => "[[!field default_img=\"/uploads/$dest\" ]]");
		 		$template->param(linkcode => "![texto alternativo](/uploads/$dest)");
				$uploadsummary=$template->output;

				postrename($q, $session, $src, $dest, scalar $q->param("attachment"))
					unless defined $srcfile;
			} else {
		      if ( $srcfile eq ""){
		  			error("srcfile no existe");
		     	} elsif ( ! -f $config{srcdir}."/".$srcfile) {
					error(sprintf("'%s' no es un archivo"), dirname($config{srcdir}."/".$srcfile));
			   } 
				rename($config{srcdir}."/".$srcfile, $absdest) 
					or die(sprintf("no se pudo mover el archivo desde srcfile %s hasta %s", $srcfile, $destfile));
			}

			# Aca termina si el archivo no estaba en el repo, o sea subida temporal en .ikiwiki/attachments/

			# Queue of rename actions to perfom.
			# my @torename;
			# push @torename, {
			# 	src => $src,
			#         	srcfile => $srcfile,
			#  	dest => $dest,
			#         	destfile => $destfile,
			#  	required => 1,
			# };

			# @torename=rename_hook(
			#  	torename => \@torename,
			#  	done => {},
			#  	cgi => $q,
			#  	session => $session,
			# );

			require IkiWiki::Render;
			IkiWiki::disable_commit_hook() if $config{rcs};


			if ($config{rcs}) {
				IkiWiki::rcs_remove($srcfile);
				# $rcs_removed = 1;
			}


			# my %origpagesources=%pagesources;

			# First file renaming.
			# foreach my $rename (@torename) {
			# 	if ($rename->{required}) {
			# 		do_rename($rename, $q, $session);
			# 	}
			# 	else {
			# 		eval {do_rename($rename, $q, $session)};
			# 		if ($@) {
			# 			$rename->{error}=$@;
			# 			next;
			# 		}
			# 	}

			# 	# Temporarily tweak pagesources to point to
			# 	# the renamed file, in case fixlinks needs
			# 	# to edit it.
			# 	$pagesources{$rename->{src}}=$rename->{destfile};
			# }
			IkiWiki::rcs_commit_staged(
				message => sprintf(gettext("move to media and remove %s from src"), $srcfile),
				session => $session,
			) if $config{rcs};

			# Then link fixups.
			# parece que esto arregla los links dentro decada page, por ahora lo desabilitamos
			# TODO: activarlos!
			# foreach my $rename (@torename) {
			# 	next if $rename->{src} eq $rename->{dest};
			# 	next if $rename->{error};
			# 	foreach my $p (fixlinks($rename, $session)) {
			# 		# map old page names to new
			# 		foreach my $r (@torename) {
			# 			next if $rename->{error};
			# 			if ($r->{src} eq $p) {
			# 				$p=$r->{dest};
			# 				last;
			# 			}
			# 		}
			# 		push @{$rename->{fixedlinks}}, $p;
			# 	}
			# }

			# Then refresh.
			# %pagesources=%origpagesources;
			if ($config{rcs}) {
				IkiWiki::enable_commit_hook();
				IkiWiki::rcs_update();
			}
			IkiWiki::refresh();
			IkiWiki::saveindex();

			# Find pages with remaining, broken links.
			# foreach my $rename (@torename) {
			# 	next if $rename->{src} eq $rename->{dest};
			# 	
			# 	foreach my $page (keys %links) {
			# 		my $broken=0;
			# 		foreach my $link (@{$links{$page}}) {
			# 			my $bestlink=bestlink($page, $link);
			# 			if ($bestlink eq $rename->{src}) {
			# 				push @{$rename->{brokenlinks}}, $page;
			# 				last;
			# 			}
			# 		}
			# 	}
			# }

			# Generate a summary, that will be shown at the top
			# of the edit template.
			# $renamesummary="";
			# foreach my $rename (@torename) {
			# 	my $template=template("renamesummary.tmpl");
			# 	$template->param(src => $rename->{srcfile});
			# 	$template->param(dest => $rename->{destfile});
			# 	$template->param(error => $rename->{error});
			# 	if ($rename->{src} ne $rename->{dest}) {
			# 		$template->param(brokenlinks_checked => 1);
			# 		$template->param(brokenlinks => linklist($rename->{dest}, $rename->{brokenlinks}));
			# 		$template->param(fixedlinks => linklist($rename->{dest}, $rename->{fixedlinks}));
			# 	}
			# 	$renamesummary.=$template->output;
			# }
			my $template=template("uploadsummary.tmpl");
			$uploadsummary="";
			$template->param(src => $src);
			$template->param(dest => $dest);
			$template->param(info => "Se actualizó el repositorio");
	 		$template->param(defaultcode => "[[!field default_img=\"/uploads/$dest\" ]]");
	 		$template->param(linkcode => "![texto alternativo](/uploads/$dest)");
			$uploadsummary=$template->output;
		
			postrename($q, $session, $src, $dest, scalar $q->param("attachment"));
		}
		else {
			IkiWiki::showform($form, $buttons, $session, $q);
		}

		exit 0;
	}
}

# Add subpages to the list of pages to be renamed, if needed.
sub rename_subpages (@) {
	error("nos colgamos porque estamos en renamepage");
	my %params = @_;

	my %torename = %{$params{torename}};
	my $q = $params{cgi};
	my $src = $torename{src};
	my $srcfile = $torename{src};
	my $dest = $torename{dest};
	my $destfile = $torename{dest};

	return () unless ($q->param("subpages") && $src ne $dest);
   error("rename_subpages no deberia pasar de aqui");
   
	my @ret;
	foreach my $p (keys %pagesources) {
		next unless $pagesources{$p}=~m/^\Q$src\E\//;
		# If indexpages is enabled, the srcfile should not be confused
		# with a subpage.
		next if $pagesources{$p} eq $srcfile;

		my $d=$pagesources{$p};
		$d=~s/^\Q$src\E\//$dest\//;
		push @ret, {
			src => $p,
			srcfile => $pagesources{$p},
			dest => pagename($d),
			destfile => $d,
			required => 0,
		};
	}
	return @ret;
}

# sub linklist {
# 	# generates a list of links in a form suitable for FormBuilder
# 	my $dest=shift;
# 	my $list=shift;
# 	# converts a list of pages into a list of links
# 	# in a form suitable for FormBuilder.
# 
# 	[map {
# 		{
# 			page => htmllink($dest, $dest, $_,
# 					noimageinline => 1,
# 					linktext => pagetitle($_),
# 				)
# 		}
# 	} @{$list}]
# }

sub renamepage_hook ($$$$) {
   error("colgamos porque estamos en renamepage_hook");
	my ($page, $src, $dest, $content)=@_;

	IkiWiki::run_hooks(renamepage => sub {
		$content=shift->(
			page => $page,
			oldpage => $src,
			newpage => $dest,
			content => $content,
		);
	});

	return $content;
}

# sub rename_hook {
#  ....
#  }

# sub do_rename ($$$) {
#	....
# }

# sub fixlinks ($$$) {
# ....
# }

1
