# Infra

Repository with helpers to easily manage my personal VPS.

## Install

To start using this repository in a new production environment, start by installing git, creating the workdir and cloning this repository into it by executing the following snippet:

```bash
apt update && apt install -y git vim
mkdir /fns && cd /fns
git clone https://gitlab.com/afonsodemori/infra.git && cd infra
cp .env.dist .env && vi .env
```

Once the repository is cloned and `.env` is correctly set, run `bin/install` to run the first installation. It will:

1. Install the required software (`bin/install-packages`)
2. Copy the `.profile` for root with shortcuts and PS1 configuration (`bin/install-profile`)
3. Create the directories for the project (`bin/install-dirs`)
4. Generate an SSH key and copy it to the current production server (`bin/install-ssh-keys`)

Each of the previous commands can also be run independently and as much as needed.

## Simulation server

To minimally simulate the production server, there is a script at `bin/server-simulation` that runs a debian container with privileges to run docker inside. The instructions of this README can be executed inside that container as if it was another server. It's an approximation, since it's not a VPS, but good enough for testing :-)
