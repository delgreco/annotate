#!/usr/bin/env raku
use lib 'lib';
use ExifTool;

=begin pod
=head1 index.raku

Annotate files where they live, and create a browsable archive.

=head2 MAIN( $dir )

Accept a directory to index.  If no --dir=[dir] is passed, prompt for one.

=end pod

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

=begin pod

=head2 index( $dir, $subdir )

Index the directory given in the first arg, recursively.  If a true value is passed for the second arg, we know we are dealing with a subdirectory.

=end pod

sub index( :$directory, :$subdir = 0 ) {
    my $output-file = "$directory/index.html";
    unless $directory.IO.d {
        say "The path you entered is not a directory or does not exist.";
        say "Path: {$directory.IO}";
        return;
    }
    
    my $content = ''; my $title = '';
    # load titles and notes
    my $count = 0;
    
    # build index from all files in directory
    my $filecount = 0; my $totalsubfiles = 0;
    my $series = 0;
    my $previous_name = ''; my $subdirs;
    my $image-ext = /:i jpe?g | png | tiff? | webp /;

    for $directory.IO.dir.sort(*.basename.lc) -> $file {
        if $file.IO.d {  # subdirectory recursion
            next if $file.basename.starts-with('.');
            next if $file.basename eq 'lib' || $file.basename eq '.git';
            
            my $count = index( :directory( "$directory/{$file.basename}" ), :subdir(1) );
            $totalsubfiles = $totalsubfiles + $count;
            $subdirs ~= "<li><a href='{$file.basename}/index.html'> 📁 {$file.basename} ($count)</a></li>\n";
        }
        elsif $file.f {  # normal file processing
            # Whitelist images that support XMP metadata
            next unless $file.extension ~~ $image-ext;

            $filecount++;
            my $num; my $name;
            # assumption: files starting with a letter may have been manually named
            # unless IMG* or image*
            if ( not $file.basename ~~ /^(IMG|image)/ ) && $file.basename ~~ /^<[A..Za..z]>/ {
                # look for intentionally named files in series like: Fire_01.jpeg
                if $file.basename ~~ /(.+?)[_ ]?(\d+)?\..+$/ {
                    $name = $/[0].Str;
                    $name = $name.subst("_", " ", :g).trim;
                    if $/[1] { 
                        $series++;
                        $num = $/[1].Str;
                        if $filecount == 1 || ($previous_name && $previous_name ne $name) {
                            $series = 0;  # reset
                        }
                    }
                    else {
                        $series = 0;  # reset
                    }
                }
            }
            else { 
                $name = $file.basename;
            }

            my $note = '';
            
            # Read XMP metadata
            try {
                my %meta = read-metadata($file, 'XMP:Description');
                $note = %meta{'XMP:Description'} // '';
                CATCH { default { } }
            }
            
            # Escape quotes for data-notes attribute
            my $escaped-note = $note.Str.subst('"', '&quot;', :g);

            if $series > 0 {
                $content ~= qq|<li>&nbsp;&nbsp;&nbsp;&nbsp;<a href="#" data-filename="{$file.basename}" data-notes="{$escaped-note}" onClick="showImg(this.dataset.filename, this.dataset.notes);">{$name} {$num}</a>|;
                if $note {
                    $content ~= ": {$note}";
                }
                $content ~= "</li>\n";
            }
            else {
                # We don't need to close previous here if we always close at the end of each iteration
                # but the current logic is: if series, it's a sub-item.
                if $note {
                    $content ~= qq|<li><a href="#" data-filename="{$file.basename}" data-notes="{$escaped-note}" onClick="showImg(this.dataset.filename, this.dataset.notes);">{$name}</a>: {$note}</li>\n|;
                }
                else {
                    $content ~= qq|<li><a href="#" data-filename="{$file.basename}" onClick="showImg(this.dataset.filename);">{$name}</a></li>\n|;
                }
            }
            $previous_name = $name;
        }
    }
    # Remove the extra </li>\n if it was there

    # read the template and replace the placeholder
    my $template-file = 'index.tmpl';
    my $template = $template-file.IO.slurp;

    # Load archive header from ARCHIVE_HEADER file in script directory
    my $header-file = $*PROGRAM.parent.add('ARCHIVE_HEADER');
    my $archive-header = $header-file.f ?? $header-file.slurp.trim !! 'The Archive';
    $template ~~ s/'<!-- ARCHIVE_HEADER -->'/$archive-header/;
    # if we *have* subdirectories
    if $subdirs {
        $template ~~ s/'<!-- SUBDIRS -->'/$subdirs/;
    }
    else {
        $template ~~ s/'<!-- SUBDIRS -->'//;
    }
    # if we *are* a subdirectory
    my $linkup = "<h3 style='margin: 0;'><a href='../index.html'>../</a></h3>";
    if $subdir {
        $template ~~ s/'<!-- SUBDIR -->'/$linkup/;
    }
    else {
        $template ~~ s/'<!-- SUBDIR -->'//;
    }
    $template ~~ s/'<!-- CONTENT -->'/$content/;
    my $dirname;
    if $directory ~~ m| '/'? ( <-[/]>+ ) $ | {
        $dirname = $0;  # everything after the last slash
    }
    $title = $dirname unless $title;
    $template ~~ s:g/'<!-- TITLE -->'/$title/;
    my $now = DateTime.now;
    my @months = <None January February March April May June July August September October November December>;
    my @days   = <None Monday Tuesday Wednesday Thursday Friday Saturday Sunday>;
    my $h      = $now.hour;
    my $ampm   = $h >= 12 ?? 'PM' !! 'AM';
    $h = $h % 12 || 12;
    my $dt-str = sprintf '%s, %s %d, %04d at %d:%02d %s',
        @days[$now.day-of-week], @months[$now.month], $now.day, $now.year, $h, $now.minute, $ampm;
    $template ~~ s:g/'<!-- DATETIME -->'/$dt-str/;
    my $total = $totalsubfiles + $filecount;
    if $total != $filecount {
        $template ~~ s:g/'<!-- TOTAL -->'/($total total)/;
        $template ~~ s:g/'<!-- COUNT -->'/($filecount this page)/;
    }
    else {
        $template ~~ s:g/'<!-- COUNT -->'/($filecount)/;
        $template ~~ s:g/'<!-- TOTAL -->'//;
    }
    # pick a random image to display for spice
    my @images = $directory.IO.dir
        .grep(*.IO.f)
        .grep({ $_.extension.lc ~~ /^(jpe?g|png|tiff?|webp)$/ })
        .map(*.basename).sort;

    my @json_entries;
    for @images -> $img {
        my $cap = $img;
        try {
            my %meta = read-metadata("$directory/$img".IO, 'XMP:Description');
            if %meta{'XMP:Description'} -> $xmp-note {
                $cap ~= ": $xmp-note";
            }
            CATCH { default { } }
        }
        my $escaped_cap = $cap.subst('"', '\\"', :g);
        @json_entries.push: qq|\{ "filename": "$img", "caption": "$escaped_cap" \}|;
    }
    $template ~~ s/'<!-- IMAGES_JSON -->'/{ @json_entries.join(', ') }/;

    my $randomimg = @images.pick;
    if $randomimg {
        $template ~~ s:g/'<!-- RANDOM_IMAGE -->'/$randomimg/;
        my $caption = $randomimg;
        try {
            my %meta = read-metadata("$directory/$randomimg".IO, 'XMP:Description');
            if %meta{'XMP:Description'} -> $xmp-note {
                $caption ~= ": $xmp-note";
            }
            CATCH { default { } }
        }
        $template ~~ s:g/'<!-- RANDOM_IMAGE_CAPTION -->'/$caption/;
    }
    else {
        $template ~~ s:g/'<!-- RANDOM_IMAGE -->'//;
        $template ~~ s:g/'<!-- RANDOM_IMAGE_CAPTION -->'//;
    }
    # write the output to index.html
    $output-file.IO.spurt($template);
    say "Generated '$output-file'";
    return $total;
}



