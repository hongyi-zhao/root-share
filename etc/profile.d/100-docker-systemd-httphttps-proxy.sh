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

#https://note.qidong.name/2020/05/docker-proxy/
#The proxy set in this file is for dockerd which can use any of the host network interfaces, including docker0.
#The proxy types can be orgnized including http/https/socks5 and socks5h is not supported yet. 

#https://github.com/yeasy/docker_practice/blob/master/install/mirror.md#ubuntu-1604debian-8centos-7
#Ubuntu 16.04+、Debian 8+、CentOS 7+

#目前主流 Linux 发行版均已使用 systemd 进行服务管理，这里介绍如何在使用 systemd 的 Linux 发行版中配置镜像加速器。

#请首先执行以下命令，查看是否在 docker.service 文件中配置过镜像地址。

#$ systemctl cat docker | grep '\-\-registry\-mirror'

#如果该命令有输出，那么请执行 $ systemctl cat docker 查看 ExecStart= 出现的位置，修改对应的文件内容去掉 --registry-mirror 参数及其值，并按接下来的步骤进行配置。

#如果以上命令没有任何输出，那么就可以在 /etc/docker/daemon.json 中写入如下内容（如果文件不存在请新建该文件）：

#{
#  "registry-mirrors": [
#    "https://hub-mirror.c.163.com",
#    "https://mirror.baidubce.com"
#  ]
#}

#    注意，一定要保证该文件符合 json 规范，否则 Docker 将不能启动。

#之后重新启动服务。

#$ sudo systemctl daemon-reload
#$ sudo systemctl restart docker

#https://github.com/docker-practice/docker-registry-cn-mirror-test/actions/runs/148084125/workflow
#          registrys="
#          docker.io
#          registry-1.docker.io
#          mirror.baidubce.com
#          hub-mirror.c.163.com
#          docker.mirrors.ustc.edu.cn
#          mirror.gcr.io
#          $ALIYUN_MIRROR
#          "

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



docker_service_d=/etc/systemd/system/docker.service.d
http_proxy_conf=$docker_service_d/http-proxy.conf 


if [ $(id -u) -ne 0 ] && type -fp docker > /dev/null; then
  if [ ! -d "$docker_service_d" ]; then
    mkdir -p "$docker_service_d"
  fi
  if [ ! -e "$http_proxy_conf" ] || ! egrep -q '^[ ]*"httpProxy": "socks5://127.0.0.1:18888",' $http_proxy_conf; then
    sed -r 's/^[[:blank:]]*[|]//' <<-EOF | sudo tee $http_proxy_conf > /dev/null  
        |[Service]
        |Environment="HTTP_PROXY=socks5://127.0.0.1:18888/"
        |Environment="HTTPS_PROXY=socks5://127.0.0.1:18888/"
        |Environment="NO_PROXY=localhost,127.0.0.1,packages.deepin.com,*.mirror.aliyuncs.com,mirror.baidubce.com,hub-mirror.c.163.com,*.cn"
	EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
  fi
fi



