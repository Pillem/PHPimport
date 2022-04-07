Bash script for finding missing 'use' statements in php projects


-------------------------
--- PHP Import Finder ---
-------------------------
Usage:
./findMissingUse.sh -a [options]              Detect all importable classes and search all files for missing use statements

./findMissingUse.sh -f FILE [options]         Search all files for use statements in file FILE

./findMissingUse.sh -c CLASSNAME [options]    Search all files for missing use statement for CLASSNAME

Options:
 -v       Verbose output

Output:

List of detected errors with lines formatted as either:

- 'FILEPATH' 'CLASSNAME' 
  indicating a missing use statement for 'CLASSNAME' in 'FILEPATH'
  
or:

- 'FILEPATH' 'CLASSNAME' 'REASON'
  indicating that the class does have a file in the same dir as 'FILEPATH' but the capitalisation of the 'CLASSNAME' does not match. This does not always cause errors in php but is bad practice.
