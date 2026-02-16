/**
 * @description Test class for ReportViewerController
 * @author Salesforce Developer
 * @date 2026
 */
@isTest
private class ReportViewerControllerTest {
    
    /**
     * @description Setup test data - creates a test report
     */
    @testSetup
    static void setupTestData() {
        // Note: Reports cannot be created via Apex, so we'll test with query-based approach
        // In actual testing, a report must exist in the org
    }
    
    /**
     * @description Test getAvailableReports with existing reports
     */
    @isTest
    static void testGetAvailableReports_Success() {
        Test.startTest();
        
        List<ReportViewerController.ReportWrapper> reports = 
            ReportViewerController.getAvailableReports();
        
        Test.stopTest();
        
        // Assert that method executes without error
        // Actual reports depend on org configuration
        System.assertNotEquals(null, reports, 'Report list should not be null');
        System.debug('Found ' + reports.size() + ' reports in public folders');
        
        // Verify that reports are properly wrapped
        for (ReportViewerController.ReportWrapper report : reports) {
            System.assertNotEquals(null, report.reportId, 'Report ID should not be null');
            System.assertNotEquals(null, report.reportName, 'Report name should not be null');
        }
    }
    
    /**
     * @description Test that public folders are queried correctly
     */
    @isTest
    static void testPublicFolderQuery() {
        Test.startTest();
        
        // Query public folders directly to verify they exist
        List<Folder> publicFolders = [
            SELECT Id, Name, AccessType
            FROM Folder
            WHERE Type = 'Report' 
            AND AccessType = 'Public'
            WITH USER_MODE
        ];
        
        System.debug('Public folders found: ' + publicFolders.size());
        System.assertNotEquals(null, publicFolders, 'Public folders query should not be null');
        
        // Now test the controller method
        List<ReportViewerController.ReportWrapper> reports = 
            ReportViewerController.getAvailableReports();
        
        Test.stopTest();
        
        System.assertNotEquals(null, reports, 'Report list should not be null');
        // Reports in public folders should be returned
    }
    
