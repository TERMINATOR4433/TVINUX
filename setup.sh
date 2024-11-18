#!/data/data/com.termux/files/usr/bin/bash

# Paths
FLAG_FILE="/data/data/com.termux/files/home/.script_run_flag"
TIME_FILE="/data/data/com.termux/files/home/.script_run_time"
BASHRC_FILE="/data/data/com.termux/files/home/.bashrc"
MOTD_FILE="/data/data/com.termux/files/usr/etc/motd"
SSH_KEEPALIVE_SCRIPT="/data/data/com.termux/files/home/ssh_keepalive.sh"

# ASCII Art Logo
LOGO=$(cat << "EOF"
              @@@@@@@@@@@@@@@@@@@@@@
              @@@@@@@@@@@@@@@@@@@@@@
              @@@@@@@@@@@@@@@@@@@@@
             @@@@@@@@@@@@@@@@@@@@@@
                  @@@@@@@@@@
                  @@@@@@@@@@
                 @@@@@@@@@@
                 @@@@@@@@@@
                @@@@@@@@@@
               /@@@@@@@@@,             @@@@@
               @@@@@@@@@@              @@@@@
              @@@@@@@@@@ @@@@@  @@@@@ @@@@@   @@@@@ @@@@@   @@@@@  @@@@@  @@@@@   @@@@
              @@@@@@@@@@ @@@@@ #@@@@  @@@@@  @@@@@@@@@@@@  &@@@@%  @@@@@  @@@@@# @@@@
             @@@@@@@@@@  @@@@  @@@@  @@@@@   @@@@@  @@@@@  @@@@@  @@@@@    @@@@@@@@
             @@@@@@@@@@ @@@@@ @@@@  %@@@@*  @@@@@  @@@@@  @@@@@   @@@@@    @@@@@@@
            @@@@@@@@@@  @@@@&@@@@   @@@@@  @@@@@   @@@@@  @@@@@  @@@@@     @@@@@.
           %@@@@@@@@@.  @@@@@@@@   @@@@@   @@@@@  @@@@@  @@@@@  ,@@@@%   @@@@@@@@
           @@@@@@@@@@   @@@@@@@.   @@@@@  @@@@@   @@@@@  @@@@@  @@@@@   @@@@@@@@@
          //////////    //////    /////   /////  /////  ////////////  *///  /////   @
          @@@@@@@@@@   *@@@@@*   .@@@@@  @@@@@  ,@@@@,   @@@@@ @@@@@ @@@@    @@@@@  @@@@@@
         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
EOF
)

# Step 1: Update and Install Important Packages
echo "Updating packages and installing required tools..."
pkg update && pkg upgrade -y
pkg install -y openssh python termux-api curl vim git wget htop nano

# Step 2: Configure SSH with Serveo
USERNAME=$(whoami)  # Get the current user's name

echo "Setting up SSH with Serveo..."
read -p "Enter a password for your SSH connection: " -s SSH_PASSWORD
echo
echo "Confirm your password: "
read -p "Re-enter your password: " -s CONFIRM_PASSWORD
echo

# Ensure the passwords match
if [ "$SSH_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
    echo "Passwords do not match. Please run the script again."
    exit 1
fi

SSH_PORT=38453
IP=$(curl -s ifconfig.me)

# Save SSH password in a temporary file (remove this in production for security reasons)
echo "Password: $SSH_PASSWORD" > /data/data/com.termux/files/home/.ssh_password
chmod 600 /data/data/com.termux/files/home/.ssh_password

nohup ssh -R $SSH_PORT:localhost:8022 serveo.net > /dev/null 2>&1 &

echo "SSH server setup complete."
echo "IP Address: $IP"
echo "Username: $USERNAME"
echo "Password: $SSH_PASSWORD"
echo "Port: $SSH_PORT"

# Step 3: Replace MOTD with TVINUX Logo
echo "Setting up MOTD..."
echo -e "$LOGO" > "$MOTD_FILE"

# Step 4: Configure .bashrc
echo "Configuring .bashrc..."
cat > "$BASHRC_FILE" << EOF
# .bashrc for Termux

# Clear screen on startup
clear

# ASCII Art Banner
echo -e "\033[1;34m" # Set text color to blue
cat << "LOGO_EOF"
$LOGO
LOGO_EOF

# Tagline
echo -e "\033[1;32m" # Set text color to green
echo "Welcome to your Termux terminal - Simplify, Create, Dominate!"
echo -e "\033[0m" # Reset text color

# Aliases and Functions
alias cls="clear"
alias ll="ls -la"
alias update="pkg update && pkg upgrade -y"
alias install="pkg install"

# Prompt customization
PS1="\033[1;34m\u@\h\033[1;32m:\w\033[0m$ "
EOF

# Step 5: Create a Keepalive Script for SSH
echo "Creating SSH keep-alive script..."
cat > "$SSH_KEEPALIVE_SCRIPT" << EOF
#!/data/data/com.termux/files/usr/bin/bash

# Ensure SSH is running with Serveo
while true; do
    if ! pgrep -f "ssh -R $SSH_PORT:localhost:8022 serveo.net" > /dev/null; then
        echo "Restarting SSH connection to Serveo..."
        nohup ssh -R $SSH_PORT:localhost:8022 serveo.net > /dev/null 2>&1 &
    fi
    sleep 3600  # Check every 1 hour
done
EOF
chmod +x "$SSH_KEEPALIVE_SCRIPT"

# Run Keepalive Script in the Background
nohup bash "$SSH_KEEPALIVE_SCRIPT" > /dev/null 2>&1 &

# Step 6: Script Time Management
if [ -f "$FLAG_FILE" ]; then
    last_run_time=$(stat -c %Y "$TIME_FILE")
    current_time=$(date +%s)
    time_diff=$((current_time - last_run_time))

    if [ $time_diff -ge 1800 ]; then
        echo "30 minutes have passed, running updates..."
        touch "$TIME_FILE"
    else
        echo "Script already run within the last 30 minutes."
    fi
else
    echo "First-time setup complete."
    touch "$FLAG_FILE"
    touch "$TIME_FILE"
fi

echo "Setup complete. Enjoy your customized Termux environment!"
