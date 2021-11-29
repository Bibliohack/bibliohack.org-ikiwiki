# bibliohack.org-ikiwiki

Customized ikiwiki installation for <https://bibliohack.org>.

This is a whimsical experiment to know the limits of ikiwiki! 

Here are some of the main customizations:

### YAML & Field

Yaml and Field plugin enable yaml headers with field metadata on all post for various uses

### Translation

We use a (unfinished but functional) modified version of [intrigeri's po plugin](https://ikiwiki.info/plugins/po/). To make a page "translatable" 
we need add a `translatable: yes` line to meta yaml header, and run `ikiwiki --setup ..` to create a translated version of the page. Then, the complete 
article content (that has been copied from the original language) must be fully manually translated.

### Tag translation

We use a provisional method. In the translated page you must add a hash field called "translated_tags" like this

```
translated_tags:
 - tag: red
   tranlated: rojo
 - tag: green
   translated: verde
```

A bug (?) in tagged() pagespec exclude translated pages from the list obtained with inline directive, then we use `field_item(translated_tags tag)` from
[field pagespec](https://ikiwiki.info/plugins/contrib/field/#index5h2) that select pages with 'translated_tags' field and tag. To do this we modified field 
plugin to enable regex into hash object.

### Uploaded media

Uploadmedia plugin upload images to a self-created folder with the name of the page in `/media_underlay/uploads/...` in order to keep media out 
of the `src` repository, and when the image has been uploaded the page returns the path of the image to place in yaml meta header or markdown content.

## Content and Media

The content of website is located in <https://github.com/Bibliohack/bibliohack.org-contents> and the `/media_undelay/uploads/` media file is managed with `rclone` or `rsync`.

