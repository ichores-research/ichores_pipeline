#!/bin/bash

# --- Configuration ---
# Base Docker Compose file (always included)
COMPOSE_FILES="-f compose/pipeline/docker-compose.yml"

# Initialize environment variables.
# If not provided via CLI, these will remain empty, meaning they won't be
# explicitly exported or passed to Docker Compose services unless the
# Docker Compose files themselves define defaults or conditions for their use.
ROS_MASTER_URI=""
ROS_IP=""
DATASET=""
CONFIG=""

# Initialize flags to track if options were provided
ROBOT_SELECTED=false
REASONER_SELECTED=false
MOTION_SELECTED=false

# --- Functions ---

# Function to display usage information
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  -u <uri>              Set ROS_MASTER_URI (e.g., http://localhost:11311) (Optional)"
  echo "  -i <ip_address>       Set ROS_IP (e.g., 192.168.1.100) (Optional)"
  echo "  -d <dataset_name>     Set DATASET (e.g., ycb_ichores) (Optional)"
  echo "  -r <robot_type>       Specify robot type (hsr, tiago-prague, tiago-krakow) (REQUIRED)"
  echo "  -e <reasoner_type>    Specify reasoner type (uncom, reasoner, goal_state_reasoner) (REQUIRED)"
  echo "  -m <motion_module>    Specify motion module (motion, motion-stack, tiago-motion) (REQUIRED)"
  echo "  -h                    Display this help message"
  exit 1
}

# --- Main Logic ---
echo "--- Configuring System Containers ---"

# Parse command-line options
# u:, i:, d:, c:, r:, e:, m: indicate that these options require an argument
while getopts "u:i:d:r:e:m:h" opt; do
  case $opt in
    u) # ROS_MASTER_URI configuration
      ROS_MASTER_URI="$OPTARG"
      echo "  ROS_MASTER_URI set to: $ROS_MASTER_URI"
      ;;
    i) # ROS_IP configuration
      ROS_IP="$OPTARG"
      echo "  ROS_IP set to: $ROS_IP"
      ;;
    d) # DATASET configuration
      DATASET="$OPTARG"
      echo "  DATASET set to: $DATASET"
      ;;
    r) # Robot configuration
      ROBOT_TYPE="$OPTARG"
      ROBOT_SELECTED=true
      case "$ROBOT_TYPE" in
        "hsr")
          # Updated path to reflect subdirectory
          echo "  Robot: HSR selected"
          CONFIG="./config/params_hsr.yaml"
          ;;
        "tiago-prague")
          # Updated path to reflect subdirectory
          echo "  Robot: TIAGo (Prague) selected"
          CONFIG="./config/params_tiago_prague.yaml"
          ;;
        "tiago-krakow")
          # Updated path to reflect subdirectory
          echo "  Robot: TIAGo (Krakow) selected"
          CONFIG="./config/params_tiago_cracow.yaml"
          ;;
        *)
          echo "Error: Invalid robot type '$ROBOT_TYPE'. Must be hsr, tiago-prague, or tiago-krakow." >&2
          usage
          ;;
      esac
      ;;
    e) # Reasoner configuration
      REASONER_TYPE="$OPTARG"
      REASONER_SELECTED=true
      case "$REASONER_TYPE" in
        "uncom")
          # Updated path to reflect subdirectory
          # COMPOSE_FILES+=" -f compose/uncom/docker-compose.yml"
          echo "  Reasoner: Uncom selected"
          ;;
        "reasoner") # Generic reasoner, renamed to avoid option name conflict
          # Updated path to reflect subdirectory
          COMPOSE_FILES+=" -f compose/reasoner_pipeline/docker-compose.yml"
          echo "  Reasoner: Reasoner_pipeline selected"
          ;;
        "goal_state_reasoner")
          # Updated path to reflect subdirectory
          COMPOSE_FILES+=" -f compose/goal_state_reasoning/docker-compose.yml"
          echo "  Reasoner: Goal State Reasoner selected"
          ;;
        *)
          echo "Error: Invalid reasoner type '$REASONER_TYPE'. Must be uncom, reasoner, or goal_state_reasoner." >&2
          usage
          ;;
      esac
      ;;
    m) # Motion module configuration
      MOTION_MODULE_TYPE="$OPTARG"
      MOTION_SELECTED=true
      case "$MOTION_MODULE_TYPE" in
        "motion")
          # Updated path to reflect subdirectory
          COMPOSE_FILES+=" -f compose/motion/docker-compose.yml"
          echo "  Motion Module: Motion selected"
          ;;
        "motion-stack")
          # Updated path to reflect subdirectory
          # COMPOSE_FILES+=" -f compose/docker-compose.yml"
          echo "  Motion Module: Motion Stack selected"
          ;;
        "tiago-motion")
          # Updated path to reflect subdirectory
          # COMPOSE_FILES+=" -f compose/docker-compose.yml"
          echo "  Motion Module: TIAGo Motion selected"
          ;;
        *)
          echo "Error: Invalid motion module type '$MOTION_MODULE_TYPE'. Must be motion, motion-stack, or tiago-motion." >&2
          usage
          ;;
      esac
      ;;
    h) # Help option
      usage
      ;;
    \?) # Invalid option
      echo "Error: Invalid option: -$OPTARG" >&2
      usage
      ;;
    :) # Option requires an argument
      echo "Error: Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done

# --- Validation Checks ---
if [ "$ROBOT_SELECTED" = false ]; then
  echo "Error: A robot type (-r) is required." >&2
  usage
fi

if [ "$REASONER_SELECTED" = false ]; then
  echo "Error: A reasoner type (-e) is required." >&2
  usage
fi

if [ "$MOTION_SELECTED" = false ]; then
  echo "Error: A motion module (-m) is required." >&2
  usage
fi

# Set default dataset if not provided
if [ -z "$DATASET" ]; then
  DATASET="ycb_ichores"
fi

# Export environment variables if they were set.
# These will be available to Docker Compose and subsequently to the containers.
if [ -n "$ROS_MASTER_URI" ]; then
  export ROS_MASTER_URI
fi
if [ -n "$ROS_IP" ]; then
  export ROS_IP
fi
if [ -n "$DATASET" ]; then
  export DATASET
fi
if [ -n "$CONFIG" ]; then
  export CONFIG
fi

# Execute docker-compose with the selected files
echo ""
echo "--- Running Docker Compose ---"
echo "Command: docker compose $COMPOSE_FILES up -d"
docker compose $COMPOSE_FILES up -d

echo ""
echo "--- Setup Complete ---"
echo "To stop the services: docker compose $COMPOSE_FILES down"
echo "Remember to build images if necessary: docker compose $COMPOSE_FILES build"
