# sd-serverdiagnostics
Server Connector For MageDiagnostics

## Installation Process:

- `git clone` the repo contents to the /opt folder on each webserver

- cp .env.sample .env

- In the .env file, set the Server key from the server key value found for that client in the magediagnostics dashboard

- In the .env file, set the `SD_MAGEDIAGNOSTICS_API_ENDPOINT` to `https://magediagnostics.com:1234/api/v1/server`

- Add a cron tab entry `0 0 * * * /opt/sd-serverdiagnostics/main.sh`