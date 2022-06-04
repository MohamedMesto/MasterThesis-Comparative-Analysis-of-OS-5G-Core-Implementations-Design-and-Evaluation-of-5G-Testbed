#!/bin/bash
# ##############################################################################
#
# Buildbot start script for "Theses"
#
# @version  1.1 (2012-03-17)
# @author   Alex
# @url      http://github.com/Thesis
# @todo     Just an initial version, a lot of things todo
# @history  1.0 Initial version
#
# ##############################################################################

# config #######################################################################
export PATH=/usr/local/share/python:/usr/local/bin:$PATH

name_master="paper-master"
name_slave="paper-slave"
url_master="http://localhost:8811/waterfall"
url_config="https://raw.github.com/tubav/Core/master/resources/build/buildbot.cfg"
conf_port="localhost:9989"
conf_pwd="pass"
conf_slave="example-slave"
# ##############################################################################

# auto setup ###################################################################
export LC_LANG="en_US.UTF-8";
function setupEasy {
    if [ "`which $1`" == "" ]; then
        echo "We need to install $1 first. Please press enter";
        read
        easy_install $1
        if [ "$?" != "0" ]; then
            echo "Ok, trying again as root. Please press enter";
            read
            sudo easy_install $1
            if [ "$?" != "0" ]; then
                echo "Ok, no luck. Please install $1 yourself. Sorry."
            fi
        fi
    fi
}
# ##############################################################################

# menu #########################################################################
while true; do
  echo "========================================="
  echo "What do you want to do?"
  echo " 0) Exit"
  echo " 1) Start master and slave"
  echo " 2) Stop master and slave"
  echo " 3) Show buildbot"
  echo " 4) Reload config"
  echo " 5) Invoke change for all projects"
  echo " 6) Invoke change for specific project"
  echo " 7) Show log"
  echo "========================================="
  echo -n "Your choice: "

  read input
  if [ "$input" == "0" ]; then
    exit 0
  elif [ "$input" == "1" ]; then
    # start master #############################################################
    if [ "`which buildbot`" == "" ]; then setupEasy buildbot; fi
    if [ ! -d "$name_master" ]; then buildbot create-master "$name_master"; fi
    if [ ! -f "$name_master/master.cfg" ]; then curl "$url_config" > "$name_master/master.cfg"; fi
    if [ "`ps waux|grep -i python|grep $name_master`" == "" ]; then buildbot start "$name_master"; fi
    # ##########################################################################

    # start slave ##################################################################
    if [ "`which buildslave`" == "" ]; then setupEasy buildbot-slave; fi
    if [ ! -d "$name_slave" ]; then buildslave create-slave "$name_slave" "$conf_port" "$conf_slave" "$conf_pwd"; fi
    if [ "`ps waux|grep -i python|grep $name_slave`" == "" ]; then nice -n 15 buildslave start "$name_slave"; fi
    # ##############################################################################
  elif [ "$input" == "2" ]; then
    buildslave stop "$name_slave"
    buildbot stop "$name_master"
  elif [ "$input" == "3" ]; then
    open "$url_master"
  elif [ "$input" == "4" ]; then
    buildbot reconfig "$name_master"
  elif [ "$input" == "5" ]; then
    buildbot sendchange --project "all" --master "$conf_port" --who "script" manual
  elif [ "$input" == "6" ]; then
    echo -n "Which project: "
    read project
    buildbot sendchange --project "$project" --master "$conf_port" --who "script" manual
  elif [ "$input" == "7" ]; then
    tail -f "${name_master}/twistd.log"
  fi
done
# ##############################################################################
