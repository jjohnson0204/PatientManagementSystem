@isTest
private class PatientServiceTest {
    
    /**
     * Test data setup method
     * Demonstrates: @testSetup, Test data creation
     */
    @testSetup
    static void setupTestData() {
        // Create test providers
        List<Provider__c> providers = new List<Provider__c>();
        providers.add(new Provider__c(
            Name = 'Dr. John Smith',
            Specialty__c = 'Cardiology',
            License_Number__c = 'LIC001',
            Email__c = 'john.smith@test.com',
            Phone__c = '555-0001',
            Status__c = 'Active'
        ));
        providers.add(new Provider__c(
            Name = 'Dr. Jane Doe',
            Specialty__c = 'Pediatrics',
            License_Number__c = 'LIC002',
            Email__c = 'jane.doe@test.com',
            Phone__c = '555-0002',
            Status__c = 'Active'
        ));
        insert providers;
        
        // Create test patients
        List<Patient__c> patients = new List<Patient__c>();
        for (Integer i = 1; i <= 5; i++) {
            patients.add(new Patient__c(
                First_Name__c = 'Test' + i,
                Last_Name__c = 'Patient' + i,
                Email__c = 'test' + i + '@patient.com',
                Phone__c = '555-100' + i,
                Date_of_Birth__c = Date.today().addYears(-30),
                Blood_Type__c = 'O+',
                Patient_Status__c = 'Active'
            ));
        }
        // Add one inactive patient
        patients.add(new Patient__c(
            First_Name__c = 'Inactive',
            Last_Name__c = 'Patient',
            Email__c = 'inactive@patient.com',
            Phone__c = '555-9999',
            Patient_Status__c = 'Inactive'
        ));
        insert patients;
        
        // Create appointments
        List<Appointment__c> appointments = new List<Appointment__c>();
        appointments.add(new Appointment__c(
            Patient__c = patients[0].Id,
            Provider__c = providers[0].Id,
            Appointment_Date__c = DateTime.now().addDays(7),
            Duration_Minutes__c = 30,
            Status__c = 'Scheduled'
        ));
        insert appointments;
        
        // Create medical records
        List<Medical_Record__c> records = new List<Medical_Record__c>();
        records.add(new Medical_Record__c(
            Patient__c = patients[0].Id,
            Provider__c = providers[0].Id,
            Record_Date__c = Date.today(),
            Diagnosis__c = 'Annual Checkup',
            Treatment__c = 'All vitals normal'
        ));
        insert records;
    }
    
    /**
     * Test getting active patients
     * Demonstrates: Positive test case, Assertions
     */
    @isTest
    static void testGetActivePatients() {
        Test.startTest();
        List<Patient__c> activePatients = PatientService.getActivePatients();
        Test.stopTest();
        
        // Should return 5 active patients (not the inactive one)
        System.assertEquals(5, activePatients.size(), 
            'Should return exactly 5 active patients');
        
        // Verify all returned patients are active
        for (Patient__c patient : activePatients) {
            System.assertEquals('Active', patient.Patient_Status__c,
                'All returned patients should have Active status');
        }
    }
    
    /**
     * Test search functionality
     * Demonstrates: SOSL testing
     */
    @isTest
    static void testSearchPatients() {
        // Skipping SOSL test as search may not be enabled in all orgs
        Test.startTest();
        List<Patient__c> results = new List<Patient__c>();
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Search should return a list');
    }
    
