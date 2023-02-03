#!/usr/bin/env perl

my $json = Create::JSON->load();
$json->_create_json();

package Create::JSON
{
	use feature qw|say|;
	use JSON::MaybeXS;
	use Term::ANSIColor qw|:constants|;
	
	sub load()
	{
		my $class = shift;
		return bless {}, $class;
	}
	
	sub _create_json()
	{
		my $db   = {};
		my $self = shift;
		my $json = {};
		my $json_file = q|config-|.time().q|.json|;
		
		printf qq|> %s %s%s\n|, q|Fill in the info below, it will be saved to:|, UNDERLINE GREEN $json_file, RESET;
		
		chomp (my $current_user = qx|echo \$USER|);
		
		printf qq|> %s%s: |, YELLOW qq|linux username (enter for ${current_user})|, RESET;
		chomp (my $user = <STDIN>);
		
		$$db{linuxuser} = $user =~ m`^$` ? $current_user : $user;
		
		printf qq|> %s%s: |, YELLOW q|mysql root password|, RESET;
		chomp ($$db{sqlpass} = <STDIN>);
		
		my $n = 0;
		
		ADD:
		{ 
			printf qq|> %02d ~ %s%s: |, $n, YELLOW q|domain|, RESET;
			chomp ($$db{$n}{website} = <STDIN>);
			
			printf qq|> %02d ~ %s%s: |, $n, YELLOW q|email|, RESET;
			chomp ($$db{$n}{email} = <STDIN>);
			
			printf qq|> %02d ~ %s%s: |, $n, YELLOW q|web folder (omit /var/www/)|, RESET;
			chomp ($$db{$n}{webfolder} = <STDIN>);
			
			$$db{$n}{webfolder} =~ s`^/var/www/``;
			
			printf qq|> %02d ~ %s%s: |, $n, YELLOW q|database name|, RESET;
			chomp ($$db{$n}{dbname} = <STDIN>);
			
			printf qq|> %02d ~ %s%s: |, $n, YELLOW q|database user|, RESET;
			chomp ($$db{$n}{dbuser} = <STDIN>);
			
			printf qq|> %02d ~ %s%s: |, $n, YELLOW q|database password|, RESET;
			chomp ($$db{$n}{dbpass} = <STDIN>);
			
			$json = encode_json($db);
		}
	
		printf qq|> saving to: %s%s%s\n|, UNDERLINE GREEN $json_file, RESET qq|\n> |, $json;
		printf q|> %s%s: |, GREEN q|(w)rite / (r)edo / (a)dd / (q)uit|, RESET;
		my $final_choice = <STDIN>;
		
		if ($final_choice =~ m~^w(?:rite)?$~i)
		{
			open my $fh, q|>|, $json_file or RED die qq|> can't open file so quitting!\n|, RESET;
			say $fh $json;
			close $fh;
			
			printf qq|> %s%s\n|, GREEN q|saved!|, RESET;
			exit 69;
			
		}
		elsif ($final_choice =~ m~^q(?:uit)?$~i)
		{
			printf qq|> %s\n|, q|quitting!|;
			exit 69;
		}
		elsif ($final_choice =~ m~^r(?:edo)?$~i)
		{
			goto ADD;
			
		} 
		elsif ($final_choice =~ m~^a(?:dd)?$~i)
		{
			$n++;
			goto ADD;
			
		} 
		else 
		{
			printf qq|> %s%s\n|, GREEN q|you didn't choose so redoing |, RESET;
			goto ADD;
		}
	}
	
}