hab config apply mysql.default $(date +%s) demo-stuff/wordpress-demo/wordpress-mysql-config.toml
hab svc load alan/mysql/5.7.17/20190206001723
hab svc load alan/wordpress/4.9.5/20190208145358 --bind database:mysql.default