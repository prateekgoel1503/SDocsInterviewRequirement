/**
 * @description Centralized logging utility for Report Viewer application
 * @author Salesforce Developer
 * @date 2026
 */
public class LoggerUtil {
    
    // Constants for log levels
    private static final String LEVEL_DEBUG = 'DEBUG';
    private static final String LEVEL_INFO = 'INFO';
    private static final String LEVEL_WARN = 'WARN';
    private static final String LEVEL_ERROR = 'ERROR';
    
    // Store logs in memory for batch insert
    private static List<Error_Log__c> logsToInsert = new List<Error_Log__c>();
    
    /**
     * @description Log debug message (async for cacheable methods)
     */
    public static void debug(String component, String method, String message) {
        System.debug(LoggingLevel.DEBUG, component + '.' + method + ': ' + message);
        logAsync(LEVEL_DEBUG, component, method, message, null);
    }
    
    /**
     * @description Log info message (async for cacheable methods)
     */
    public static void info(String component, String method, String message) {
        System.debug(LoggingLevel.INFO, component + '.' + method + ': ' + message);
        logAsync(LEVEL_INFO, component, method, message, null);
    }
    
    /**
     * @description Log warning message (async for cacheable methods)
     */
    public static void warn(String component, String method, String message) {
        System.debug(LoggingLevel.WARN, component + '.' + method + ': ' + message);
        logAsync(LEVEL_WARN, component, method, message, null);
    }
    
    /**
     * @description Log error message with exception (async for cacheable methods)
     */
    public static void error(String component, String method, String message, Exception ex) {
        String stackTrace = ex != null ? ex.getStackTraceString() : null;
        String errorMessage = message + (ex != null ? ': ' + ex.getMessage() : '');
        
        System.debug(LoggingLevel.ERROR, component + '.' + method + ': ' + errorMessage);
        logAsync(LEVEL_ERROR, component, method, errorMessage, stackTrace);
    }
    
    /**
     * @description Async method to save logs (called from cacheable methods)
     */
    @future
    public static void logAsync(String level, String component, String method, String message, String stackTrace) {
        try {
            Error_Log__c errorLog = new Error_Log__c(
                Component_Name__c = component,
                Method_Name__c = method,
                Error_Message__c = message,
                Stack_Trace__c = stackTrace,
                Log_Level__c = level,
                User_Id__c = UserInfo.getUserId()
            );
            
            Database.insert(errorLog, false);
            System.debug(LoggingLevel.INFO, 'LoggerUtil: Async log saved');
        } catch (Exception e) {
            // If logging fails, just output to debug log
            System.debug(LoggingLevel.ERROR, 'LoggerUtil: Failed to save async log - ' + e.getMessage());
        }
    }
    
    /**
     * @description Sync method to save logs (for non-cacheable methods)
     */
    public static void saveLogs() {
        if (logsToInsert.isEmpty()) {
            return;
        }
        
        try {
            // Use separate try-catch to avoid recursive logging
            Database.insert(logsToInsert, false);
            System.debug(LoggingLevel.INFO, 'LoggerUtil: Saved ' + logsToInsert.size() + ' logs');
            logsToInsert.clear();
        } catch (Exception e) {
            // If logging fails, just output to debug log
            System.debug(LoggingLevel.ERROR, 'LoggerUtil: Failed to save logs - ' + e.getMessage());
            logsToInsert.clear();
        }
    }
    
    /**
     * @description Manually flush logs (call at end of transaction)
     * Note: This won't work in cacheable methods, use async methods instead
     */
    public static void flush() {
        // For cacheable methods, logs are already saved asynchronously
        // This is a no-op to maintain backward compatibility
        System.debug(LoggingLevel.INFO, 'LoggerUtil: flush() called (async logging active)');
    }
}
