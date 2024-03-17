# Stupid Rss Generator
This is a stupid perl script that generates an RSS XML file that you can subscribe to with your RSS reader.

## Why
Mainly because I want to be able to subscribe to serial books. As we all know, RSS is dying since it is hard to harvest data from RSS users.

## How
- **This is at early stage. Use at your own risk. The library depended may change. If you find following instruction leaves out some packages uninstalled, you may need to install them yourself with `cpan` (or `cpanm`/`cpanplus`, more recommended)**
- Install reasonable version of `perl` and `cpan`. Better though to have [`CPANPLUS`](https://metacpan.org/pod/CPANPLUS) if you only want to use perl instead of writing perl as it supports skipping testing which might take a very long time.
- Dependencies that needed to be installed from OS:
  - `expat-devel` (or `libexpat1-dev`) (for XML::Parser)
- `perl Makefile.PL`
- `make installdeps`.
- run the single script `stupid_rss_generator.pl`.
- By default, it stores generated rss file at `./rss/<book-title>.xml`.
- By default, it stores and reads metadata from `./record.yaml`. (Will create one and iteractively ask you information needed if not found)
- You need to input regrex by yourself. It should be easy with arbitrary gpt services.

## And 
- I don't use windows or OS X. Perl should work on them but I am not sure.

## TODO
- countless todos in the code
- proper cli interface
