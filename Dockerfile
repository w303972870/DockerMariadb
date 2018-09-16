FROM alpine:latest
MAINTAINER Eric Wang <wdc-zhy@163.com>

ARG PATH=/bin:$PATH
 
ENV DATA_DIR=/data/mariadb/database/ LOGS_DIR=/data/mariadb/logs/

RUN  addgroup -S mysql &&\ 
adduser -D -S -h /var/cache/mysql -s /sbin/nologin -G mysql mysql &&  mkdir -p $DATA_DIR $LOGS_DIR

ADD Dockerfile /root/
ADD my.cnf /root/


RUN mkdir /data/mariadb/docker-entrypoint-initdb.d && \
    apk -U upgrade && apk add mariadb tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone && \
    apk add --no-cache --virtual .build-deps  linux-headers bison libexecinfo-dev && \
    apk del .build-deps linux-headers bison libexecinfo-dev && \
    rm -rf /var/cache/apk/* && sed -i "s|socket =.*|socket = ${DATA_DIR}/mysql.sock|" /root/my.cnf \
        && sed -i "s|log_error =.*|log_error = ${LOGS_DIR}/mysql-error.log|" /root/my.cnf \
        && sed -i "s|slow_query_log_file =.*|slow_query_log_file = ${LOGS_DIR}/mysql-slow.log|" /root/my.cnf \
        && sed -i "s|general_log_file =.*|general_log_file = ${LOGS_DIR}/general.log|" /root/my.cnf \
        && sed -i "s|datadir =.*|datadir = ${DATA_DIR}\nplugin-load="sphinx=ha_sphinx.so"\n|" /root/my.cnf \
        && sed -i "s|pid-file =.*|pid-file = ${DATA_DIR}/mysql.pid|" /root/my.cnf \
        && \cp /root/my.cnf /etc/mysql/my.cnf \
        && echo -e '\n!includedir /etc/mysql/conf.d/' >> /etc/mysql/my.cnf && mkdir -p /etc/mysql/conf.d/ && \ 
	chown -R mysql:mysql $DATA_DIR  

ADD ha_sphinx.so /usr/lib/mariadb/plugin/

VOLUME  ["$DATA_DIR", "$LOGS_DIR"]

COPY docker-entrypoint.sh /usr/local/bin/ 
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3306

CMD ["mysqld_safe" ,  "--defaults-file=/etc/mysql/my.cnf"]
