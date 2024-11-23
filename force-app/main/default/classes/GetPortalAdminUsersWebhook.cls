@RestResource(urlMapping='/GetPortalAdminUsers/*')
global without sharing class GetPortalAdminUsersWebhook {

    @HttpPost
    global static void processAdminUsers() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Log the incoming request body
            String requestBody = req.requestBody.toString();
            System.debug('Incoming Webhook Request Body: ' + requestBody);

            // Deserialize the incoming payload
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            // Extract user data from the payload
            if (!payload.containsKey('userDbId') || !payload.containsKey('userId') || !payload.containsKey('userName') || !payload.containsKey('companyName') || !payload.containsKey('companyId')) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Invalid payload: Missing required fields.');
                return;
            }

            // Extract data from payload
            Integer userDbId = (Integer) payload.get('userDbId');
            String userId = (String) payload.get('userId');
            Integer companyId = (Integer) payload.get('companyId');
            String userName = (String) payload.get('userName');
            String companyName = (String) payload.get('companyName');

            // Query for existing user record using userDbId to avoid duplicates
            List<Portal_Admin_User__c> existingUserRecords = [
                SELECT Id, User_Db_Id__c, User_Id__c
                FROM Portal_Admin_User__c 
                WHERE User_Db_Id__c = :userDbId LIMIT 1
            ];

            Portal_Admin_User__c userRecord;

            // If a record already exists, update it; otherwise, create a new record
            if (!existingUserRecords.isEmpty()) {
                // Record exists, retrieve the first record
                userRecord = existingUserRecords[0];
                System.debug('Existing Record Found: ' + userRecord.Id);
            } else {
                // No existing user found, create a new one
                userRecord = new Portal_Admin_User__c();
                System.debug('No existing record found. Creating new user record.');
            }

            // Update or set the fields on the user record
            userRecord.User_Db_Id__c = userDbId;
            userRecord.Company_Id__c = companyId;
            userRecord.User_Id__c = userId;
            userRecord.User_Name__c = userName;
            userRecord.Name = companyName;

            // Insert or update the record
            /*
            if (userRecord.Id == null) {
                insert userRecord; // Create a new record
                System.debug('New user record inserted: ' + userRecord.Id);
            } else {
                update userRecord; // Update the existing record
                System.debug('User record updated: ' + userRecord.Id);
            }*/
            upsert userRecord User_Db_Id__c;

            // Respond with success message
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('User processed successfully.');

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
}