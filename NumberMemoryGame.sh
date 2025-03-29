#!/bin/bash

# Game configuration
start_length=1
current_length=$start_length
high_score=0
base_showing_time=4
current_showing_time=$base_showing_time
current_number=""
current_attempt=1
use_big_numbers=1         # 1 for enabled, 0 for disabled
constant_time=1           # 1 for constant time, 0 for increasing time
time_increase_threshold=6 # Round number when time starts increasing

# Function to clear the screen
clear_screen() {
  clear
}

# Function to generate a random number of specific length
generate_number() {
  local length=$1
  local number=""

  for ((i = 0; i < length; i++)); do
    digit=$((RANDOM % 10))
    number="${number}${digit}"
  done

  echo "$number"
}

# Function to convert a number to big ASCII art
display_big_number() {
  local number=$1
  local lines=("" "" "" "" "" "")

  # Big ASCII digits definition (5 lines each)
  local -A big_digits
  big_digits[0]=" ██████  
██    ██ 
██    ██ 
██    ██ 
 ██████  "

  big_digits[1]="   ██   
 ████   
   ██   
   ██   
 ██████ "

  big_digits[2]=" ██████  
██    ██ 
    ██   
  ██     
████████ "

  big_digits[3]=" ██████  
      ██ 
  █████  
      ██ 
 ██████  "

  big_digits[4]="██    ██ 
██    ██ 
████████ 
      ██ 
      ██ "

  big_digits[5]="████████ 
██       
███████  
      ██ 
███████  "

  big_digits[6]=" ██████  
██       
███████  
██    ██ 
 ██████  "

  big_digits[7]="████████ 
     ██  
    ██   
   ██    
  ██     "

  big_digits[8]=" ██████  
██    ██ 
 ██████  
██    ██ 
 ██████  "

  big_digits[9]=" ██████  
██    ██ 
 ███████ 
      ██ 
 ██████  "

  # Build each line of the big number
  for ((i = 0; i < ${#number}; i++)); do
    digit="${number:$i:1}"
    IFS=$'\n' read -d '' -ra digit_lines <<<"${big_digits[$digit]}"

    for ((j = 0; j < 5; j++)); do
      lines[$j]+="${digit_lines[$j]}  "
    done
  done

  # Print the big number with random colors
  for ((i = 0; i < 5; i++)); do
    # Random color for each line
    color=$((31 + RANDOM % 7))
    echo -e "\033[${color}m${lines[$i]}\033[0m"
  done
}

# Function to display a number (big or regular)
display_number() {
  local number=$1

  if [ $use_big_numbers -eq 1 ]; then
    display_big_number "$number"
  else
    echo -e "\033[1;36m\n  $number\033[0m\n"
  fi
}

# Function to display a colorful progress bar
display_progress_bar() {
  local duration=$1
  local steps=40
  local sleep_time=$(echo "scale=3; $duration / $steps" | bc)

  # Disable normal buffering of stdin
  stty -echo -icanon time 0 min 0

  echo -n "["
  for ((i = 0; i < steps; i++)); do
    # Check if any key is pressed, but don't process it
    if read -t 0.01 -n 1; then
      # Consume any key presses during the display phase
      read -t 0.01 -n 10 discard
    fi

    # Calculate color using ANSI escape codes (RGB effect)
    case $((i % 7)) in
    0) color="\033[91m" ;; # Red
    1) color="\033[93m" ;; # Yellow
    2) color="\033[92m" ;; # Green
    3) color="\033[96m" ;; # Cyan
    4) color="\033[94m" ;; # Blue
    5) color="\033[95m" ;; # Magenta
    6) color="\033[97m" ;; # White
    esac

    echo -ne "${color}█\033[0m"
    sleep $sleep_time
  done
  echo "]"

  # Reset terminal settings
  stty echo icanon
}

