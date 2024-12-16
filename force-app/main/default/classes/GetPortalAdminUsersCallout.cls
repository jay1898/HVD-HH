public class GetPortalAdminUsersCallout {
    
    public static void getUsers() {
        try {
            String accessToken = System.label.Portal_Admin_Access_Token;
            String endpoint = System.label.Portal_Admin_Users + '?PageSize=' + 10000 + '&OrderBy=userDbId%20desc';
            System.debug('Endpoint@@' + Endpoint);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> data = (List<Object>) jsonResponse.get('data');
                
                if (data.isEmpty()) {
                    System.debug('No data received from the API.');
                    return;
                }
                
                Set<Decimal> userDbIdsFromAPI = new Set<Decimal>();
                for (Object obj : data) {
                    Map<String, Object> dataMap = (Map<String, Object>) obj;
                    userDbIdsFromAPI.add((Decimal) dataMap.get('userDbId'));
                }
                
                // Query existing records in Salesforce
                Map<Decimal, Portal_Admin_User__c> existingUsersMap = new Map<Decimal, Portal_Admin_User__c>();
                for (Portal_Admin_User__c existingUser : [
                    SELECT Id, User_DB_Id__c, Company_Id__c, User_Id__c, User_Name__c, Name 
                    FROM Portal_Admin_User__c
                ]) {
                    existingUsersMap.put(existingUser.User_DB_Id__c, existingUser);
                }
                
                List<Portal_Admin_User__c> recordsToInsert = new List<Portal_Admin_User__c>();
                List<Portal_Admin_User__c> recordsToUpdate = new List<Portal_Admin_User__c>();
                List<Portal_Admin_User__c> recordsToDelete = new List<Portal_Admin_User__c>();
                
                // Determine records to insert or update
                for (Object obj : data) {
                    Map<String, Object> dataMap = (Map<String, Object>) obj;
                    
                    Decimal userDbId = (Decimal) dataMap.get('userDbId');
                    Portal_Admin_User__c userRecord;
                    
                    if (existingUsersMap.containsKey(userDbId)) {
                        // Update existing record
                        userRecord = existingUsersMap.get(userDbId);
                        userRecord.Company_Id__c = (Integer) dataMap.get('companyId');
                        userRecord.User_Id__c = (String) dataMap.get('userId');
                        userRecord.User_Name__c = (String) dataMap.get('userName');
                        userRecord.Name = (String) dataMap.get('companyName');
                        recordsToUpdate.add(userRecord);
                        
                        // Remove from the map so remaining records can be marked for deletion
                        existingUsersMap.remove(userDbId);
                    } else {
                        // Create new record
                        userRecord = new Portal_Admin_User__c();
                        userRecord.User_DB_Id__c = userDbId;
                        userRecord.Company_Id__c = (Integer) dataMap.get('companyId');
                        userRecord.User_Id__c = (String) dataMap.get('userId');
                        userRecord.User_Name__c = (String) dataMap.get('userName');
                        userRecord.Name = (String) dataMap.get('companyName');
                        recordsToInsert.add(userRecord);
                    }
                }
                
                // Any remaining records in the map are no longer in the API response, mark them for deletion
                recordsToDelete.addAll(existingUsersMap.values());
                
                // Perform DML operations
                if (!recordsToInsert.isEmpty()) {
                    Database.SaveResult[] insertResults = Database.insert(recordsToInsert, false);
                    handleDmlErrors(insertResults, recordsToInsert, 'Insert');
                }
                
                if (!recordsToUpdate.isEmpty()) {
                    Database.SaveResult[] updateResults = Database.update(recordsToUpdate, false);
                    handleDmlErrors(updateResults, recordsToUpdate, 'Update');
                }
                
                if (!recordsToDelete.isEmpty()) {
                    Database.DeleteResult[] deleteResults = Database.delete(recordsToDelete, false);
                    handleDmlErrors(deleteResults, recordsToDelete, 'Delete');
                }
            } else {
                System.debug('HTTP Error: ' + res.getStatus());
            }
        } 
        catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
    
    private static void handleDmlErrors(Database.SaveResult[] results, List<Portal_Admin_User__c> records, String operation) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                Database.Error err = results[i].getErrors()[0];
                System.debug(operation + ' Failed for Record: ' + records[i]);
                System.debug('Error Message: ' + err.getMessage());
            }
        }
    }
    
    private static void handleDmlErrors(Database.DeleteResult[] results, List<Portal_Admin_User__c> records, String operation) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                Database.Error err = results[i].getErrors()[0];
                System.debug(operation + ' Failed for Record: ' + records[i]);
                System.debug('Error Message: ' + err.getMessage());
            }
        }
    }
}