中文版：docker volume create portainer_data  
docker run -d --restart=always --name="portainer" -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data 6053537/portainer-ce:latest  


官方版：docker volume create portainer_data  
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce

docker run -d --name=heimdall -p 80:80 -p 443:443 -v /data/heimdall:/config --restart=unless-stopped linuxserver/heimdall


docker run -d --name talebook -p 8080:80 -v /data/Calibre:/data talebook/talebook


docker run -d --name qd -p 8923:80 -v /data/qd/config:/usr/src/app/config a76yyyy/qiandao

docker run -d --restart=unless-stopped -v /data/alist:/opt/alist/data -p 5244:5244 -e PUID=0 -e PGID=0 -e UMASK=022 --name="alist" xhofe/alist:latest


docker run -d --name lucky --restart=always --net=host -v /data/luckyconf:/goodluck gdy666/lucky


docker run -d --net=host 1activegeek/airconnect


docker run -d --name=douban-api-rs --restart=unless-stopped -p 5000:80 ghcr.io/cxfksword/douban-api-rs:latest


