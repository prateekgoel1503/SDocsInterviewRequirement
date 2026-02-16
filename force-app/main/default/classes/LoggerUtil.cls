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
     * @description Log debug message
     */
    public static void debug(String component, String method, String message) {
        log(LEVEL_DEBUG, component, method, message, null);
        System.debug(LoggingLevel.DEBUG, component + '.' + method + ': ' + message);
    }
    
    /**
     * @description Log info message
     */
    public static void info(String component, String method, String message) {
        log(LEVEL_INFO, component, method, message, null);
        System.debug(LoggingLevel.INFO, component + '.' + method + ': ' + message);
    }
    
    /**
     * @description Log warning message
     */
    public static void warn(String component, String method, String message) {
        log(LEVEL_WARN, component, method, message, null);
        System.debug(LoggingLevel.WARN, component + '.' + method + ': ' + message);
    }
    
    /**
     * @description Log error message with exception
     */
    public static void error(String component, String method, String message, Exception ex) {
        String stackTrace = ex != null ? ex.getStackTraceString() : null;
        String errorMessage = message + (ex != null ? ': ' + ex.getMessage() : '');
        
        log(LEVEL_ERROR, component, method, errorMessage, stackTrace);
        System.debug(LoggingLevel.ERROR, component + '.' + method + ': ' + errorMessage);
        
        // Auto-save error logs
        saveLogs();
    }
    
    /**
     * @description Internal method to create log record
     */
    private static void log(String level, String component, String method, String message, String stackTrace) {
        Error_Log__c errorLog = new Error_Log__c(
            Component_Name__c = component,
            Method_Name__c = method,
            Error_Message__c = message,
            Stack_Trace__c = stackTrace,
            Log_Level__c = level,
            User_Id__c = UserInfo.getUserId()
        );
        
        logsToInsert.add(errorLog);
        
        // Auto-save for non-error logs if batch size reached
        if (logsToInsert.size() >= 10 && level != LEVEL_ERROR) {
            saveLogs();
        }
    }
    
    /**
     * @description Save all pending logs to database
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
     */
    public static void flush() {
        saveLogs();
    }
}
