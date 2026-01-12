public with sharing class AppointmentService {
    
    @AuraEnabled(cacheable=true)
    public static List<Appointment__c> getUpcomingAppointments() {
        return [
            SELECT Id, Name, Patient__r.Name, Patient__r.First_Name__c, 
                   Patient__r.Last_Name__c, Provider__r.Name, 
                   Provider__r.Specialty__c, Appointment_Date__c, 
                   Duration_Minutes__c, Status__c, Notes__c
            FROM Appointment__c
            WHERE Appointment_Date__c >= :DateTime.now()
            AND Status__c = 'Scheduled'
            ORDER BY Appointment_Date__c ASC
            LIMIT 50
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Patient__c> getActivePatientsForScheduling() {
        return [
            SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Phone__c
            FROM Patient__c
            WHERE Patient_Status__c = 'Active'
            ORDER BY Last_Name__c, First_Name__c
            LIMIT 1000
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Provider__c> getActiveProviders() {
        return [
            SELECT Id, Name, Specialty__c, Email__c, Phone__c
            FROM Provider__c
            WHERE Status__c = 'Active'
            ORDER BY Name
            LIMIT 1000
        ];
    }
    
    @AuraEnabled
    public static Appointment__c createAppointment(
        Id patientId, 
        Id providerId, 
        DateTime appointmentDate, 
        Integer durationMinutes,
        String notes
    ) {
        // Validation
        if (patientId == null || providerId == null || appointmentDate == null) {
            throw new AuraHandledException('Patient, Provider, and Appointment Date are required');
        }
        
        if (appointmentDate < DateTime.now()) {
            throw new AuraHandledException('Cannot schedule appointments in the past');
        }
        
        // Check for scheduling conflicts
        List<Appointment__c> conflicts = [
            SELECT Id 
            FROM Appointment__c
            WHERE Provider__c = :providerId
            AND Status__c = 'Scheduled'
            AND Appointment_Date__c = :appointmentDate
        ];
        
        if (!conflicts.isEmpty()) {
            throw new AuraHandledException('This provider already has an appointment at this time');
        }
        
        Appointment__c newAppt = new Appointment__c(
            Patient__c = patientId,
            Provider__c = providerId,
            Appointment_Date__c = appointmentDate,
            Duration_Minutes__c = durationMinutes != null ? durationMinutes : 30,
            Status__c = 'Scheduled',
            Notes__c = notes
        );
        
        try {
            insert newAppt;
            
            // Query and return the complete record with relationships
            return [
                SELECT Id, Name, Patient__r.Name, Provider__r.Name,
                       Appointment_Date__c, Duration_Minutes__c, Status__c, Notes__c
                FROM Appointment__c
                WHERE Id = :newAppt.Id
            ];
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating appointment: ' + e.getDmlMessage(0));
        }
    }
    
    @AuraEnabled
    public static void cancelAppointment(Id appointmentId) {
        try {
            Appointment__c appt = new Appointment__c(
                Id = appointmentId,
                Status__c = 'Cancelled'
            );
            update appt;
        } catch (DmlException e) {
            throw new AuraHandledException('Error cancelling appointment: ' + e.getDmlMessage(0));
        }
    }
}