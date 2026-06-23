
# SMEE_URL (webhook)
export SMEE_URL="https://smee.io/WOi7gUgFDGQcVAQ"

alias srcrc="source ~/.bashrc"
alias fdir="cd ~/ros2_ws/src/ros2_ci"
alias tdir="cd ~/simulation_ws/src/ros1_ci"

# git
cleanpull() {
    git reset --hard HEAD
    git clean -fd
    git pull
}

dkradd() {
    newgrp docker
}

killjenkins() {
    kill $(cat ~/webpage_ws/jenkins/jenkins.pid)
}

tbld() {
    cd  ~/simulation_ws/src/ros1_ci
    docker build -t tortoisebot-noetic-gazebo:latest .
}

fbld() {
    cd  ~/ros2_ws/src/ros2_ci
    docker build -t fastbot-humble-gazebo:latest .
}

frun() {
    docker run --rm \
    -e DISPLAY=${DISPLAY} \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    fastbot-humble-gazebo:latest bash -lc \
    'ros2 launch fastbot_gazebo one_fastbot_room.launch.py'
}

startjenkins() {
    bash jenkins-infra/scripts/jenkins_bootstrap.sh
}

installplugins() {
    bash jenkins-infra/scripts/install_plugins.sh
}