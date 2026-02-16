/**
 * @description Test class for LoggerUtil
 * @author Salesforce Developer
 * @date 2026
 */
@isTest
private class LoggerUtilTest {
    
    /**
     * @description Test debug logging
     */
    @isTest
    static void testDebugLogging() {
        Test.startTest();
        
        LoggerUtil.debug('TestComponent', 'testMethod', 'This is a debug message');
        LoggerUtil.flush();
        
        Test.stopTest();
        
        // Query for the created log
        List<Error_Log__c> logs = [
            SELECT Id, Component_Name__c, Method_Name__c, Error_Message__c, Log_Level__c
            FROM Error_Log__c
            WHERE Component_Name__c = 'TestComponent'
            AND Log_Level__c = 'DEBUG'
            WITH USER_MODE
        ];
        
        System.assertEquals(1, logs.size(), 'Should create one debug log');
        System.assertEquals('TestComponent', logs[0].Component_Name__c);
        System.assertEquals('testMethod', logs[0].Method_Name__c);
        System.assertEquals('This is a debug message', logs[0].Error_Message__c);
    }
    
    /**
     * @description Test info logging
     */
    @isTest
    static void testInfoLogging() {
        Test.startTest();
        
        LoggerUtil.info('TestComponent', 'testMethod', 'This is an info message');
        LoggerUtil.flush();
        
        Test.stopTest();
        
        List<Error_Log__c> logs = [
            SELECT Id, Log_Level__c, Error_Message__c
            FROM Error_Log__c
            WHERE Log_Level__c = 'INFO'
            WITH USER_MODE
        ];
        
        System.assertEquals(1, logs.size(), 'Should create one info log');
        System.assertEquals('This is an info message', logs[0].Error_Message__c);
    }
    
    /**
     * @description Test warning logging
     */
    @isTest
    static void testWarnLogging() {
        Test.startTest();
        
        LoggerUtil.warn('TestComponent', 'testMethod', 'This is a warning message');
        LoggerUtil.flush();
        
        Test.stopTest();
        
        List<Error_Log__c> logs = [
            SELECT Id, Log_Level__c, Error_Message__c
            FROM Error_Log__c
            WHERE Log_Level__c = 'WARN'
            WITH USER_MODE
        ];
        
        System.assertEquals(1, logs.size(), 'Should create one warning log');
        System.assertEquals('This is a warning message', logs[0].Error_Message__c);
    }
    
    /**
     * @description Test error logging with exception
     */
    @isTest
    static void testErrorLoggingWithException() {
        Test.startTest();
        
        try {
            Integer result = 10 / 0; // Force exception
        } catch (Exception ex) {
            LoggerUtil.error('TestComponent', 'testMethod', 'Division by zero error', ex);
        }
        
        Test.stopTest();
        
        List<Error_Log__c> logs = [
            SELECT Id, Log_Level__c, Error_Message__c, Stack_Trace__c
            FROM Error_Log__c
            WHERE Log_Level__c = 'ERROR'
            WITH USER_MODE
        ];
        
        System.assertEquals(1, logs.size(), 'Should create one error log');
        System.assert(logs[0].Error_Message__c.contains('Division by zero error'));
        System.assertNotEquals(null, logs[0].Stack_Trace__c, 'Stack trace should be captured');
    }
    
    /**
     * @description Test error logging without exception
     */
    @isTest
    static void testErrorLoggingWithoutException() {
        Test.startTest();
        
        LoggerUtil.error('TestComponent', 'testMethod', 'Generic error', null);
        
        Test.stopTest();
        
        List<Error_Log__c> logs = [
            SELECT Id, Log_Level__c, Error_Message__c, Stack_Trace__c
            FROM Error_Log__c
            WHERE Log_Level__c = 'ERROR'
            WITH USER_MODE
        ];
        
        System.assertEquals(1, logs.size(), 'Should create one error log');
        System.assertEquals('Generic error', logs[0].Error_Message__c);
        System.assertEquals(null, logs[0].Stack_Trace__c, 'Stack trace should be null');
    }
    
    /**
     * @description Test batch logging (10 logs auto-flush)
     */
    @isTest
    static void testBatchLogging() {
        Test.startTest();
        
        // Create 11 debug logs to trigger auto-flush at 10
        for (Integer i = 0; i < 11; i++) {
            LoggerUtil.debug('BatchComponent', 'batchMethod', 'Log message ' + i);
        }
        
        Test.stopTest();
        
        List<Error_Log__c> logs = [
            SELECT Id 
            FROM Error_Log__c
            WHERE Component_Name__c = 'BatchComponent'
            WITH USER_MODE
        ];
        
        // Should have at least 10 logs (batch auto-flushed)
        System.assert(logs.size() >= 10, 'Should auto-flush after 10 logs');
    }
    
    /**
     * @description Test saveLogs method directly
     */
    @isTest
    static void testSaveLogsDirectly() {
        Test.startTest();
        
        LoggerUtil.debug('Component1', 'method1', 'Message 1');
        LoggerUtil.info('Component2', 'method2', 'Message 2');
        LoggerUtil.saveLogs();
        
        Test.stopTest();
        
        List<Error_Log__c> logs = [
            SELECT Id 
            FROM Error_Log__c
            WITH USER_MODE
        ];
        
        System.assertEquals(2, logs.size(), 'Should save both logs');
    }
    
    /**
     * @description Test user ID is captured
     */
    @isTest
    static void testUserIdCapture() {
        Test.startTest();
        
        LoggerUtil.info('TestComponent', 'testMethod', 'Test message');
        LoggerUtil.flush();
        
        Test.stopTest();
        
        List<Error_Log__c> logs = [
            SELECT Id, User_Id__c
            FROM Error_Log__c
            WITH USER_MODE
        ];
        
        System.assertEquals(1, logs.size(), 'Should create one log');
        System.assertEquals(UserInfo.getUserId(), logs[0].User_Id__c, 'Should capture current user ID');
    }
    
    /**
     * @description Test multiple log levels
     */
    @isTest
    static void testMultipleLogLevels() {
        Test.startTest();
        
        LoggerUtil.debug('Component', 'method', 'Debug');
        LoggerUtil.info('Component', 'method', 'Info');
        LoggerUtil.warn('Component', 'method', 'Warning');
        
        try {
            throw new IllegalArgumentException('Test exception');
        } catch (Exception ex) {
            LoggerUtil.error('Component', 'method', 'Error', ex);
        }
        
        Test.stopTest();
        
        List<Error_Log__c> logs = [
            SELECT Id, Log_Level__c
            FROM Error_Log__c
            WITH USER_MODE
        ];
        
        System.assertEquals(4, logs.size(), 'Should create 4 logs');
        
        Set<String> logLevels = new Set<String>();
        for (Error_Log__c log : logs) {
            logLevels.add(log.Log_Level__c);
        }
        
        System.assert(logLevels.contains('DEBUG'), 'Should have DEBUG log');
        System.assert(logLevels.contains('INFO'), 'Should have INFO log');
        System.assert(logLevels.contains('WARN'), 'Should have WARN log');
        System.assert(logLevels.contains('ERROR'), 'Should have ERROR log');
    }
}
