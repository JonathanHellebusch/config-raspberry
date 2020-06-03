#!/bin/bash

#ssh pi@pi
#...raspberry

git clone https://github.com/JonathanHellebusch/config-raspberry.git
sed -i -e 's/\r$//' ./config-raspberry/start-config.sh
chmod 777 ./config-raspberry/start-config.sh
sudo ./config-raspberry/start-config.sh