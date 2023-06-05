#! /bin/bash

function usage() { 
    echo "Usage: $0 <command> [-s <45|90>] [-p <string>]" 1>&2; exit 1; 
}

# Function to handle the "export" command
function handle_export() {
    echo "Export command executed"
    # Add your export logic here
    filename=$1

    if [ ! -f "$filename" ]; then
        echo "filename $filename does not exist"
        usage
        exit 1
    fi

    echo "Creating link in archive for $filename"
    ln -s $(pwd)/$filename $exportDirectory/$filename
}

# Function to handle the "update" command
function build_export() {
    echo "Build command executed"
    # Add your update logic here

    echo "Building $exportDirectory"

    zip -r $zipFilename $exportDirectory

    echo "Exported $zipFilename"
}

function main() {


    # Main script logic
    case "$1" in
        "export")
            handle_export $2
            ;;
        "build")
            build_export
            ;;
        *)
            echo "Unknown command: $1"
            echo "Usage: booboo [export|update]"
            exit 1
            ;;
    esac


    while getopts ":s:p:" o; do
        case "${o}" in
            s)
                s=${OPTARG}
                ((s == 45 || s == 90)) || usage
                ;;
            p)
                p=${OPTARG}
                ;;
            *)
                usage
                ;;
        esac
    done
    shift $((OPTIND-1))

    if [ -z "${s}" ] || [ -z "${p}" ]; then
        usage
    fi

    echo "s = ${s}"
    echo "p = ${p}"
}


exportDirectory="$HOME/.lc-export"
zipFilename="$HOME/launchcode-files.zip"

if [ ! -d "$exportDirectory" ]; then
    mkdir "$exportDirectory"
    echo "Directory $exportDirectory created"
fi

main $@