#!/bin/bash


# This script is aimed to make the entire environment change from dark to light
# themes and viceversa. It currently supports urxvt, vim and cmus, which are my 
# most used programs.
#
# WARNING: Some actions require parts of my setup to run properly, so don't expect
# everything to work right away

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

# Set the environmental variable 
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
	sed -i 's/^export LIGHT_THEME=.*/export LIGHT_THEME=""/' "$conffile"
fi

#URxvt
if [ -f  "$HOME/.Xresources" ]; then
	conffile="$HOME/.Xresources"
elif [ -f "$HOME/.Xdefaults" ]; then
	conffile="$HOME/.Xdefaults"
else
	echo "Could not find configuration file for urxvt" >&2
fi

if [ -f "$conffile" ]; then
	if grep -i 'URxvt\*background:.*' "$conffile" >/dev/null 2>&1; then
		$light &&\
			sed -i 's/^URxvt\*background:.*/URxvt*background: white/I' "$conffile" ||\
			sed -i 's/^URxvt\*background:.*/URxvt*background: #242424/I' "$conffile"
	else
		$light &&\
			echo 'URxvt*background: white' >> "$conffile" ||\
			echo 'URxvt*background: #242424' >> "$conffile"
	fi

	if grep -i 'URxvt\*foreground:.*' "$conffile" >/dev/null 2>&1; then
		$light &&\
			sed -i 's/^URxvt\*foreground:.*/URxvt*foreground: black/I' "$conffile" ||\
			sed -i 's/^URxvt\*foreground:.*/URxvt*foreground: white/I' "$conffile" 
	else
		$light &&\
			echo 'URxvt*foreground: black' >> "$conffile"
			echo 'URxvt*foreground: white' >> "$conffile"
	fi
fi
xrdb "$conffile"

# Apply the changes to every running terminal
for tty in /dev/pts/*; do
	is_num='^[0-9]+$'
	if [[ $(basename $tty) =~ $is_num ]]; then
		if $light; then
			echo -e '\033]11;#ffffff\007\033]10;#000000\007\033]12;#000000\007' > $tty
		else
			echo -e '\033]11;#242424\007\033]10;#ffffff\007\033]12;#ffffff\007' > $tty
		fi
	fi
done


# VIM
# Vim already has the scheme changing in its config file, but this will change it for all the 
# current running instances (provided you launched them as servers, for which there's an alias
# in my bash config)
vim --serverlist |\
	while read server; do
		vim --servername "$server" --remote-send '<Esc>:call ColorChange()<CR>'
	done

# CMUS
if hash cmus 2>/dev/null; then
	# If cmus is running...
	if cmus-remote -Q >/dev/null 2>&1; then
		if $light; then
			cmus-remote -C "colorscheme tension-light"
		else
			cmus-remote -C "colorscheme gems"
		fi
	fi
fi
