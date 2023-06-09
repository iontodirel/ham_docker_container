#!/bin/bash

# **************************************************************** #
# ham_docker_container - Containers for APRS and ham radio         #
# Version 0.1.0                                                    #
# https://github.com/iontodirel/ham_docker_container               #
# Copyright (c) 2023 Ion Todirel                                   #
# **************************************************************** #

# NOTE: Please modify the path to 'find_devices' as appropriate by updating FIND_DEVICES
: "${FIND_DEVICES:=/find_devices/find_devices}"
# Generic configuration in the same directory as the script
: "${_GPS_CONTAINER_FD_CONFIG:=ublox_config.json}"
# Can simply remain the same
: "${OUT_JSON:=output.json}"
: "${_GPS_CONTAINER_PORT:=2947}"
: "${_GPS_CONTAINER_SVC_CONF_FILE:=/services.json}"

# Check that the services.json file exists
if ! test -f "$_GPS_CONTAINER_SVC_CONF_FILE"
then
    echo "Error: No services.json config file found \"$_GPS_CONTAINER_SVC_CONF_FILE\""
    exit 1
fi

gps_enable_service=$(jq -r '.gps // "" ' $_GPS_CONTAINER_SVC_CONF_FILE)

if [[ "$gps_enable_service" == "disabled" ]]; then

    echo "gps service state is disabled, begin waiting for service state change to \"enabled\""

    # if the service is disabled just wait in the container until the service is enabled

    while true; do
    
        gps_enable_service=$(jq -r '.gps // "enabled" ' $_GPS_CONTAINER_SVC_CONF_FILE)
    
        if [[ "$gps_enable_service" == "enabled" ]]; then
            echo "gps service state is now enabled"
            break
        elif [[ "$gps_enable_service" != "disabled" ]]; then
            echo "Error: Unknown gps service state, expected: \"enabled\" or \"disabled\""
            exit 1
        fi
    
        echo "Service gps disabled, waiting (10s) for service state changes"
      
        inotifywait -t 10 -e modify $_GPS_CONTAINER_SVC_CONF_FILE
    
    done

fi

echo "Using \"$_GPS_CONTAINER_FD_CONFIG\" to find devices using find_devices"
echo "See https://github.com/iontodirel/find_devices"

# if find_devices config file does not exist then exit
if ! test -f "$_GPS_CONTAINER_FD_CONFIG"
then
    echo "Error: No find_devices config file found \"$_GPS_CONTAINER_FD_CONFIG\""
    exit 1
fi

# Check that the find_devices utility is found
if ! command -v "$FIND_DEVICES" >/dev/null 2>&1; then
    echo "Error: Executable" \"$FIND_DEVICES\"" not found"
    exit 1
fi

# Call find_devices
if ! $FIND_DEVICES -c $_GPS_CONTAINER_FD_CONFIG -o $OUT_JSON --no-stdout; then
    echo "Error: Failed to find devices"
    exit 1
fi

# Get counts and names
serial_ports_count=$(jq ".serial_ports | length" $OUT_JSON)
# Pick the first serial port
serial_port=$(jq -r '.serial_ports[0].name // ""' $OUT_JSON)

echo "Serial ports count: \"$serial_ports_count\""
echo "Serial port: \"$serial_port\""

# Return if no soundcards and serial ports were found
if [ $serial_ports_count -eq 0 ]; then
    echo "Error: No serial ports found, expected at least one serial port"
    exit 1
fi

# Check counts
# Update as appropriate
if [ $serial_ports_count -ne 1 ]; then
    echo "Error: serial ports not equal to 1"
    exit 1
fi

echo "Using serial port for GPS \"$serial_port\""
echo "Starting gpsd with serial port \"$serial_port\", with options: -S $_GPS_CONTAINER_PORT -G -n -N -F /var/run/gpsd.sock"

rm -f /var/run/gpsd.sock

/usr/sbin/gpsd $serial_port -S $_GPS_CONTAINER_PORT -G -n -N -F /var/run/gpsd.sock > /dev/null 2>&1
