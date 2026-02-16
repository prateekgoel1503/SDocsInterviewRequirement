# Salesforce Report Viewer Component

## Overview

A complete Salesforce solution that allows users to select and view Salesforce reports through a Lightning Web Component (LWC), with a Visualforce page that launches the component in a modal and displays the data.

## Features

- **Lightning Web Component**: Modern, responsive report viewer with dynamic data table
- **Apex Reports API Integration**: Secure, user-context execution using Salesforce Reports API
- **Visualforce Modal Integration**: Lightning Out implementation for embedding LWC in Visualforce
- **Sample Contact Report**: Pre-configured report for testing (FirstName, LastName, Email)
- **Error Handling**: Comprehensive error handling and user-friendly messages
- **Test Coverage**: Complete Apex test class included

## Architecture

### Components

1. **ReportViewerController.cls** - Apex controller with Reports API integration
   - `getAvailableReports()` - Fetches reports accessible to current user
   - `runReport(reportId)` - Executes report and returns formatted data
   - Runs with sharing for user-context security

2. **reportViewer (LWC)** - Lightning Web Component
   - Report selection combobox using `lightning-combobox`
   - Data display using `lightning-datatable`
   - Loading states with `lightning-spinner`
   - Standard Salesforce components only (no custom CSS)

3. **ReportViewerPage.page** - Visualforce page
   - Button to launch modal
   - Lightning Out integration for LWC embedding
   - JavaScript to pass data back from LWC to VF
   - Data display section showing selected report results

4. **Contact_Report** - Sample report
   - Tabular format
   - Columns: First Name, Last Name, Email
   - Based on Contacts

## Installation

### Prerequisites

- Salesforce org (Developer, Sandbox, or Production)
- Salesforce CLI (`sf` or `sfdx`)
- Proper permissions to deploy metadata

### Deployment Steps

1. **Authenticate with your org**:
   ```bash
   sf org login web --alias myorg
   ```

2. **Deploy the metadata**:
   ```bash
   sf project deploy start --target-org myorg
   ```

3. **Verify deployment**:
   ```bash
   sf project deploy report --target-org myorg
   ```

### Post-Deployment Setup

1. **Add Tab to App**:
   - Go to Setup → App Manager
   - Edit your desired app
   - Add the "Report Viewer" tab to the app

2. **Assign Permissions** (if needed):
   - Ensure users have access to the Visualforce page
   - Ensure users have "Run Reports" permission
   - Grant access to the Contact Report or create additional reports

3. **Create Test Data** (optional):
   - Add some Contact records with FirstName, LastName, and Email
   - This will populate the sample Contact Report

## Usage

### Accessing the Component

**Option 1: Via Tab**
1. Navigate to the "Report Viewer" tab in your app
2. Click "Open Report Viewer" button
3. Select a report from the dropdown
4. View the report data in the table
5. Close the modal to see data on the VF page

**Option 2: Direct URL**
- Access via: `https://your-instance.salesforce.com/apex/ReportViewerPage`

### Using the Component

1. **Select a Report**:
   - Open the modal
   - Choose from available reports in the dropdown
   - Component automatically loads report data

2. **View Data**:
   - Data displays in a sortable table
   - Total record count shown at bottom
   - Error messages appear if issues occur

3. **Close Modal**:
   - Click Close button or click outside modal
   - Selected report data appears on the VF page

## File Structure

```
force-app/main/default/
├── aura/
│   └── ReportViewerApp/           # Lightning Out app
│       ├── ReportViewerApp.app
│       └── ReportViewerApp.app-meta.xml
├── classes/
│   ├── ReportViewerController.cls
│   ├── ReportViewerController.cls-meta.xml
│   ├── ReportViewerControllerTest.cls
│   └── ReportViewerControllerTest.cls-meta.xml
├── lwc/
│   └── reportViewer/
│       ├── reportViewer.html
│       ├── reportViewer.js
│       └── reportViewer.js-meta.xml
├── pages/
│   ├── ReportViewerPage.page
│   └── ReportViewerPage.page-meta.xml
├── reports/
│   └── ContactReports/
│       ├── Contact_Report.report-meta.xml
│       └── ContactReports-meta.xml
└── tabs/
    └── ReportViewerPage.tab-meta.xml
```

