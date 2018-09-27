```
docker pull w303972870/mariadb
```
|软件|版本|
|:---|:---|
|mariadb|10.2.15|


#### 启动命令示例：为了初始化必须指定一个默认的root密码MYSQL_ROOT_PASSWORD

```
docker run -dit -p 3306:3306 -v /data/mariadb/:/data/ -e MYSQL_ROOT_HOST=192.168.12.% -e MYSQL_ROOT_PASSWORD=123456 docker.io/w303972870/mariadb
```
|变量|解释|
|:---|:---|
|MYSQL_ROOT_HOST|'root'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}|
|MYSQL_ROOT_PASSWORD|'root'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}|
|MYSQL_RANDOM_ROOT_PASSWORD|随机生成一个root密码|
|MYSQL_INITDB_SKIP_TZINFO|不导入时区信息到MYSQL中|
|MYSQL_DATABASE|默认创建一个数据库|
|MYSQL_USER|新建一个用户|
|MYSQL_PASSWORD|新建用户的密码|

### 启动之后，需要mysql -h 127.0.0.1 -p3306 -u root连接容器mysql后重新配置访问限制，

### 数据目录：/data/database/
### 日志目录：/data/logs/
### 默认配置文件：/data/etc/my.cnf

默认配置文件已开启sphinx引擎，如果没有开启可通过命令： INSTALL PLUGIN sphinx SONAME 'ha_sphinx.so'; 安装，使用命令show engines;查看

### 已开放3306端口

### 我的/data/mariadb/目录结构
```
/data/mariadb/
├── database
├── docker-entrypoint-initdb.d
├── etc
│   └── my.cnf
└── logs
```

### docker-entrypoint-initdb.d目录内可以放置.sh,.sql,.sq.gz三类文件，作用可以看docker-entrypoint.sh
```
  for f in /data/docker-entrypoint-initdb.d/*; do
    case "$f" in
      *.sh)     echo "$0: running $f"; . "$f" ;;
      *.sql)    echo "$0: running $f"; execute < "$f"; echo ;;
      *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | execute; echo ;;
      *)        echo "$0: ignoring $f" ;;
    esac
    echo
  done
```


**附上一个简单的my.cnf配置文件**

```
[client]
port = 3306
socket = /tmp/mysql.sock
default-character-set = utf8mb4
 
[mysqld]
port = 3306
socket = /tmp/mysql.sock
datadir = /data/mariadb/database/
pid-file = /data/mariadb/database/mysql.pid
user = mysql
bind-address = 0.0.0.0
server-id = 1
 
init-connect = 'SET NAMES utf8mb4'
character-set-server = utf8mb4
 
skip-name-resolve
#skip-networking
back_log = 300
 
max_connections = 1000
max_connect_errors = 6000
open_files_limit = 65535
table_open_cache = 1024
max_allowed_packet = 4M
binlog_cache_size = 1M
max_heap_table_size = 8M
tmp_table_size = 128M
 
read_buffer_size = 2M
read_rnd_buffer_size = 8M
sort_buffer_size = 8M
join_buffer_size = 8M
key_buffer_size = 256M
 
thread_cache_size = 64
 
query_cache_type = 1
query_cache_size = 64M
query_cache_limit = 2M
 
ft_min_word_len = 4
 
log_bin = mysql-bin
binlog_format = ROW
expire_logs_days = 30
 
log_error = /data/mariadb/mysql-error.log
slow_query_log = 1
long_query_time = 1
slow_query_log_file = /data/mariadb/mysql-slow.log
general_log = ON
log_output = FILE
general_log_file =  /data/mariadb/general.log
 
performance_schema = 0
 
#lower_case_table_names = 1
 
skip-external-locking
 
default_storage_engine = InnoDB
#default-storage-engine = MyISAM
innodb_file_per_table = 1
innodb_open_files = 500
innodb_buffer_pool_size = 1024M
innodb_write_io_threads = 4
innodb_read_io_threads = 4
innodb_thread_concurrency = 0
innodb_purge_threads = 1
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 2M
innodb_log_file_size = 32M
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120
 
bulk_insert_buffer_size = 8M
myisam_sort_buffer_size = 64M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
 
interactive_timeout = 28800
wait_timeout = 28800
 
[mysqldump]
quick
max_allowed_packet = 16M
 
[myisamchk]
key_buffer_size = 256M
sort_buffer_size = 8M
read_buffer = 4M
write_buffer = 4M
```




