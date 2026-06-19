#!/bin/bash
# Install Jenkins plugins using the Plugin Installation Manager Tool.
# Run from the ros2_ci repo root after jenkins_bootstrap.sh has downloaded jenkins.war.
# Usage:
#   ./jenkins-infra/scripts/install_plugins.sh
#   FORCE_PLUGINS=1 ./jenkins-infra/scripts/install_plugins.sh   # reinstall

set -euo pipefail

JENKINS_HOME="${JENKINS_HOME:-$HOME/webpage_ws/jenkins}"
JENKINS_FILE="${JENKINS_FILE:-$HOME/jenkins.war}"
JENKINS_VERSION="${JENKINS_VERSION:-2.504.3}"

PLUGINS_FILE="${PLUGINS_FILE:-jenkins-infra/jenkins/plugins.txt}"
PLUGINS_MARKER="${PLUGINS_MARKER:-$JENKINS_HOME/.plugins_installed_${JENKINS_VERSION}}"
FORCE_PLUGINS="${FORCE_PLUGINS:-0}"

PIM_VERSION="2.13.2"
PIM_JAR="$HOME/jenkins-plugin-manager-${PIM_VERSION}.jar"
PIM_URL="https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/${PIM_VERSION}/jenkins-plugin-manager-${PIM_VERSION}.jar"

echo "JENKINS_HOME:  $JENKINS_HOME"
echo "JENKINS_WAR:   $JENKINS_FILE"
echo "Jenkins ver:   $JENKINS_VERSION"
echo "Plugins file:  $PLUGINS_FILE"

if [ ! -f "$JENKINS_FILE" ]; then
  echo "ERROR: Jenkins WAR not found at $JENKINS_FILE — run jenkins_bootstrap.sh first."
  exit 1
fi

if [ ! -f "$PLUGINS_FILE" ]; then
  echo "ERROR: plugins file not found: $PLUGINS_FILE"
  echo "Run this script from the ros2_ci repo root."
  exit 1
fi

if [ "$FORCE_PLUGINS" != "1" ] && [ -f "$PLUGINS_MARKER" ]; then
  echo "Plugins already installed for Jenkins ${JENKINS_VERSION}."
  echo "To reinstall: FORCE_PLUGINS=1 $0"
  exit 0
fi

if [ ! -f "$PIM_JAR" ]; then
  echo "Downloading plugin manager tool ${PIM_VERSION}..."
  curl -fsSL "$PIM_URL" -o "$PIM_JAR"
fi

mkdir -p "$JENKINS_HOME/plugins"

echo "Installing plugins into $JENKINS_HOME/plugins ..."
java -jar "$PIM_JAR" \
  --war "$JENKINS_FILE" \
  --plugin-file "$PLUGINS_FILE" \
  --plugin-download-directory "$JENKINS_HOME/plugins"

touch "$PLUGINS_MARKER"
echo "Done. Plugins installed."
