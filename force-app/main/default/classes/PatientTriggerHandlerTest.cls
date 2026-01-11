@isTest
private class PatientTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a provider for medical records
        Provider__c provider = new Provider__c(
            Name = 'Dr. Test Provider',
            Specialty__c = 'General Practice',
            License_Number__c = 'TEST123',
            Status__c = 'Active'
        );
        insert provider;
    }
    
    /**
     * Test default status assignment on insert
     */
    @isTest
    static void testDefaultStatusOnInsert() {
        Patient__c patient = new Patient__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@test.com'
            // Not setting Patient_Status__c
        );
        
        Test.startTest();
        insert patient;
        Test.stopTest();
        
        Patient__c inserted = [SELECT Patient_Status__c FROM Patient__c WHERE Id = :patient.Id];
        System.assertEquals('Active', inserted.Patient_Status__c, 
            'Status should default to Active');
    }
    
    /**
     * Test validation - missing required fields
     */
    @isTest
    static void testValidationMissingFields() {
        Patient__c patient = new Patient__c(
            First_Name__c = 'John'
            // Missing Last_Name__c
        );
        
        Test.startTest();
        try {
            insert patient;
            System.assert(false, 'Should have thrown validation error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('required'), 
                'Error should mention required fields');
        }
        Test.stopTest();
    }
    
    /**
     * Test validation - future date of birth
     */
    @isTest
    static void testValidationFutureDOB() {
        Patient__c patient = new Patient__c(
            First_Name__c = 'Jane',
            Last_Name__c = 'Smith',
            Date_of_Birth__c = Date.today().addDays(1) // Future date
        );
        
        Test.startTest();
        try {
            insert patient;
            System.assert(false, 'Should have thrown validation error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('future'), 
                'Error should mention future date');
        }
        Test.stopTest();
    }
    
    /**
     * Test duplicate email detection
     */
    @isTest
    static void testDuplicateEmailValidation() {
        // Create first patient
        Patient__c patient1 = new Patient__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'duplicate@test.com',
            Patient_Status__c = 'Active'
        );
        insert patient1;
        
        // Try to create second patient with same email
        Patient__c patient2 = new Patient__c(
            First_Name__c = 'Jane',
            Last_Name__c = 'Smith',
            Email__c = 'duplicate@test.com',
            Patient_Status__c = 'Active'
        );
        
        Test.startTest();
        try {
            insert patient2;
            System.assert(false, 'Should have thrown duplicate email error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('email already exists'), 
                'Error should mention duplicate email');
        }
        Test.stopTest();
    }
    
    /**
     * Test initial medical record creation
     */
    @isTest
    static void testInitialMedicalRecordCreation() {
        Patient__c patient = new Patient__c(
            First_Name__c = 'Medical',
            Last_Name__c = 'Test',
            Email__c = 'medical@test.com',
            Patient_Status__c = 'Active'
        );
        
        Test.startTest();
        insert patient;
        Test.stopTest();
        
        List<Medical_Record__c> records = [
            SELECT Id, Diagnosis__c, Treatment__c 
            FROM Medical_Record__c 
            WHERE Patient__c = :patient.Id
        ];
        
        System.assertEquals(1, records.size(), 
            'Should create one initial medical record');
        System.assertEquals('Initial Registration', records[0].Diagnosis__c,
            'Should have correct diagnosis');
    }
    
    /**
     * Test preventing status change from Deceased
     */
    @isTest
    static void testCannotChangeDeceasedStatus() {
        Patient__c patient = new Patient__c(
            First_Name__c = 'Deceased',
            Last_Name__c = 'Patient',
            Email__c = 'deceased@test.com',
            Patient_Status__c = 'Deceased'
        );
        insert patient;
        
        patient.Patient_Status__c = 'Active';
        
        Test.startTest();
        try {
            update patient;
            System.assert(false, 'Should not allow changing deceased status');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('deceased'), 
                'Error should mention deceased patient');
        }
        Test.stopTest();
    }
    
    /**
     * Test appointment cancellation on status change
     */
    @isTest
    static void testAppointmentCancellationOnStatusChange() {
        // Create patient
        Patient__c patient = new Patient__c(
            First_Name__c = 'Status',
            Last_Name__c = 'Change',
            Email__c = 'statuschange@test.com',
            Patient_Status__c = 'Active'
        );
        insert patient;
        
        // Create provider and appointment
        Provider__c provider = [SELECT Id FROM Provider__c LIMIT 1];
        
        Appointment__c appt = new Appointment__c(
            Patient__c = patient.Id,
            Provider__c = provider.Id,
            Appointment_Date__c = DateTime.now().addDays(7),
            Duration_Minutes__c = 30,
            Status__c = 'Scheduled'
        );
        insert appt;
        
        // Change patient status to Inactive
        patient.Patient_Status__c = 'Inactive';
        
        Test.startTest();
        update patient;
        Test.stopTest();
        
        Appointment__c updatedAppt = [
            SELECT Status__c 
            FROM Appointment__c 
            WHERE Id = :appt.Id
        ];
        
        System.assertEquals('Cancelled', updatedAppt.Status__c,
            'Appointment should be cancelled when patient becomes inactive');
    }
    
    /**
     * Test bulk insert (governor limits)
     */
    @isTest
    static void testBulkInsert() {
        List<Patient__c> patients = new List<Patient__c>();
        
        for (Integer i = 0; i < 200; i++) {
            patients.add(new Patient__c(
                First_Name__c = 'Bulk',
                Last_Name__c = 'Patient' + i,
                Email__c = 'bulk' + i + '@test.com',
                Patient_Status__c = 'Active'
            ));
        }
        
        Test.startTest();
        insert patients;
        Test.stopTest();
        
        // Verify all medical records were created
        Integer recordCount = [
            SELECT COUNT() 
            FROM Medical_Record__c 
            WHERE Patient__c IN :patients
        ];
        
        System.assertEquals(200, recordCount,
            'Should create medical record for each patient');
    }
}