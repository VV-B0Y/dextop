#!/bin/bash

# dependencies #

curl -sL get.cnsl.app/console > "${PREFIX}"/bin/console && . "${PREFIX}"/bin/console

# script #

script=$(basename -- "${BASH_SOURCE[0]}")

# version #

version="11-18-2021"

# usage #

while (($#))
do
	case "${1}" in
		-t|--termux)
			dextop_option="termux"
		;;
		
		-p|--proot)
			dextop_option="proot"
		;;
		
		-i|--i3wm)
			desktop_option="i3wm"
		;;
		
		-e|--ede)
			desktop_option="ede"
		;;

		-k|--kde)
			desktop_option="kde"
		;;

		-x|--xfce)
			desktop_option="xfce"
		;;
		
		-n|--none)
			desktop_option="none"
		;;
		
		-b|--base)
			install_option="base"
		;;

		-f|--full)
			install_option="full"
		;;

		-h|--help)
			echo
			echo -e "USAGE:"
			echo
			echo -e "-t, --termux           \t Setup Termux environment only - VNC setup not included."
			echo -e "-p, --proot            \t Setup Proot environment - VNC setup included."
			echo
			echo -e "-i, --i3wm             \t I3WM setup: install i3 window manager and utilities."
			echo
			echo -e "-e, --ede              \t EDE setup: install E desktop environment and utilities."
			echo -e "-k, --kde              \t KDE5 setup: install K desktop environment and utilities."
			echo -e "-x, --xfce             \t XFCE4 setup: install XFCE desktop environment and utilities."
			echo -e "-n, --none             \t No DE setup: console access to environment and utilities."
			echo
			echo -e "-b, --base             \t Base setup: download and install base distribution image only."
			echo
			echo -e "-f, --full             \t Full setup: download and install full desktop environment and utilities."
			echo
			echo -e "-h, --help             \t Show help and usage information."
			echo
			echo -e "'${script}' [ Version ${version} ]"
			echo

			exit
		;;

		"")
			# handle empty argument:
			# use default values specified in script

			:
		;;

		*)
			echo
			echo -e "Usage: ${script} | [OPTION]"
			echo
			echo -e "${script}: Unknown option '${1}'"
			echo -e "Type './${script} --help' for help and usage information."
			echo

			exit 1

		;;

		esac

	shift

done

# clear #

console.clear

# message #

console.title "Linux on Android" "Termux // Dextop // Ubuntu" "${version}"
echo

# prompt #

console.script "Initializing setup [ ${script%-*} ]"
echo

# variables #

# set defaults

[ -z "${dextop_option}" ]														&& dextop_option="proot"
[ -z "${desktop_option}" ]														&& desktop_option="i3wm"

# export variables

echo '# variables #'															>> "${PREFIX}"/bin/dextop

echo "export version=${version}"												>> "${PREFIX}"/bin/dextop

echo '# dextop #'																>> "${PREFIX}"/bin/dextop

echo 'export MAIN_DIRECTORY="${PREFIX%/*}"'										>> "${PREFIX}"/bin/dextop
echo 'export BINARIES_DIRECTORY="${PREFIX}"/bin'								>> "${PREFIX}"/bin/dextop
echo 'export CONFIGURATIONS_DIRECTORY="${PREFIX}"/etc'							>> "${PREFIX}"/bin/dextop
echo 'export LIBRARIES_DIRECTORY="${PREFIX}"/lib'								>> "${PREFIX}"/bin/dextop
echo 'export SOURCES_DIRECTORY="${PREFIX}"/etc/apt'								>> "${PREFIX}"/bin/dextop
echo 'export BACKUP_DIRECTORY="${MAIN_DIRECTORY}"/bkp'							>> "${PREFIX}"/bin/dextop
echo 'export IMAGE_DIRECTORY="${MAIN_DIRECTORY}"/img'							>> "${PREFIX}"/bin/dextop
echo 'export ISO_DIRECTORY="${MAIN_DIRECTORY}"/iso'								>> "${PREFIX}"/bin/dextop
echo 'export MOUNT_DIRECTORY="${MAIN_DIRECTORY}"/mnt'							>> "${PREFIX}"/bin/dextop

echo '# options #'																>> "${PREFIX}"/bin/dextop

echo "export dextop_option=${dextop_option}"									>> "${PREFIX}"/bin/dextop
echo "export desktop_option=${desktop_option}"									>> "${PREFIX}"/bin/dextop
echo "export install_option=${install_option}"									>> "${PREFIX}"/bin/dextop

# source variables

[ -f "${PREFIX}"/bin/dextop ] && . "${PREFIX}"/bin/dextop

# values #

utilities_list=(
	termux-utilities
	termux-setup
	proot-utilities
	proot-setup
	vnc-utilities
	vnc-setup
	user-utilities
	user-setup
)

# download #

console.download get.dxtp.app "${BINARIES_DIRECTORY}" ${utilities_list[@]}

# clear #

console.clear

# initialize setup list

setup_list=()

# options #

# termux

if [[ "${dextop_option}" = "termux" ]]
then
	# populate setup list

	setup_list+=(
		termux-setup
		vnc-setup
	)
fi

# proot

if [[ "${dextop_option}" = "proot" ]]
then
	# populate setup list

	setup_list+=(
		termux-setup
		proot-setup
		vnc-setup
	)
fi

# setup #

for setup in ${setup_list[@]}
do
	"${BINARIES_DIRECTORY}"/"${setup}"

	console.clear
done

# source variables:
# get additional setup values

[ -f "${PREFIX}"/bin/dextop ] && . "${PREFIX}"/bin/dextop

# write configuration

cat << 'FILE' ->> "${HOME_DIRECTORY}"/.profile

# dextop configuration #

# download / install / configure packages and scripts for user session:
# use 'user-packages' and 'user-addons' to customize setup

if [ ! -f "${BINARIES_DIRECTORY}"/dextop-configuration-complete ]
then
	# run configuration utilities

	"${BINARIES_DIRECTORY}"/proot-configuration

	# run user setup

	"${BINARIES_DIRECTORY}"/user-setup

	# confirm uninterrupted configuration

	echo "yes" > "${BINARIES_DIRECTORY}"/dextop-configuration-complete
else
	:
fi
FILE

# checkpoint #

# confirm uninterrupted configuration

echo "yes" > "${BINARIES_DIRECTORY}"/dextop-checkpoint-complete

# cleanup #

if [ -f "${BINARIES_DIRECTORY}"/dextop-checkpoint-complete ]
then
	# message #

	console.scs "Setup complete [ ${script%-*} ]"
	echo

	console.fwd "Removing setup files..."
	echo

	# remove setup files

	remove_list=(
		"${HOME}/dextop"
	)

	console.delete ${remove_list[@]}
	
	# remove sensitive information from dextop file
	
	sed -i						\
		-e '/user_email/d'		\
		-e '/user_password/d'	"${BINARIES_DIRECTORY}"/dextop

	# exit shell after setup

	console.countdown "Closing in" 3 

	kill -9 $(pgrep -f "${SHELL}")
else
	console.err "Setup errors were encountered [ ${script%-*} ]"
	echo

	console.inf "Consult setup logs at '"${PREFIX}"/var/log/' for details."
	echo
fi

# test