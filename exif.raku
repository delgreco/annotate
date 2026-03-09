#!/usr/bin/env raku
use lib 'lib';
use ExifTool;

sub MAIN(*@args, *%named-args) {
    if ! @args {
        usage();
        return;
    }
    
    my $first = @args[0];
    
    if $first eq 'read' {
        @args.shift;
        handle-read(@args);
    }
    elsif $first eq 'write' {
        @args.shift;
        handle-write(@args, %named-args);
    }
    elsif $first.IO.f {
        interactive-mode($first.IO);
    }
    elsif $first.IO.d {
        my @image-extensions = <jpg jpeg png tiff tif webp heic>;
        for $first.IO.dir.grep({ .f && .extension && .extension.lc ~~ any(@image-extensions) }).sort -> $file {
            interactive-mode($file);
        }
    }
    else {
        usage();
    }
}

sub handle-read(@args) {
    if ! @args {
        usage();
        return;
    }
    my $path = @args.shift;
    my $file = $path.IO;
    unless $file.f {
        note "Error: File not found: $path";
        exit 1;
    }
    
    say "Reading metadata from $path...";
    my %meta = read-metadata($file, |@args);
    
    if ( ! %meta ) {
        say "No matching metadata found.";
    }
    else {
        for %meta.sort(*.key) -> $pair {
            say "{$pair.key}: {$pair.value}";
        }
    }
}

sub handle-write(@args, %named-args) {
    if ! @args {
        usage();
        return;
    }
    my $path = @args.shift;
    my $file = $path.IO;
    unless $file.f {
        note "Error: File not found: $path";
        exit 1;
    }
    
    my %valid-tags = %named-args.grep({ .key !~~ /^ ['help'|'usage'] $/ });
    
    unless %valid-tags {
        note "Error: No tags provided to write. Use --TagName=Value";
        exit 1;
    }
    
    say "Writing metadata to $path...";
    try {
        write-metadata($file, %valid-tags);
        say "Successfully updated $path (backup created if first time).";
        CATCH {
            default {
                note "Failed: $_";
                exit 1;
            }
        }
    }
}

sub interactive-mode(IO::Path $file) {
    say "\n" ~ ("-" x 40);
    say "File: {$file.basename}";
    
    my %meta;
    try {
        %meta = read-metadata($file, 'XMP:Description');
        CATCH {
            default {
                note "Skipping {$file.basename}: Could not read metadata (is it an image?)";
                return;
            }
        }
    }
    
    if %meta{'XMP:Description'} -> $desc {
        say "Current Description: $desc";
    }
    else {
        say "Current Description: [None]";
    }
    
    my $prompt-text = "Enter new description (blank to skip, 'q' to quit): ";
    my $new-desc = prompt($prompt-text);
    
    if $new-desc eq 'q' {
        say "Exiting.";
        exit 0;
    }
    
    if $new-desc.trim -> $val {
        say "Writing new description...";
        try {
            write-metadata($file, { 'XMP-dc:Description' => $val });
            say "Success!";
            CATCH {
                default {
                    note "Error writing metadata: $_";
                }
            }
        }
    }
    else {
        say "No changes made.";
    }
}

sub usage() {
    say "Usage:";
    say "  exif.raku <path>                        -- Interactive mode for image(s) or directory";
    say "  exif.raku read <path> [<tags> ...]      -- Read specific tags";
    say "  exif.raku write <path> --TagName=Value  -- Write specific tags";
    say "\nNote: For 'write', named arguments must come BEFORE 'write'.";
    say "Example: raku exif.raku --XMP-dc:Description=\"Test\" write img.jpg";
}
