# annotate
Use XMP metadata to annotate and index an image archive.

You must have Raku installed to run this program. See [this page](https://rakudo.org/downloads). I use the Rakudo Star bundle, to good effect.

[Exiftool](https://exiftool.org/) also needs to be installed and available.

## Usage

### Indexing (`index.raku`)

Generate a browsable HTML archive for a directory. This script reads the `XMP:Description` tag from image files and uses it for captions.

```bash
raku index.raku --dir=/path/to/images
```

It will recursively index subdirectories and generate an `index.html` in each.

### Metadata Management (`annotate.raku`)

Manage image metadata interactively or via CLI.

#### Interactive Mode

Open each image in your default viewer and prompt for a new description:

```bash
# Process a single file
raku annotate.raku image.jpg

# Process an entire directory
raku annotate.raku /path/to/images/
```

In directory mode, it skips non-image files and allows you to quit any time by entering `q`.

#### CLI Mode

Read or write specific tags without interaction:

```bash
# Read specific tags
raku annotate.raku read image.jpg XMP:Description

# Write a specific tag
raku annotate.raku --XMP-dc:Description="My new caption" write image.jpg
```
