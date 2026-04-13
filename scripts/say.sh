#!/bin/bash
# Send a speech command to the UNCOM pipeline via simulated audio.
# Usage: ./scripts/say.sh "place the mustard in the bowl"

if [ -z "$1" ]; then
    echo "Usage: $0 \"<your command>\""
    exit 1
fi

docker exec uncom-uncom_ros-1 bash -c \
    "source /root/catkin_ws/devel/setup.bash && rosrun uncom simulation_audio.py --text '$1' --file_path /root/output/temp.wav"
