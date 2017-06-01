#!/bin/bash

# Add .NET Core repo with key
sudo sh -c 'echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/dotnet-release/ xenial main" > /etc/apt/sources.list.d/dotnetdev.list'
#sudo apt-key adv --keyserver apt-mo.trafficmanager.net --recv-keys 417A0893
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 417A0893



# Make sure you have the lastest packages
sudo apt -y -q update

# Install Java JRE and JDK
sudo apt -y install default-jdk

# Install npm
sudo apt -y install npm

# Install n which we will use to install Nodejs
sudo npm install -g n

# Install Nodejs
sudo n stable

# Install bower, gulp and grunt used by agent
sudo npm install -g bower gulp grunt

# Install Maven, and and gradle for Java support
sudo apt install -y maven ant gradle

# Install .NET Core & Agent
# Install Prereq
sudo apt-get install -y dotnet-dev-1.0.4

# Download agent
dl=~/Downloads
if [ ! -d "$dl" ]; then
   mkdir ~/Downloads
fi
cd ~/Downloads
wget https://github.com/Microsoft/vsts-agent/releases/download/v2.104.1/vsts-agent-ubuntu.16.04-x64-2.104.1.tar.gz

# Stamp out an Agent
ad=~/Agents
if [ ! -d "$ad" ]; then
   mkdir ~/Agents
fi
cd ~/Agents

mkdir a1
cd a1

tar xzf ~/Downloads/vsts-agent-ubuntu.16.04-x64-2.104.1.tar.gz

# Prime the .Env file for the agent
./env.sh

# Not all machines will have docker
if [ -z "$(which docker)" ]; then
   echo docker=$(which docker) >> .env
fi

#configure npm
sudo chown -R $USER:$GROUP ~/.npm
sudo chown -R $USER:$GROUP ~/.config