**附上一个别人写的测试脚本，需要稍作修改才能用(!!!停用脚本)**
```
#!/bin/sh
#Test docker image

set -eo pipefail

ENV_FILE=/tmp/mariadb_alpine_test_env

#https://mariadb.com/kb/en/library/mariadb-environment-variables/
export MYSQL_PWD=

echo_success() {
  echo "$(tput setaf 10)$1$(tput sgr0)"
}

echo_error() {
  echo >&2 "$(tput setaf 9)$1$(tput sgr0)"
}

#Execute MySQL statements
execute() {
  if [ -n "$MYSQL_USER" ]; then
    mysql --protocol=tcp --port=33060 --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" -ss -e "$1"
  else
    # two -s to make it output only result
    mysql --protocol=tcp --port=33060 -uroot -ss -e "$1"
  fi
}

container_status() {
  docker inspect --format '{{.State.Status}}' mariadb_alpine_test 2> /dev/null || true
}

start_container() {
  if [ -z "$DOCKER_VOLUME" ]; then
    docker run --detach --name mariadb_alpine_test -p 33060:3306 \
      --env-file="$ENV_FILE" \
      -e MYSQL_ROOT_PASSWORD="$MYSQL_PWD" \
      mysql:latest > /dev/null
  else
    docker run --detach --name mariadb_alpine_test -p 33060:3306 \
      --env-file="$ENV_FILE" \
      -e MYSQL_ROOT_PASSWORD="$MYSQL_PWD" \
      -v "${DOCKER_VOLUME}" \
      mysql:latest > /dev/null
  fi
}

remove_container() {
  docker stop mariadb_alpine_test &> /dev/null || true
  docker rm mariadb_alpine_test &> /dev/null || true
}

#Check whether container is running
is_container_running() {
  # status: created running paused restarting removing exited dead
  status=$(container_status)
  [ "$status" = 'created' -o "$status" = 'running' ]
}

#Whether mysql is running correctly
is_mysql_running() {
  execute 'SELECT 1' &> /dev/null
}

wait_running() {
  for i in `seq 30 -1 0`; do
    if ! is_container_running; then
      echo_error 'Container failed to start'
      exit 1
    fi

    if is_mysql_running; then
      break
    fi

    sleep 1
  done

  if [ "$i" = 0 ]; then
    echo_error 'Test failed'
    exit 1
  fi
}

check_running() {
  wait_running
  echo_success 'Test successful'
}

#Test MYSQL_ROOT_PASSWORD
test_root_password() {
  export MYSQL_PWD='root'
  echo "Test MYSQL_ROOT_PASSWORD='${MYSQL_PWD}'"
  echo > "$ENV_FILE"
  start_container
  check_running
  remove_container

  # password with special characters
  export MYSQL_PWD='a#F a$b~-'
  echo "Test MYSQL_ROOT_PASSWORD='${MYSQL_PWD}'"
  echo > "$ENV_FILE"
  start_container
  check_running
  remove_container
}

#Test MYSQL_RANDOM_ROOT_PASSWORD
test_random_root_password() {
  unset MYSQL_PWD
  echo "Test MYSQL_RANDOM_ROOT_PASSWORD=yes"
  echo "MYSQL_RANDOM_ROOT_PASSWORD=yes" > "$ENV_FILE"
  start_container
  for i in `seq 30 -1 0`; do
    if ! is_container_running; then
      echo_error 'Container failed to start'
      exit 1
    fi

    password=$(docker logs mariadb_alpine_test 2>&1 | grep -m1 '^GENERATED ROOT PASSWORD:' | cut -d' ' -f4- || true)
    if [ -n "$password" ]; then
      export MYSQL_PWD="$password"
      break
    fi

    sleep 1
  done

  if [ -z "$MYSQL_PWD" ]; then
    echo_error 'Failed to get random root password'
    exit 1
  else
    check_running
    remove_container
  fi
}

#Test MYSQL_ALLOW_EMPTY_PASSWORD
test_empty_root_password() {
  unset MYSQL_PWD
  echo 'Test MYSQL_ALLOW_EMPTY_PASSWORD=yes'
  echo "MYSQL_ALLOW_EMPTY_PASSWORD=yes" > "$ENV_FILE"
  start_container
  check_running
  remove_container
}

#Test MYSQL_ROOT_HOST
test_mysql_root_host() {
  export MYSQL_PWD=mypassword

  # Docker host ip
  local host=$(docker network inspect bridge --format '{{(index .IPAM.Config 0).Gateway}}')
  echo "Test MYSQL_ROOT_HOST=$host"
  echo "MYSQL_ROOT_HOST=$host" > "$ENV_FILE"
  start_container
  check_running
  remove_container

  # host not owned by current machine
  local host=example.com
  echo "Test MYSQL_ROOT_HOST=$host"
  echo "MYSQL_ROOT_HOST=$host" > "$ENV_FILE"
  start_container
  # Wait for mysqld to startup
  for i in `seq 30 -1 0`; do
    if ! is_container_running; then
      echo_error 'Container failed to start'
      exit 1
    fi

    if docker logs mariadb_alpine_test 2>&1 | grep 'mysqld_safe Starting mysqld daemon' &> /dev/null; then
      sleep 3
      break
    fi
  done
  # Should not be allowed to access the
  result=$(execute 'SELECT 1' 2>&1 || true)
  if [ "$result" = "1" ]; then
    echo_error 'Should not be allowed to connect'
    exit 1
  else
    echo_success 'Test successful'
    remove_container
  fi
}

#Test MYSQL_DATABASE
test_mysql_database() {
  export MYSQL_PWD=mypassword
  local database=blog
  echo "Test MYSQL_DATABASE=$database"
  echo "MYSQL_DATABASE=$database" > "$ENV_FILE"
  start_container
  wait_running
  if execute "SHOW CREATE DATABASE \`$database\`;" &> /dev/null; then
    echo_success 'Test successful'
    remove_container
  else
    echo_error "Database $database not exist"
    exit 1
  fi
}

#Test MYSQL_USER, MYSQL_PASSWORD
test_mysql_user() {
  export MYSQL_PWD=mypassword

  export MYSQL_USER=alice
  export MYSQL_PASSWORD=alice_password
  echo "Test MYSQL_USER=$MYSQL_USER, MYSQL_PASSWORD=$MYSQL_PASSWORD"
  echo -e "MYSQL_USER=$MYSQL_USER\nMYSQL_PASSWORD=$MYSQL_PASSWORD" > "$ENV_FILE"
  start_container
  check_running
  remove_container
  unset MYSQL_USER
  unset MYSQL_PASSWORD
}

#MYSQL_INITDB_SKIP_TZINFO
test_skip_tzinfo() {
  export MYSQL_PWD=mypassword

  echo 'Test MYSQL_INITDB_SKIP_TZINFO='
  echo 'MYSQL_INITDB_SKIP_TZINFO=' > "$ENV_FILE"
  start_container
  wait_running
  local count=$(execute 'SELECT COUNT(*) FROM mysql.time_zone' || true)
  if [ "$count" = "0" ]; then
    echo_error "No timezone records inserted"
    exit 1
  else
    echo_success "Test successful"
    remove_container
  fi

  echo 'Test MYSQL_INITDB_SKIP_TZINFO=yes'
  echo 'MYSQL_INITDB_SKIP_TZINFO=yes' > "$ENV_FILE"
  start_container
  wait_running
  local count=$(execute 'SELECT COUNT(*) FROM mysql.time_zone' || true)
  if [ "$count" != "0" ]; then
    echo_error "Timezone records inserted"
    exit 1
  else
    echo_success "Test successful"
    remove_container
  fi
}


test_volume() {
  export MYSQL_PWD=mypassword
  export DOCKER_VOLUME="$(mktemp -p /tmp -d mariadb_alpine_test_volume.XXXXX):/var/lib/mysql"
  echo 'Test volume'
  echo > "$ENV_FILE"
  start_container
  wait_running
  remove_container

  # Use already initialized volume
  start_container
  check_running
  remove_container

  unset DOCKER_VOLUME
}

test_custom_initialization_script() {
  export MYSQL_PWD='root'
  export DOCKER_VOLUME="$(readlink -e test/initdb.d):/docker-entrypoint-initdb.d"
  echo "Test custom initialization script"
  echo > "$ENV_FILE"

  start_container
  wait_running

  local result=$(execute "USE test_docker; SELECT name from users where name = 'admin' LIMIT 1" || true)
  if [ "$result" = "Admin" ]; then
    echo_success "Test successful"
    remove_container
  else
    echo_error "No records found"
    exit 1
  fi
}

remove_container

test_root_password
test_empty_root_password
test_random_root_password
test_mysql_root_host
test_mysql_database
test_mysql_user
test_skip_tzinfo
test_volume
test_custom_initialization_script

echo 'Clean up temp files...'
rm -f  "$ENV_FILE"
sudo rm -rf /tmp/mariadb_alpine_test_volume*
```
