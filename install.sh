#!/bin/bash

echo "export PATH=$PATH:$HOME/.global" >> .bashrc
[ ! -d "$HOME/.global" ] && mkdir "$HOME/.global"
for name in bash/*; do
	if [ ${name##*.} = "sh" ]; then
		chmod a+x $name
		cp $name "$HOME/.global/${name%%.*}"
	else
		cp $name ~/.global
	fi
done
