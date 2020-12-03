#!/usr/bin/env bash

#For maximum compatibility, use pproxy for converting socks5 to http:
#$ pproxy --reuse -r socks5://127.0.0.1:18889 -l http://:8080/ -vv

#Some enhances/supplements by me:
# Confirm the environment variable is set correctly: 
#docker info |& grep -i proxy
# Check the http proxy is in use when running docker:
#$ sudo tcpdump -i any port 8080
#or
#$ sudo tcpdump -i any port 18889


#https://stackoverflow.com/questions/61590317/use-socks5-proxy-from-host-for-docker-build
#https://docs.docker.com/config/daemon/systemd/#httphttps-proxy

#    regular install

#    Create a systemd drop-in directory for the docker service:

#    sudo mkdir -p /etc/systemd/system/docker.service.d

#    Create a file named /etc/systemd/system/docker.service.d/http-proxy.conf that adds the HTTP_PROXY environment variable:

#    [Service]
#    Environment="HTTP_PROXY=http://proxy.example.com:80"

#    If you are behind an HTTPS proxy server, set the HTTPS_PROXY environment variable:

#    [Service]
#    Environment="HTTPS_PROXY=https://proxy.example.com:443"

#    Multiple environment variables can be set; to set both a non-HTTPS and a HTTPs proxy;

#    [Service]
#    Environment="HTTP_PROXY=http://proxy.example.com:80"
#    Environment="HTTPS_PROXY=https://proxy.example.com:443"

#    If you have internal Docker registries that you need to contact without proxying you can specify them via the NO_PROXY environment variable.

#    The NO_PROXY variable specifies a string that contains comma-separated values for hosts that should be excluded from proxying. These are the options you can specify to exclude hosts:
#        IP address prefix (1.2.3.4)
#        Domain name, or a special DNS label (*)
#        A domain name matches that name and all subdomains. A domain name with a leading “.” matches subdomains only. For example, given the domains foo.example.com and example.com:
#            example.com matches example.com and foo.example.com, and
#            .example.com matches only foo.example.com
#        A single asterisk (*) indicates that no proxying should be done
#        Literal port numbers are accepted by IP address prefixes (1.2.3.4:80) and domain names (foo.example.com:80)

#    Config example:

#    [Service]
#    Environment="HTTP_PROXY=http://proxy.example.com:80"
#    Environment="HTTPS_PROXY=https://proxy.example.com:443"
#    Environment="NO_PROXY=localhost,127.0.0.1,docker-registry.example.com,.corp"

#    Flush changes and restart Docker

#    sudo systemctl daemon-reload
#    sudo systemctl restart docker

#    Verify that the configuration has been loaded and matches the changes you made, for example:

#    sudo systemctl show --property=Environment docker
#        
#    Environment=HTTP_PROXY=http://proxy.example.com:80 HTTPS_PROXY=https://proxy.example.com:443 NO_PROXY=localhost,127.0.0.1,docker-registry.example.com,.corp


#https://github.com/ApolloAuto/apollo/issues/12224
#Disable that proxy and try again, or use http/https proxy. See https://docs.bazel.build/versions/master/external.html#using-proxies


#https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file
#https://docs.docker.com/config/daemon/systemd/#custom-docker-daemon-options

#Custom Docker daemon options

#There are a number of ways to configure the daemon flags and environment variables for your Docker daemon. The recommended way is to use the platform-independent daemon.json file, which is located in /etc/docker/ on Linux by default. See Daemon configuration file.

#You can configure nearly all daemon configuration options using daemon.json. The following example configures two options. One thing you cannot configure using daemon.json mechanism is a HTTP proxy.


#https://docs.docker.com/network/proxy/#configure-the-docker-client
#Configure Docker to use a proxy server

#If your container needs to use an HTTP, HTTPS, or FTP proxy server, you can configure it in different ways:

#    In Docker 17.07 and higher, you can configure the Docker client to pass proxy information to containers automatically.

#    In Docker 17.06 and lower, you must set appropriate environment variables within the container. You can do this when you build the image (which makes the image less portable) or when you create or run the container.

#Configure the Docker client

#    On the Docker client, create or edit the file ~/.docker/config.json in the home directory of the user which starts containers. Add JSON such as the following, substituting the type of proxy with httpsProxy or ftpProxy if necessary, and substituting the address and port of the proxy server. You can configure multiple proxy servers at the same time.

