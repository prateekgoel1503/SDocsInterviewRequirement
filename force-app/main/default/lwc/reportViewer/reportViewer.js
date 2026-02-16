import { LightningElement, wire, track, api } from 'lwc';
import getAvailableReports from '@salesforce/apex/ReportViewerController.getAvailableReports';
import runReport from '@salesforce/apex/ReportViewerController.runReport';

export default class ReportViewer extends LightningElement {
    @track reportOptions = [];
    selectedReportId = '';
    selectedReportName = '';
    @track reportData = [];
    @track tableColumns = [];
    totalRecords = 0;
    errorMessage = '';
    isLoading = false;

    // Wire to get available reports
    @wire(getAvailableReports)
    wiredReports({ error, data }) {
        if (data) {
            console.log('Reports loaded:', data);
            this.reportOptions = data.map(report => ({
                label: report.reportName,
                value: report.reportId
            }));
            this.errorMessage = '';
        } else if (error) {
            console.error('Error loading reports:', error);
            this.errorMessage = 'Error loading reports: ' + this.getErrorMessage(error);
            this.reportOptions = [];
        }
    }

    // Handle report selection change
    handleReportChange(event) {
        this.selectedReportId = event.detail.value;
        console.log('Report selected:', this.selectedReportId);
        
        // Get the selected report name from options
        const selectedOption = this.reportOptions.find(
            opt => opt.value === this.selectedReportId
        );
        this.selectedReportName = selectedOption ? selectedOption.label : '';
        console.log('Report name:', this.selectedReportName);
        
        if (this.selectedReportId) {
            this.fetchReportData();
        } else {
            this.clearReportData();
        }
    }

    // Fetch report data
    fetchReportData() {
        this.isLoading = true;
        this.errorMessage = '';
        
        runReport({ reportId: this.selectedReportId })
            .then(result => {
                console.log('Report data received:', result);
                
                if (result && result.rows && result.rows.length > 0) {
                    // Set table columns
                    this.tableColumns = result.columns.map(col => ({
                        label: col.label,
                        fieldName: col.fieldName,
                        type: col.type
                    }));
                    
                    // Set report data with unique id for each row
                    this.reportData = result.rows.map((row, index) => ({
                        id: `row-${index}`,
                        ...row
                    }));
                    
                    this.totalRecords = result.totalRecords;
                    
                    console.log('Table columns:', this.tableColumns);
                    console.log('Report data rows:', this.reportData.length);
                } else {
                    this.clearReportData();
                    this.errorMessage = 'No data available for this report.';
                }
                
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching report data:', error);
                this.errorMessage = 'Error loading report data: ' + this.getErrorMessage(error);
                this.clearReportData();
                this.isLoading = false;
            });
    }

    // Clear report data
    clearReportData() {
        this.reportData = [];
        this.tableColumns = [];
        this.totalRecords = 0;
    }

    // Extract error message from error object
    getErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        } else if (error.message) {
            return error.message;
        } else if (typeof error === 'string') {
            return error;
        }
        return 'An unknown error occurred';
    }

    // Computed properties
    get showTable() {
        return !this.isLoading && this.reportData.length > 0;
    }

    get showNoData() {
        return !this.isLoading && 
               this.selectedReportId && 
               this.reportData.length === 0 && 
               !this.errorMessage;
    }

    // Method to get current report data (for VF page integration)
    @api
    getCurrentReportData() {
        return {
            reportId: this.selectedReportId,
            reportName: this.selectedReportName,
            data: this.reportData,
            columns: this.tableColumns,
            totalRecords: this.totalRecords
        };
    }
}
