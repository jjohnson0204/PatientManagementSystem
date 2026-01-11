import { LightningElement, wire, track } from 'lwc';
import getActivePatients from '@salesforce/apex/PatientService.getActivePatients';
import searchPatients from '@salesforce/apex/PatientService.searchPatients';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PatientList extends LightningElement {
    @track patients = [];
    @track error;
    @track searchTerm = '';
    wiredPatientsResult;

    columns = [
        { label: 'Patient Name', fieldName: 'Name', type: 'text' },
        { label: 'First Name', fieldName: 'First_Name__c', type: 'text' },
        { label: 'Last Name', fieldName: 'Last_Name__c', type: 'text' },
        { label: 'Email', fieldName: 'Email__c', type: 'email' },
        { label: 'Phone', fieldName: 'Phone__c', type: 'phone' },
        { label: 'Blood Type', fieldName: 'Blood_Type__c', type: 'text' },
        { label: 'Status', fieldName: 'Patient_Status__c', type: 'text' }
    ];

    @wire(getActivePatients)
    wiredPatients(result) {
        this.wiredPatientsResult = result;
        if (result.data) {
            this.patients = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.patients = [];
            this.showToast('Error', 'Error loading patients', 'error');
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleSearch() {
        if (this.searchTerm) {
            searchPatients({ searchTerm: this.searchTerm })
                .then(result => {
                    this.patients = result;
                    this.error = undefined;
                })
                .catch(error => {
                    this.error = error;
                    this.patients = [];
                    this.showToast('Error', 'Error searching patients', 'error');
                });
        } else {
            // If search is empty, refresh to show all active patients
            this.handleRefresh();
        }
    }

    handleRefresh() {
        return refreshApex(this.wiredPatientsResult);
    }

    handleNewPatient() {
        // Navigate to new patient creation
        this.showToast('Info', 'New Patient creation coming soon!', 'info');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    get hasPatients() {
        return this.patients && this.patients.length > 0;
    }
}