#    You can optionally exclude hosts or ranges from going through the proxy server by setting a noProxy key to one or more comma-separated IP addresses or hosts. Using the * character as a wildcard is supported, as shown in this example.

#    {
#     "proxies":
#     {
#       "default":
#       {
#         "httpProxy": "http://127.0.0.1:3001",
#         "httpsProxy": "http://127.0.0.1:3001",
#         "noProxy": "*.test.example.com,.example2.com"
#       }
#     }
#    }

#    Save the file.

#    When you create or start new containers, the environment variables are set automatically within the container.

#Use environment variables
#Set the environment variables manually

#When you build the image, or using the --env flag when you create or run the container, you can set one or more of the following variables to the appropriate value. This method makes the image less portable, so if you have Docker 17.07 or higher, you should configure the Docker client instead.
#Variable 	Dockerfile example 	docker run Example
#HTTP_PROXY 	ENV HTTP_PROXY "http://127.0.0.1:3001" 	--env HTTP_PROXY="http://127.0.0.1:3001"
#HTTPS_PROXY 	ENV HTTPS_PROXY "https://127.0.0.1:3001" 	--env HTTPS_PROXY="https://127.0.0.1:3001"
#FTP_PROXY 	ENV FTP_PROXY "ftp://127.0.0.1:3001" 	--env FTP_PROXY="ftp://127.0.0.1:3001"
#NO_PROXY 	ENV NO_PROXY "*.test.example.com,.example2.com" 	--env NO_PROXY="*.test.example.com,.example2.com"

# But based on my testing, for running the apollo's docker/scripts/dev_start.sh script, even with the following version, still I must use the proxy settings in this file:
#$ docker -v
#Docker version 19.03.12, build 48a66213fe

# Running the host proxy server on the docker0 interface, so that it can be used from docker container.
#$ ip a s docker0 | grep 'inet '
#    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0


#info sed
#'[:blank:]'
#     Blank characters: space and tab.
#'[:space:]'
#     Space characters: in the 'C' locale, this is tab, newline, vertical
#     tab, form feed, carriage return, and space.

#https://medium.com/@airman604/getting-docker-to-work-with-a-proxy-server-fadec841194e
#https://note.qidong.name/2020/05/docker-proxy/
#The proxy set in this file is for dockerd which can use any of the host network interfaces, including docker0.
#The proxy types can be orgnized including http/https/socks5 and socks5h is not supported yet. 

#https://lug.ustc.edu.cn/wiki/mirrors/help/docker/

#Docker 镜像使用帮助
#目录

#    使用说明

#使用说明Permalink

#新版的 Docker 使用 /etc/docker/daemon.json（Linux） 或者 %programdata%\docker\config\daemon.json（Windows） 来配置 Daemon。

#请在该配置文件中加入（没有该文件的话，请先建一个）：

#{
#  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
#}

#https://mirrors.ustc.edu.cn/help/dockerhub.html
#由于访问原始站点的网络带宽等条件的限制，导致 Docker Hub, Google Container Registry (gcr.io) 与 Quay Container Registry (quay.io) 的镜像缓存处于基本不可用的状态。故从 2020 年 4 月起，从科大校外对 Docker Hub 镜像缓存的访问会被 302 重定向至其他国内 Docker Hub 镜像源。从 2020 年 8 月 16 日起，从科大校外对 Google Container Registry 的镜像缓存的访问会被 302 重定向至阿里云提供的公开镜像服务（包含了部分 gcr.io 上存在的容器镜像）；从科大校外对 Quay Container Registry 的镜像缓存的访问会被 302 重定向至源站。

#对于使用 systemd 的系统（Ubuntu 16.04+、Debian 8+、CentOS 7）， 在配置文件 /etc/docker/daemon.json 中加入：

#{
#  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn/"]
#}

#重新启动 dockerd：

#sudo systemctl restart docker



#For docker push, use the following mirror and disable the proxy.

#{
#  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn/"]
#}

#$ docker push hongyizhao/deepin-wine:lion 


#https://github.com/ApolloAuto/apollo/issues/12224
#Disable that proxy and try again, or use http/https proxy. See https://docs.bazel.build/versions/master/external.html#using-proxies

#OTOH, socks5h protocol cannot be used here.
#$ docker pull hongyizhao/deepin:apricot 
#Error response from daemon: Get https://registry-1.docker.io/v2/: proxyconnect tcp: dial tcp: lookup socks5h: Temporary failure in name resolution


