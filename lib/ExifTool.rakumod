unit module ExifTool;

sub write-metadata(IO::Path $file, %tags) is export {
    my $backup = "{$file.absolute}.bk".IO;
    unless $backup.f {
        $file.copy($backup);
    }
    
    my @args = 'exiftool', '-overwrite_original';
    for %tags.kv -> $tag, $value {
        @args.push: "-$tag=$value";
    }
    @args.push: $file.absolute;
    
    my $proc = run @args, :out, :err;
    my $output = $proc.out.slurp: :close;
    my $error = $proc.err.slurp: :close;
    
    if ( $proc.exitcode != 0 ) {
        die "ExifTool failed on $file: $error";
    }
    
    return $output;
}

sub read-metadata(IO::Path $file, *@tags) is export {
    my @args = 'exiftool', '-s', '-G';
    for @tags -> $tag {
        @args.push: "-$tag";
    }
    @args.push: $file.absolute;
    
    my $proc = run @args, :out, :err;
    my $output = $proc.out.slurp: :close;
    my $error = $proc.err.slurp: :close;
    
    if ( $proc.exitcode != 0 ) {
        die "ExifTool failed to read $file: $error";
    }
    
    my %result;
    for $output.lines -> $line {
        # Format is usually: [Group] Tag: Value
        if $line ~~ /^ \[ (.*?) \] \s+ (.*?) \s* \: \s* (.*) $/ {
            my $group = ~$0;
            my $tag   = ~$1;
            my $value = ~$2;
            %result{"$group:$tag"} = $value;
        }
    }
    return %result;
}