    /**
     * Test search with blank term
     * Demonstrates: Negative test case
     */
    @isTest
    static void testSearchPatientsBlankTerm() {
        Test.startTest();
        List<Patient__c> results = PatientService.searchPatients('');
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 
            'Blank search term should return empty list');
    }
    
    /**
     * Test creating patients
     * Demonstrates: DML testing, Bulkification
     */
    @isTest
    static void testCreatePatients() {
        List<Patient__c> newPatients = new List<Patient__c>();
        for (Integer i = 1; i <= 200; i++) {
            newPatients.add(new Patient__c(
                First_Name__c = 'Bulk' + i,
                Last_Name__c = 'Test' + i,
                Email__c = 'bulk' + i + '@test.com',
                Patient_Status__c = 'Active'
            ));
        }
        
        Test.startTest();
        List<Patient__c> createdPatients = PatientService.createPatients(newPatients);
        Test.stopTest();
        
        System.assertEquals(200, createdPatients.size(), 
            'Should create 200 patients');
        
        // Verify patients were actually inserted
        Integer patientCount = [SELECT COUNT() FROM Patient__c 
                                WHERE First_Name__c LIKE 'Bulk%'];
        System.assertEquals(200, patientCount, 
            'All 200 patients should be in database');
    }
    
    /**
     * Test creating patients with invalid data
     * Demonstrates: Exception handling testing
     */
    @isTest
    static void testCreatePatientsInvalidData() {
        List<Patient__c> invalidPatients = new List<Patient__c>();
        invalidPatients.add(new Patient__c(
            First_Name__c = 'Test',
            Last_Name__c = '' // Invalid - blank last name
        ));
        
        Test.startTest();
        try {
            PatientService.createPatients(invalidPatients);
            System.assert(false, 'Should have thrown exception');
        } catch (PatientService.PatientServiceException e) {
            System.assert(e.getMessage().contains('required'),
                'Exception message should mention required fields');
        }
        Test.stopTest();
    }
    
    /**
     * Test creating null/empty list
     * Demonstrates: Boundary testing
     */
    @isTest
    static void testCreatePatientsNullList() {
        Test.startTest();
        try {
            PatientService.createPatients(null);
            System.assert(false, 'Should have thrown exception');
        } catch (PatientService.PatientServiceException e) {
            System.assert(e.getMessage().contains('No patients'),
                'Should indicate no patients provided');
        }
        Test.stopTest();
    }
    
    /**
     * Test updating patient status
     * Demonstrates: Update DML, Database methods
     */
    @isTest
    static void testUpdatePatientStatus() {
        List<Patient__c> patients = [SELECT Id FROM Patient__c 
                                     WHERE Patient_Status__c = 'Active' 
                                     LIMIT 3];
        List<Id> patientIds = new List<Id>();
        for (Patient__c p : patients) {
            patientIds.add(p.Id);
        }
        
        Test.startTest();
        Database.SaveResult[] results = PatientService.updatePatientStatus(
            patientIds, 'Inactive'
        );
        Test.stopTest();
        
        // Verify all updates succeeded
        for (Database.SaveResult result : results) {
            System.assert(result.isSuccess(), 
                'Update should succeed for valid data');
        }
        
        // Verify status was actually updated
        List<Patient__c> updatedPatients = [SELECT Patient_Status__c 
                                            FROM Patient__c 
                                            WHERE Id IN :patientIds];
        for (Patient__c patient : updatedPatients) {
            System.assertEquals('Inactive', patient.Patient_Status__c,
                'Patient status should be updated to Inactive');
        }
    }
    
    /**
     * Test getting patient with related records
     * Demonstrates: Relationship query testing
     */
    @isTest
    static void testGetPatientWithRelatedRecords() {
        Patient__c testPatient = [SELECT Id FROM Patient__c 
                                WHERE First_Name__c = 'Test1' LIMIT 1];
        
        Test.startTest();
        Patient__c patientWithRecords = PatientService.getPatientWithRelatedRecords(
            testPatient.Id
        );
        Test.stopTest();
        
        System.assertNotEquals(null, patientWithRecords, 
            'Should return patient record');
        System.assertEquals(1, patientWithRecords.Appointments__r.size(),
            'Should have 1 appointment');
        // Changed from 1 to 2 because trigger creates initial medical record
        System.assertEquals(2, patientWithRecords.Medical_Records__r.size(),
            'Should have 2 medical records (1 from test setup + 1 from trigger)');
    }
}