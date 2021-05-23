# base image
FROM ubuntu:focal

# >> dealing with Nginx <<
# installs nginx
RUN apt-get update
RUN echo "y" | apt-get install nginx

# allows HTTP traffic
RUN echo "y" | apt-get install ufw
RUN ufw allow 'Nginx HTTP'

# >> dealing with the app <<
# defines a working directory to install the app
WORKDIR /var/www/app

# install dependencies
RUN echo "Y" | apt-get install python3
RUN echo "Y" | apt-get install python3-pip
COPY requirements.txt ./
RUN pip3 install -r requirements.txt
RUN pip3 install -U flask-cors
COPY . .

# seeds database
RUN echo "y" | python3 manage.py seed_db

# default command: run in production mode
CMD ["flask", "run"]