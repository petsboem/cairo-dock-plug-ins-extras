#!/bin/bash

# This is a part of the external applet Calendar for Cairo-Dock
#
# Copyright : (C) 2009 by Royohboy & Matttbe
#                 2009-2012 by Matttbe
#                         Thanks to Nochka85 for his demo
# E-mail : werbungfuerroy@googlemail.com and matttbe@gmail.com
#
#
# This program is free software; you can redistribute it and/or
# modify it under the term -fs of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# http://www.gnu.org/licenses/licenses.html#GPL

## Rev : 21/01/2010

. /usr/share/cairo-dock/plug-ins/Dbus/CDBashApplet.sh $*

COMMAND=$0
SCRIPT_NAME=`basename $COMMAND`
DROP_DATA=$1

#############################################################################################################
get_ALL_conf_params() {

calendar_command=`get_conf_param "calendar_command"`

import_command=`get_conf_param "import_command"`

icon_command=`get_conf_param "icon_script"`
if [ "$icon_command" != "" ]; then
	if [ "${icon_command:0:1}" = "~" ]; then
		icon_command="$HOME/${icon_command:1}"
	elif [ "${icon_command:0:1}" != "/" ]; then
		icon_command="`dirname $COMMAND`/$icon_command"
	fi
fi
}

#############################################################################################################
on_click() {

which cal > /dev/null
if [ $? -eq 0 ]; then
	#dbus-send --session --dest=$DBUS_NAME $DBUS_PATH $DBUS_INTERFACE.applet.ShowDialog  string:"`cal -h`" int32:$time_dialog_cal_today
	MESSAGE="<tt>`cal -h`</tt>"
	python -c "import dbus; message=\"\"\"$MESSAGE\"\"\"; print dbus.Bus().call_blocking(
		\"$DBUS_NAME\",
		\"$DBUS_PATH\",
		\"$DBUS_INTERFACE.applet\",
		'PopupDialog',
		'a{sv}a{sv}',
		({'message': message, 'use-markup':True},{},))"
else
	echo "$APP_NAME applet -> Script Name : $SCRIPT_NAME -> 'cal' isn't installed"
	call ShowDialog "string:\"ERROR: 'cal' isn't installed\"" "int32:5"
fi
exit
}

#############################################################################################################
on_middle_click() {
calendar_command=`get_conf_param "calendar_command"`

$calendar_command
exit
}

#############################################################################################################
on_scroll_icon() {

if [ $1 -eq 1 ]; then
	# Scroll UP

	which cal > /dev/null
	if [ $? -eq 0 ]; then
		MESSAGE="<tt>`cal -h -3`</tt>"
		python -c "import dbus; message=\"\"\"$MESSAGE\"\"\"; print dbus.Bus().call_blocking(
			\"$DBUS_NAME\",
			\"$DBUS_PATH\",
			\"$DBUS_INTERFACE.applet\",
			'PopupDialog',
			'a{sv}a{sv}',
			({'message': message, 'use-markup':True},{},))"
	else
		echo "$APP_NAME applet -> Script Name : $SCRIPT_NAME -> 'cal' isn't installed"
		call ShowDialog "string:\"ERROR: 'cal' isn't installed\"" "int32:5"
	fi

else
	# Scroll DOWN

	which calendar > /dev/null
	if [ $? -nq 0 ]; then
		echo "$APP_NAME applet -> Script Name : $SCRIPT_NAME -> 'calendar' isn't installed"
		call ShowDialog "string:\"ERROR: 'calendar' isn't installed\"" "int32:5"
		exit
	fi

	calendar -f /usr/share/calendar/calendar.all > /dev/null # The loading takes a few time :-/
	sleep 0.5
	dbus-send --session --dest=$DBUS_NAME $DBUS_PATH $DBUS_INTERFACE.applet.ShowDialog  string:"`calendar -f /usr/share/calendar/calendar.all`" int32:0
fi

exit
}

#############################################################################################################
on_drop_data() {
import_command=`get_conf_param "import_command"`

if [ "`echo $DROP_DATA |grep 'file://'`" != "" ]; then 	# It's a file !
	DROP_DATA="`echo $DROP_DATA | cut -c 8-`"  # we remove 'file://' before the location
	$import_command $DROP_DATA
fi

exit
}

kill_other_processes() {
	ps ux | grep "update_calendar.sh"| grep "bash" | awk '{ system("pkill -15 -P "$2" && kill -15 "$2)}'
}

#############################################################################################################
begin() {
cp $CONF_FILE $CONF_FILE.bak
# Generate fresh calendar icon
get_ALL_conf_params

kill_other_processes

bash update_calendar.sh "$icon_command" &
exit
}

#############################################################################################################
end() {
kill_other_processes
}

#############################################################################################################
reload() {
diff $CONF_FILE $CONF_FILE.bak >/dev/null
if [ $? -eq 1 ]; then
	begin
fi
exit
}

#############################################################################################################

run $*

exit 0

