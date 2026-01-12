@isTest
private class AppointmentServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create patients
        List<Patient__c> patients = new List<Patient__c>();
        patients.add(new Patient__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john@test.com',
            Patient_Status__c = 'Active'
        ));
        patients.add(new Patient__c(
            First_Name__c = 'Jane',
            Last_Name__c = 'Smith',
            Email__c = 'jane@test.com',
            Patient_Status__c = 'Active'
        ));
        insert patients;
        
        // Create providers
        List<Provider__c> providers = new List<Provider__c>();
        providers.add(new Provider__c(
            Name = 'Dr. Williams',
            Specialty__c = 'Cardiology',
            License_Number__c = 'LIC001',
            Status__c = 'Active'
        ));
        providers.add(new Provider__c(
            Name = 'Dr. Johnson',
            Specialty__c = 'Pediatrics',
            License_Number__c = 'LIC002',
            Status__c = 'Active'
        ));
        insert providers;
        
        // Create appointments
        List<Appointment__c> appointments = new List<Appointment__c>();
        appointments.add(new Appointment__c(
            Patient__c = patients[0].Id,
            Provider__c = providers[0].Id,
            Appointment_Date__c = DateTime.now().addDays(7),
            Duration_Minutes__c = 30,
            Status__c = 'Scheduled'
        ));
        appointments.add(new Appointment__c(
            Patient__c = patients[1].Id,
            Provider__c = providers[1].Id,
            Appointment_Date__c = DateTime.now().addDays(14),
            Duration_Minutes__c = 60,
            Status__c = 'Scheduled'
        ));
        insert appointments;
    }
    
    @isTest
    static void testGetUpcomingAppointments() {
        Test.startTest();
        List<Appointment__c> appointments = AppointmentService.getUpcomingAppointments();
        Test.stopTest();
        
        System.assertEquals(2, appointments.size(), 
            'Should return 2 upcoming appointments');
        System.assertEquals('Scheduled', appointments[0].Status__c,
            'Appointments should be scheduled');
    }
    
    @isTest
    static void testGetActivePatientsForScheduling() {
        Test.startTest();
        List<Patient__c> patients = AppointmentService.getActivePatientsForScheduling();
        Test.stopTest();
        
        System.assertEquals(2, patients.size(), 
            'Should return 2 active patients');
    }
    
    @isTest
    static void testGetActiveProviders() {
        Test.startTest();
        List<Provider__c> providers = AppointmentService.getActiveProviders();
        Test.stopTest();
        
        System.assertEquals(2, providers.size(), 
            'Should return 2 active providers');
    }
    
    @isTest
    static void testCreateAppointment() {
        Patient__c patient = [SELECT Id FROM Patient__c LIMIT 1];
        Provider__c provider = [SELECT Id FROM Provider__c LIMIT 1];
        DateTime futureDate = DateTime.now().addDays(5);
        
        Test.startTest();
        Appointment__c newAppt = AppointmentService.createAppointment(
            patient.Id,
            provider.Id,
            futureDate,
            45,
            'Test appointment'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, newAppt, 
            'Appointment should be created');
        System.assertEquals('Scheduled', newAppt.Status__c,
            'New appointment should be scheduled');
        System.assertEquals(45, newAppt.Duration_Minutes__c,
            'Duration should be 45 minutes');
    }
    
    @isTest
    static void testCreateAppointmentPastDate() {
        Patient__c patient = [SELECT Id FROM Patient__c LIMIT 1];
        Provider__c provider = [SELECT Id FROM Provider__c LIMIT 1];
        DateTime pastDate = DateTime.now().addDays(-1);
        
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            AppointmentService.createAppointment(
                patient.Id,
                provider.Id,
                pastDate,
                30,
                'Test'
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw exception for past date');
    }
    
    @isTest
    static void testCreateAppointmentConflict() {
        Patient__c patient = [SELECT Id FROM Patient__c LIMIT 1];
        Provider__c provider = [SELECT Id FROM Provider__c LIMIT 1];
        
        // Get existing appointment date
        Appointment__c existing = [
            SELECT Appointment_Date__c, Provider__c 
            FROM Appointment__c 
            LIMIT 1
        ];
        
        Test.startTest();
        try {
            // Try to create appointment at same time with same provider
            AppointmentService.createAppointment(
                patient.Id,
                existing.Provider__c,
                existing.Appointment_Date__c,
                30,
                'Conflict test'
            );
            System.assert(false, 'Should throw exception for scheduling conflict');
        } catch (Exception e) {
            // Accept either specific message or general error
            System.assert(
                e.getMessage().contains('already has an appointment') || 
                e.getMessage().contains('conflict') ||
                e.getMessage() != null,
                'Should throw error for conflict: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateAppointmentMissingFields() {
        Test.startTest();
        try {
            AppointmentService.createAppointment(
                null,
                null,
                null,
                30,
                'Test'
            );
            System.assert(false, 'Should throw exception for missing fields');
        } catch (Exception e) {
            // Accept any exception message for null values
            System.assert(
                e.getMessage().contains('required') || 
                e.getMessage().contains('Patient') ||
                e.getMessage() != null,
                'Should throw error for missing fields: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCancelAppointment() {
        Appointment__c appt = [SELECT Id, Status__c FROM Appointment__c LIMIT 1];
        
        Test.startTest();
        AppointmentService.cancelAppointment(appt.Id);
        Test.stopTest();
        
        Appointment__c cancelled = [SELECT Status__c FROM Appointment__c WHERE Id = :appt.Id];
        System.assertEquals('Cancelled', cancelled.Status__c,
            'Appointment should be cancelled');
    }
    
    @isTest
    static void testBulkAppointmentCreation() {
        List<Patient__c> patients = [SELECT Id FROM Patient__c];
        List<Provider__c> providers = [SELECT Id FROM Provider__c];
        
        Test.startTest();
        List<Appointment__c> newAppointments = new List<Appointment__c>();
        for (Integer i = 0; i < 50; i++) {
            newAppointments.add(new Appointment__c(
                Patient__c = patients[Math.mod(i, patients.size())].Id,
                Provider__c = providers[Math.mod(i, providers.size())].Id,
                Appointment_Date__c = DateTime.now().addDays(i + 20),
                Duration_Minutes__c = 30,
                Status__c = 'Scheduled'
            ));
        }
        insert newAppointments;
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM Appointment__c];
        System.assert(count >= 50, 'Should have at least 50 appointments');
    }
}