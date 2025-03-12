#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

# welcome message
echo -e "\n~~~Welcome to our salon~~~\n"

# Display available services
AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
if [[ -z $AVAILABLE_SERVICES ]]; then
  echo "Sorry, no services are available right now."
  exit 1
fi

echo -e "Here are the services we offer:\n"
echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME; do
  echo "$SERVICE_ID) $NAME"
done


# Prompt for service selection with validation
while true; do
  echo -e "\nPlease select a service by entering the number:"
  read SERVICE_ID_SELECTED

  # Check if input is a number
  if [[ $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
    # Verify if the service exists
    SERVICE_EXISTS=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED")
    if [[ -n $SERVICE_EXISTS ]]; then
      # Get the service name for later use
      SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED" | sed 's/^[[:space:]]*//')
      break
    fi
  fi
  # Show the list again for any invalid input
  echo -e "\nHere are the services we offer:\n"
  echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME; do
    echo "$SERVICE_ID) $NAME"
  done
done

# Prompt for customer phone number
echo -e "\nPlease enter your phone number:"
read CUSTOMER_PHONE

# Check if customer exists
CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'" | sed 's/^[[:space:]]*//')
if [[ -z $CUSTOMER_NAME ]]; then
  # New customer: prompt for name and insert into database
  echo -e "\nIt looks like you're new here. Please enter your name:"
  read CUSTOMER_NAME
  INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
  if [[ $INSERT_CUSTOMER_RESULT != "INSERT 0 1" ]]; then
    echo "Error registering customer. Please try again."
    exit 1
  fi
fi

# Prompt for appointment time
echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

# Get customer ID for the appointment
CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'" | sed 's/^[[:space:]]*//')

# Insert appointment into database
INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
if [[ $INSERT_APPOINTMENT_RESULT != "INSERT 0 1" ]]; then
  echo "Error booking appointment. Please try again."
  exit 1
fi

# Confirmation message
echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
exit 0
