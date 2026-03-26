#!/bin/bash
# Script to install package via pacman in kitty with ASCII art

PACKAGE_NAME="$1"

if [ -z "$PACKAGE_NAME" ]; then
    echo "Error: Package name not provided"
    exit 1
fi

# Clear screen
clear

# Display ASCII art
echo " @@@@@@   @@@  @@@   @@@@@@   @@@@@@@   @@@@@@@   @@@ "
echo "@@@@@@@   @@@  @@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@ "
echo "!@@       @@!  @@@  @@!  @@@  @@!  @@@  @@!  @@@  @@! "
echo "!@!       !@!  @!@  !@!  @!@  !@!  @!@  !@!  @!@  !@  "
echo "!!@@!!    @!@!@!@!  @!@!@!@!  @!@!!@!   @!@@!@!   @!@ "
echo " !!@!!!   !!!@!!!!  !!!@!!!!  !!@!@!    !!@!!!    !!! "
echo "     !:!  !!:  !!!  !!:  !!!  !!: :!!   !!:           "
echo "    !:!   :!:  !:!  :!:  !:!  :!:  !:!  :!:       :!: "
echo ":::: ::   ::   :::  ::   :::  ::   :::   ::        :: "
echo ":: : :     :   : :   :   : :   :   : :   :        ::: "
echo ""
echo "Installing package: $PACKAGE_NAME"
echo ""

# Execute installation
sudo pacman -S "$PACKAGE_NAME"

# Wait for Enter
read -p "Press Enter to close..."
