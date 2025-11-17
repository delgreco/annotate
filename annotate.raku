#!/usr/bin/env raku

sub MAIN(
    Str :$dir = '', # optional: --dir=[directory]
) {
    my $d = $dir;
    my $p = $*PROGRAM.absolute;
    my $path-obj = $p.IO;
    my $progdir = $path-obj.dirname;
    if $*CWD ne $progdir {
        die "Error: script must be run from its own directory: $progdir";
    }
    unless $d {
        $d = prompt("Enter a directory path: ");
    }
    if ( $d ) {
        my $filecount = index( :directory($d) );
    }
    else {
        say "ERROR: directory not defined.";
    }
}

sub index( :$directory, :$subdir = 0 ) {
    my $output-file = "$directory/index.html";
    my $annotations-file = "$directory/Annotations.txt";
    if $directory.IO.d {
        if ! $annotations-file.IO.f {
            say "The file 'Annotations.txt' does not exist in directory '$directory'.";
            return;
        }
    } 
    else {
        say "The path you entered is not a directory or does not exist.";
        say "Path: {$directory.IO}";
        return;
    }
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
            %notes{$filename} = $annotation;
            if ! $filename || ! $annotation {
                say "Invalid capture: $filename, $annotation";
            }
        }
        else {
            say "Invalid format: $line";
        }
    }
    #say %notes;
    # build index from all files in directory
    my $filecount = 0; my $totalsubfiles = 0;
    my $series = 0;
    my $previous_name = ''; my $subdirs;
    for $directory.IO.dir.sort -> $file {
        # skip Annotations.txt or .Annotations.txt.swp
        next if $file.basename ~~ / ^ \.?Annotations\.txt.* $ /;
        next if $file.basename eq '.DS_Store';
        next if $file.basename eq 'index.html';
        # say "File object: {$file.^name}";
        if $file.IO.d {  # subdirectory recursion
            my $count = index( :directory( "$directory/{$file.basename}" ), :subdir(1) );
            $totalsubfiles = $totalsubfiles + $count;
            $subdirs ~= "<li><a href='{$file.basename}/index.html'> 📁 {$file.basename} ($count)</a></li>\n";
        }
        elsif $file.f {  # normal file processing
            $filecount++;
            my $num; my $name;
            # assumption: files starting with a letter may have been manually named
            # unless IMG* or image*
            if ( not $file.basename ~~ /^(IMG|image)/ ) && $file.basename ~~ /^<[A..Za..z]>/ {
                # look for intentionally named files in series like: Fire_01.jpeg
                if $file.basename ~~ /(.+?)(\d+)?\..+$/ {
                    # note that our captured values are actually match objects
                    # that need to be braced to strings like {$name} and {$num}
                    # for interpolation below
                    $name = $/[0] // 'None';
                    $name = $name.subst("_", " ", :g);
                    if $/[1] { 
                        $series++;
                        $num = $/[1];
                        # reset series for first file so name displays
                        # or reset if we have a new file from new series
                        if $filecount == 1 || ($previous_name && $previous_name ne $name) {
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
            }
            else { # files not starting with a letter, prob not manually named
                # so process as non-series and show filename exactly
                $name = $file.basename;
            }
            if $series > 0 {
                $content ~= qq|&nbsp; - <a href="#" data-filename="{$file.basename}" onClick="showImg(this.dataset.filename);">{$num}</a> |;
            }
            else {
                if %notes{$file.basename}:exists {
                    $content ~= qq|<li><a href="#" data-filename="{$file.basename}" data-notes="{ %notes{ $file.basename } }" onClick="showImg(this.dataset.filename, this.dataset.notes);">{$name}</a>: { %notes{ $file.basename } }|;
                }
                else {
                    $content ~= qq|<li><a href="#" data-filename="{$file.basename}" onClick="showImg(this.dataset.filename);">{$name}</a>|;
                }
            }
            $content ~= "</li>\n" if $series == 0;
            $previous_name = $name;
        }
        else {
            say "This is neither a directory nor a normal file: {$file.basename}";
        }
    }
    # read the template and replace the placeholder
    my $template-file = 'index.tmpl';
    my $template = $template-file.IO.slurp;
    # if we *have* subdirectories
    $template ~~ s/'<!-- SUBDIRS -->'/$subdirs/ if $subdirs;
    # if we *are* a subdirectory
    my $linkup = "<h3><a href='../index.html'>../</a></h3>";
    $template ~~ s/'<!-- SUBDIR -->'/$linkup/ if $subdir;
    $template ~~ s/'<!-- CONTENT -->'/$content/;
    my $dirname;
    if $directory ~~ m| '/'? ( <-[/]>+ ) $ | {
        $dirname = $0;  # everything after the last slash
    }
    $title = $dirname unless $title;
    $template ~~ s:g/'<!-- TITLE -->'/$title/;
    my $now = DateTime.now;
    $now = sprintf '%04d-%02d-%02d %02d:%02d',
    $now.year,
    $now.month,
    $now.day,
    $now.hour,
    $now.minute;
    $template ~~ s:g/'<!-- DATETIME -->'/$now/;
    $template ~~ s:g/'<!-- COUNT -->'/$filecount/;
    my $total = $totalsubfiles + $filecount;
    $template ~~ s:g/'<!-- TOTAL -->'/($total total)/ if $total != $filecount;
    # pick a random image to display for spice
    my @images = $directory.IO.dir
        .grep(*.IO.f)                     # only files
        .grep({ $_.extension ne 'txt' })  # exclude .txt file
        .grep({ $_.extension ne 'html' }) # exclude .html file
        .map(*.basename);                 # get the filenames
    my $randomimg = @images.pick;
    $template ~~ s:g/'<!-- RANDOM_IMAGE -->'/$randomimg/;
    my $caption = "$randomimg: { %notes{$randomimg} // '' }";
    $template ~~ s:g/'<!-- RANDOM_IMAGE_CAPTION -->'/$caption/;
    # write the output to index.html
    $output-file.IO.spurt($template);
    say "Generated '$output-file'";
    return $filecount;
}



