#!/bin/bash
HOME_DIR="/home/mks"
PRINTER_DATA="printer_data"
BACKUP_LOCATION="${HOME_DIR}/config_backup"
PRINTER_DATA_CP="${HOME_DIR}/${PRINTER_DATA}"
PRINTER_CONFIG_FOLDER="${PRINTER_DATA_CP}/config"
PRINTER_CONFIG_FOLDER_ESCAPED="${PRINTER_DATA}\/config"
FLUIDD_CONFIG="${PRINTER_CONFIG_FOLDER}/fluidd.cfg"
MOONRAKER_CONFIG="${PRINTER_CONFIG_FOLDER}/moonraker.conf"
PLR_CONFIG="${PRINTER_CONFIG_FOLDER}/plr.cfg"
PRINTER_CONFIG="${PRINTER_CONFIG_FOLDER}/printer.cfg"

R=$'\e[1;91m' 
G=$'\e[1;92m'
NL_NOCOLOR=$'\n\e[0m' 

clear_screen() {
    clear
    tput cup 0 0
}

press_any_key() {
    echo -e "${G}Done, press any key to continue${NL_NOCOLOR}"
    read
}

# Helper function to stop moonraker and klipper services
stop_services() {
    echo -e "${G}Stopping moonraker and klipper services${NL_NOCOLOR}"
    sudo systemctl stop moonraker.service
    sudo systemctl stop klipper.service
}

# Helper function to start moonraker and klipper services
start_services() {
    echo -e "${G}Starting moonraker and klipper services${NL_NOCOLOR}"
    sudo systemctl start klipper.service
    sudo systemctl start moonraker.service
}

# Changes deb. to archive. in sources.list so users can update and so kiauh does not error out
update_system() {
    echo -e "${G}Updating sources.list, see Updating armbian section in Readme for more info${NL_NOCOLOR}"

    sudo sed -i "s/\/\/deb./\/\/archive./g" /etc/apt/sources.list
    
    echo -e "${G}sources.list after update${NL_NOCOLOR}"
    cat /etc/apt/sources.list

    echo -e "${G}Performing update${NL_NOCOLOR}"
    sudo apt update
    sudo apt upgrade

    press_any_key
}

# Starts armbian-config so that user can update timezone
update_timezone() {

    echo -e "${G}Updating Timezone, see Timezone Configuration section in Readme${NL_NOCOLOR}"
    sleep 5
    sudo armbian-config

    press_any_key
}

# starts armbian resize to resize to larger eMMC drive
resize_disk()
{   
    echo -e "${G}Resizing disk${NL_NOCOLOR}"
    sleep 5
    sudo systemctl start armbian-resize-filesystem.service

    press_any_key
}

# Runs kiauh installer
run_kiauh()
{   
    echo -e "${G}Going to launch Kiauh, see Running Kiauh in Readme to remove/install plugins"
    sleep 5
    ${HOME_DIR}/kiauh/kiauh.sh
    echo -e "${G}Did Kiauh update?"
    read choice
    case $choice in
        Y|y|Yes|yes) echo "${G}Launching Kiauh again...${NL_NOCOLOR}"; sleep 5; ${HOME_DIR}/kiauh/kiauh.sh;;
    esac

    press_any_key
}

# Backups folders before removing them just in case....
backup_function() {
    echo -e "${G}Backing up files${NL_NOCOLOR}"
    stop_services

    echo -e "${G}Making backup location${NL_NOCOLOR}"

    mkdir ${BACKUP_LOCATION}
    
    echo -e "${G}Backing up gcode_files${NL_NOCOLOR}"
    cp -rp ${HOME_DIR}/gcode_files ${BACKUP_LOCATION}/

    echo -e "${G}Backing up klipper config${NL_NOCOLOR}"
    cp -rp ${HOME_DIR}/klipper_config ${BACKUP_LOCATION}/

    echo -e "${G}Backing up moonraker database to keep print history${NL_NOCOLOR}"
    cp -rp ${HOME_DIR}/.moonraker_database ${BACKUP_LOCATION}/

    press_any_key
}