# Function to format the number with strikes for incorrect digits
format_with_strikes() {
  local user_input=$1
  local correct_number=$2
  local result=""
  local max_len=${#user_input}

  if [ ${#correct_number} -gt $max_len ]; then
    max_len=${#correct_number}
  fi

  for ((i = 0; i < max_len; i++)); do
    if [ $i -lt ${#user_input} ] && [ $i -lt ${#correct_number} ]; then
      if [ "${user_input:$i:1}" = "${correct_number:$i:1}" ]; then
        # Correct digit - green
        result="${result}\033[32m${user_input:$i:1}\033[0m"
      else
        # Wrong digit - red with strike
        result="${result}\033[31m̶${user_input:$i:1}\033[0m"
      fi
    elif [ $i -lt ${#user_input} ]; then
      # Extra digits - red
      result="${result}\033[31m${user_input:$i:1}\033[0m"
    else
      # Missing digits - red placeholder
      result="${result}\033[31m_\033[0m"
    fi
  done

  echo -e "$result"
}

# Function to calculate showing time based on round number
calculate_showing_time() {
  local round=$1
  local time=$base_showing_time

  # If time should increase after threshold round and not using constant time
  if [ $constant_time -eq 0 ] && [ $round -gt $time_increase_threshold ]; then
    local extra_time=$((round - time_increase_threshold))
    time=$((base_showing_time + extra_time))
  else
    time=$base_showing_time
  fi

  echo $time
}

# Function to play the game
play_game() {
  current_length=$start_length
  current_attempt=1

  while true; do
    # Calculate showing time based on current round
    current_showing_time=$(calculate_showing_time $current_attempt)

    # Display game info
    echo -e "\nRound $current_attempt - Remember this $current_length-digit number:"
    if [ $constant_time -eq 0 ] && [ $current_attempt -gt $time_increase_threshold ]; then
      echo -e "Time increased to \033[1;33m$current_showing_time seconds\033[0m"
    else
      echo -e "Time: \033[1;33m$current_showing_time seconds\033[0m"
    fi

    # Generate and display the number
    current_number=$(generate_number $current_length)
    echo ""

    # Display number (either big or regular based on settings)
    display_number "$current_number"
    echo ""

    # Show progress bar and prevent input during display phase
    echo "MEMORIZING PHASE - Wait for the bar to complete..."
    display_progress_bar $current_showing_time

    # Clear the screen
    clear_screen

    # Ask for user input
    echo -n "Enter the number you saw: "
    read user_input

    if [ "$user_input" = "$current_number" ]; then
      # Correct answer
      echo -e "\033[32m✓\033[0m - That's correct!"

      # Increase difficulty
      ((current_length++))
      ((current_attempt++))

      # Update high score if needed
      if [ $((current_attempt - 1)) -gt $high_score ]; then
        high_score=$((current_attempt - 1))
        echo "New high score: $high_score!"
      fi
    else
      # Wrong answer
      echo -e "\033[31m✗\033[0m - Incorrect!"

      # Show the mistake by comparing the strings
      echo -n "Your answer:     "
      format_with_strikes "$user_input" "$current_number"
      echo "Correct number:  $current_number"
      echo "Your score: $((current_attempt - 1))"

      echo "Press Enter to return to the main menu..."
      read
      break
    fi
  done
}

# Function to show settings
show_settings() {
  while true; do
    echo -e "\n=== SETTINGS ==="
    echo "1. Reset high score (current: $high_score)"
    echo "2. Set starting number length (current: $start_length)"

    if [ $use_big_numbers -eq 1 ]; then
      echo "3. Big numbers display (currently: ENABLED)"
    else
      echo "3. Big numbers display (currently: DISABLED)"
    fi

    if [ $constant_time -eq 1 ]; then
      echo "4. Time mode (currently: CONSTANT TIME - $base_showing_time seconds)"
    else
      echo "4. Time mode (currently: INCREASING TIME after round $time_increase_threshold - starts at $base_showing_time seconds)"
    fi

    echo "5. Change base time (currently: $base_showing_time seconds)"
    echo "6. Back to main menu"
    echo -n "> "

    read choice

    case $choice in
    1)
      high_score=0
      echo "High score reset to 0."
      ;;
    2)
      echo -n "Enter new starting number length: "
      read length
      if [[ $length =~ ^[0-9]+$ ]] && [ $length -gt 0 ]; then
        start_length=$length
        echo "Starting length set to $length."
      else
        echo "Invalid input. Please enter a positive number."
      fi
      ;;
    3)
      if [ $use_big_numbers -eq 1 ]; then
        use_big_numbers=0
        echo "Big numbers display DISABLED."
      else
        use_big_numbers=1
        echo "Big numbers display ENABLED."
      fi
      ;;
    4)
      if [ $constant_time -eq 1 ]; then
        constant_time=0
        echo "Changed to INCREASING TIME mode (time increases after round $time_increase_threshold)."
      else
        constant_time=1
        echo "Changed to CONSTANT TIME mode ($base_showing_time seconds for all rounds)."
      fi
      ;;
    5)
      echo -n "Enter new base time in seconds (1-15): "
      read new_time
      if [[ $new_time =~ ^[0-9]+$ ]] && [ $new_time -ge 1 ] && [ $new_time -le 15 ]; then
        base_showing_time=$new_time
        echo "Base time set to $new_time seconds."
      else
        echo "Invalid input. Please enter a number between 1 and 15."
      fi
      ;;
    6)
      return
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
    esac
  done
}

# Main menu
while true; do
  clear_screen
  echo -e "\033[1;36m╔═══════════════════════════════════╗\033[0m"
  echo -e "\033[1;36m║        NUMBER MEMORY GAME         ║\033[0m"
  echo -e "\033[1;36m╚═══════════════════════════════════╝\033[0m"
  echo ""
  echo -e "1. \033[1;32mstart\033[0m"
  echo -e "2. \033[1;33msettings\033[0m"
  echo -e "3. \033[1;31mexit\033[0m"
  echo -n "> "

  read choice

  case $choice in
  "start" | "1")
    play_game
    ;;
  "settings" | "2")
    show_settings
    ;;
  "exit" | "3")
    echo "Thanks for playing! Goodbye."
    exit 0
    ;;
  *)
    echo "Invalid option. Please try again."
    ;;
  esac
done
