#! /bin/bash

function usage() { 
    echo "Usage: $0 <command> [-s <45|90>] [-p <string>]" 1>&2; exit 1; 
}

# Function to concatenate two paths and avoid double slashes
function joinpath() {
    local path1=$1
    local path2=$2

    # Remove trailing slash from path1 and leading slash from path2, if they exist
    local cleaned_path1=${path1%/}
    local cleaned_path2=${path2#/}

    # Concatenate the paths with a forward slash
    local result="${cleaned_path1}/${cleaned_path2}"

    echo "$result"
}

function is_git_project() {
    local directory=$1

    # Check if the directory contains a .git subdirectory
    if [ -d "$directory/.git" ]; then
        return 0  # Return success (Git project found)
    else
        return 1  # Return failure (Not a Git project)
    fi
}

function cleanup_git_proj() {
    cp "$resources_dir/$gitignore_template" ./.gitignore

    local gitignore_file=".gitignore"

    # Read the .gitignore file line by line
    while IFS= read -r ignore_item; do
        # Skip comment lines starting with #
        if [[ $ignore_item =~ ^# ]]; then
            continue
        fi

        # Remove leading and trailing whitespace from the ignore item
        ignore_item="$(echo "$ignore_item" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

        # Remove the item from the Git history
        git filter-branch --index-filter "git rm -r --cached --ignore-unmatch '$ignore_item'" --prune-empty -f -- --all
    done < "$gitignore_file"
}

function export_directory() {
    echo "Export directory! $1"
    source_dir="$1"
    original_directory=$(pwd)

    cd $source_dir

    absolute_dir_path=$(pwd)

    # Traverse the directory and look for Git projects
    find "$directory" -type d | while read -r dir; do
        if is_git_project "$dir"; then
            echo "Git project found: $dir"
        fi
    done


    file_path_from_home="${absolute_dir_path/#$HOME}"
    target_symlink_path=$(joinpath "$exportDirectory" "$file_path_from_home")

    mkdir -p "$target_symlink_path"

    cd $original_directory
}

# This function will export a file to $HOME/.lc-export with a symbolic link
# It preserves the directory structure relative to $HOME inside of the archive
#
# $(export_file "~/work/foobar.txt") will create a symbolic link "~/.lc-export/work/foobar.txt"
function export_file() {
    local original_directory=$(pwd)
    local filename=$1
    local relative_file_directory=$(dirname "$filename")
    local base_name=$(basename "$filename")

    cd $relative_file_directory

    local absolute_file_path=$(pwd)/$base_name
    
    local file_path_from_home="${absolute_file_path/#$HOME/}"

    echo "Creating link in archive for $absolute_file_path"
    
    local target_symlink_path=$(joinpath "$exportDirectory" "$file_path_from_home")

    mkdir -p "$(dirname "$target_symlink_path")"

    ln -s "$absolute_file_path" "$target_symlink_path"
    
    cd $original_directory
}

# Function to handle the "export" command
function handle_export() {
    echo "Export command executed"
    # Add your export logic here
    local filename=$1

    if [ -f "$filename" ]; then
        export_file "$filename"
    elif [ -d "$filename" ]; then
        export_directory "$filename"
    else
        echo "filename $filename does not exist"
        usage
        exit 1
    fi

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

resources_dir="/usr/local/bin/lc-export-tool"
gitignore_template="lc-securebook-gitignore.txt"
exportDirectory="$HOME/.lc-export"
zipFilename="$HOME/launchcode-files.zip"

if [ ! -d "$exportDirectory" ]; then
    mkdir "$exportDirectory"
    echo "Directory $exportDirectory created"
fi

main $@