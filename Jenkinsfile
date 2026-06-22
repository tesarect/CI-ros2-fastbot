pipeline {
  agent any

  environment {
    DOCKER_IMAGE = 'fastbot-humble-gazebo'
    GAZEBO_STARTUP_TIMEOUT = '90'
  }

  stages {
    stage('Compute Tag') {
      steps {
        script {
          env.IMAGE_TAG = (env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : 'local')
        }
        echo "Using image tag: ${IMAGE_TAG}"
      }
    }

    stage('Build Docker Image') {
      steps {
        echo "Building Docker image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
        sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} ."
      }
    }

    stage('Launch Gazebo') {
      steps {
        echo "Launching Gazebo with FastBot (debug — no tests)"
        echo "
              ░████                                        ░██                                                  ░██        
            ░██                                           ░██                                                  ░██        
          ░████████ ░██░████  ░███████  ░█████████████     ░████████  ░██░████  ░██████   ░████████   ░███████  ░████████  
            ░██    ░███     ░██    ░██ ░██   ░██   ░██    ░██    ░██ ░███           ░██  ░██    ░██ ░██    ░██ ░██    ░██ 
            ░██    ░██      ░██    ░██ ░██   ░██   ░██    ░██    ░██ ░██       ░███████  ░██    ░██ ░██        ░██    ░██ 
            ░██    ░██      ░██    ░██ ░██   ░██   ░██    ░███   ░██ ░██      ░██   ░██  ░██    ░██ ░██    ░██ ░██    ░██ 
            ░██    ░██       ░███████  ░██   ░██   ░██    ░██░█████  ░██       ░█████░██ ░██    ░██  ░███████  ░██    ░██ 
                                                                                                                                                                                                                                                                                
        "
        sh '''
          xhost +local:docker || true
          docker run --rm \
            -e DISPLAY=${DISPLAY} \
            -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
            ${DOCKER_IMAGE}:${IMAGE_TAG} bash -lc '
              set -e
              source /opt/ros/humble/setup.bash
              source /ros2_ws/install/setup.bash

              echo "Launching Gazebo..."
              ros2 launch fastbot_gazebo one_fastbot_room.launch.py

              echo "Gazebo exited."
            '
        '''
      }
    }
  }

  post {
    always {
      sh 'docker image prune -f >/dev/null 2>&1 || true'
    }
    success { echo 'Pipeline completed successfully!' }
    failure  { echo 'Pipeline failed!' }
  }
}