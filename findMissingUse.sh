#!/bin/bash
# PHP Import finder, written by Pim de Vroom, pimdevroom@live.nl

function testImports(){
    classString=$1
    fileNm=$2
    print=$3
    
    # Remove comments from code to prevent needing imports for commented code
    multiCommentLines=$( { awk -e '/\/\*/, /\*\//' $fileNm & grep -E "//.*" $fileNm; } )
    validCode=$( grep -v -x -F "$multiCommentLines" $fileNm)
    validCodeWithoutUse=$( echo "$validCode" | awk -e '/class\s[A-Z][a-zA-Z]*[\s]*[a-z]*[\s]*[a-zA-Z]*/, /}/'  )
    validCodeOnlyUse=$( echo "$validCode" | awk -e '/<?php/, /class\s[A-Z][a-zA-Z]*[\s]*[a-z]*[\s]*[a-zA-Z]*/'  )
    # echo "$validCodeOnlyUse"

    findCountTotal=$( echo "$validCode" | grep -E "\b$classString\b" | wc -l)

    # Return if class is only referenced in comments
    if [ $findCountTotal -lt 1 ] ; then 
        if $print; then 
            echo "${green}${fileNm} ${yellow}Class '"${classString}"' only referenced in comments${reset}"
        fi
        return # File did not need use statement because reference was in comment
    fi
            
    search=$(echo "$validCodeOnlyUse" | grep -E "^use\s.*\b$classString\b" )

    # if search empty => use statement missing
    if [ -z "$search" ] ; then
        dirFiles=$(dirname $fileNm | xargs ls | awk '{print tolower($0)}' )
        classStringLower=$( echo "$classString" | awk '{print tolower($0)}' ) 
        classStringLower="${classStringLower}.php"
        fileLowerInCurrentDir=$( echo  "$dirFiles"  | grep -F "$classStringLower")
        
        link=$(dirname $fileNm)
        fileInCurrentDir="${link}/${classString}.php"
        
        # Use statement required if referenced class is not a file in current DIR
        if [ ! -f $fileInCurrentDir ] ; then
            if [ -z "$fileLowerInCurrentDir" ] ; then
                log="${red}${fileNm} ${yellow}${classString}${reset}"    # No file exists
            else # File exists but has wrong capitalisation
                log="${purple}${fileNm} ${yellow}${classString} ${green}File with class exists in current DIR but has wrong capitalisation${reset}"
            fi

            missingImportArray+=( "$log" )
            if $print; then 
                echo "${log}"
            fi
        elif $print; then 
            echo "${green}${fileNm} ${yellow}References class file in same DIR${reset}" 
        fi
    else
        if $print; then 
            echo "${green}${fileNm} ${classString}${reset}" 
        fi
    fi
}

function help(){
    echo "Usage:"
    echo "./findMissingUse.sh -a [options]              Detect all importable classes and search all files for missing use statements"
    echo "./findMissingUse.sh -f FILE [options]         Search all files for use statements in file FILE"
    echo "./findMissingUse.sh -c CLASSNAME [options]    Search all files for missing use statement for CLASSNAME"
    echo
    echo "Options:"
    echo " -v       Verbose output"
    echo 
    echo "Output:"
    echo "List of detected errors with lines formatted as either:"
    echo "- ${red}'FILEPATH' ${yellow}'CLASSNAME' ${reset}"
    echo "  indicating a missing use statement for ${yellow}'CLASSNAME'${reset} in ${red}'FILEPATH'${reset}"
    echo "or:"
    echo "- ${purple}'FILEPATH' ${yellow}'CLASSNAME' ${green}'REASON'${reset}"
    echo "  indicating that the class does have a file in the same dir as ${purple}'FILEPATH'${reset} but the capitalisation of the ${yellow}'CLASSNAME'${reset} does not match. This does not always cause errors in php but is bad practice."
    exit 0
}

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
purple=`tput setaf 5`
redder=`tput setaf 9`
reset=`tput sgr0`
missingImportArray=()
verbose=false
traits=$(grep -RPoh --include='*.php' --exclude-dir={vendor,database,storage} "(?<=trait\s)[A-Z][a-zA-Z]*")
regexA="(?<=[^\\\\\"])\b[A-Z][a-zA-Z]*\b(?=\s\\\$[a-zA-Z])" # Finding classes by " TEXT $..."
regexB="(?<=[^\\\\\"])\b[A-Z][a-zA-Z]*(?=::)"                # Finding classes by " TEXT::..."

