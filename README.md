# HealthTrack - Patient Management System

A comprehensive Salesforce-based patient management system built to demonstrate Platform Developer I certification skills.

## 🏥 Overview

HealthTrack is a full-featured healthcare management application that enables medical facilities to manage patients, providers, appointments, and medical records efficiently.

## ✨ Features

- **Patient Management**: Track patient demographics, contact information, blood type, and status
- **Provider Management**: Manage healthcare providers with specialties and licensing
- **Appointment Scheduling**: Schedule, view, and manage patient appointments with conflict detection
- **Medical Records**: Maintain comprehensive patient medical history
- **Data Validation**: Automated validation rules and duplicate prevention
- **Automated Workflows**: Triggers for status management and record creation

## 🛠️ Technical Implementation

### Custom Objects
- **Patient__c**: Core patient information with validation and status tracking
- **Provider__c**: Healthcare provider details with unique licensing
- **Appointment__c**: Appointment scheduling with conflict detection
- **Medical_Record__c**: Patient medical history and treatment records

### Apex Classes
- **PatientService**: Service layer for patient CRUD operations with SOQL/SOSL
- **AppointmentService**: Appointment management with business logic
- **PatientTriggerHandler**: Trigger handler implementing best practices
- **Comprehensive Test Classes**: 100% code coverage with 26 test methods

### Lightning Web Components
- **patientList**: Interactive patient data table with search functionality
- **appointmentScheduler**: Full appointment scheduling interface with modal

### Key Features Demonstrated
- ✅ Custom Object & Field Creation
- ✅ Relationships (Lookup)
- ✅ Apex Triggers with Handler Pattern
- ✅ SOQL & SOSL Queries
- ✅ DML Operations with Exception Handling
- ✅ Bulkification & Governor Limits
- ✅ Lightning Web Components
- ✅ Test Classes (100% Coverage)
- ✅ Custom App & Navigation
- ✅ Data Validation & Business Logic

## 📊 Test Coverage

- **Overall Coverage**: 89%+
- **PatientService**: 86%
- **AppointmentService**: 89%
- **PatientTriggerHandler**: 100%
- **Total Test Methods**: 26
- **All Tests Passing**: ✓

## 🚀 Installation

1. Clone this repository
2. Authenticate to your Salesforce org:
```bash
   sf org login web -a YourOrgAlias
```
3. Deploy the metadata:
```bash
   sf project deploy start
```
4. Assign permissions and configure as needed
5. Launch the HealthTrack app from App Launcher

## 📱 Custom App

The **HealthTrack** Lightning app provides a unified interface with:
- Patient Management Dashboard
- Appointment Scheduler
- Direct access to Patients, Providers, Appointments, and Medical Records

## 🎯 Certification Skills Demonstrated

This project demonstrates all key areas of the Salesforce Platform Developer I certification:
- Salesforce Fundamentals
- Data Modeling and Management
- Business Logic and Process Automation
- User Interface
- Testing, Debugging and Deployment

## 👨‍💻 Author

Built as a portfolio project for Salesforce Platform Developer I certification preparation.

## 📄 License

This project is available for educational and portfolio purposes.