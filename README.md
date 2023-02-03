# Web Admin Tools

### *(Tested on Ubuntu 22.04 LTS)*

## setup.sh

- Load dependancies for installer script.

## json-generator.pl

- Run this before running the tools below. This generates the info needed for the other tools to run.

## cms-backup-restore.rb

Ruby wrapper for the following shell commands:

#### *Backup*

```
mkdir -vp TIME_DATABASE 
&& 
cp -vr DIR TIME_DATABASE/ 
&& 
sudo mysqldump --user='USER' --password='PASS' DATABASE > TIME_DATABASE/TIME_DATABASE.sql 
&& 
tar -cvzf TIME_DATABASE.tar.gz TIME_DATABASE 
&& 
rm -vr TIME_DATABASE
```

#### *SQL Export*

```
sudo mysqldump --user='USER' --password='PASS' DATABASE > TIME_DATABASE.sql
```

#### *UnTar to Directory*

```
tar -xvzf TARBALL -C DIR
```

#### *Import SQL Database*

```
mysql -u'USER' –p'PASS' 'DATABASE' < 'DBFILE
```

## ubuntu-server-installer.pl

This helper script will setup a web server with a AMP stack. It has the following options: *(run with sudo)*

#### *updaters*

- **update_upgrade** -- apt update && apt upgrade -y

#### *installers*

- **install_essentials** -- install essential packages
- **install_fun** -- install optional packages
- **install_apache** -- install apache
- **install_php** -- install php, tweak php.ini
- **install_mysql** -- install mysql

#### *setups* 

- **setup_sudo** -- no more sudo password required
- **setup_ufw** -- setup software firewall
- **setup_mysql_db** -- setup mysql database 

#### *load configs*

- **config_apache_webconf** -- virtualhost setup for web server
- **config_bashrc** -- setup your .bashrc

