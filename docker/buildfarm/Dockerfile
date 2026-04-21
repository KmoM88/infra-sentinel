FROM ubuntu:noble

RUN apt-get update && apt-get upgrade -y \
	&& apt-get install -y \
	iputils-ping \
	tmux \
	git \
	python3 \
	python3-all \
	python3-pip

RUN pip3 install --no-cache-dir --break-system-packages \
	empy jenkinsapi rosdistro ros_buildfarm

COPY docker/buildfarm/jenkins.ini /.buildfarm/jenkins.ini

RUN git clone https://github.com/ros2/ci.git
RUN git clone https://github.com/ros-infrastructure/ros_buildfarm.git
RUN git clone https://github.com/ros-infrastructure/ros_buildfarm_config.git