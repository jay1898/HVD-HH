@RestResource(urlMapping='/GetLicencesPerUser/*')
global with sharing class GetLicencesPerUserWebhook {

    @HttpPost
    global static void processLicences() {
        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;

            String requestBody = req.requestBody.toString();
            System.debug('Incoming Webhook Request Body: ' + requestBody);

            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            if (payload.containsKey('data')) {
                List<Object> data = (List<Object>) payload.get('data');
                System.debug('Extracted Data: ' + data);

                List<Licences_Per_User__c> licenceRecords = new List<Licences_Per_User__c>();
                for (Object obj : data) {
                    Map<String, Object> dataMap = (Map<String, Object>) obj;
                    System.debug('Processing Record: ' + dataMap);

                    Licences_Per_User__c licence = new Licences_Per_User__c();
                    licence.Company_ID__c = (Integer) dataMap.get('companyId');
                    licence.Name = (String) dataMap.get('companyName');
                    licence.Fiscal_ID__c = (String) dataMap.get('fiscalId');
                    licence.User_ID__c = (String) dataMap.get('userId');
                    licence.User_Name__c = (String) dataMap.get('userName');
                    licence.Application_Name__c = (String) dataMap.get('applicationName');
                    licence.System_ID__c = (Integer) dataMap.get('systemId');
                    licence.System_Name__c = (String) dataMap.get('systemName');

                    String companyModified = (String) dataMap.get('companyModified');
                    licence.Company_Modified_Date__c = parseDateTime(companyModified);

                    String userApplicationModified = (String) dataMap.get('userApplicationModified');
                    licence.User_Application_Modified__c = parseDateTime(userApplicationModified);

                    licenceRecords.add(licence);
                }

                // Save records to Salesforce
                if (!licenceRecords.isEmpty()) {
                    Database.SaveResult[] saveResults = Database.insert(licenceRecords, false);
                    handleSaveResults(saveResults, licenceRecords);
                }
            } else {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Invalid payload: Missing "data" key.');
                return;
            }

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('Licenses processed successfully.');
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }

    // Helper Method to Parse DateTime
    private static DateTime parseDateTime(String dateTimeString) {
        if (String.isNotBlank(dateTimeString)) {
            dateTimeString = dateTimeString.split('\\.')[0].replace('T', ' ');
            return DateTime.valueOf(dateTimeString);
        }
        return null;
    }

    // Helper Method to Handle Save Results
    private static void handleSaveResults(Database.SaveResult[] saveResults, List<Licences_Per_User__c> licenceRecords) {
        for (Integer i = 0; i < saveResults.size(); i++) {
            if (!saveResults[i].isSuccess()) {
                Database.Error err = saveResults[i].getErrors()[0];
                System.debug('Failed Record: ' + licenceRecords[i]);
                System.debug('Error Message: ' + err.getMessage());
            }
        }
    }
}