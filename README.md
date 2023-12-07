# File Digest Calculator
This scripts finds duplicate files and uniqs them.

## Usage
### Digest calculation
`calculate_file_digest.rb` calculates the digests of files. The following command line will calculate the digests of all files and subfiles in a current directory and will output them to `digests.csv`.
```
$ ruby calculate_file_digest.rb -o digests.csv -r .

$
```

### Duplicate file search
`find_duplicate_file.rb` finds duplicate files. The following command line will search files with same content from `digest.csv` and will output them to `duplicate_files.json`.
```
$ ruby find_duplicate_file.rb -k sha256 -o duplicate_files.json digest.csv

$
```

Multiple input files can be specified as follows:
```
$ ruby find_duplicate_file.rb -k sha256 -o duplicate_files.json digest1.csv digest2.csv

$
```

Multiple keys can be specified. The following command line will search files with same file name and content from `digest.csv`.
```
$ ruby find_duplicate_file.rb -k 'file_name' -k sha256 -o duplicate_files.json digest.csv

$
```

### Delete duplicate file
`delete_duplicate_file.rb` delete duplicate files. The following command line will delete second and subsequent files in each element in `duplicate_files.json`.
```
$ ruby calculate_file_digest.rb duplicate_files.json

$
```

## Repository information
Author: calotocen  
URL: https://github.com/calotocen/FileDigestCalculator
