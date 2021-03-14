FROM skycone/python3

MAINTAINER Leo Du <liusongdu@hotmail.com>

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y nginx supervisor && \
    rm -rf /var/lib/apt/lists/*

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
