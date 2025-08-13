#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

# Get user_id from the database
# The column in the 'users' table MUST be named 'username' for this to work.
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

# If USER_ID is empty, the user is new
if [[ -z $USER_ID ]]
then
  # Print welcome message for new user
  echo "Welcome, $USERNAME! It looks like this is your first time here."

  # Insert new user
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  # Get the new user_id
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # If user exists, get their game stats
  # The column in the 'games' table MUST be named 'user_id'
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$USER_ID")
  BEST_GAME=$($PSQL "SELECT MIN(guesses) FROM games WHERE user_id=$USER_ID")

  # Print the welcome back message
  # Using echo to trim any whitespace that psql might add
  echo "Welcome back, $(echo $USERNAME | sed -r 's/^ *| *$//g')! You have played $(echo $GAMES_PLAYED | sed -r 's/^ *| *$//g') games, and your best game took $(echo $BEST_GAME | sed -r 's/^ *| *$//g') guesses."
fi

# --- GAME STARTS HERE ---
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0
echo "Guess the secret number between 1 and 1000:"

while read GUESS
do
  # Check if input is an integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Increment guess count
  ((NUMBER_OF_GUESSES++))

  # Compare guess to secret number
  if [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    # Correct guess
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Insert game result into database
    # This requires a 'guesses' and 'user_id' column in the 'games' table
    INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(guesses, user_id) VALUES($NUMBER_OF_GUESSES, $USER_ID)")
    
    # Exit game
    break
  fi
done
