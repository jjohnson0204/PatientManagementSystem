import { LightningElement, wire, track } from 'lwc';
import getUpcomingAppointments from '@salesforce/apex/AppointmentService.getUpcomingAppointments';
import getActivePatientsForScheduling from '@salesforce/apex/AppointmentService.getActivePatientsForScheduling';
import getActiveProviders from '@salesforce/apex/AppointmentService.getActiveProviders';
import createAppointment from '@salesforce/apex/AppointmentService.createAppointment';
import cancelAppointment from '@salesforce/apex/AppointmentService.cancelAppointment';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AppointmentScheduler extends LightningElement {
    @track appointments = [];
    @track patients = [];
    @track providers = [];
    @track showModal = false;
    @track selectedPatientId;
    @track selectedProviderId;
    @track appointmentDateTime;
    @track durationMinutes = 30;
    @track notes = '';
    
    wiredAppointmentsResult;
    
    columns = [
        { label: 'Appointment #', fieldName: 'Name', type: 'text' },
        { label: 'Patient', fieldName: 'patientName', type: 'text' },
        { label: 'Provider', fieldName: 'providerName', type: 'text' },
        { label: 'Specialty', fieldName: 'specialty', type: 'text' },
        { label: 'Date & Time', fieldName: 'Appointment_Date__c', type: 'date', 
          typeAttributes: { year: 'numeric', month: 'short', day: '2-digit', 
                           hour: '2-digit', minute: '2-digit' } },
        { label: 'Duration (min)', fieldName: 'Duration_Minutes__c', type: 'number' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Cancel', name: 'cancel' }
                ]
            }
        }
    ];

    @wire(getUpcomingAppointments)
    wiredAppointments(result) {
        this.wiredAppointmentsResult = result;
        if (result.data) {
            this.appointments = result.data.map(appt => {
                return {
                    ...appt,
                    patientName: appt.Patient__r ? appt.Patient__r.Name : '',
                    providerName: appt.Provider__r ? appt.Provider__r.Name : '',
                    specialty: appt.Provider__r ? appt.Provider__r.Specialty__c : ''
                };
            });
        } else if (result.error) {
            this.showToast('Error', 'Error loading appointments', 'error');
        }
    }

    @wire(getActivePatientsForScheduling)
    wiredPatients({ error, data }) {
        if (data) {
            this.patients = data.map(patient => {
                return {
                    label: patient.Name + ' (' + patient.First_Name__c + ' ' + patient.Last_Name__c + ')',
                    value: patient.Id
                };
            });
        } else if (error) {
            this.showToast('Error', 'Error loading patients', 'error');
        }
    }

    @wire(getActiveProviders)
    wiredProviders({ error, data }) {
        if (data) {
            this.providers = data.map(provider => {
                return {
                    label: provider.Name + (provider.Specialty__c ? ' - ' + provider.Specialty__c : ''),
                    value: provider.Id
                };
            });
        } else if (error) {
            this.showToast('Error', 'Error loading providers', 'error');
        }
    }

    handlePatientChange(event) {
        this.selectedPatientId = event.detail.value;
    }

    handleProviderChange(event) {
        this.selectedProviderId = event.detail.value;
    }

    handleDateTimeChange(event) {
        this.appointmentDateTime = event.detail.value;
    }

    handleDurationChange(event) {
        this.durationMinutes = event.detail.value;
    }

    handleNotesChange(event) {
        this.notes = event.detail.value;
    }

    openModal() {
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.resetForm();
    }

    resetForm() {
        this.selectedPatientId = null;
        this.selectedProviderId = null;
        this.appointmentDateTime = null;
        this.durationMinutes = 30;
        this.notes = '';
    }

    handleSaveAppointment() {
        // Validation
        if (!this.selectedPatientId || !this.selectedProviderId || !this.appointmentDateTime) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }

        createAppointment({
            patientId: this.selectedPatientId,
            providerId: this.selectedProviderId,
            appointmentDate: this.appointmentDateTime,
            durationMinutes: parseInt(this.durationMinutes),
            notes: this.notes
        })
        .then(() => {
            this.showToast('Success', 'Appointment created successfully', 'success');
            this.closeModal();
            return refreshApex(this.wiredAppointmentsResult);
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'cancel') {
            this.handleCancelAppointment(row.Id);
        }
    }

    handleCancelAppointment(appointmentId) {
        if (confirm('Are you sure you want to cancel this appointment?')) {
            cancelAppointment({ appointmentId: appointmentId })
            .then(() => {
                this.showToast('Success', 'Appointment cancelled', 'success');
                return refreshApex(this.wiredAppointmentsResult);
            })
            .catch(error => {
                this.showToast('Error', 'Error cancelling appointment', 'error');
            });
        }
    }

    handleRefresh() {
        return refreshApex(this.wiredAppointmentsResult);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    get hasAppointments() {
        return this.appointments && this.appointments.length > 0;
    }
}