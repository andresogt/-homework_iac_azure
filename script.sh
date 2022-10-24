#!/bin/bash
sudo apt update
sudo apt install docker.io -y
git clone https://github.com/andresogt/cicdworkshop.git
cd cicdworkshop/
sudo docker build -t sod .
sudo docker run -d -p 80:80 sod