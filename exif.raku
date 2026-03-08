#!/usr/bin/env raku
use lib 'lib';
use ExifTool;

sub MAIN(*@args, *%named-args) {
    if ! @args {
        usage();
        return;
    }
    
    my $command = @args.shift;
    
    if $command eq 'read' {
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
    elsif $command eq 'write' {
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
    else {
        usage();
    }
}

sub usage() {
    say "Usage:";
    say "  exif.raku read <path> [<tags> ...]";
    say "  exif.raku write <path> --TagName=Value [--OtherTag=Value]";
}
