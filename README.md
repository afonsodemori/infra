# About

👋 Hi, I'm Afonso!

I'm a Software Engineer, and this repository contains a series of scripts and configuration files to help me manage my VPS, where I make my experiments and have some projects hosted once in a while.

If this can help you somehow, go ahead and fork it :-)

You can find me at https://afonso.dev or https://github.com/afonsodemori.

# Install

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

# Copying data from another server

There's a helper to copy the data from another production server, defined in `.env`.

To do the copy, run `make copy/all`. This command will execute the following commands in sequence:

```bash
make copy/letsencrypt
make copy/mariadb
```

# Simulation server

To minimally simulate the production server, there is a script at `bin/server-simulation` that runs a debian container with privileges to run docker inside. The instructions of this README can be executed inside that container as if it was another server. It's an approximation, since it's not a VPS, but good enough for testing :-)

# Troubleshoot

## Adding swap to a new server

Sometimes it's necessary to set or add swap to the ~low cost~ VPS. It can be achieved with the following snippet:

```bash
swapon --show # or free -m -> check swap size
fallocate -l 10G /swapfile # create a swap file
chmod 600 /swapfile # set the correct permission
mkswap /swapfile # set up a swap area on the file
swapon /swapfile # activate the swap file
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab && cat /etc/fstab # make the change permanent
swapon --show # check the swap size
```

### Sonar requirements

_TODO: Automate it!_

> **Docker Host Requirements**
>
> Because SonarQube uses an embedded Elasticsearch, make sure that your Docker host configuration complies with the Elasticsearch production mode requirements and File Descriptors configuration.
>
> For example, on Linux, you can set the recommended values for the current session by running the following commands as root on the host:

```bash
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
```

From: https://hub.docker.com/_/sonarqube

---

_— [afonso.dev](https://afonso.dev)_
