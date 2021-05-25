# base image
FROM ubuntu:focal

#>> dealing with the os <<
# updates package manager
RUN apt-get update

# >> dealing with the app <<
# defines a working directory to install the app
WORKDIR /usr/app

# install dependencies
RUN echo "Y" | apt-get install python3
RUN echo "Y" | apt-get install python3-pip
COPY requirements.txt ./
RUN pip3 install -r requirements.txt
RUN pip3 install -U flask-cors
COPY . .

# default command: run in production mode
CMD ["flask", "run", "--host=0.0.0.0", "--cert=adhoc"]