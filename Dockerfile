# https://medium.com/swlh/alpine-slim-stretch-buster-jessie-bullseye-bookworm-what-are-the-differences-in-docker-62171ed4531d
FROM ubuntu:16.04
#FROM python:3.7.10-buster

MAINTAINER Leo Du <liusongdu@hotmail.com>

ENV PYTHON_VERSION 3.7.10

# Install required packages and remove the apt packages cache when done.
RUN apt-get update && \
    #apt-get upgrade -y && \
    apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev curl nginx supervisor libmysqlclient-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Python3
# ${PYTHON_VERSION::3} is e.g. 3.7
RUN cd /usr/src && \
    curl -SL "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" -o Python-${PYTHON_VERSION}.tgz && \
    tar xzf Python-${PYTHON_VERSION}.tgz && \
    rm -f /usr/src/Python-${PYTHON_VERSION}.tgz

RUN cd /usr/src/Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make altinstall && \
    ln -s /usr/local/bin/python3 /usr/local/bin/python && \
    rm -rf /usr/src/Python-${PYTHON_VERSION}

# Install pip
#RUN python -m pip install --upgrade pip setuptools --no-deps
ENV PYTHON_PIP_VERSION 21.0.1
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/b60e2320d9e8d02348525bd74e871e466afdf77c/get-pip.py
ENV PYTHON_GET_PIP_SHA256 c3b81e5d06371e135fb3156dc7d8fd6270735088428c4a9a5ec1f342e2024565

RUN apt-get update && \
    #apt-get upgrade -y && \
    apt-get install -y wget && \
    rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	\
	wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
	echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict -; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

# Install uwsgi now because it takes a little while
RUN python -m pip install uwsgi --no-deps

# setup all the configfiles
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
COPY nginx-app.conf /etc/nginx/sites-available/default
COPY supervisor-app.conf /etc/supervisor/conf.d/

# COPY requirements.txt and RUN pip install BEFORE adding the rest of your code, this will cause Docker's caching mechanism
# to prevent re-installing (all your) dependencies when you made a change a line or two in your app.
COPY app/requirements.txt /home/docker/code/app/
RUN python -m pip install -r /home/docker/code/app/requirements.txt --no-deps

# add (the rest of) our code
COPY . /home/docker/code/

EXPOSE 80

CMD ["supervisord", "-n"]
