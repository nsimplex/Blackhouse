PROJECT:=Blackhouse
AUTHOR:=simplex
VERSION:=1.2.1
API_VERSION:=3
DESCRIPTION:=Adds a set of mechanics for the Night Light, centered around the turning of Flowers into Evil Flowers.
FORUM_THREAD:=21767-Download-Blackhouse
FORUM_DOWNLOAD_ID:=277

PROJECT_lc:=$(shell echo $(PROJECT) | tr A-Z a-z)

ICON_DIR:=favicon

ICON:=$(ICON_DIR)/$(PROJECT_lc).tex
ICON_ATLAS:=$(ICON_DIR)/$(PROJECT_lc).xml

CORE_FILES:=modmain.lua modinfo.lua
BASE_SCRIPTS:=$(foreach f, imports.lua flowerlogic.lua customizability.lua configuration_schema.lua, src/$(f))
COMPONENT_SCRIPTS:=$(foreach f, corruptible.lua corruptionaura.lua, scripts/components/$(f))
MISC_SCRIPTS:=$(foreach f, utils.lua math/set.lua math/weakset.lua math/probability.lua, scripts/$(PROJECT_lc)/$(f))
CONFIGURATION_SCRIPTS:=rc.lua rc.defaults.lua
MISC_FILES:=AUTHORS.txt COPYING.txt $(ICON) $(ICON_ATLAS)

FILES:=$(CORE_FILES) $(BASE_SCRIPTS) $(COMPONENT_SCRIPTS) $(MISC_SCRIPTS) $(CONFIGURATION_SCRIPTS) $(MISC_FILES)


.PHONY: dist rc count modmain.lua modinfo.lua

SHELL:=/usr/bin/bash

define MOD_INFO =
--[[
Copyright (C) 2013  $(AUTHOR)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

The file $(ICON) is based on textures from Klei Entertainment's
Don't Starve and is not covered under the terms of this license.
]]--

name = "$(PROJECT)"
version = "$(VERSION)"
author = "$(AUTHOR)"


description = "$(DESCRIPTION)"
forumthread = "$(FORUM_THREAD)"


api_version = $(API_VERSION)
icon = "$(ICON)"
icon_atlas = "$(ICON_ATLAS)"
endef
export MOD_INFO

PROJECT_NAME:=$(PROJECT)
PROJECT_VERSION:=$(VERSION)
PROJECT_AUTHOR=$(AUTHOR)
PROJECT_FORUM_THREAD=$(FORUM_THREAD)
PROJECT_FORUM_DOWNLOAD_ID=$(FORUM_DOWNLOAD_ID)
export PROJECT_NAME
export PROJECT_VERSION
export PROJECT_AUTHOR
export PROJECT_FORUM_THREAD
export PROJECT_FORUM_DOWNLOAD_ID


define RC_PRE =
------
---- [Configurations]
----
---- Modify at will.
---- Remove the "--" in front of the options you wish to change.
----
---- Any line in this file can be safely deleted.
---- Feel free to clean it up by erasing option lines you don't intend on changing.
------


endef
export RC_PRE

define RC_DEFAULTS_PRE =
------
---- [Default configurations]
----
---- Modify rc.lua instead.
------


endef
export RC_DEFAULTS_PRE

PROJECT_NAME:=$(PROJECT)
PROJECT_VERSION:=$(VERSION)
export PROJECT_NAME
export PROJECT_VERSION

dist: $(PROJECT).zip

modmain.lua: tools/touch_modmain.pl
	perl -i $< $@

modinfo.lua:
	echo "$$MOD_INFO" > $@

# Please don't run this inside a symbolic link.
CURDIR_TAIL:=$(notdir $(CURDIR))
$(PROJECT).zip: $(FILES) Post.discussion Post.upload
	echo -e "$$PROJECT_NAME $$PROJECT_VERSION (http://forums.kleientertainment.com/showthread.php?21767).\nCreated by simplex.\nPackaged on `date +%F`." | \
		( cd ..; zip -FS -8 --archive-comment $(CURDIR)/$(PROJECT).zip $(foreach f, $(FILES), $(CURDIR_TAIL)/$(f)) )

Post.discussion: Post.template tools/postman.pl rc.example.lua
	tools/postman.pl discussion < $< > $@

Post.upload: Post.template tools/postman.pl rc.example.lua
	tools/postman.pl upload < $< > $@

rc: tools/rc_gen.pl rc.template.lua
	$< rc < rc.template.lua > rc.lua
	$< rc.defaults < rc.template.lua > rc.defaults.lua
	$< rc.example < rc.template.lua > rc.example.lua

rc.defaults.lua: rc

rc.lua: rc

rc.example.lua: rc

count: $(FILES)
	@(for i in $(FILES); do wc -l $$i; done) | sort -s -g | perl -e '$$t = 0; while($$l = <>){ $$t += $$l; print $$l; } print "Total: $$t\n";'
