#!/bin/bash
(
	echo "DROP DATABASE IF EXISTS ralph_ng;"
	echo "CREATE DATABASE ralph_ng DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
) | mysql -uroot
