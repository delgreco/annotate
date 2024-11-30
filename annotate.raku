#!/usr/bin/env raku

my $template-file = 'index.tmpl';

my $directory = prompt("Enter a directory path: ");
my $title = prompt("Enter a title for this index: ");

if $directory.IO.d {
    # say "You entered a valid directory: $directory";
    my $output-file = "$directory/index.html";
    my $annotations-file = "$directory/Annotations.txt";
    if $annotations-file.IO.f {
        my $content = "";
        # Read and process the file line by line
        for $annotations-file.IO.lines -> $line {
            next if $line ~~ /^\s*$/;  # skip blank lines
            if $line ~~ / ^ (.*?) \: (.+) $ / {
                my $filename = $0;
                my $annotation = $1;
                if $filename && $annotation {
                    # say "File: $filename";
                    # say "Annotation: $annotation";
                    $content ~= "<li><a href='$filename'\>$filename\</a\>: $annotation\</li\>\n";
                    # say "-" x 40;  # separator
                }
                else {
                    say "Invalid capture: $filename, $annotation";
                }
            }
            else {
                say "Invalid format: $line";
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
    else {
        say "The file 'Annotations.txt' does not exist in the directory.";
    }
} 
else {
    say "The path you entered is not a directory or does not exist.";
}


