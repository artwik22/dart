#!/bin/bash
# Script to install package from AUR via yay/paru in kitty with ASCII art

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
echo "Installing AUR package: $PACKAGE_NAME"
echo ""

# Check if yay or paru is available
if command -v yay >/dev/null 2>&1; then
    HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
    HELPER="paru"
else
    echo "Error: yay or paru not found. Please install one of them."
    read -p "Press Enter to close..."
    exit 1
fi

# Execute installation
$HELPER -S "$PACKAGE_NAME"

# Wait for Enter
read -p "Press Enter to close..."



