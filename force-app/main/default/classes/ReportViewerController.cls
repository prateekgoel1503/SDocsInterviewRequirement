/**
 * @description Controller class for Report Viewer component
 * @author Salesforce Developer
 * @date 2026
 */
public with sharing class ReportViewerController {
    
    /**
     * @description Wrapper class for report metadata
     */
    public class ReportWrapper {
        @AuraEnabled public String reportId;
        @AuraEnabled public String reportName;
        @AuraEnabled public String reportType;
        
        public ReportWrapper(String id, String name, String type) {
            this.reportId = id;
            this.reportName = name;
            this.reportType = type;
        }
    }
    
    /**
     * @description Wrapper class for report data results
     */
    public class ReportDataWrapper {
        @AuraEnabled public List<Map<String, Object>> rows;
        @AuraEnabled public List<ColumnWrapper> columns;
        @AuraEnabled public Integer totalRecords;
        
        public ReportDataWrapper() {
            this.rows = new List<Map<String, Object>>();
            this.columns = new List<ColumnWrapper>();
            this.totalRecords = 0;
        }
    }
    
    /**
     * @description Wrapper class for table columns
     */
    public class ColumnWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
        
        public ColumnWrapper(String label, String fieldName, String type) {
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
        }
    }
    
    /**
     * @description Retrieves list of available reports accessible to current user
     * @return List<ReportWrapper> List of report metadata
     */
    @AuraEnabled(cacheable=true)
    public static List<ReportWrapper> getAvailableReports() {
        List<ReportWrapper> reportList = new List<ReportWrapper>();
        
        try {
            LoggerUtil.info('ReportViewerController', 'getAvailableReports', 'Fetching available reports');
            
            // Step 1: Get public folder IDs
            List<Folder> publicFolders = [
                SELECT Id, Name, DeveloperName
                FROM Folder
                WHERE Type = 'Report' 
                AND AccessType = 'Public'
                WITH USER_MODE
            ];
            
            Set<Id> publicFolderIds = new Set<Id>();
            for (Folder f : publicFolders) {
                publicFolderIds.add(f.Id);
            }
            
            LoggerUtil.debug('ReportViewerController', 'getAvailableReports', 
                'Found ' + publicFolderIds.size() + ' public folders');
            
            // Step 2: Query reports
            // Include reports where:
            // - OwnerId is in public folders (queryable folders with AccessType='Public')
            // - FolderName is 'Public Reports' (special org-level public folder)
            // - CreatedById is current user (user's own reports)
            List<Report> reports = [
                SELECT Id, Name, DeveloperName, Format, FolderName
                FROM Report
                WHERE Format IN ('Tabular', 'Summary', 'Matrix')
                AND (
                    OwnerId IN :publicFolderIds
                    OR FolderName = 'Public Reports'
                    OR CreatedById = :UserInfo.getUserId()
                )
                WITH USER_MODE
                ORDER BY Name
                LIMIT 200
            ];
            
            LoggerUtil.info('ReportViewerController', 'getAvailableReports', 
                'Found ' + reports.size() + ' reports');
            
            for (Report r : reports) {
                reportList.add(new ReportWrapper(
                    r.Id,
                    r.Name,
                    r.Format
                ));
            }
            
            LoggerUtil.flush();
            
        } catch (Exception e) {
            LoggerUtil.error('ReportViewerController', 'getAvailableReports', 
                'Error fetching reports', e);
            throw new AuraHandledException('Error retrieving reports: ' + e.getMessage());
        }
        
        return reportList;
    }
    
    /**
     * @description Runs specified report and returns formatted data
     * @param reportId The ID of the report to execute
     * @return ReportDataWrapper Formatted report data with rows and columns
     */
    @AuraEnabled
    public static ReportDataWrapper runReport(String reportId) {
        ReportDataWrapper result = new ReportDataWrapper();
        
        // Validate input BEFORE try-catch
        if (String.isBlank(reportId)) {
            LoggerUtil.warn('ReportViewerController', 'runReport', 'Blank report ID provided');
            throw new AuraHandledException('Report ID is required');
        }
        
        try {
            LoggerUtil.info('ReportViewerController', 'runReport', 'Running report: ' + reportId);
            
            // Run the report using Reports API
            Reports.ReportResults reportResults = Reports.ReportManager.runReport(reportId, true);
            Reports.ReportMetadata reportMetadata = reportResults.getReportMetadata();
            Reports.ReportFactWithDetails factDetails = 
                (Reports.ReportFactWithDetails) reportResults.getFactMap().get('T!T');
            
            if (factDetails == null) {
                LoggerUtil.warn('ReportViewerController', 'runReport', 'No data returned from report');
                return result;
            }
            
            // Get column information from detail columns
            List<String> detailColumns = reportMetadata.getDetailColumns();
            LoggerUtil.debug('ReportViewerController', 'runReport', 
                'Detail columns: ' + String.join(detailColumns, ', '));
            
            // Build column metadata
            Map<String, Reports.DetailColumn> extendedMetadata = 
                reportResults.getReportExtendedMetadata().getDetailColumnInfo();
            
            for (String columnName : detailColumns) {
                Reports.DetailColumn columnMetadata = extendedMetadata.get(columnName);
                if (columnMetadata != null) {
                    String dataTypeString = String.valueOf(columnMetadata.getDataType());
                    result.columns.add(new ColumnWrapper(
                        columnMetadata.getLabel(),
                        columnName.replace('.', '_'),
                        getColumnType(dataTypeString)
                    ));
                }
            }
            
            // Get row data
            List<Reports.ReportDetailRow> reportRows = factDetails.getRows();
            LoggerUtil.info('ReportViewerController', 'runReport', 
                'Processing ' + reportRows.size() + ' rows');
            
            for (Reports.ReportDetailRow row : reportRows) {
                Map<String, Object> rowData = new Map<String, Object>();
                List<Reports.ReportDataCell> dataCells = row.getDataCells();
                
                for (Integer i = 0; i < dataCells.size() && i < detailColumns.size(); i++) {
                    String fieldName = detailColumns[i].replace('.', '_');
                    Reports.ReportDataCell cell = dataCells[i];
                    rowData.put(fieldName, cell.getLabel() != null ? cell.getLabel() : '');
                }
                
                result.rows.add(rowData);
            }
            
            result.totalRecords = result.rows.size();
            LoggerUtil.info('ReportViewerController', 'runReport', 
                'Successfully processed ' + result.totalRecords + ' records');
            
            LoggerUtil.flush();
            
        } catch (Reports.InvalidReportMetadataException e) {
            LoggerUtil.error('ReportViewerController', 'runReport', 'Invalid report metadata', e);
            throw new AuraHandledException('Invalid report configuration: ' + e.getMessage());
        } catch (Exception e) {
            LoggerUtil.error('ReportViewerController', 'runReport', 'Error executing report', e);
            throw new AuraHandledException('Error executing report: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Maps Report API data types to lightning-datatable types
     * @param dataType The Reports API data type
     * @return String The corresponding datatable type
     */
    private static String getColumnType(String dataType) {
        if (dataType == null) {
            return 'text';
        }
        
        Map<String, String> typeMap = new Map<String, String>{
            'currency' => 'currency',
            'percent' => 'percent',
            'double' => 'number',
            'int' => 'number',
            'date' => 'date',
            'datetime' => 'date',
            'time' => 'text',
            'boolean' => 'boolean',
            'email' => 'email',
            'phone' => 'phone',
            'url' => 'url'
        };
        
        return typeMap.containsKey(dataType.toLowerCase()) 
            ? typeMap.get(dataType.toLowerCase()) 
            : 'text';
    }
}
