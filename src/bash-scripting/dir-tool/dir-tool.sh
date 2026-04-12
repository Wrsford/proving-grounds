#!/bin/bash


# Checks if a dir and file within it exist. Creates the file if the dir exists but the file doesn't

#not going overboard on this one

read -p "Enter the directory path: " dir_path
read -p "Enter the file name: " file_name

if [ -d "$dir_path" ]; then
    echo "Directory exists: $dir_path"
    if [ -f "$dir_path/$file_name" ]; then
        echo "File exists: $dir_path/$file_name"
    else
        touch "$dir_path/$file_name"
        echo "File did not exist, created: $dir_path/$file_name"
        ls -la "$dir_path/$file_name"
    fi
else
    echo "Directory does not exist: $dir_path"
fi