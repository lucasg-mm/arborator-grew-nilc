# --------BUILD PHASE--------
# specify a base image
FROM node:14

# defines a working directory
WORKDIR /usr/app

# install dependencies
COPY ./package.json ./
RUN npm install -g @quasar/cli
RUN npm install
COPY ./ ./

# builds everything
RUN quasar build

CMD ["quasar", "serve", "./dist/spa", "--port", "80", "--https", "--proxy", "prod-proxy.js", "--cert", "./keys/cert.pem", "--key", "./keys/arborator-grew.pem"]