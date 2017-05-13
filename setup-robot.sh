apt-get update || true
apt-get upgrade -y

apt-get update
apt-get upgrade -y

if [ uname -r  != "4.4." ]; then
    echo "Your kernel version is too old, please re-image"
    exit 5
fi

apt-get install -y apt-transport-https screen ros-kinetic-tf2-web-republisher \
ros-kinetic-rosbridge-server ros-kinetic-nav-core ros-kinetic-move-base-msgs \
ros-kinetic-sick-tim ros-kinetic-ubiquity-motor ros-kinetic-raspicam-node \
ros-kinetic-robot-upstart pifi

su ubuntu -c "cd /home/ubuntu/catkin_ws/src/magni_robot; git pull"
su ubuntu -c "cd /home/ubuntu/catkin_ws/src; git clone https://github.com/UbiquityRobotics/demos"
su ubuntu -c "cd /home/ubuntu/catkin_ws/src; git clone https://github.com/UbiquityRobotics/move_basic"
su ubuntu -c "cd /home/ubuntu/catkin_ws/src; git clone https://github.com/UbiquityRobotics/fiducials"
su ubuntu -c "cd /home/ubuntu/catkin_ws/src; git clone https://github.com/UbiquityRobotics/ubiquity_motor"

rosdep init || true
su ubuntu -c "rosdep update"

su ubuntu -c "bash -c \" cd /home/ubuntu/catkin_ws; rosdep install --from-paths src --ignore-src --rosdistro=kinetic -y\" "
su ubuntu -c "bash -c \" cd /home/ubuntu/catkin_ws;source /opt/ros/kinetic/setup.bash; catkin_make -j 1\" "

cat <<EOM >/usr/sbin/magni-joystick
#!/bin/bash

function log() {
  logger -s -p user.$1 ${@:2}
}

log info "magni-joystick: Using workspace setup file /home/ubuntu/catkin_ws/devel/setup.bash"
source /home/ubuntu/catkin_ws/devel/setup.bash

log_path="/tmp"
if [[ ! -d $log_path ]]; then
  CREATED_LOGDIR=true
  trap 'CREATED_LOGDIR=false' ERR
    log warn "magni-joystick: The log directory you specified \"$log_path\" does not exist. Attempting to create."
    mkdir -p $log_path 2>/dev/null
    chown ubuntu:ubuntu $log_path 2>/dev/null
    chmod ug+wr $log_path 2>/dev/null
  trap - ERR
  # if log_path could not be created, default to tmp
  if [[ $CREATED_LOGDIR == false ]]; then
    log warn "magni-joystick: The log directory you specified \"$log_path\" cannot be created. Defaulting to \"/tmp\"!"
    log_path="/tmp"
  fi
fi

export ROS_HOSTNAME=$(hostname).local

export ROS_MASTER_URI=http://$ROS_HOSTNAME:11311

log info "magni-joystick: Launching ROS_HOSTNAME=$ROS_HOSTNAME, ROS_IP=$ROS_IP, ROS_MASTER_URI=$ROS_MASTER_URI, ROS_LOG_DIR=$log_path"

# Punch it.
export ROS_HOME=$(echo ~ubuntu)/.ros
export ROS_LOG_DIR=$log_path
roslaunch magni_demos joystick.launch &
PID=$!

log info "magni-joystick: Started roslaunch as background process, PID $PID, ROS_LOG_DIR=$ROS_LOG_DIR"
echo "$PID" > $log_path/magni-joystick.pid

wait "$PID"
EOM

chmod +x /usr/sbin/magni-joystick

cat <<EOM >$R/etc/systemd/system/magni-joystick.service 
[Unit]
After=NetworkManager.service time-sync.target
Conflicts=magni-speech-commands.service

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/sbin/magni-joystick

[Install]
WantedBy=multi-user.target

EOM

cat <<EOM >/usr/sbin/magni-speech-commands
#!/bin/bash

function log() {
  logger -s -p user.$1 ${@:2}
}

log info "magni-speech-commands: Using workspace setup file /home/ubuntu/catkin_ws/devel/setup.bash"
source /home/ubuntu/catkin_ws/devel/setup.bash

log_path="/tmp"
if [[ ! -d $log_path ]]; then
  CREATED_LOGDIR=true
  trap 'CREATED_LOGDIR=false' ERR
    log warn "magni-speech-commands: The log directory you specified \"$log_path\" does not exist. Attempting to create."
    mkdir -p $log_path 2>/dev/null
    chown ubuntu:ubuntu $log_path 2>/dev/null
    chmod ug+wr $log_path 2>/dev/null
  trap - ERR
  # if log_path could not be created, default to tmp
  if [[ $CREATED_LOGDIR == false ]]; then
    log warn "magni-speech-commands: The log directory you specified \"$log_path\" cannot be created. Defaulting to \"/tmp\"!"
    log_path="/tmp"
  fi
fi

export ROS_HOSTNAME=$(hostname).local

export ROS_MASTER_URI=http://$ROS_HOSTNAME:11311

log info "magni-speech-commands: Launching ROS_HOSTNAME=$ROS_HOSTNAME, ROS_IP=$ROS_IP, ROS_MASTER_URI=$ROS_MASTER_URI, ROS_LOG_DIR=$log_path"

# Punch it.
export ROS_HOME=$(echo ~ubuntu)/.ros
export ROS_LOG_DIR=$log_path
roslaunch magni_demos speech_control.launch &
PID=$!

log info "magni-speech-commands: Started roslaunch as background process, PID $PID, ROS_LOG_DIR=$ROS_LOG_DIR"
echo "$PID" > $log_path/magni-joystick.pid

wait "$PID"
EOM

chmod +x /usr/sbin/magni-speech-commands

cat <<EOM >$R/etc/systemd/system/magni-speech-commands.service 
[Unit]
After=NetworkManager.service time-sync.target
Conflicts=magni-joystick.service

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/sbin/magni-speech-commands

[Install]
WantedBy=multi-user.target

EOM