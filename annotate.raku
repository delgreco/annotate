#!/usr/bin/env raku

my $p = $*PROGRAM.absolute;
my $path-obj = $p.IO;
my $progdir = $path-obj.dirname;

if $*CWD ne $progdir {
    die "Error: script must be run from its own directory: $progdir";
}

my $template-file = 'index.tmpl';

my $directory = prompt("Enter a directory path: ");

my $output-file = "$directory/index.html";
my $annotations-file = "$directory/Annotations.txt";

if $directory.IO.d {
    # say "You entered a valid directory: $directory";
    if $annotations-file.IO.f {
        index();
    }
    else {
        say "The file 'Annotations.txt' does not exist in directory '$directory'.";
    }
} 
else {
    say "The path you entered is not a directory or does not exist.";
    say "Path: {$directory.IO}";
}

sub index() {
    my %notes;
    my $content = ''; my $title = '';
    # load titles and notes
    my $count = 0;
    for $annotations-file.IO.lines -> $line {
        next if $line ~~ /^\s*$/;  # ignore blank lines
        $count++;
        if ( $count == 1 ) {
            $title = $line;
            next;
        }
        if $line ~~ / ^ (.*?) \: (.+) $ / {
            my $filename = $0;
            my $annotation = $1;
            # say "File: $filename";
            # say "Annotation: $annotation";
            %notes{$filename} = $annotation;
            if $filename && $annotation {
                # $content ~= "<li><a href='$filename'\>$filename\</a\>: $annotation\</li\>\n";
                # say "-" x 40;  # separator
                # great
            }
            else {
                say "Invalid capture: $filename, $annotation";
            }
        }
        else {
            say "Invalid format: $line";
        }
    }
    #say %notes;
    # build index from all files in directory
    my $filecount = 0; my $series = 0;
    my $previous_name = '';
    for $directory.IO.dir.sort -> $file {
        # skip Annotations.txt or .Annotations.txt.swp
        next if $file.basename ~~ / ^ \.?Annotations\.txt.* $ /;
        next if $file.basename eq '.DS_Store';
        next if $file.basename eq 'index.html';
        # say "File object: {$file.^name}";
        # if it's a file (not a directory)
        if $file.f {
            # say "Processing file: {$file.basename}"; # Use the filename
            my $num; my $name;
            # look for files in series like: Fire_01.jpeg
            if $file.basename ~~ /(.+?)(\d+)?\..+$/ {
                $name = $/[0] // 'None';
                $name = $name.subst("_", " ", :g);
                # say $file.basename;
                if $/[1] { 
                    $series++;
                    $num = $/[1];
                    say "Detected series marker for {$file.basename}: " ~ $/[1] ~ " " ~ $name;
                    say "Prev: {$previous_name} Current: {$name}";
                    if $previous_name && $previous_name ne $name {
                        $series = 0;  # reset
                    }
                }
                else {
                    $series = 0;  # reset, as it's not a series file
                }
            }
            else {
                say "ERROR: file should match regex";
            }
            if $series > 0 {
                $content ~= "&nbsp; - <a href='#' onClick=\"showImg('{$file.basename}');\">{$num}</a> ";
            }
            else {
                if %notes{$file.basename}:exists {
                    # escape single quotes for JavaScript
                    # and convert any double into escaped singles
                    my $notes = %notes{$file.basename}.subst("'", "\\'", :g).subst('"', "\\'", :g);
                    
                    $content ~= "<li><a href='#' onClick=\"showImg('{$file.basename}', '$notes');\">{$name}</a>: { %notes{ $file.basename } }";
                }
                else {
                    $content ~= "<li><a href='#' onClick=\"showImg('{$file.basename}');\">{$name}</a>";
                }
            }
            $content ~= "</li>\n" if $series == 0;
            $filecount++;
            $previous_name = $name;
        }
    }
    # read the template and replace the placeholder
    my $template = $template-file.IO.slurp;
    $template ~~ s/'<!-- CONTENT -->'/$content/;
    $template ~~ s:g/'<!-- TITLE -->'/$title/;
    $template ~~ s:g/'<!-- COUNT -->'/$filecount/;
    # pick a random image to display for spice
    my @images = $directory.IO.dir.grep(*.IO.f).map(*.basename);
    my $randomimg = @images.pick;
    $template ~~ s:g/'<!-- RANDOM_IMAGE -->'/$randomimg/;
    my $caption = "$randomimg: { %notes{$randomimg} // '' }";
    $template ~~ s:g/'<!-- RANDOM_IMAGE_CAPTION -->'/$caption/;
    # write the output to index.html
    $output-file.IO.spurt($template);
    say "Generated 'index.html' successfully at: $output-file";
}



