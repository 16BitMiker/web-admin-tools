#!/bin/bash

perl -M'Term::ANSIColor'=':constants' -E 'printf qq|> %s%s |, GREEN q|press enter to setup ubuntu installer requirements...|, RESET; <STDIN>;'

perl -M'Term::ANSIColor'=':constants' -sE 'map { printf qq|> %s%s\n|, YELLOW $_, RESET; system $_; } split m~`~, $cmds' -- -cmds='sudo apt update -y`sudo apt install perl -y`sudo apt install cpanminus -y`sudo cpanm Expect`sudo cpanm JSON::MaybeXS`cpanm Data::Dump' 

perl -M'Term::ANSIColor'=':constants' -e 'printf qq|> %s%s\n|, GREEN q|setup complete!|, RESET;' 

