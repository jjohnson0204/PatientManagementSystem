public class PatientTriggerHandler {
    
    /**
     * Before Insert Handler
     * Demonstrates: Trigger context, Field defaults, Validation
     */
    public static void beforeInsert(List<Patient__c> newPatients) {
        // Set default status if not provided
        for (Patient__c patient : newPatients) {
            if (String.isBlank(patient.Patient_Status__c)) {
                patient.Patient_Status__c = 'Active';
            }
            
            // Validate required fields
            validatePatient(patient);
        }
        
        // Check for duplicate emails
        checkDuplicateEmails(newPatients);
    }
    
    /**
     * Before Update Handler
     * Demonstrates: Trigger.oldMap usage, Field history tracking
     */
    public static void beforeUpdate(List<Patient__c> newPatients, 
                                    Map<Id, Patient__c> oldMap) {
        for (Patient__c patient : newPatients) {
            Patient__c oldPatient = oldMap.get(patient.Id);
            
            // Prevent status change from Deceased
            if (oldPatient.Patient_Status__c == 'Deceased' && 
                patient.Patient_Status__c != 'Deceased') {
                patient.addError('Cannot change status of deceased patient');
            }
            
            // Validate on update
            validatePatient(patient);
        }
    }
    
    /**
     * After Insert Handler
     * Demonstrates: DML in triggers, Related record creation
     */
    public static void afterInsert(List<Patient__c> newPatients) {
        // Create initial medical record for new patients
        createInitialMedicalRecords(newPatients);
    }
    
    /**
     * After Update Handler
     * Demonstrates: Field change detection, Complex business logic
     */
    public static void afterUpdate(List<Patient__c> newPatients, 
                                   Map<Id, Patient__c> oldMap) {
        List<Id> statusChangedPatients = new List<Id>();
        
        for (Patient__c patient : newPatients) {
            Patient__c oldPatient = oldMap.get(patient.Id);
            
            // Track status changes
            if (patient.Patient_Status__c != oldPatient.Patient_Status__c) {
                statusChangedPatients.add(patient.Id);
            }
        }
        
        // Update future appointments if status changed
        if (!statusChangedPatients.isEmpty()) {
            updateAppointmentsForStatusChange(statusChangedPatients);
        }
    }
    
    /**
     * Helper: Validate patient data
     */
    private static void validatePatient(Patient__c patient) {
        if (String.isBlank(patient.First_Name__c) || 
            String.isBlank(patient.Last_Name__c)) {
            patient.addError('First Name and Last Name are required');
        }
        
        if (patient.Date_of_Birth__c != null && 
            patient.Date_of_Birth__c > Date.today()) {
            patient.addError('Date of Birth cannot be in the future');
        }
    }
    
    /**
     * Helper: Check for duplicate emails
     * Demonstrates: SOQL in triggers, Set operations
     */
    private static void checkDuplicateEmails(List<Patient__c> patients) {
        Set<String> emails = new Set<String>();
        
        for (Patient__c patient : patients) {
            if (String.isNotBlank(patient.Email__c)) {
                emails.add(patient.Email__c.toLowerCase());
            }
        }
        
        if (!emails.isEmpty()) {
            List<Patient__c> existingPatients = [
                SELECT Email__c 
                FROM Patient__c 
                WHERE Email__c IN :emails
            ];
            
            Set<String> existingEmails = new Set<String>();
            for (Patient__c existing : existingPatients) {
                existingEmails.add(existing.Email__c.toLowerCase());
            }
            
            for (Patient__c patient : patients) {
                if (String.isNotBlank(patient.Email__c) && 
                    existingEmails.contains(patient.Email__c.toLowerCase())) {
                    patient.Email__c.addError('A patient with this email already exists');
                }
            }
        }
    }
    
    /**
     * Helper: Create initial medical records
     */
    private static void createInitialMedicalRecords(List<Patient__c> patients) {
        List<Medical_Record__c> records = new List<Medical_Record__c>();
        
        for (Patient__c patient : patients) {
            records.add(new Medical_Record__c(
                Patient__c = patient.Id,
                Record_Date__c = Date.today(),
                Diagnosis__c = 'Initial Registration',
                Treatment__c = 'Patient profile created'
            ));
        }
        
        if (!records.isEmpty()) {
            insert records;
        }
    }
    
    /**
     * Helper: Update appointments when patient status changes
     */
    private static void updateAppointmentsForStatusChange(List<Id> patientIds) {
        List<Appointment__c> appointmentsToUpdate = [
            SELECT Id, Status__c, Patient__r.Patient_Status__c
            FROM Appointment__c
            WHERE Patient__c IN :patientIds
            AND Status__c = 'Scheduled'
            AND Appointment_Date__c > :DateTime.now()
        ];
        
        for (Appointment__c appt : appointmentsToUpdate) {
            if (appt.Patient__r.Patient_Status__c == 'Deceased' || 
                appt.Patient__r.Patient_Status__c == 'Inactive') {
                appt.Status__c = 'Cancelled';
            }
        }
        
        if (!appointmentsToUpdate.isEmpty()) {
            update appointmentsToUpdate;
        }
    }
}