# regexC="use [A-Z][a-zA-Z]*;"
# regexWithinClass="(?s)class\s[A-Z][a-zA-Z]*[\s]*[a-z]*[\s]*[a-zA-Z]*\n[\s]*{.*\n.*use\s[A-Z][a-zA-Z]*;" # everything after class name ... {

echo "${yellow}-------------------------${reset}"
echo "${red}--- ${green}PHP Import Finder${red} ---${reset}"
echo "${yellow}-------------------------${reset}"

if [ $# -eq 0 ] || [ $1 == "--help" ] ; then
    help
fi

if [ $1 == "-c" ]; then
    echo "Searching for missing 'use' statements for class '${2}'"
    echo
    
    # classesA=$(grep -oRPH --include='*.php' --exclude-dir={vendor,database,storage} "(?<=[^\\\\\"])\b${2}\b(?=\s\\\$[a-zA-Z])" )
    # classesB=$(grep -oRPH --include='*.php' --exclude-dir={vendor,database,storage} "(?<=[^\\\\\"])\b${2}(?=::)" )
    classesC=$(grep -oRPH --include='*.php' --exclude-dir={vendor,database,storage} "\b${2}\b" ) # To not miss the "use trait;" inside class

    if [ ! -z "$3" ] && [ $3 == '-v' ]; then
        verbose=true
    fi
elif [ $1 == "-f" ]; then
    echo "Searching for missing 'use' statements for file '${2}'"
    echo
    classesA=$(grep -oPH "$regexA" $2 )
    classesB=$(grep -oPH "$regexB" $2 )
    # test=$(grep -Pzo "(?s)class\s[A-Z].*{.*use\s[A-Z][a-zA-Z]*" $2)
    classesC=$(grep -oHF "$traits" $2)
    
    if [ ! -z "$3" ] && [ $3 == '-v' ]; then
        verbose=true
    fi
elif [ $1 == "-a" ]; then
    echo "Searching for missing 'use' statements"
    echo
    if [ ! -z "$2" ] && [ "$2" == "-v" ]; then
        echo "verbose"
        verbose=true
    fi
    classesA=$(grep -oRPH --include='*.php' --exclude-dir={vendor,database,storage} "$regexA")
    classesB=$(grep -oRPH --include='*.php' --exclude-dir={vendor,database,storage} "$regexB")
    classesC=$( grep -oRHF --include='*.php' --exclude-dir={vendor,database,storage} "$traits" )
else 
    help
fi

classes=$( ( echo "$classesA" & echo "$classesB" & echo "$classesC" ) | grep -vP 'PDO' | grep -v -e '^[[:space:]]*$' | sort -u)
    
if [ ! -z "$classes" ]; then
    while IFS= read -r line
    do
        fileName=$(echo "${line}" | awk -F : '{print $1}')
        className=$(echo "${line}" | awk -F : '{print $NF}')
        # echo "${fileName} ${className} "
        testImports $className $fileName $verbose
    done < <(printf '%s\n' "$classes")
fi

echo
echo "-------------------------"
echo "|${redder}        Results        ${reset}|"
echo "-------------------------"
echo "Files with incorrect or missing  'use' statements:"

for file in "${missingImportArray[@]}"; do
        echo "${file}"
done
echo -------------------------
echo "Found ${#missingImportArray[@]} files without correct import"





