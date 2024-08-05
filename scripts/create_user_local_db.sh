#!/bin/bash
(
    echo "CREATE USER 'ralph_ng'@'localhost' IDENTIFIED BY 'ralph_ng';"
	echo "GRANT ALL PRIVILEGES ON ralph_ng.* TO 'ralph_ng'@'localhost';"
	echo "FLUSH PRIVILEGES;"
) | mysql -uroot
