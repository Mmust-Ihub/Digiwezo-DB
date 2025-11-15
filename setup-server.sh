#! /bin/bash

# --------- Example usage: sudo ./setup-server.sh "REMOTE_USER"
USERNAME="$1"

echo "Updating system packages..."
apt update -y
upgrade -y

echo "Installing essential tools..."
apt install -y \
	curl \
	wget \
	unzip \
	software-properties-common \
	ca-certificates \
	apt-transport-https \
	ca-certificates \
	gnupg \
	lsb-release

echo "System updated and essential tools installed"

mkdir -p /home/"${USERNAME}"/db
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/db

echo "Installing Docker..."

if ! command -v "aws" >/dev/null 2>&1; then
	# Remove any conflicting packages
	for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt remove $pkg 2>/dev/null || true; done

	# Add Docker's official GPG key
	install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	chmod a+r /etc/apt/keyrings/docker.asc

	# Add the repository to APT sources
	echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
		tee /etc/apt/sources.list.d/docker.list >/dev/null

	# Install Docker
	apt update -y
	apt install -y docker-ce docker-ce-cli docker-compose-plugin

	# Start and enable Docker
	systemctl start docker
	systemctl enable docker

	# Add current user to docker group
	usermod -aG docker "$USERNAME"
	echo "Added $USERNAME to docker group."

	echo "Docker installed successfully"

fi

echo " Installing the AWS CLI"

if ! command -v "aws" >/dev/null 2>&1; then
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	./aws/install
	rm -rf aws*
fi
