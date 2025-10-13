#!/bin/zsh
sleep 10
date >> runme.txt
echo "Running camilladsp..." >> runme.txt

while true
do
  camilladsp \
    --port 1234 \
    --address 0.0.0.0 \
    --statefile ~/camilladsp/statefile.yml \
    --logfile ~/camilladsp/logs/camilladsp.log \
    -vv \
    ~/camilladsp/configs/active_config_min.yml
done
EOF
