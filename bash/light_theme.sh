#!/bin/bash

# idea() {
# 	[ -d "$HOME" ]
# 	cat > "$HOME"/.IntelliJIdea2017.1/config/options/colors.scheme.xml <<EOF
# <application>
#   <component name="EditorColorsManagerImpl">
# 	  <global_color_scheme name="_@user_Darcula" />
# 	</component>
# </application>
# EOF

# <laf class-name="com.intellij.ide.ui.laf.darcula.DarculaLaf"
# <laf class-name="com.intellij.ide.ui.laf.IntelliJLaf"
# }

case $SHELL in
	*bash)
		if [ -f "$HOME/.bash_customs" ]; then
			conffile="$HOME/.bash_customs"
		else
			conffile="$HOME/.bashrc"
		fi;;
	*zsh)
		if [ -f "$HOME/.zsh_customs" ]; then
			conffile="$HOME/.zsh_customs"
		else
			conffile="$HOME/.zshrc"
		fi;;
	*ksh)
		conffile="$HOME/.profile";;
	*csh|*tcsh)
		conffile="$HOME/.login";;
esac

if [ -z $LIGHT_THEME ]; then
	light=true
	echo "Setting light theme"
	export -p LIGHT_THEME="true"
	echo "export LIGHT_THEME=true" >> "$conffile"
else
	light=false
	echo "Setting dark theme"
	export LIGHT_THEME=""
	sed -i '/^export LIGHT_THEME=.*/d' "$conffile"
fi

#URxvt
if [ -f  "$HOME/.Xresources" ]; then
	conffile="$HOME/.Xresources"
elif [ -f "$HOME/.Xdefaults" ]; then
	conffile="$HOME/.Xdefaults"
else
	echo "Could not find configuration file for urxvt" >&2
fi

if [ -f "$conffile" ] && $light; then
	sed -i 's/^URxvt\*background:.*/URxvt*background: white/' "$conffile"
	sed -i 's/^URxvt\*foreground:.*/URxvt*foreground: black/' "$conffile"

	# Apply the changes to the running terminal
	[ $TERM=rxvt-unicode-256color ] && echo -e '\033]11;#000000\007\033]10;#ffffff\007'
else
	sed -i 's/^URxvt\*background:.*/URxvt*background: #242424/' "$conffile"
	sed -i 's/^URxvt\*foreground:.*/URxvt*foreground: white/' "$conffile"

	# Apply the changes to the running terminal
	[ $TERM=rxvt-unicode-256color ] && echo -e '\033]11;#242424\007\033]10;#000000\007'
fi

xrdb "$conffile"

# VIM
# Vim already has the scheme changing in its config file, but this will change it for all the 
# current running instances (provided you launched them as servers, for which there's an alias
# in my bash config)
vim --serverlist |\
	while read server; do
		vim --servername "$server" --remote-send '<Esc>:call ColorChange()<CR>'
	done
