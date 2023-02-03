#!/usr/bin/env perl

use feature qw|say|;

my $linux = Ubuntu::Installer->load();
$linux->go();

package Ubuntu::Installer
{
	use Expect;
	use feature qw|say|;
	use JSON::MaybeXS;
	use Term::ANSIColor qw|:constants|;
	use Data::Dump qw|dump|;
	
	######### public
	# initialize class
	sub load
	{
		my $class   = shift; 
		
		my $self = bless { }, $class;
		
		unless (@ARGV == 1 and $ARGV[0] =~ m`\.json\Z` and -f -e $ARGV[0])
		{
			LOAD_MENU:
			{
				printf qq|\033[2J|;
				
				$$self{json} = $self->_scan_for_json();
				
				unless ($$self{json})
				{
					system q|./json-generator.pl|;
					goto LOAD_MENU;
				}
				
				printf  q|> %s%s |, YELLOW q|r(edo) / p(roceed) / q(uit):|, RESET; 
				chomp (my $opt = <STDIN>);
				
				if ($opt =~ m`^q(?:uit)?\Z`i)
				{
					printf qq|> %s%s\n|, RED q|quitting!|, RESET;
					exit 69;
				}
				elsif ($opt =~ m`^p(?:roceed)?\Z`i)
				{
					return $self;
				}
				else 
				{
					goto LOAD_MENU;
				}
			}
		}
	}
	
	# go! main sub to run app
	sub go 
	{
		printf qq|\033[2J|;
		
		my $self = shift;
		my @choices = qw~setup_sudo update_upgrade install_essentials install_fun setup_ufw install_apache install_php install_mysql setup_mysql_db config_apache_webconf config_bashrc~;
		
		my $n;
		
		MAIN_LOOP:
		{
			$n = 0;
			
			# menu bar
			printf qq|%s %s %s\n|, q|~|x15, q|MENU|, q|~|x15;
			
			# change behaviour of array interpolation
			local $" = qq|\n|;
			
			# menu choices
			map { printf qq|%-2d ~ %s%s\n|, $n++, BLUE $_, RESET } @choices;
			
			# menu bar
			printf qq|%s\n|  , q|~|x37;
			
			# choose
			printf qq|> %s%s: |, YELLOW q|choose|, RESET;
			
			chomp (my $choice = <STDIN>);
			
			if ($choice =~ m`^q(?:uit)?\Z`)
			{
				printf qq|> %s%s\n|, RED q|quitting!|, RESET;
				exit 69;
			}
			
			unless ($choices[$choice])
			{
				printf qq|> %s\n|, q|invalid choice!|;
				exit 69;
			}
			
			eval(qq|\$self->_$choices[$choice]|);
		
			goto MAIN_LOOP;
		}
	
	}
	
	######### private: write / run subs
	# json creating
	sub _scan_for_json()
	{
		my $self = shift;
		
		printf qq|%s\n|, q|load .json file: |; 
		
		# border
		printf qq|%s\n|, q|~|x30; 
		
		my $n = 0;
		chomp (my @json = grep { m`\.json$` } glob(q|*.json|));
		
		# if no json then return undef
		return undef unless @json;
		
		map { printf qq|%-d ~ %s%s\n|, $n++, BLUE $_, RESET } @json;
		
		# border
		printf qq|%s\n|, q|~|x30;
		
		CHOOSE_FILE: printf qq|> %s%s: |, YELLOW q|choose|, RESET; 
		chomp (my $choice = <STDIN>);
		
		goto CHOOSE_FILE if ($choice =~ m`(?:^$|[[:alpha:]]+)`mi);
		goto CHOOSE_FILE unless $json[$choice];
		
		open my $fh, q|<|, $json[$choice] 
		or die RED qq|can't open .json so quitting!\n|, RESET;
		
		my $json_file = join q||, <$fh>;
		
		my $json = decode_json($json_file);
				
		printf qq|%s\n|, q|~|x30;
		$n = 0;

		for my $key (sort keys %{$json})
		{
			if ($key =~ m`^\d+$`)
			{
				printf qq|%-d ~ %s%s\n|, $n++, BLUE $$json{$key}{dbname}, RESET;
			}
		}
		printf qq|%s\n|, q|~|x30;
		
		CHOOSE_INSTANCE: printf qq|> %s%s: |, YELLOW q|choose|, RESET; 
		chomp ($choice = <STDIN>);
		
		goto CHOOSE_INSTANCE unless $$json{$choice}{dbname};
		
		return { %{$$json{$choice}}, linuxuser => $$json{linuxuser}, sqlpass => $$json{sqlpass} };
	}
	
	# write config
	sub _write_config($$$$)
	{
		my $self    = shift;
		my $folder  = shift;
		my $file    = shift;
		my $content = shift;
		
		$folder =~ s`^(?!/)|(?<!/)\Z`/`g;
		
		printf qq|> writing to %s%s\n|, GREEN qq|${folder}${file}|, RESET;
		
		open my $fh, q|>>|, $folder.$file or die RED qq|> can't open file to write config! quitting!\n|, RESET;
		
		print $fh $content; 
		close $fh;
	}
	
	# process commands
	sub _process_cmd()
	{
		my $self = shift;
		chomp (my $cmd  = shift);
		
		my $regex   = qr~(^\Z|^\s+|^\t+)|\n{2,}~m;
		
		$cmd =~ s`$regex`$1 ? q|| : qq|\n|`eg;
		
		map
		{
			unless (m~^\Z~)
			{
				printf qq|> %s%s\n|, YELLOW $_, RESET;
				eval { system $_ };
				
				if ($? > 0)
				{
					printf qq|> %s%s\n|, RED q|something went wrong!|, RESET;
					local $@;
					say $@;
					exit 69;
				}
			}
			
		} split qr~\n~, $cmd	
	
	}
	
	######### private: installation subs
	# apt update and upgrade
	sub _update_upgrade() 
	{ 
		my $self = shift; 
		my $cmd  = <<~'CMDS';
			sudo apt update -y
			sudo apt upgrade -y
			sudo apt autoremove -y
		CMDS
	
		$self->_process_cmd($cmd);
	}
		
	# install all essential packages	
	sub _install_essentials() 
	{ 
		my $self = shift;
		my $cmd  = <<~'CMDS';
			sudo apt install ruby -y
			sudo gem install watir
			sudo gem install colorize
			sudo apt install ufw -y
			sudo apt install vim -y
			sudo apt install git -y
			sudo apt install rsync -y
			sudo apt install make -y
			sudo apt install curl -y
			sudo apt install wget -y
			sudo apt install ack-grep -y
			sudo apt install gpm -y
			sudo apt install pcregrep -y
			sudo apt install lynx -y
			sudo apt install htop -y
			sudo apt install git -y
			sudo apt install ssh -y
			sudo apt install net-tools -y
			sudo apt install ifupdown -y
			sudo apt install unzip -y
		CMDS

		$self->_process_cmd($cmd);
	}
		
	# install fun packages
	sub _install_fun()
	{ 
		my $self = shift; 
		my $cmd  = <<~'CMDS';
			sudo apt install youtube-dl -y
			sudo apt install xdotool -y 
			sudo apt install minimodem -y
			sudo apt install zbar-tools -y
			sudo apt install qrencode -y
			sudo apt install sox -y
			sudo apt install ffmpeg -y
			sudo apt install imagemagick -y
			sudo apt install zenity -y
			sudo apt install dialog -y
			sudo apt install expect -y
			sudo apt install yad -y
		CMDS
		
		$self->_process_cmd($cmd);
	}
		
	# setup sudo no password
	sub _setup_sudo()
	{
		my $self = shift; 
		
		my $cmd = <<~'CMDS'; 
			echo "LINUXUSER" | perl -nle 'print qq~${_} ALL=(ALL) NOPASSWD:ALL~' | sudo tee -a /etc/sudoers
		CMDS
		
		$cmd =~ s`LINUXUSER`$$self{json}{linuxuser}`ge;
		
		$self->_process_cmd($cmd);
	}

	# install apache
	sub _install_apache()
	{ 
		my $self = shift; 
		
		my $cmd = <<~"CMDS";
			sudo apt install -y apache2 apache2-utils libapache2-mod-perl2
			sudo a2enmod rewrite
			sudo a2enmod ssl
			sudo a2enmod perl
			sudo a2dissite 000-default.conf
			sudo touch /etc/apache2/sites-available/web.conf
			sudo a2ensite web.conf
			sudo service apache2 reload
			sudo chown -R LINUXUSER:www-data /var/www
			sudo chmod -R 775 /var/www
			sudo service apache2 restart
			cd /var/www && sudo chown -R LINUXUSER:www-data .
			cd /var/www && sudo chmod -R 775 .
			mkdir -p /var/www/WEBFOLDER
		CMDS
		
		my $webfolder = $$self{json}{webfolder};
		my $linuxuser = $$self{json}{linuxuser};
		
		$cmd =~ s`(WEBFOLDER)|LINUXUSER`$1 ? $webfolder : $linuxuser`ge;
		
		$self->_process_cmd($cmd);
	}
	
	# install php
	sub _install_php()
	{ 
		my $self = shift; 
		my $cmd = <<~'CMDS'; 
			sudo apt install php -y
			sudo apt install libapache2-mod-php -y
			sudo apt install php-mysql -y
			sudo apt install php-curl -y
			sudo apt install php-gd -y
			sudo apt install php-mbstring -y
			sudo apt install php-xml -y
			sudo apt install php-xmlrpc -y
			sudo apt install php-soap -y
			sudo apt install php-intl -y
			sudo apt install php-zip -y
			php --ini | perl -nlE 'say $& if m`[^/]+\K/.*?php.ini\Z`' | sudo xargs -n 1 -I {} perl -i-$(date '+%s').bak -pe 's`^upload_max_filesize\s+=\s+\K([[:alnum:]-]+)(?{ $m = q|500M| })|^post_max_size\s+=\s+\K(?1)(?{ $m = q|500M| })|^memory_limit\s+=\s+\K(?1)(?{ $m = q|256M| })`$m`mge' {}
			sudo service apache2 restart
		CMDS
		
		$self->_process_cmd($cmd);
	}
	
	# setup software firewall
	sub _setup_ufw()
	{ 
		my $self = shift; 
		my $cmd = <<~'CMDS';
			sudo ufw default allow outgoing
			sudo ufw default deny incoming
			sudo ufw allow ssh
			sudo ufw allow http
			sudo ufw allow https
			yes | sudo ufw enable
			sudo ufw status verbose
		CMDS
	
		$self->_process_cmd($cmd);
	}
	
	# install mysql
	sub _install_mysql()
	{
		my $self = shift; 
		
		my $pass = $$self{json}{sqlpass};
		
		# only works the first time!
		my $cmd = <<~'CMDS'; 
			sudo apt install mysql-server -y
			sudo mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'YOUR_PASSWORD';"
			sudo mysql -uroot -pYOUR_PASSWORD -e "FLUSH PRIVILEGES;"
		CMDS
		
		$cmd =~ s`YOUR_PASSWORD`$pass`ge;
		
		$self->_process_cmd($cmd);
	
		my $expect  = Expect->new;
		my $command = q|sudo mysql_secure_installation|;
		my $timeout = 200;

		$expect->raw_pty(1);  
		$expect->spawn($command) or die RED "> cannot spawn ${command}: ${!}\n", RESET;
		
		$expect->expect($timeout,
			[ qr~Enter[^\n]+?password for user root:~ => sub { my $exp = shift; $exp->send("${pass}\n"); exp_continue; } ],
			[ qr~VALIDATE PASSWORD~i => sub { my $exp = shift; $exp->send("n\n"); exp_continue; } ],
			[ qr~Change the root password\?~i => sub { my $exp = shift; $exp->send("n\n"); exp_continue; } ],
			[ qr~Remove anonymous users\?~i => sub { my $exp = shift; $exp->send("y\n"); exp_continue; } ],
			[ qr~Disallow root login remotely\?~i => sub { my $exp = shift; $exp->send("y\n"); exp_continue; } ],
			[ qr~Remove test database and access to it\?~i => sub { my $exp = shift; $exp->send("y\n"); exp_continue; } ],
			[ qr~Reload privilege tables now\?~ => sub { my $exp = shift; $exp->send("y\n"); exp_continue; } ],
		);
		
		$expect->soft_close();
	}
	
	# setup database
	sub _setup_mysql_db()
	{
		my $self = shift;
		
		my $pass   = $$self{json}{sqlpass};
		my $dbname = $$self{json}{dbname};
		my $dbuser = $$self{json}{dbuser};
		my $dbpass = $$self{json}{dbpass};
		
		my $cmd = <<~'CMDS';
			sudo mysql -uroot -pPASS -e "CREATE DATABASE DBNAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
			sudo mysql -uroot -pPASS -e "CREATE USER 'DBUSER'@localhost IDENTIFIED BY 'DBPASS';"
			sudo mysql -uroot -pPASS -e "GRANT ALL PRIVILEGES ON DBNAME.* to 'DBUSER'@'localhost';"
			sudo mysql -uroot -pPASS -e "FLUSH PRIVILEGES;"
		CMDS
	
		$cmd =~ s`(?x)
		
			PASS(?{ $m = $pass })
			|
			DBNAME(?{ $m = $dbname })
			|
			DBUSER(?{ $m = $dbuser })
			|
			DBPASS(?{ $m = $dbpass })
		
		`$m`ge;

		$self->_process_cmd($cmd);
	}
	
	sub _config_apache_webconf()
	{ 
		my $self = shift; 
		
		my $email     = $$self{json}{email};
		my $website   = $$self{json}{website};
		my $linuxuser = $$self{json}{linuxuser};
		my $webfolder = $$self{json}{webfolder};
		
		$webfolder =~ s`^/|/$``g;
		
		my $config = <<~'CONFIG' =~ s`^(?:\t+|\s+)``mrg;
			########### WEBSITE
		
			<VirtualHost *:80>
				TABServerName WEBSITE
		
				TABRewriteEngine On
		
				TABRewriteCond %{SERVER_NAME} =WEBSITE
				TABRewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
			
			</VirtualHost>
		
			<IfModule mod_ssl.c>
				TAB<VirtualHost *:443>
			
					TABTABServerAdmin EMAIL
			
					TABTABServerName WEBSITE:443
			
					TABTABServerAlias WEBSITE
			
					TABTABDocumentRoot /var/www/WEBFOLDER
			
					TABTAB<Directory /var/www/WEBFOLDER/>
			
						TABTABTABOptions Indexes FollowSymLinks MultiViews
			
						TABTABTABAllowOverride All
			
						TABTABTABOrder allow,deny
			
						TABTABTABallow from all
			
						TABTABTABIndexOrderDefault Descending Date
			
					TABTAB</Directory>
			
					TABTABErrorLog /var/log/web-error-random.log
			
					TABTAB# Possible values include: debug, info, notice, warn, error, crit, alert, emerg.
			
					TABTABLogLevel warn
			
					TABTABTABCustomLog /var/log/web-access-random.log combined
				
				TAB</VirtualHost>
			</IfModule>
		
		
		CONFIG
		
		$config =~ s`(?x)
		
			WEBFOLDER(?{ $m = $webfolder })
			|
			WEBSITE(?{ $m = $website })
			|
			EMAIL(?{ $m = $email })
			|
			TAB(?{ $m = qq|\t| })
		
		`$m`ge;

		# say $config; exit; # debug
		
		$self->_process_cmd(qq|sudo chown -vR ${linuxuser} /etc/apache2/sites-available/|);
		$self->_write_config(q|/etc/apache2/sites-available/|, q|web.conf|, $config);
		$self->_process_cmd(q|sudo service apache2 restart|);
	}

	sub _config_bashrc()
	{
		my $self = shift;

		my $linuxuser = $$self{json}{linuxuser};

		(my $config = <<~'CONFIG') =~ s`^(?:\t+|\s+)``rgm;
			
			######## customized .bashrc config
			
			set -o vi
			
			# exports
			export VISUAL=/usr/bin/vim
			export PS1='\w> '
			export PATH=$HOME/code:$PATH
			
			# alias
			alias c='clear' # clear screen
			alias l='clear && ls -lha' # ls -lha
			alias bed="vi ${HOME}/.bashrc && source ${HOME}/.bashrc && clear" # edit .bashrc
			alias h='history' # view history
			alias web='sudo vi /etc/apache2/sites-available/web.conf && sudo service apache2 restart' alias www='cd /var/www/'
			alias up='sudo apt update -y && sudo apt upgrade -y'
			alias ssl='sudo certbot --apache && sudo service apache2 restart'
			alias w='clear && sudo fail2ban-client status sshd | grep -v Banned && printf "*** REMOTE LOGINS ***\n" && (lastlog | grep -v "\*\*Never") && printf "*** STILL LOGGED IN ***\n" && (last | grep -i still)'
			alias cpr="rsync --archive --verbose --update  --progress "
			
			# functions
			function webfriend()
			{
				TABperl -M'Term::ANSIColor 2.00 qw(:pushpop)' -MFile::Copy -E 'map { chomp; if (-f) { $o=$_; $_ = lc $_; s`[.-](?{$m=$&})|[\s+_](?{$m=q[-]})|[[:punct:]](?{$m=q[]})`$m`ge; s`-{2,}(?{$m=q[-]})|-(?=\.)(?{$m=q[]})`$m`ge; say PUSHCOLOR BRIGHT_YELLOW $o, RESET q[ >> ], PUSHCOLOR BRIGHT_GREEN $_; move ($o, $_); print RESET }} glob(q[*])'
			}
			
			function mysqlbackup()
			{
				TABperl -se 'map { print qq[\L$_\E> ]; chomp($in = <STDIN>); $db->{$_} = $in } qw[USER PASS DATABASE]; $db->{TIME} = time; system($sql =~ s`USER|PASS|DATABASE|TIME`$db->{$&}`ger);' -- -sql="sudo mysqldump --user='USER' --password='PASS' DATABASE > TIME_DATABASE.sql"
			}

			function sudouser()
			{
				TABperl -MTerm::ANSIColor=':constants' -sE 'printf q|> %s%s: |, GREEN q|user|, RESET; chomp($u = <STDIN>); $n = 0; map { if ($n++ == 2) { qx|${_}| =~ s~^${u}.*$~say q|> |, YELLOW $&, RESET~gemr } else { $run = qq|sudo ${_} ${u}|; printf qq|> %s%s\n|, YELLOW $run, RESET; system $run; } } split m~`~, $cmds;' -- -cmds='adduser`usermod -aG sudo`cat /etc/passwd'
			}

			function clonewww()
			{
				TABwget --user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36' --continue --limit-rate=500k --wait=2 --random-wait --no-if-modified-since --mirror --convert-links --adjust-extension --page-requisites --no-parent $1
			}

		CONFIG

		$config =~ s`TAB(?{$m = qq|\t|})`$m`ge;

		my $dir = qq|/home/${linuxuser}|;
		
		$self->_write_config($dir, q|.bashrc|, $config);
		$self->_process_cmd(qq|source ${dir}/.bashrc|);
	}
	
}

__END__