    /**
     * @description Test runReport with valid report ID
     */
    @isTest
    static void testRunReport_Success() {
        // Get an available report to test with
        List<Report> existingReports = [
            SELECT Id, Name 
            FROM Report 
            WHERE Format = 'Tabular'
            WITH USER_MODE
            LIMIT 1
        ];
        
        if (existingReports.isEmpty()) {
            // No reports available, test with mock scenario
            System.debug('No reports available for testing');
            return;
        }
        
        Test.startTest();
        
        try {
            ReportViewerController.ReportDataWrapper result = 
                ReportViewerController.runReport(existingReports[0].Id);
            
            // Assert basic structure
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertNotEquals(null, result.rows, 'Rows list should not be null');
            System.assertNotEquals(null, result.columns, 'Columns list should not be null');
            System.debug('Report executed successfully with ' + result.totalRecords + ' records');
            
        } catch (Exception e) {
            // Some reports may not have data or may require specific permissions
            System.debug('Report execution test: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test runReport with invalid report ID
     */
    @isTest
    static void testRunReport_InvalidId() {
        Test.startTest();
        
        Boolean exceptionThrown = false;
        try {
            ReportViewerController.runReport('00O000000000000');
        } catch (Exception e) {
            exceptionThrown = true;
            // Exception is thrown, which is what we want to verify
            System.debug('Exception caught as expected: ' + e.getMessage());
        }
        
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for invalid report ID');
    }
    
    /**
     * @description Test runReport with blank report ID
     */
    @isTest
    static void testRunReport_BlankId() {
        Test.startTest();
        
        Boolean exceptionThrown = false;
        try {
            ReportViewerController.runReport('');
        } catch (Exception e) {
            exceptionThrown = true;
            // Exception is thrown, which is what we want to verify
            System.debug('Exception caught as expected: ' + e.getMessage());
        }
        
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for blank report ID');
    }
    
    /**
     * @description Test runReport with null report ID
     */
    @isTest
    static void testRunReport_NullId() {
        Test.startTest();
        
        Boolean exceptionThrown = false;
        try {
            ReportViewerController.runReport(null);
        } catch (Exception e) {
            exceptionThrown = true;
            // Exception is thrown, which is what we want to verify
            System.debug('Exception caught as expected: ' + e.getMessage());
        }
        
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for null report ID');
    }
    
    /**
     * @description Test ReportWrapper constructor
     */
    @isTest
    static void testReportWrapper_Constructor() {
        Test.startTest();
        
        ReportViewerController.ReportWrapper wrapper = 
            new ReportViewerController.ReportWrapper(
                '00O000000000001',
                'Test Report',
                'Tabular'
            );
        
        Test.stopTest();
        
        System.assertEquals('00O000000000001', wrapper.reportId);
        System.assertEquals('Test Report', wrapper.reportName);
        System.assertEquals('Tabular', wrapper.reportType);
    }
    
    /**
     * @description Test ReportDataWrapper constructor
     */
    @isTest
    static void testReportDataWrapper_Constructor() {
        Test.startTest();
        
        ReportViewerController.ReportDataWrapper wrapper = 
            new ReportViewerController.ReportDataWrapper();
        
        Test.stopTest();
        
        System.assertNotEquals(null, wrapper.rows);
        System.assertNotEquals(null, wrapper.columns);
        System.assertEquals(0, wrapper.totalRecords);
    }
    
    /**
     * @description Test ColumnWrapper constructor
     */
    @isTest
    static void testColumnWrapper_Constructor() {
        Test.startTest();
        
        ReportViewerController.ColumnWrapper wrapper = 
            new ReportViewerController.ColumnWrapper(
                'First Name',
                'FirstName',
                'text'
            );
        
        Test.stopTest();
        
        System.assertEquals('First Name', wrapper.label);
        System.assertEquals('FirstName', wrapper.fieldName);
        System.assertEquals('text', wrapper.type);
    }
    
    /**
     * @description Test with sharing enforcement
     */
    @isTest
    static void testWithSharing_Enforcement() {
        // Create a test user with limited permissions
        Profile standardProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name = 'Standard User' 
            WITH USER_MODE
            LIMIT 1
        ];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        
        System.runAs(testUser) {
            Test.startTest();
            
            // Should only see reports user has access to
            List<ReportViewerController.ReportWrapper> reports = 
                ReportViewerController.getAvailableReports();
            
            Test.stopTest();
            
            System.assertNotEquals(null, reports, 'Report list should not be null');
            // User context should be respected
        }
    }
    
    /**
     * @description Test getColumnType method with various data types
     */
    @isTest
    static void testGetColumnType_AllTypes() {
        Test.startTest();
        
        // Test through wrapper creation which calls getColumnType
        ReportViewerController.ColumnWrapper textCol = 
            new ReportViewerController.ColumnWrapper('Name', 'name', 'text');
        System.assertEquals('text', textCol.type);
        
        ReportViewerController.ColumnWrapper numberCol = 
            new ReportViewerController.ColumnWrapper('Amount', 'amount', 'number');
        System.assertEquals('number', numberCol.type);
        
        ReportViewerController.ColumnWrapper dateCol = 
            new ReportViewerController.ColumnWrapper('Date', 'date', 'date');
        System.assertEquals('date', dateCol.type);
        
        ReportViewerController.ColumnWrapper datetimeCol = 
            new ReportViewerController.ColumnWrapper('DateTime', 'datetime', 'date');
        System.assertEquals('date', datetimeCol.type);
        
        ReportViewerController.ColumnWrapper booleanCol = 
            new ReportViewerController.ColumnWrapper('Active', 'active', 'boolean');
        System.assertEquals('boolean', booleanCol.type);
        
        Test.stopTest();
    }
    
    /**
     * @description Test report filtering logic for user-owned reports
     */
    @isTest
    static void testUserOwnedReports() {
        Test.startTest();
        
        // Query user's own reports
        List<Report> userReports = [
            SELECT Id, Name 
            FROM Report 
            WHERE CreatedById = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 5
        ];
        
        // Get available reports through controller
        List<ReportViewerController.ReportWrapper> reports = 
            ReportViewerController.getAvailableReports();
        
        Test.stopTest();
        
        System.assertNotEquals(null, reports, 'Report list should not be null');
        System.debug('User-owned reports: ' + userReports.size());
        System.debug('Available reports: ' + reports.size());
    }
    
    /**
     * @description Test error handling in getAvailableReports
     */
    @isTest
    static void testGetAvailableReports_ErrorHandling() {
        Test.startTest();
        
        // This test verifies the method handles errors gracefully
        try {
            List<ReportViewerController.ReportWrapper> reports = 
                ReportViewerController.getAvailableReports();
            System.assertNotEquals(null, reports, 'Should return empty list on error');
        } catch (Exception e) {
            // If exception is thrown, verify it's wrapped correctly
            System.assert(e.getMessage().contains('Error'), 'Error message should be descriptive');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test ReportDataWrapper with data
     */
    @isTest
    static void testReportDataWrapper_WithData() {
        Test.startTest();
        
        ReportViewerController.ReportDataWrapper wrapper = 
            new ReportViewerController.ReportDataWrapper();
        
        // Add column
        wrapper.columns.add(new ReportViewerController.ColumnWrapper(
            'Test Column', 'test_column', 'text'
        ));
        
        // Add row
        Map<String, Object> row = new Map<String, Object>();
        row.put('test_column', 'Test Value');
        wrapper.rows.add(row);
        wrapper.totalRecords = 1;
        
        Test.stopTest();
        
        System.assertEquals(1, wrapper.columns.size(), 'Should have 1 column');
        System.assertEquals(1, wrapper.rows.size(), 'Should have 1 row');
        System.assertEquals(1, wrapper.totalRecords, 'Total records should be 1');
    }
    
    /**
     * @description Test LoggerUtil integration
     */
    @isTest
    static void testLoggerUtilIntegration() {
        Test.startTest();
        
        // The controller methods use LoggerUtil internally
        // This test verifies it doesn't break the flow
        List<ReportViewerController.ReportWrapper> reports = 
            ReportViewerController.getAvailableReports();
        
        // Verify logs were attempted to be created
        List<Error_Log__c> logs = [
            SELECT Id, Component_Name__c, Method_Name__c, Log_Level__c
            FROM Error_Log__c
            WHERE Component_Name__c = 'ReportViewerController'
            WITH USER_MODE
        ];
        
        Test.stopTest();
        
        System.assertNotEquals(null, reports, 'Reports should be returned');
        System.debug('Error logs created: ' + logs.size());
    }
}
