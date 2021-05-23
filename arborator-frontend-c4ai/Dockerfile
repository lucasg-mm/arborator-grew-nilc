# --------BUILD PHASE--------
# specify a base image
FROM node:14

# defines a working directory
WORKDIR /usr/app

# install dependencies
COPY ./ ./
RUN npm install -g @quasar/cli
RUN npm install

# builds everything
RUN quasar build

# --------RUN PHASE--------
FROM nginx
EXPOSE 80
COPY --from=0 /usr/app/dist/spa /usr/share/nginx/html