## Technical Details

### Security

- **User Context Execution**: All queries run as the current user (`with sharing`)
- **Field-Level Security**: Respects user's FLS and CRUD permissions
- **Report Access**: Only shows reports the user has permission to access
- **Input Validation**: Report ID validation in Apex methods

### Error Handling

- Try-catch blocks in all Apex methods
- AuraHandledException for proper LWC error display
- User-friendly error messages
- Console logging for debugging

### API Usage

- **Salesforce Reports API**: `Reports.ReportManager` namespace
- **Methods Used**:
  - `Reports.ReportManager.runReport(reportId, includeDetails)`
  - SOQL query on Report object for metadata
- **API Version**: 60.0

### Data Flow

```
User clicks "Open Report Viewer"
    ↓
Visualforce opens modal with Lightning Out
    ↓
LWC loads and fetches available reports (@wire)
    ↓
User selects report
    ↓
LWC calls Apex runReport method
    ↓
Apex uses Reports API to execute report
    ↓
Data returned to LWC and displayed in datatable
    ↓
User closes modal
    ↓
LWC data passed to VF page via JavaScript
    ↓
VF page displays report data in table
```

## Testing

### Running Tests

```bash
sf apex run test --class-names ReportViewerControllerTest --result-format human --target-org myorg
```

### Test Coverage

- ReportViewerControllerTest.cls provides comprehensive coverage
- Tests positive and negative scenarios
- Tests error handling and edge cases
- Tests with sharing enforcement

## Customization

### Adding More Report Types

Reports API supports various formats. The component handles:
- Tabular reports
- Summary reports
- Matrix reports

### Modifying the LWC

The component uses only standard Salesforce components:
- `lightning-card`
- `lightning-combobox`
- `lightning-datatable`
- `lightning-spinner`
- `lightning-icon`

Modify `reportViewer.html` and `reportViewer.js` as needed.

### Styling

Currently uses SLDS (Salesforce Lightning Design System) automatically via standard components. To add custom styling:
1. Create a CSS file in the LWC bundle
2. Import it in the JavaScript file
3. Apply classes in the HTML template

## Troubleshooting

### Common Issues

**Issue**: No reports appear in dropdown
- **Solution**: Ensure user has "Run Reports" permission and access to reports

**Issue**: Modal doesn't open
- **Solution**: Check browser console for JavaScript errors, ensure Lightning Out is properly configured

**Issue**: Report data doesn't load
- **Solution**: Verify report ID is valid and user has access, check debug logs

**Issue**: Error: "Invalid report configuration"
- **Solution**: Ensure report format is Tabular, Summary, or Matrix

### Debug Mode

Enable debug logs:
1. Setup → Debug Logs
2. Create log for your user
3. Set Apex Code level to FINEST
4. Run the component and check logs

### Browser Console

Check browser console (F12) for:
- JavaScript errors
- LWC component lifecycle messages
- Network requests to Apex methods

## Best Practices

1. **Report Selection**: Create a custom report folder for frequently used reports
2. **Performance**: Limit report results using report filters
3. **User Training**: Train users on report selection and data interpretation
4. **Maintenance**: Regularly review and update reports as needed

## Limitations

- Reports cannot be created via Apex (must exist in org)
- Matrix reports may have complex data structures
- Large reports may take longer to load
- Lightning Out requires Lightning Experience enabled

## Version History

- **Version 1.0** (February 2026)
  - Initial release
  - LWC component with report selection
  - Apex Reports API integration
  - Visualforce modal implementation
  - Sample Contact report

## License

This code is provided as-is for demonstration and learning purposes.

## Support

For issues or questions:
1. Check debug logs in Salesforce
2. Review browser console for JavaScript errors
3. Verify user permissions and report access
4. Test with the sample Contact Report first