# Moves configuration from backup folder to printer_data folder
# Finds and replaces paths so that klipper and moonraker are happy
# Remove lines that are deprecated
# Create symlinks to mks user folder so that webcamd and touch screen still works
fix_config_files() {
    echo -e "${G}Copying and fixing config files${NL_NOCOLOR}"
    echo -e "${G}Stopping klipper and moonraker services${NL_NOCOLOR}"
    
    stop_services

    echo -e "${G}Updating configuration files${NL_NOCOLOR}"

    echo -e "${G}Copying gcode_files${NL_NOCOLOR}"
    cp -rp ${BACKUP_LOCATION}/gcode_files/* ${PRINTER_DATA_CP}/gcodes/
    echo -e "${G}Removing ~/gcode_files${NL_NOCOLOR}"
    rm -rf ${HOME_DIR}/gcode_files 

    echo -e "${G}Copying klipper config${NL_NOCOLOR}"
    cp -rp ${BACKUP_LOCATION}/klipper_config/* ${PRINTER_DATA_CP}/config/

    echo -e "${G}Removing ~/klipper_config${NL_NOCOLOR}"
    rm -rf ${HOME_DIR}/klipper_config
    
    echo -e "${G}Removing newly created moonraker database files"
    rm -rf ${PRINTER_DATA_CP}/database/*

    echo -e "${G}Moving moonraker data to keep print history${NL_NOCOLOR}"
    cp ${BACKUP_LOCATION}/.moonraker_database/* ${PRINTER_DATA_CP}/database/

    echo -e "${G}Removing ~/.moonraker_database${NL_NOCOLOR}"
    rm -rf ${HOME_DIR}/.moonraker_database

    echo -e "${G}Removing ~/klipper_logs${NL_NOCOLOR}"
    rm -rf ${HOME_DIR}/klipper_logs

    echo -e "${G}Moving power loss resume scripts in to ${PRINTER_CONFIG_FOLDER} folder"
    mkdir --parents ${PRINTER_CONFIG_FOLDER}/plr
    mv ${HOME_DIR}/clear_plr.sh ${PRINTER_CONFIG_FOLDER}/plr
    mv ${HOME_DIR}/plr.sh ${PRINTER_CONFIG_FOLDER}/plr

    echo -e "${G}Creating symlinks so that webcamd and touchscreen still works correctly${NL_NOCOLOR}"
    ln -s ${PRINTER_DATA_CP}/gcodes ${HOME_DIR}/gcode_files
    ln -s ${PRINTER_DATA_CP}/config ${HOME_DIR}/klipper_config
    ln -s ${PRINTER_DATA_CP}/logs ${HOME_DIR}/klipper_logs

    echo -e "${G}Fixing configuration files to point to new configuration location${NL_NOCOLOR}"
    # fluidd.cfg
    sed -i -e "s/mks\/gcode_files/mks\/${PRINTER_DATA}\/gcodes/g" ${FLUIDD_CONFIG}

    # moonraker.conf
    sed -i -e "s/klipper_config/${PRINTER_CONFIG_FOLDER_ESCAPED}/g" ${MOONRAKER_CONFIG}
    sed -i -e "s/\/tmp\/klippy_uds/\/home\/mks\/${PRINTER_DATA}\/comms\/klippy.sock/g" ${MOONRAKER_CONFIG}
    #Removing depreciated lines
    sed -i -e "/enable_debug_logging: False/d" ${MOONRAKER_CONFIG}
    sed -i -e "/config_path/d" ${MOONRAKER_CONFIG}
    sed -i -e "/\[file_manager\]/d" ${MOONRAKER_CONFIG}
    sed -i -e "/log_path/d" ${MOONRAKER_CONFIG}
    sed -i -e "/database/d" ${MOONRAKER_CONFIG}

    #plr.cfg
    sed -i -e "s/klipper_config/${PRINTER_DATA}/g" ${PLR_CONFIG}
    sed -i -e "s/mks\/clear_plr.sh/mks\/${PRINTER_CONFIG_FOLDER_ESCAPED}\/plr\/clear_plr.sh/g" ${PLR_CONFIG}
    sed -i -e "s/mks\/plr.sh/mks\/${PRINTER_CONFIG_FOLDER_ESCAPED}\/plr\/plr.sh/g" ${PLR_CONFIG}

    #printer.cfg
    sed -i -e "s/path: ~\/gcode_files/path: \/home\/mks\/${PRINTER_DATA}\/gcodes/g" ${PRINTER_CONFIG}
    sed -i -e "s/klipper_config/printer_data\/config/g" ${PRINTER_CONFIG}
    #Removing depreciated lines
    sed -i "/max_accel_to_decel/d" ${PRINTER_CONFIG}

    #Updating away from the custom gcode
    sed -i -e "s/K109/M109/g" ${PRINTER_CONFIG}
    sed -i -e "s/K190/M190/g" ${PRINTER_CONFIG}

    press_any_key
}

# Launches menuconfig so that user can select Linux process to recompile
# Reference : https://www.klipper3d.org/RPi_microcontroller.html#install-the-rc-script 
update_rpi_mcu() {
    echo -e "${G}Recompiling RPI mcu${NL_NOCOLOR}"
    #Updating RPI
    cd ${HOME_DIR}/klipper

    echo -e "${G}Launching menuconfig, please see Updating RPI MCU section in Readme${NL_NOCOLOR}"
    sleep 5
    
    make menuconfig
    make flash

    press_any_key
}

# Function helper to clean up ~config_backup folder
clean_up_config_backup(){
    echo -e "${G}Removing ~/config_backup folder${NL_NOCOLOR}"
    rm -rf ${HOME_DIR}/config_backup

    press_any_key
}

# Enables webcamd service
enable_webcamd() {
    echo -e "${G}Enabling webcamd service${NL_NOCOLOR}"
    sudo systemctl enable webcamd.service

    echo -e "${G}Starting webcamd service${NL_NOCOLOR}"
    sudo systemctl start webcamd.service

    press_any_key
}

# Prints out menu
print_menu() {
    clear_screen
    echo ""
    echo "Choose a to update all or go through 1-7 in order"
    echo ""
    echo "1) Update System"
    echo ""
    echo "2) Update Timezone"
    echo ""
    echo "3) Resized Disk"
    echo ""
    echo "4) Backup files"
    echo ""
    echo "5) Run kiauh"
    echo ""
    echo "6) Fix configuration files"
    echo ""
    echo "7) Update RPI MCU"
    echo ""
    echo "8) Clean up config_back (only run after everything is working correctly)"
    echo ""
    echo "9) Enable webcamd"
    echo ""
    echo "a) Run all"
    echo ""
    echo "q) Quit"
}

# Runs all commands in correct order
run_all(){
    update_system
    update_timezone
    resize_disk
    backup_function
    run_kiauh
    fix_config_files
    update_rpi_mcu
    start_services
}

# Main loop
while true; do
    print_menu
    echo -e "${G}Enter your choice: ${NL_NOCOLOR}"
    read choice
    case $choice in
        1) update_system;;
        2) update_timezone;;
        3) resize_disk;;
        4) backup_function;;
        5) run_kiauh;;
        6) fix_config_files;;
        7) update_rpi_mcu;;
        8) clean_up_config_backup;;
        9) enable_webcamd;;
        a) run_all;;
        q) clear; echo -e "${G}Please reboot and Happy Printing${NL_NOCOLOR}"; sleep 2; exit 0;;
        *) echo -e "${R}Invalid choice. Please try again.${NL_NOCOLOR}";;
    esac
done