
echo "export PATH=$PATH:$HOME/.global >> .bashrc"
mkdir ~/.global
for name in bash/*; do
	if [ ${name##*.} = "sh" ]; then
		chmod a+x $name
		cp ${name%%.*} ~/.global/
	else
		cp $name ~/.global
	fi
done
