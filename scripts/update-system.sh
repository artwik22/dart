#!/bin/bash
# Script to update system via pacman in kitty with ASCII art

# Clear screen
clear

# Display ASCII art
echo " @@@  @@@   @@@@@@   @@@@@@@   @@@@@@@   @@@ "
echo "@@@  @@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@ "
echo "@@!  @@@  @@!  @@@  @@!  @@@  @@!  @@@  @@! "
echo "!@!  @!@  !@!  @!@  !@!  @!@  !@!  @!@  !@  "
echo "@!@  !@!  @!@!@!@!  @!@!!@!   @!@!!@!   @!@ "
echo "!@!  !!!  !!!@!!!!  !!@!@!    !!@!@!    !!! "
echo "!!:  !!!  !!:  !!!  !!: :!!   !!:       !!: "
echo ":!:  !:!  :!:  !:!  :!:  !:!  :!:       :!: "
echo " ::   ::  ::   :::  ::   :::   ::        :: "
echo " :   : :   :   : :   :   : :   :        ::: "
echo ""
echo "Updating system packages..."
echo ""

# Execute update
sudo pacman -Syyu

# Wait for Enter
read -p "Press Enter to close..."

