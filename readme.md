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

Two Jenkinsfiles are available in the repo:

| File | Test binary | Expected result |
|---|---|---|
| `Jenkinsfile` | `test_waypoints` (0.1m tolerance) | SUCCESS ✅ |
| `Jenkinsfile_failcase` | `test_fail_waypoints` (0.01m tolerance) | FAILURE ❌ |

### To demonstrate the FAIL case

**Step 1 — Change Script Path in Jenkins GUI:**

Jenkins → job → **Configure** → **Script Path** → change from `Jenkinsfile` to `Jenkinsfile_failcase` → Save

![Fail case Jenkins config](resources/fail%20case.png)

**Step 2 — Trigger a build with a dummy commit on the PR branch:**

```bash
git checkout jenkins-trigger
git commit --allow-empty -m "trigger fail case demo"
git push
```

Jenkins triggers automatically → build will show **FAILURE** (robot cannot meet 0.01m tolerance).

### To revert to PASS

Jenkins → job → **Configure** → **Script Path** → change back to `Jenkinsfile` → Save

![Pass case Jenkins config](resources/pass%20case(default).png)

Then push another dummy commit:

```bash
git commit --allow-empty -m "revert to pass case"
git push
```

---