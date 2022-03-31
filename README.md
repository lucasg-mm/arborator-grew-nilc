# Arborator-Grew NILC
Arborator-Grew NILC is a fork of the recently proposed Arborator-Grew annotation tool, which is [available here](https://github.com/Arborator).

## How to Install and Run it

### Installing Docker and Docker Compose

Arborator-Grew NILC is a containerized application. It's meant to be installed and run using Docker and Docker Compose, so, in order to follow this tutorial, you will have to install these two pieces of software first.

* [Click here for information about how to install Docker](https://docs.docker.com/engine/install/)
* [Click here for information about how to install Docker Compose](https://docs.docker.com/compose/install/)

### Installing the Application Itself

#### Run the Preparatory Script

After Docker and Docker Compose are installed, clone this repository and go to its root directory. Execute the bash script named `prep.bash` inside the `project_management_scripts` directory. You can do this by executing the following command in the repo's root directory:

```console
bash ./project_management_scripts/prep.bash
```

This script executes some preparatory work, like setting up an SSL self-signed certificate for the https. 

#### Insert Social Login Keys and Secret

This app uses social login. In order to make this feature work correctly, please, insert your social login keys and secrets inside `backend/.flaskenv`.

#### Run the App in Development Mode

After that, to install and run the app in development mode, execute the following command in the repo's root directory:

```console
docker-compose -f docker-compose.dev.yml up
```

The app will then be available at https://localhost:8080/.

#### Run the App in Production Mode

If you want to install and run the app in production mode, insert the host and the address where you intend to host your app inside the `urls.js` file inside the `frontend` directory.

After that, execute the following command in the repo's root directory:

```console
docker-compose up
```
The app will then be available at https://localhost:80/. It will also be available at the address specified in `frontend/urls.js`, if everything else regarding that is already set up.
