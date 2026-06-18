# Base image — humble-desktop-full includes Gazebo 11, rviz2, and all ROS 2 core tools
FROM osrf/ros:humble-desktop-full

# Install Gazebo ROS integration and robot model dependencies
RUN apt-get update && apt-get install -y \
  ros-humble-gazebo-ros-pkgs \
  ros-humble-gazebo-ros2-control \
  ros-humble-xacro \
  ros-humble-robot-state-publisher \
  ros-humble-joint-state-publisher \
  python3-colcon-common-extensions \
  && rm -rf /var/lib/apt/lists/*

# Create workspace
RUN mkdir -p /ros2_ws/src
WORKDIR /ros2_ws/src

# Copy fastbot packages into the workspace
COPY ./fastbot /ros2_ws/src/

# Build workspace
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && cd /ros2_ws && colcon build --executor sequential"

# Source workspace for interactive shells
RUN echo "source /ros2_ws/install/setup.bash" >> ~/.bashrc

# Entrypoint sources both ROS 2 and workspace before any command
RUN printf '#!/bin/bash\nsource /opt/ros/humble/setup.bash\nsource /ros2_ws/install/setup.bash\nexec "$@"\n' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]