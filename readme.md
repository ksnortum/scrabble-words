Readme for scrabble.pl
======================

`scrabble.pl` is a command line Scrabble(r) word generator written in Perl.  See 
`scrabble.html` for syntax and command line options.

Installation
============

Install Perl if Needed
----------------------

You need Perl to run `scrabble.pl`.  First see if your distribution has it installed.  Go
to a command line and type

	perl -v

If you don't get a copyright notice for Perl, install it.  Go to 
[the Perl webpage](http://www.perl.org).  For Windows(r) I suggest 
[Strawberry Perl](http://www.strawberryperl.com).

Install the Custom Modules
--------------------------

The custom modules `Permutation.pm` and `Subset.pm` need to be installed.  Look in 
Perl installation directory and you should see a site/lib directory.  Copy the two
files there.  You can use `permutations.pl` and `subset.pl` to test that the 
modules are installed and working properly.

Install the Word Libraries
--------------------------

Unzip the two Scrabble word dictionaries using `gunzip`:

	gunzip sowpods.txt.gz
	gunzip twl.txt.gz

You can put these libraries anywhere.  On Unix-like systems you can try 
/usr/local/lib/scrabble/.  Modify `scrabble.pl` to point to the correct path:

	my $SOWPODS_PATH = "/usr/local/lib/scrabble/sowpods.txt";

SOWPODS and Collins are the same dictionary.  If you want to your system's spell check
dictionary or any other custom dictionary, set its path for the WORDS_PATH and use
WORDS as your custom dictionary on the command line.

	my $WORDS_PATH = "/usr/share/dict/words";

Limitations
===========

* You can only use one blank tile (dot) at a time, and even one increases the process
time greatly.

* If the program uses a blank tile as, say, a "z", it counts this in the score.  All
blank tiles should have a value of zero.

* You cannot give the positions of any letters, but you can accomplish this with the 
list output and piping to `grep`.

Copyright
=========

`scrabble.pl` and the modules `Permutation.pm` and `Subset.pm` are copyright 2014 by 
Knute Snortum.  They are open source software and can be used under the same license as
Perl itself.

The files `sowpods.txt` and `twl.txt` appear to be copyright free, but I would suggest
investigating this before using them in a commercial program.

Contact
=======

You can contact me at knute (at) snortum (dot) net or as Knute Snortum on Google+.
