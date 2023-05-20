-- Create tables
CREATE TABLE Location (
  LocationID NUMBER PRIMARY KEY,
  State VARCHAR2(50) NOT NULL,
  City VARCHAR2(50) NOT NULL
);

CREATE TABLE BloodType (
  BloodTypeID NUMBER PRIMARY KEY,
  BloodGroup VARCHAR2(10) NOT NULL,
  RhFactor VARCHAR2(10) NOT NULL
);

--Maintain records of hospitals and blood banks statewise, including their contact information and blood unit inventory:
CREATE TABLE Hospital (
  HospitalID NUMBER PRIMARY KEY,
  Name VARCHAR2(100) NOT NULL,
  LocationID NUMBER,
  ContactNumber VARCHAR2(20),
  CONSTRAINT fk_hospital_location
    FOREIGN KEY (LocationID) REFERENCES Location(LocationID)
);

CREATE TABLE BloodBank (
  BloodBankID NUMBER PRIMARY KEY,
  Name VARCHAR2(100) NOT NULL,
  LocationID NUMBER,
  ContactNumber VARCHAR2(20),
  CONSTRAINT fk_bloodbank_location
    FOREIGN KEY (LocationID) REFERENCES Location(LocationID)
);


CREATE TABLE Donor (
  DonorID NUMBER PRIMARY KEY,
  Name VARCHAR2(100) NOT NULL,
  Age NUMBER NOT NULL,
  Gender VARCHAR2(10) NOT NULL,
  Phone VARCHAR2(20),
  Address VARCHAR2(200),
  BloodTypeID NUMBER,
  LastDonationDate DATE,
  CONSTRAINT fk_donor_bloodtype
    FOREIGN KEY (BloodTypeID) REFERENCES BloodType(BloodTypeID),
  CONSTRAINT nn_donor_name CHECK (Name IS NOT NULL),
  CONSTRAINT nn_donor_age CHECK (Age IS NOT NULL),
  CONSTRAINT nn_donor_gender CHECK (Gender IS NOT NULL),
  CONSTRAINT nn_donor_phone CHECK (Phone IS NOT NULL),
  CONSTRAINT nn_donor_address CHECK (Address IS NOT NULL)
);

CREATE TABLE Donation (
  DonationID NUMBER PRIMARY KEY,
  DonorID NUMBER,
  DonationDate DATE NOT NULL,
  BloodTypeID NUMBER,
  HospitalID NUMBER,
  CONSTRAINT fk_donation_donor
    FOREIGN KEY (DonorID) REFERENCES Donor(DonorID),
  CONSTRAINT fk_donation_bloodtype
    FOREIGN KEY (BloodTypeID) REFERENCES BloodType(BloodTypeID),
  CONSTRAINT fk_donation_hospital
    FOREIGN KEY (HospitalID) REFERENCES Hospital(HospitalID),
  CONSTRAINT nn_donation_donationdate CHECK (DonationDate IS NOT NULL)
);

CREATE TABLE Reminder (
  ReminderID NUMBER PRIMARY KEY,
  DonorID NUMBER,
  NextDonationDate DATE NOT NULL,
  CONSTRAINT fk_reminder_donor
    FOREIGN KEY (DonorID) REFERENCES Donor(DonorID),
  CONSTRAINT nn_reminder_nextdonationdate CHECK (NextDonationDate IS NOT NULL)
);

-- Create indexes
CREATE INDEX idx_donor_bloodtype ON Donor(BloodTypeID);
CREATE INDEX idx_donation_donor ON Donation(DonorID);
CREATE INDEX idx_donation_bloodtype ON Donation(BloodTypeID);
CREATE INDEX idx_donation_hospital ON Donation(HospitalID);
CREATE INDEX idx_hospital_location ON Hospital(LocationID);
CREATE INDEX idx_bloodbank_location ON BloodBank(LocationID);
CREATE INDEX idx_reminder_donor ON Reminder(DonorID);


