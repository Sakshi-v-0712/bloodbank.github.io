import cx_Oracle
import json
import requests
import sys

# Replace these values with your own Google Maps API key and Oracle database connection details
google_maps_api_key = 'YOUR_GOOGLE_MAPS_API_KEY'
oracle_username = 'YOUR_ORACLE_USERNAME'
oracle_password = 'YOUR_ORACLE_PASSWORD'
oracle_host = 'YOUR_ORACLE_HOST'
oracle_port = 'YOUR_ORACLE_PORT'
oracle_service_name = 'YOUR_ORACLE_SERVICE_NAME'

def update_donor_location(donor_id, state, city):
    # Construct the URL for the Google Maps Geocoding API request
    url = f'https://maps.googleapis.com/maps/api/geocode/json?address={city},{state}&key={google_maps_api_key}'
    
    # Send the request to the Google Maps Geocoding API
    response = requests.get(url)
    
    # Parse the JSON response
    data = json.loads(response.text)
    
    # Extract the latitude and longitude coordinates from the response
    location = data['results'][0]['geometry']['location']
    lat = location['lat']
    lng = location['lng']
    
    # Connect to the Oracle database
    dsn = cx_Oracle.makedsn(oracle_host, oracle_port, service_name=oracle_service_name)
    conn = cx_Oracle.connect(user=oracle_username, password=oracle_password, dsn=dsn)
    
    # Call the UpdateDonorLocation procedure to update the location of the donor in the database
    cursor = conn.cursor()
    cursor.callproc('UpdateDonorLocation', [donor_id, state, city])
    
    # Close the database connection
    conn.close()

if __name__ == '__main__':
    # Parse command line arguments
    donor_id = int(sys.argv[1])
    state = sys.argv[2]
    city = sys.argv[3]
    
    # Update the location of the donor
    update_donor_location(donor_id, state, city)



'''Replace the following placeholder values in the code:

YOUR_GOOGLE_MAPS_API_KEY with your actual Google Maps API key.
YOUR_ORACLE_USERNAME with your Oracle database username.
YOUR_ORACLE_PASSWORD with your Oracle database password.
YOUR_ORACLE_HOST with the host address of your Oracle database.
YOUR_ORACLE_PORT with the port number of your Oracle database.
YOUR_ORACLE_SERVICE_NAME with the service name of your Oracle database.
Save the code to a Python file (e.g., update_donor_location.py).

Open a command prompt or terminal and navigate to the directory where the Python file is saved.

Execute the Python script by providing the donor ID, state, and city as command-line arguments. For example:

arduino
Copy code
python update_donor_location.py 1 "New York" "New York City"
Note: Make sure to provide the actual values for the donor ID, state, and city.

The script will call the Google Maps Geocoding API to retrieve the latitude and longitude coordinates for the given state and city. It will then connect to the Oracle database using the provided credentials and update the donor's location using the UpdateDonorLocation stored procedure.

Please note that you need to have the necessary permissions and configurations set up for the Oracle database and Google Maps API to ensure successful execution of the code.'''


from flask import Flask, render_template, request
import cx_Oracle

app = Flask(__name__)

# Database connection details
dsn = cx_Oracle.makedsn(host='localhost', port=1521, sid='your_sid')
username = 'your_username'
password = 'your_password'

# Establish a connection to the Oracle database
connection = cx_Oracle.connect(username, password, dsn)

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/register_donor", methods=["POST"])
def register_donor():
    # Retrieve the form data
    donor_id = request.form.get("donor_id")
    name = request.form.get("name")
    age = request.form.get("age")
    gender = request.form.get("gender")
    phone = request.form.get("phone")
    address = request.form.get("address")
    blood_type_id = request.form.get("blood_type_id")
    last_donation_date = request.form.get("last_donation_date")

    try:
        # Execute the PL/SQL procedure RegisterOrUpdateDonor
        cursor = connection.cursor()
        cursor.callproc("RegisterOrUpdateDonor", [donor_id, name, age, gender, phone, address, blood_type_id, last_donation_date])
        cursor.close()

        return "Donor registered successfully."
    except cx_Oracle.DatabaseError as e:
        # Handle the database error
        error, = e.args
        return f"An error occurred: {error.message}"

@app.route("/update_donor_location", methods=["POST"])
def update_donor_location():
    # Retrieve the form data
    donor_id = request.form.get("donor_id")
    state = request.form.get("state")
    city = request.form.get("city")

    try:
        # Execute the PL/SQL procedure UpdateDonorLocation
        cursor = connection.cursor()
        cursor.callproc("UpdateDonorLocation", [donor_id, state, city])
        cursor.close()

        return "Donor location updated successfully."
    except cx_Oracle.DatabaseError as e:
        # Handle the database error
        error, = e.args
        return f"An error occurred: {error.message}"

@app.route("/donation_history/<donor_id>")
def donation_history(donor_id):
    try:
        # Execute the PL/SQL function GetDonationHistory
        cursor = connection.cursor()
        result = cursor.var(cx_Oracle.CURSOR)
        cursor.callfunc("GetDonationHistory", result, [donor_id])
        donation_history = result.getvalue().fetchall()
        cursor.close()

        return render_template("donation_history.html", donor_id=donor_id, donation_history=donation_history)
    except cx_Oracle.DatabaseError as e:
        # Handle the database error
        error, = e.args
        return f"An error occurred: {error.message}"

@app.route("/send_donation_reminders")
def send_donation_reminders():
    try:
        # Execute the PL/SQL procedure SendDonationReminder
        cursor = connection.cursor()
        cursor.callproc("SendDonationReminder")
        cursor.close()

        return "Donation reminders sent successfully."
    except cx_Oracle.DatabaseError as e:
        # Handle the database error
        error, = e.args
        return f"An error occurred: {error.message}"

if __name__ == "__main__":
    app.run()

    # Close the database connection
    connection.close()
