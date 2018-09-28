#!/bin/sh
chmod 644 /data/etc/my.cnf

_get_config() {
  conf="$1"
   /usr/bin/mysqld --verbose --help --log-bin-index="$(mktemp -u)" 2>/dev/null | awk '$1 == "'"$conf"'" { print $2; exit }'
}

DATA_DIR="$(_get_config 'datadir')"
if [ ! -d "$DATA_DIR/mysql" ]; then

  mkdir -p "$DATA_DIR"
  chown mysql: "$DATA_DIR"

  echo "初始化数据库中($DATA_DIR)"
  /usr/bin/mysql_install_db --user=mysql --datadir="$DATA_DIR" --skip-name-resolve --basedir=/usr/ --rpm > /data/logs/mysql_install_db.log
  chown -R mysql: "$DATA_DIR"

  echo
  for f in /data/docker-entrypoint-initdb.d/*; do
    case "$f" in
      *.sh)     echo "$0: running $f"; . "$f" ;;
      *.sql)    echo "$0: running $f"; execute < "$f"; echo ;;
      *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | execute; echo ;;
      *)        echo "$0: ignoring $f" ;;
    esac
    echo
  done
  echo
  echo '数据库初始化完成，等待启动.'
  echo
fi

chown -R mysql: "$DATA_DIR"
exec "$@"
