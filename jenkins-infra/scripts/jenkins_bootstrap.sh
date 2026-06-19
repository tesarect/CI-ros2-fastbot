#!/bin/bash
# Install Docker (if needed) + Java 21 + Jenkins WAR + optional smee.io forwarder
# Usage:
#   ./jenkins_bootstrap.sh                         # start Jenkins only
#   SMEE_URL="https://smee.io/xxxxx" ./jenkins_bootstrap.sh   # also start smee forwarder

set -e

# ========= Docker =========
if ! command -v docker &> /dev/null; then
  . /etc/os-release

  if [ "${VERSION_CODENAME:-}" = "focal" ]; then
    echo "Ubuntu focal detected — installing docker.io from Ubuntu repo..."

    UPDATE_OUT="$(sudo apt-get update 2>&1)" || true

    if echo "$UPDATE_OUT" | grep -q "EXPKEYSIG F42ED6FBAB17C654"; then
      echo "ROS apt key expired; refreshing..."
      CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
      ARCH="$(dpkg --print-architecture)"
      KEYRING="/usr/share/keyrings/ros-archive-keyring.gpg"

      sudo rm -f "$KEYRING"
      curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        | sudo tee "$KEYRING" >/dev/null
      sudo chmod 644 "$KEYRING"

      ROS1_LINE="deb [arch=${ARCH} signed-by=${KEYRING}] http://packages.ros.org/ros/ubuntu ${CODENAME} main"
      ROS2_LINE="deb [arch=${ARCH} signed-by=${KEYRING}] http://packages.ros.org/ros2/ubuntu ${CODENAME} main"

      if [ -f /etc/apt/sources.list.d/ros-latest.list ]; then
        echo "$ROS1_LINE" | sudo tee /etc/apt/sources.list.d/ros-latest.list >/dev/null
        [ -f /etc/apt/sources.list.d/ros1.list ] && \
          sudo mv /etc/apt/sources.list.d/ros1.list /etc/apt/sources.list.d/ros1.list.disabled
      else
        echo "$ROS1_LINE" | sudo tee /etc/apt/sources.list.d/ros1.list >/dev/null
      fi

      echo "$ROS2_LINE" | sudo tee /etc/apt/sources.list.d/ros2.list >/dev/null

      for f in /etc/apt/sources.list.d/*.list; do
        [ "$f" = "/etc/apt/sources.list.d/ros-latest.list" ] && continue
        [ "$f" = "/etc/apt/sources.list.d/ros1.list" ] && continue
        if grep -q "http://packages.ros.org/ros/ubuntu" "$f"; then
          echo "Disabling duplicate ROS1 source: $f"
          sudo mv "$f" "${f}.disabled"
        fi
      done

      sudo rm -rf /var/lib/apt/lists/*
      sudo apt-get update
    fi

    sudo apt install -y docker.io=20.10.21-0ubuntu1~20.04.2
    sudo systemctl enable --now docker || true
    sudo mkdir -p /var/lib/docker/tmp
    sudo chmod 0711 /var/lib/docker/tmp
    sudo systemctl restart docker || true

  else
    echo "Installing Docker Engine via get.docker.com..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm -f get-docker.sh
  fi

  sudo usermod -aG docker "$USER"
  echo "Docker installed. NOTE: you may need to log out/in for group changes to apply."
else
  echo "Docker already installed. Skipping."
fi

# ========= Java 21 =========
echo "Installing Java 21..."
sudo apt-get update
sudo apt-get install -y openjdk-21-jre

# ========= Jenkins WAR =========
export JENKINS_HOME="$HOME/webpage_ws/jenkins"
mkdir -p "$JENKINS_HOME"

JENKINS_FILE="$HOME/jenkins.war"
JENKINS_VERSION="2.504.3"
JENKINS_URL_WAR="https://updates.jenkins.io/download/war/${JENKINS_VERSION}/jenkins.war"

if [ ! -f "$JENKINS_FILE" ]; then
  echo "Downloading Jenkins WAR ${JENKINS_VERSION}..."
  wget -O "$JENKINS_FILE" "$JENKINS_URL_WAR"
else
  echo "jenkins.war already present. Skipping download."
fi

if pgrep -f "java .*jenkins\.war" >/dev/null 2>&1; then
  echo "Jenkins is already running. Exiting."
  exit 0
fi

echo "Starting Jenkins..."
LOG_FILE="$JENKINS_HOME/jenkins.log"
PID_FILE="$JENKINS_HOME/jenkins.pid"

if [ -n "${SLOT_PREFIX:-}" ]; then
  sg docker -c "nohup java -jar '$JENKINS_FILE' --prefix='/${SLOT_PREFIX}/jenkins/' >'$LOG_FILE' 2>&1 & echo \$! > '$PID_FILE'"
else
  sg docker -c "nohup java -jar '$JENKINS_FILE' >'$LOG_FILE' 2>&1 & echo \$! > '$PID_FILE'"
fi

JENKINS_PID="$(cat "$PID_FILE")"
sleep 5

if [ -n "${SLOT_PREFIX:-}" ]; then
  LOCAL_URL="http://localhost:8080/${SLOT_PREFIX}/jenkins/"
  WEBHOOK_PATH="/${SLOT_PREFIX}/jenkins/github-webhook/"
else
  LOCAL_URL="http://localhost:8080/"
  WEBHOOK_PATH="/github-webhook/"
fi

CONSTRUCT_URL=""
CONSTRUCT_WEBHOOK=""
if [ -n "${SLOT_PREFIX:-}" ] && curl -s --fail --max-time 2 http://169.254.169.254/latest/meta-data/instance-id >/dev/null 2>&1; then
  INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  CONSTRUCT_URL="https://${INSTANCE_ID}.robotigniteacademy.com/${SLOT_PREFIX}/jenkins/"
  CONSTRUCT_WEBHOOK="https://${INSTANCE_ID}.robotigniteacademy.com/${SLOT_PREFIX}/jenkins/github-webhook/"
fi

echo ""
echo "Jenkins started (PID: $JENKINS_PID)"
echo "Local URL:    $LOCAL_URL"
if [ -n "$CONSTRUCT_URL" ]; then
  echo "Construct URL: $CONSTRUCT_URL"
fi

# ========= Optional smee.io forwarder =========
SMEE_PID=""
SMEE_LOG="$JENKINS_HOME/smee.log"

if [ -n "${SMEE_URL:-}" ]; then
  echo ""
  echo "Starting smee forwarder -> http://localhost:8080${WEBHOOK_PATH}"
  nohup sudo docker run --rm --network host node:20-alpine \
    sh -lc "npx -y smee-client@4.4.3 --url '${SMEE_URL}' --path '${WEBHOOK_PATH}' --port 8080" \
    >>"$SMEE_LOG" 2>&1 &
  SMEE_PID=$!
  echo "smee-client started (PID: $SMEE_PID). Log: $SMEE_LOG"
else
  echo "No SMEE_URL set — skipping smee forwarder."
fi

# ========= Save state =========
STATE_FILE="$HOME/jenkins_pid_url.txt"
{
  echo "To stop Jenkins:   kill $JENKINS_PID"
  echo "Log file:          $LOG_FILE"
  echo ""
  echo "Local Jenkins URL: $LOCAL_URL"
  if [ -n "$CONSTRUCT_URL" ]; then
    echo "Construct URL:     $CONSTRUCT_URL"
    echo "Construct Webhook: $CONSTRUCT_WEBHOOK"
  fi
  echo "Local Webhook URL: http://localhost:8080${WEBHOOK_PATH}"
  if [ -n "$SMEE_PID" ]; then
    echo ""
    echo "To stop smee:      kill $SMEE_PID"
    echo "Smee log:          $SMEE_LOG"
  fi
  echo ""
  echo "Initial admin password:"
  echo "  cat $JENKINS_HOME/secrets/initialAdminPassword"
} > "$STATE_FILE"

echo ""
echo "Details saved to: $STATE_FILE"
echo "Initial admin password:  cat $JENKINS_HOME/secrets/initialAdminPassword"
if [ -n "$CONSTRUCT_URL" ]; then
  echo "Done! Open $CONSTRUCT_URL in your browser to complete setup."
else
  echo "Done! Open $LOCAL_URL in your browser to complete setup."
fi