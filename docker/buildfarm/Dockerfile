FROM ubuntu:noble

RUN apt-get update && apt-get upgrade \
	&& apt-get install -y \
	python3 \
	python3-all \
	python3-pip

RUN pip3 install --no-cache-dir --break-system-packages \
	empy jenkinsapi rosdistro ros_buildfarm

COPY docker/buildfarm/jenkins.ini ~/.buildfarm/jenkins.ini