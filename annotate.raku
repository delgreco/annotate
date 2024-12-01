#!/usr/bin/env raku

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
    # say %notes;
    # build index from all files in directory
    for $directory.IO.dir.sort -> $file {
        # skip Annotations.txt or .Annotations.txt.swp
        next if $file.basename ~~ / ^ \.?Annotations\.txt.* $ /;
        # say "File object: {$file.^name}";
        # Check if it is a file (not a directory)
        if $file.f {
            # say "Processing file: {$file.basename}"; # Use the filename
            if %notes{$file.basename}:exists {
                $content ~= "<li><a href='{$file.basename}'>{$file.basename}</a>: { %notes{ $file.basename } }</li>\n";
            }
            else {
                $content ~= "<li><a href='{$file.basename}'>{$file.basename}</a></li>\n";
            }
            # $content ~= '<li><a href="' ~ {$file.basename.gist} ~ '">' ~ {$file.basename.gist} ~ '</a>: ' ~ %notes{ {$file.basename.gist} } ~ '</li>' ~ "\n";
        }
    }
    # read the template and replace the placeholder
    my $template = $template-file.IO.slurp;
    $template ~~ s/'<!-- CONTENT_PLACEHOLDER -->'/$content/;
    $template ~~ s:g/'<!-- TITLE_PLACEHOLDER -->'/$title/;
    # write the output to index.html
    $output-file.IO.spurt($template);
    say "Generated 'index.html' successfully at: $output-file";
}



