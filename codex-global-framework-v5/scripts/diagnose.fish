#!/usr/bin/env fish
set script_dir (cd (dirname (status --current-filename)); and pwd)
bash "$script_dir/diagnose.sh" $argv
