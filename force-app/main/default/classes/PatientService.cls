public with sharing class PatientService {
    
    /**
     * Get all active patients
     * Demonstrates: SOQL, Exception Handling
     */
    @AuraEnabled(cacheable=true)
    public static List<Patient__c> getActivePatients() {
        try {
            return [
                SELECT Id, Name, First_Name__c, Last_Name__c, 
                       Email__c, Phone__c, Date_of_Birth__c, 
                       Blood_Type__c, Patient_Status__c
                FROM Patient__c 
                WHERE Patient_Status__c = 'Active'
                ORDER BY Last_Name__c, First_Name__c
                LIMIT 1000
            ];
        } catch (Exception e) {
            System.debug('Error retrieving active patients: ' + e.getMessage());
            throw new PatientServiceException('Unable to retrieve patients: ' + e.getMessage());
        }
    }
    
    /**
     * Search patients by name
     * Demonstrates: SOSL, Dynamic queries
     */
    @AuraEnabled(cacheable=true)
    public static List<Patient__c> searchPatients(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return new List<Patient__c>();
        }
        
        String searchQuery = 'FIND \'' + String.escapeSingleQuotes(searchTerm) + '*\' ' +
                           'IN NAME FIELDS ' +
                           'RETURNING Patient__c(Id, Name, First_Name__c, Last_Name__c, ' +
                           'Email__c, Phone__c, Patient_Status__c)';
        
        List<List<SObject>> searchResults = Search.query(searchQuery);
        return (List<Patient__c>)searchResults[0];
    }
    
    /**
     * Create new patients
     * Demonstrates: Bulkification, DML, Exception Handling
     */
    public static List<Patient__c> createPatients(List<Patient__c> patients) {
        if (patients == null || patients.isEmpty()) {
            throw new PatientServiceException('No patients provided for creation');
        }
        
        // Validate before insert
        validatePatients(patients);
        
        try {
            insert patients;
            return patients;
        } catch (DmlException e) {
            System.debug('DML Error creating patients: ' + e.getMessage());
            throw new PatientServiceException('Failed to create patients: ' + e.getDmlMessage(0));
        }
    }
    
    /**
     * Update patient status
     * Demonstrates: Partial DML, Database class methods
     */
    public static Database.SaveResult[] updatePatientStatus(List<Id> patientIds, String newStatus) {
        List<Patient__c> patientsToUpdate = new List<Patient__c>();
        
        for (Id patientId : patientIds) {
            patientsToUpdate.add(new Patient__c(
                Id = patientId,
                Patient_Status__c = newStatus
            ));
        }
        
        // Use Database.update with allOrNone = false for partial success
        return Database.update(patientsToUpdate, false);
    }
    
    /**
     * Get patient with related appointments and medical records
     * Demonstrates: Parent-Child SOQL, Relationship queries
     */
    public static Patient__c getPatientWithRelatedRecords(Id patientId) {
        return [
            SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Phone__c,
                   Date_of_Birth__c, Blood_Type__c, Patient_Status__c,
                   (SELECT Id, Name, Appointment_Date__c, Status__c, 
                           Provider__r.Name, Provider__r.Specialty__c
                    FROM Appointments__r 
                    ORDER BY Appointment_Date__c DESC 
                    LIMIT 10),
                   (SELECT Id, Name, Record_Date__c, Diagnosis__c, 
                           Provider__r.Name
                    FROM Medical_Records__r 
                    ORDER BY Record_Date__c DESC 
                    LIMIT 10)
            FROM Patient__c
            WHERE Id = :patientId
        ];
    }
    
    /**
     * Validation helper method
     */
    private static void validatePatients(List<Patient__c> patients) {
        for (Patient__c patient : patients) {
            if (String.isBlank(patient.First_Name__c) || 
                String.isBlank(patient.Last_Name__c)) {
                throw new PatientServiceException('First and Last Name are required');
            }
        }
    }
    
    /**
     * Custom exception class
     */
    public class PatientServiceException extends Exception {}
}