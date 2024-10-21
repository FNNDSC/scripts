#!/bin/bash

# Start a new tmux session
tmux new-session -d -s weather_session

# Split the window into top and bottom
tmux split-window -v -p 50

# Split the top pane into two
tmux split-window -h -t 0

# Split the bottom pane into four
tmux split-window -h -t 2
tmux split-window -h -t 2
tmux split-window -h -t 4

# Run custom commands in each pane
tmux send-keys -t 0 "/usr/bin/vendor_perl/youtube-viewer -n" C-m
tmux send-keys -t 1 "btop" C-m
tmux send-keys -t 2 "while true ; do ; clear ; curl 'v2d.wttr.in/Boston?m' ; sleep 300 ; done" C-m
tmux send-keys -t 3 "while true ; do ; clear ; curl 'v2d.wttr.in/Troy%20NY?m' ; sleep 300 ; done" C-m
tmux send-keys -t 4 "while true ; do ; clear ; curl 'v2d.wttr.in/Vredehoek?m' ; sleep 300 ; done" C-m
tmux send-keys -t 5 "while true ; do ; clear ; curl 'v2d.wttr.in/Hout%20Bay?m' ; sleep 300 ; done" C-m


# Attach to the tmux session
tmux attach-session -t weather_session