--Register a new donor or update existing donor information:
CREATE OR REPLACE PROCEDURE RegisterOrUpdateDonor(
  p_DonorID IN NUMBER,
  p_Name IN VARCHAR2,
  p_Age IN NUMBER,
  p_Gender IN VARCHAR2,
  p_Phone IN VARCHAR2,
  p_Address IN VARCHAR2,
  p_BloodTypeID IN NUMBER,
  p_LastDonationDate IN DATE
)
IS
BEGIN
  -- Check if the donor already exists
  IF EXISTS (SELECT 1 FROM Donor WHERE DonorID = p_DonorID) THEN
    -- Update existing donor information
    UPDATE Donor SET
      Name = p_Name,
      Age = p_Age,
      Gender = p_Gender,
      Phone = p_Phone,
      Address = p_Address,
      BloodTypeID = p_BloodTypeID,
      LastDonationDate = p_LastDonationDate
    WHERE DonorID = p_DonorID;
  ELSE
    -- Register a new donor
    INSERT INTO Donor (DonorID, Name, Age, Gender, Phone, Address, BloodTypeID, LastDonationDate)
    VALUES (p_DonorID, p_Name, p_Age, p_Gender, p_Phone, p_Address, p_BloodTypeID, p_LastDonationDate);
  END IF;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/


--Automatically update the donor's location using the Python API and store the updated location in the Location table:

CREATE OR REPLACE PROCEDURE UpdateDonorLocation(
  p_DonorID IN NUMBER,
  p_State IN VARCHAR2,
  p_City IN VARCHAR2
)
IS
BEGIN
  -- DOUBT : CallING  the Python API to update the location
  -- Implemented the Python API integration here
  -- Automatically update the donor's location using the Google Maps Geocoding API and store the updated location in the Location table:
-- Automatically update the donor's location using the Google Maps Geocoding API and store the updated location in the Location table:

CREATE OR REPLACE PROCEDURE UpdateDonorLocation(
  p_DonorID IN NUMBER,
  p_State IN VARCHAR2,
  p_City IN VARCHAR2
)
IS
  l_python_script VARCHAR2(500) := 'path/to/your/python_script.py'; -- Replace with the path to your Python script
  l_command VARCHAR2(500);
BEGIN
  -- Call the Python script to update the location using the Google Maps Geocoding API
  l_command := 'python ' || l_python_script || ' ' || p_DonorID || ' ' || p_State || ' ' || p_City;
  -- Execute the command to run the Python script
  HOST(l_command);
  
  -- Update the location in the Location table
  UPDATE Donor
  SET LocationID = (
    SELECT LocationID
    FROM Location
    WHERE State = p_State AND City = p_City
  )
  WHERE DonorID = p_DonorID;
  
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/

  -- Update the location in the Location table
  UPDATE Donor
  SET LocationID = (
    SELECT LocationID
    FROM Location
    WHERE State = p_State AND City = p_City
  )
  WHERE DonorID = p_DonorID;
  
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/


--Track the donation history of each donor, including the date and quantity of blood donated:
CREATE OR REPLACE FUNCTION GetDonationHistory(
  p_DonorID IN NUMBER
)
RETURN SYS_REFCURSOR
IS
  c_result SYS_REFCURSOR;
BEGIN
  OPEN c_result FOR
    SELECT DonationDate
    FROM Donation
    WHERE DonorID = p_DonorID
    ORDER BY DonationDate DESC;
  RETURN c_result;
END;
/

--Send automated reminders to donors when they become eligible to donate blood again, based on predefined intervals:
CREATE OR REPLACE PROCEDURE SendDonationReminder
IS
BEGIN
  FOR reminder IN (
    SELECT d.DonorID, d.Name, d.LastDonationDate, r.NextDonationDate
    FROM Donor d
    JOIN Reminder r ON d.DonorID = r.DonorID
    WHERE r.NextDonationDate <= SYSDATE
  ) LOOP
    -- Implement the logic to send reminders to donors
    -- You can use DBMS_OUTPUT.PUT_LINE to display the reminder information for testing purposes
    
    -- Update the next donation date for the reminder
    UPDATE Reminder
    SET NextDonationDate = ADD_MONTHS(reminder.NextDonationDate, 3) -- Assuming a 3-month interval
    WHERE DonorID = reminder.DonorID;
    
    -- Commit the changes for each reminder
    COMMIT;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/



--