#https://unix.stackexchange.com/questions/24926/how-do-i-check-the-network-speed-right-now
#sudo tcpdump -w - |pv >/dev/null
#sudo iftop


#Direct reverse proxy can ensure that the acquired image is the latest and most complete, which is much more reliable than the cache proxy.
#The king are the envoy proxy or the mirror acceleration service 
#provided by domestic educational institutions and major cloud service providers.

#https://gist.github.com/y0ngb1n/7e8f16af3242c7815e7ca2f0833d3ea6#%E9%85%8D%E7%BD%AE%E5%8A%A0%E9%80%9F%E5%9C%B0%E5%9D%80
#配置加速地址
#创建或修改 /etc/docker/daemon.json：

#sudo mkdir -p /etc/docker
#sudo tee /etc/docker/daemon.json <<-'EOF'
#{
#    "registry-mirrors": [
#        "https://1nj0zren.mirror.aliyuncs.com",
#        "https://docker.mirrors.ustc.edu.cn",
#        "http://f1361db2.m.daocloud.io",
#        "https://dockerhub.azk8s.cn"
#    ]
#}
#EOF
#sudo systemctl daemon-reload
#sudo systemctl restart docker


#https://github.com/Azure/container-service-for-azure-china/issues/60
#目前 *.azk8s.cn 已经仅限于 Azure China IP 使用，不再对外提供服务, 如果确实有需求，可以联系akscn@microsoft.com 并提供IP地址，我们会根据需求 做决定是否对特定IP提供服务，谢谢理解。

#Sorry, currently *.azk8s.cn could only be accessed by Azure China IP, we don't provide public outside access any more. If you have such requirement to whitelist your IP, please contact akscn@microsoft.com, provide your IP address, we will decide whether to whitelist your IP per your reasonable requirement, thanks for understanding.


#Image booster supplied by aliyun container registry.
#The following ones are registered by myself:
#https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors
#https://cr.console.aliyun.com/undefined/instances/mirrors
#https://sdwhti62.mirror.aliyuncs.com
#https://xclx5e0b.mirror.aliyuncs.com


#Only the genuine reverse proxy for Docker Hub can give highest performance and up-to-date images content.
#Currently, the following ones can be used for this purpose:
# "https://dockerhub.mirrors.nwafu.edu.cn",
# "https://gcr.fuckcloudnative.io"
#The following one shows a unstable speed, so the supplier/provider doesn't recommend me to use it.    
# "https://docker.fuckcloudnative.io"


#https://mirrors.nwafu.edu.cn/help/reverse-proxy/dockerhub/
#Docker Hub 反向代理

#https://dockerhub.mirrors.nwafu.edu.cn/
#使用方法

#修改 /etc/docker/daemon.json ，加入：

#{
#  "registry-mirrors": ["https://dockerhub.mirrors.nwafu.edu.cn/"]
#}

#然后重新启动 Docker 服务：

#sudo systemctl daemon-reload
#sudo systemctl restart docker


etc_docker=/etc/docker
daemon_json=$etc_docker/daemon.json

docker_service_d=/etc/systemd/system/docker.service.d
proxy_conf=$docker_service_d/proxy.conf 

if [ $(id -u) -ne 0 ] && type -fp docker > /dev/null; then
  if [ ! -d "$etc_docker" ]; then
    sudo mkdir -p "$etc_docker"
  fi
  sed -r 's/^[[:blank:]]*[|]//' <<-EOF | sudo tee $daemon_json > /dev/null  
        |{
        |    "dns" : ["172.17.0.1"],
        |       "runtimes": {
        |          "nvidia": {
        |            "path": "nvidia-container-runtime",
        |            "runtimeArgs": []
        |         }
        |    },
        |    "registry-mirrors":[
        |        "https://dockerhub.mirrors.nwafu.edu.cn",
        |        "https://gcr.fuckcloudnative.io"
        |    ]
        |}
	EOF

  #Disable the proxy settings for docker daemon:
  if [ ! -d "$docker_service_d" ]; then
    sudo mkdir -p "$docker_service_d"
  fi
  sed -r 's/^[[:blank:]]*[|]//' <<-EOF | sudo tee $proxy_conf > /dev/null  
        |[Service]
        |#Environment="HTTP_PROXY=http://127.0.0.1:8080/"
        |#Environment="HTTPS_PROXY=http://127.0.0.1:8080/"
        |#Environment="NO_PROXY=localhost,127.0.0.1,.cn"
	EOF
  sudo systemctl daemon-reload
  sudo systemctl restart docker
fi


