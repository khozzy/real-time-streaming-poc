#!/usr/bin/env bash

if [ -d "./target/" ]
then
	rm -r target/
fi

echo "[*] Building Docker image"
docker build -t build-jar-inside-docker-image .

echo "[*] Packaging Flink application"
docker create -it --name build-jar-inside-docker build-jar-inside-docker-image bash

echo "[*] Copying target/ folder to host"
docker cp build-jar-inside-docker:/target ./target

echo "[*] Removing container"
docker rm -f build-jar-inside-docker