# ROS2 CI — Checkpoint 24 Task 2

## Overview
Jenkins CI pipeline that triggers on GitHub Pull Requests, builds a Docker image with ROS 2 Humble + FastBot + waypoints action server, runs Gazebo simulation + waypoints tests inside the container, and reports results back to GitHub.

---

## Repository Structure

| File | Purpose |
|---|---|
| `Dockerfile` | ROS 2 Humble + Gazebo 11 + FastBot + waypoints image |
| `Jenkinsfile` | Pipeline: build image → launch Gazebo → run waypoints tests |
| `aliases.sh` | Convenience shell aliases for the Construct machine |
| `jenkins-infra/scripts/jenkins_bootstrap.sh` | Installs + starts Jenkins each session |
| `jenkins-infra/scripts/install_plugins.sh` | Installs Jenkins plugins (run once) |
| `jenkins-infra/jenkins/plugins.txt` | Pinned plugin list for Jenkins 2.504.3 |

---

## Build image

```bash
cd ~/ros2_ws/src/ros2_ci
docker build -t fastbot-humble-gazebo:latest .
```

## Run container (manual test)

```bash
docker run --rm \
  -e DISPLAY=${DISPLAY} \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  fastbot-humble-gazebo:latest bash -lc \
  'ros2 launch fastbot_gazebo one_fastbot_room.launch.py'
```

---

## Instructions (For Evaluators)

### Prerequisites
- The Construct cloud machine with ROS 2 workspace at `~/ros2_ws`
- Docker installed
- GitHub repo `ros2_ci` with this code

### Step 1 — Start Jenkins

```bash
cd ~/ros2_ws/src/ros2_ci
bash jenkins-infra/scripts/jenkins_bootstrap.sh
```

Get the browser URL:
```bash
jenkins_address
```

Open the URL in your browser and log in with the admin credentials shown by the script.

### Step 2 — Trigger a Pull Request

On GitHub → `ros2_ci` repo → **Add file → Create new file** on a new branch → open a Pull Request against master.

Jenkins will trigger automatically within 1 minute.

### Step 3 — Verify Build

- Open Jenkins in browser → `ros2-ci` pipeline → click the PR build
- **Console Output** shows Gazebo launching and waypoints test running
- Build result: **SUCCESS**

---

## Switching Between PASS and FAIL test cases

The `Jenkinsfile` on the PR branch controls which test runs. Edit it directly on the PR branch and push — Jenkins auto-triggers.

### To run the FAIL case

On the PR branch, find this line in `Jenkinsfile`:

```bash
timeout 300 /ros2_ws/build/fastbot_waypoints/test_waypoints \
```

Change `test_waypoints` to `test_fail_waypoints`:

```bash
timeout 300 /ros2_ws/build/fastbot_waypoints/test_fail_waypoints \
```

Then commit and push to the PR branch:

```bash
git add Jenkinsfile
git commit -m "switch to fail test case"
git push
```

Jenkins triggers automatically → build will show **FAILURE** (robot cannot meet 0.01m tolerance).

### To switch back to PASS

Revert the same line back to `test_waypoints`, commit and push.

---