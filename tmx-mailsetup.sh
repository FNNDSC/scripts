#!/bin/bash

PASSWD=$1

# Start a new tmux session
tmux new-session -d -s mail_session

# Split the window into four panes
tmux split-window -v
tmux split-window -h
tmux select-pane -t 0
tmux split-window -h

# Execute commands in each pane
tmux select-pane -t 0
tmux send-keys "cd ~/src/outwright ; source venv/bin/activate ; outwright --email rudolph.pienaar@childrens.harvard.edu --password $1 --notification ~/tmp/notifications/notification.txt" C-m

tmux select-pane -t 1
tmux send-keys "cd ~/tmp/mail ; tail -f messages.mbox | bat --paging=never -l log" C-m

tmux select-pane -t 2
tmux send-keys "nvm use 20.11.0 ; cd ~/src/mbox2m365 ; source venv/bin/activate ; cd ~/tmp/mail ; find . | entr mbox2m365 --inputDir /home/rudolph/tmp/mail --mbox messages.mbox --sendFromFile --waitForStragglers 10 --playwright /home/rudolph/tmp/notifications/notification.txt " C-m

tmux select-pane -t 3
tmux send-keys "cd ~/src/mbox2m365 ; source venv/bin/activate ; cd mbox2m365 ; python mailSinkAuth.py  --mdir /home/rudolph/tmp/mail --mbox messages.mbox --port 22225" C-m

# Attach to the tmux session
tmux attach-session -t mail_session
