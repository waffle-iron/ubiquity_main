apt-get update || true
apt-get upgrade -y

apt-get update
apt-get upgrade -y

if [ uname -r  != "4.4." ]; then
    echo "Your kernel version is too old, please re-image"
    exit 5
fi

apt-get install -y apt-transport-https screen ros-kinetic-tf2-web-republisher ros-kinetic-rosbridge-server ros-kinetic-nav-core ros-kinetic-move-base-msgs ros-kinetic-sick-tim ros-kinetic-ubiquity-motor ros-kinetic-raspicam-node ros-kinetic-robot-upstart

su ubuntu -c "cd /home/ubuntu/catkin_ws/src/magni_robot; git pull"
su ubuntu -c "cd /home/ubuntu/catkin_ws/src; git clone https://github.com/UbiquityRobotics/demos"
su ubuntu -c "cd /home/ubuntu/catkin_ws/src; git clone https://github.com/UbiquityRobotics/move_basic"
su ubuntu -c "cd /home/ubuntu/catkin_ws/src; git clone https://github.com/UbiquityRobotics/fiducials"

rosdep init || true
su ubuntu -c "rosdep update"

su ubuntu -c "bash -c \" cd /home/ubuntu/catkin_ws; rosdep install --from-paths src --ignore-src --rosdistro=kinetic -y\" "
su ubuntu -c "bash -c \" cd /home/ubuntu/catkin_ws;source /opt/ros/kinetic/setup.bash; catkin_make -j 1\" "

