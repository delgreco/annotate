# annotate
Annotate files where they live.

You must have Raku installed to run this program.  See [this page](https://rakudo.org/downloads).  I use the Rakudo Star bundle, to good effect.

Run annotate.raku at the command line.  You will be prompted for a directory.  Within that directory, files you wish to annotate are expected along with a file called

    Annotations.txt

This file's format should be:

    First Line: Your Title For This Annotated Index

    filename: description
    filename: description

    filename: description
    filename: description
    [etc...]

Line delimited, blank lines ignored.

A file called

    index.html

will be created in the directory you specified.

