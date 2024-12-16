public class GetLicencesPerUserCallout {
    
    public static void getLicences() {
        try {
            Date dt = Date.today();
            Date AddDays = dt.addDays(-2);
            String formattedDate = AddDays.format();
            String Endpoint = System.label.LicencesPerUser + '?PageSize=' + 4000 + '&OrderBy=userApplicationModified%20desc';
            String accessToken = System.label.Portal_Admin_Access_Token;
            System.debug('Endpoint@@' + Endpoint);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> data = (List<Object>) jsonResponse.get('data');
                System.debug('data -->' + data);
                
                List<Licences_Per_User__c> recordsToInsert = new List<Licences_Per_User__c>();
                List<Licences_Per_User__c> recordsToUpdate = new List<Licences_Per_User__c>();
                List<Licences_Per_User__c> recordsToDelete = new List<Licences_Per_User__c>();
                Set<String> externalIds = new Set<String>();
                
                // Prepare external IDs for checking existing records
                for (Object obj : data) {
                    Map<String, Object> dataMap = (Map<String, Object>) obj;
                    String userId = (String) dataMap.get('userId');
                    String applicationId = String.valueOf((Integer) dataMap.get('applicationId'));
                    externalIds.add(userId + applicationId);
                }
                
                // Query existing records with matching external IDs
                Map<String, Licences_Per_User__c> existingRecordsMap = new Map<String, Licences_Per_User__c>();
                
                for (Licences_Per_User__c existingRecord : [
                    SELECT Id, External_Key__c
                    FROM Licences_Per_User__c
                    WHERE External_Key__c != null
                ]) {
                    existingRecordsMap.put(existingRecord.External_Key__c, existingRecord);
                }
                
                // Process API data
                for (Object obj : data) {
                    Map<String, Object> dataMap = (Map<String, Object>) obj;
                    String userId = (String) dataMap.get('userId');
                    String applicationId = String.valueOf((Integer) dataMap.get('applicationId'));
                    String externalId = userId + applicationId;

                    Licences_Per_User__c licence;
                    if (existingRecordsMap.containsKey(externalId)) {
                        // Update existing record
                        licence = existingRecordsMap.get(externalId);
                        licence.Company_ID__c = (Integer) dataMap.get('companyId');
                        licence.Name = (String) dataMap.get('companyName');
                        licence.Fiscal_ID__c = (String) dataMap.get('fiscalId');
                        licence.User_ID__c = userId;
                        licence.User_Name__c = (String) dataMap.get('userName');
                        licence.Application_Name__c = (String) dataMap.get('applicationName');
                        licence.Application_Id__c = (Integer) dataMap.get('applicationId');
                        licence.System_ID__c = (Integer) dataMap.get('systemId');
                        licence.System_Name__c = (String) dataMap.get('systemName');
                        
                        String companyModified = (String) dataMap.get('companyModified');
                        companyModified = companyModified.split('\\.')[0].replace('T', ' ');
                        licence.Company_Modified_Date__c = DateTime.valueOf(companyModified);
                        
                        String userApplicationModified = (String) dataMap.get('userApplicationModified');
                        userApplicationModified = userApplicationModified.split('\\.')[0].replace('T', ' ');
                        licence.User_Application_Modified__c = DateTime.valueOf(userApplicationModified);

                        recordsToUpdate.add(licence);

                        // Remove from map as it's being updated
                        existingRecordsMap.remove(externalId);
                    } else {
                        // Insert new record
                        licence = new Licences_Per_User__c();
                        licence.Company_ID__c = (Integer) dataMap.get('companyId');
                        licence.Name = (String) dataMap.get('companyName');
                        licence.Fiscal_ID__c = (String) dataMap.get('fiscalId');
                        licence.User_ID__c = userId;
                        licence.User_Name__c = (String) dataMap.get('userName');
                        licence.Application_Name__c = (String) dataMap.get('applicationName');
                        licence.Application_Id__c = (Integer) dataMap.get('applicationId');
                        licence.System_ID__c = (Integer) dataMap.get('systemId');
                        licence.System_Name__c = (String) dataMap.get('systemName');
                        
                        String companyModified = (String) dataMap.get('companyModified');
                        companyModified = companyModified.split('\\.')[0].replace('T', ' ');
                        licence.Company_Modified_Date__c = DateTime.valueOf(companyModified);
                        
                        String userApplicationModified = (String) dataMap.get('userApplicationModified');
                        userApplicationModified = userApplicationModified.split('\\.')[0].replace('T', ' ');
                        licence.User_Application_Modified__c = DateTime.valueOf(userApplicationModified);
                        
                        recordsToInsert.add(licence);
                    }
                }
                
                // Any records left in the map are no longer in the external system and need deletion
                recordsToDelete.addAll(existingRecordsMap.values());
                
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
                    handleDmlDeleteErrors(deleteResults, recordsToDelete, 'Delete');
                    system.debug('recordsToDelete --->'+recordsToDelete);
                }
            } else {
                System.debug('HTTP Error: ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
    
    // Handle DML Errors
    private static void handleDmlErrors(Database.SaveResult[] results, List<Licences_Per_User__c> records, String operation) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                Database.Error err = results[i].getErrors()[0];
                System.debug(operation + ' Failed for Record: ' + records[i]);
                System.debug('Error Message: ' + err.getMessage());
            }
        }
    }
    
    private static void handleDmlDeleteErrors(Database.DeleteResult[] results, List<Licences_Per_User__c> records, String operation) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                Database.Error[] errors = results[i].getErrors();
                if (errors != null && errors.size() > 0) {
                    System.debug(operation + ' Failed for Record: ' + records[i]);
                    System.debug('Error Message: ' + errors[0].getMessage());
                }
            }
        }
    }

}