# Quick Reference - Report Viewer Component

## 🚀 Quick Deploy (3 Commands)

```bash
sf org login web --alias myorg
sf project deploy start --target-org myorg
sf apex run test --class-names ReportViewerControllerTest --target-org myorg
```

## 📁 File Locations

| Component | Path |
|-----------|------|
| Apex Controller | `force-app/main/default/classes/ReportViewerController.cls` |
| Apex Test | `force-app/main/default/classes/ReportViewerControllerTest.cls` |
| LWC Component | `force-app/main/default/lwc/reportViewer/` |
| VF Page | `force-app/main/default/pages/ReportViewerPage.page` |
| Aura App | `force-app/main/default/aura/ReportViewerApp/` |
| Sample Report | `force-app/main/default/reports/ContactReports/Contact_Report.report-meta.xml` |
| Custom Tab | `force-app/main/default/tabs/ReportViewerPage.tab-meta.xml` |

## 🔧 Key Methods

### Apex Controller

```apex
// Get list of available reports (cacheable)
@AuraEnabled(cacheable=true)
public static List<ReportWrapper> getAvailableReports()

// Execute report and return formatted data
@AuraEnabled
public static ReportDataWrapper runReport(String reportId)
```

### LWC Component

```javascript
// Wire to load reports
@wire(getAvailableReports)

// Handle report selection
handleReportChange(event)

// Fetch report data
fetchReportData()

// Get data for VF page
@api getCurrentReportData()
```

### VF Page JavaScript

```javascript
// Open modal with LWC
openReportModal()

// Close modal and pass data
closeReportModal()

// Display data on VF page
displayReportDataOnVF(reportData)
```

## 🎯 Access URLs

| Resource | URL |
|----------|-----|
| VF Page | `/apex/ReportViewerPage` |
| LWC (in app) | Navigate to "Report Viewer" tab |
| Reports | `/lightning/o/Report/home` |
| Setup | `/lightning/setup/SetupOneHome/home` |

## 🔑 Required Permissions

```text
✅ Run Reports (User permission)
✅ ReportViewerController (Apex class access)
✅ ReportViewerPage (Visualforce page access)
✅ Read on Report object (CRUD)
```

## 📊 Component Structure

```
ReportViewerPage (VF)
    ↓ (Lightning Out)
ReportViewerApp (Aura)
    ↓ (dependency)
reportViewer (LWC)
    ↓ (calls)
ReportViewerController (Apex)
    ↓ (uses)
Reports.ReportManager (API)
```

## 🛠️ Common Tasks

### Add to Lightning App
```text
Setup → App Manager → [Your App] → Edit → 
Navigation Items → Add "Report Viewer"
```

### Grant Permissions
```text
Setup → Permission Sets → Create → 
Add: ReportViewerController, ReportViewerPage
```

### Create New Report
```text
Reports Tab → New Report → 
Select Type → Add Columns → Save
```

### Debug Issues
```text
Setup → Debug Logs → New Log → 
Set Apex to FINEST → Run Component
```

## 🧪 Test Class

```bash
# Run tests
sf apex run test --class-names ReportViewerControllerTest --result-format human --target-org myorg

# Expected: 8 test methods, 85%+ coverage
```

## 📝 Customization Points

### Modify Report Query
```apex
// File: ReportViewerController.cls, Line ~58
List<Report> reports = [
    SELECT Id, Name, DeveloperName, Format
    FROM Report
    WHERE Format IN ('Tabular', 'Summary', 'Matrix')
    ORDER BY Name
    LIMIT 200  // Adjust this limit
];
```

### Change LWC Styling
```javascript
// Add CSS file: reportViewer.css
// Import in JS: import styles from './reportViewer.css'
```

### Modify VF Modal Size
```css
/* File: ReportViewerPage.page, Line ~20 */
.modalContainer {
    width: 80%;        /* Change width */
    max-width: 1200px; /* Change max width */
    max-height: 80vh;  /* Change height */
}
```

## 🐛 Troubleshooting Quick Fixes

| Issue | Fix |
|-------|-----|
| No reports in dropdown | Grant "Run Reports" permission |
| Modal doesn't open | Check browser console (F12) |
| $Lightning not defined | Add `<apex:includeLightning />` to VF |
| Permission error | Deploy as admin or grant "Modify All Data" |
| Test failures | Ensure reports exist in org |

## 📚 Important Files

```bash
# View Apex controller
cat force-app/main/default/classes/ReportViewerController.cls

# View LWC JavaScript
cat force-app/main/default/lwc/reportViewer/reportViewer.js

# View VF page
cat force-app/main/default/pages/ReportViewerPage.page

# View package manifest
cat manifest/package.xml
```

## 🔍 Debug Commands

```bash
# Check deployment status
sf project deploy report --target-org myorg

# View org info
sf org display --target-org myorg

# Open org
sf org open --target-org myorg

# View limits
sf limits api display --target-org myorg

# Tail logs (if supported)
sf apex tail log --target-org myorg
```

## 💡 Pro Tips

1. **Test with sample report first** - Use Contact_Report for initial testing
2. **Check permissions** - Most issues are permission-related
3. **Use debug logs** - Enable FINEST level for Apex debugging
4. **Test in sandbox** - Always test before production deployment
5. **Clear cache** - Hard refresh browser (Cmd+Shift+R / Ctrl+F5)
6. **Check API version** - Ensure org supports API 60.0

## 🎓 Key Concepts

- **Reports API**: `Reports.ReportManager` namespace
- **Lightning Out**: Embed LWC in VF via `$Lightning`
- **Wire Service**: `@wire` for reactive data
- **With Sharing**: Security enforcement in Apex
- **AuraEnabled**: Expose Apex methods to Lightning

## 📞 Support Resources

- [Salesforce Reports API Docs](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_report_data.htm)
- [LWC Documentation](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [Lightning Out Documentation](https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/lightning_out.htm)

## ✅ Pre-Deployment Checklist

- [ ] Salesforce CLI installed
- [ ] Authenticated with org
- [ ] API version 60.0 supported
- [ ] Lightning Experience enabled
- [ ] User has admin or developer access

## 📦 What Gets Deployed

```
✅ 2 Apex classes (controller + test)
✅ 1 LWC bundle (3 files)
✅ 1 Aura bundle (2 files)
✅ 1 Visualforce page (2 files)
✅ 1 Report + folder (2 files)
✅ 1 Custom tab (1 file)

Total: 13 metadata files
```

---

**Quick Start**: See [DEPLOYMENT.md](DEPLOYMENT.md)  
**Full Docs**: See [IMPLEMENTATION.md](IMPLEMENTATION.md)  
**Overview**: See [SUMMARY.md](SUMMARY.md)
