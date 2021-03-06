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

The custom modules `Permutation.pm` and `Subset.pm` should be installed in a 
system-accessible area, but you don't have to do this if you're going to run 
everything from
one directory.  If you type `perl -V` (that's a capital V) at the end you will see
the contents of @INC.  This is Perl's install "path" to modules.  There is usually a
dot (current
directory) at the end.  If so, you can put the modules in the same directory as the
`scrabble.pl` file.  You should also see a path that ends with "site" or "site_perl".
This is where you can put `Permutation.pm` and `Subset.pm` if you want to use them
in other Perl programs.  You can use `permutations.pl` and `subset.pl` to test that the 
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

Running scrabble.pl
===================

The easiest way to run `scrabble.pl` is to `cd` into the directory where you copied
the script and type

	perl ./scrabble.pl

Whether you need to type `perl` depends on your system.

Unix-like Systems
-----------------

Perl is usually already installed and in your PATH.  At the very top of `scrabble.pl`
you should see `#! /usr/bin/perl`.  This tells the shell what this script should be
run with.  Type `which perl` and make sure /usr/bin/perl is valid for your system and
change it if necessary.  If you make `scrabble.pl` executable (see man chmod) you do
not need to type `perl`.  If you copy `scrabble.pl` into a directory in your PATH, you
do no need to cd into the directory.  At that point you should be able to do the following
from any directory:

	scrabble.pl [options] <letters>

Windows
-------

You will probably need to install Perl (see first paragraph).  If the installer hasn't
done it for you already, put the path to `perl.exe` in your PATH.  Now you can `cd`
into the folder where you copied `scrabble.pl` and type

	perl .\scrabble.pl

Getting `scrabble.pl` to execute Perl automatically may have been by your installer
(try just `scrabble.pl` to check).  If not, you will want to associate the .pl
extension with Perl.  Probably the easiest way to do this is to display `scrabble.pl`
in the Windows Explorer (Files, not Internet).  Right-click on the file and click on
Choose Default Program.  Select `perl.exe` or Perl Interpreter.

Limitations
===========

* You can only use one blank tile (dot) at a time, and even one increases the process
time greatly.

Copyright and License
=====================

`scrabble.pl`, `Subset.pm`, and `Permutation.pm` are Copyright (C) 2014, by Knute Snortum

It is free software; you can redistribute it and/or modify it under the terms of either:

* the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

* the Artistic License version 2.0.

The files `sowpods.txt` and `twl.txt` appear to be copyright free, but I would suggest
investigating this before using them in a commercial program.

Contact
=======

You can contact me at knute (at) snortum (dot) net or as Knute Snortum on Google+.
