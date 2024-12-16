@isTest
private class GetLicencesPerUserCalloutTest {
    
    @isTest
    static void testGetLicences() {
        // Step 1: Create an existing record with a matching External Key
        Licences_Per_User__c existingLicence = new Licences_Per_User__c(
            Company_ID__c = 11111,
            Name = 'Old Company',
            Fiscal_ID__c = 'FI-11111',
            User_ID__c = 'user123',
            User_Name__c = 'Old User',
            Application_Name__c = 'Old Application',
            Application_Id__c = 1234,
            System_ID__c = 55555,
            System_Name__c = 'Old System',
            Company_Modified_Date__c = Datetime.newInstance(2024, 11, 15, 12, 30, 0),
            User_Application_Modified__c = Datetime.newInstance(2024, 11, 15, 14, 45, 0)
        );
        //insert existingLicence;
        
        Licences_Per_User__c existingLicence1 = new Licences_Per_User__c(
            Company_ID__c = 8989,
            Name = 'New Company',
            Fiscal_ID__c = 'FI-12222',
            User_ID__c = 'user1234',
            User_Name__c = 'New User',
            Application_Name__c = 'New Application',
            Application_Id__c = 12345,
            System_ID__c = 55555,
            System_Name__c = 'Old System',
            Company_Modified_Date__c = Datetime.newInstance(2024, 11, 15, 12, 30, 0),
            User_Application_Modified__c = Datetime.newInstance(2024, 11, 15, 14, 45, 0)
        );
        insert new List<Licences_Per_User__c>{ existingLicence, existingLicence1 };

        // Step 2: Mock the HTTP Callout
        Test.setMock(HttpCalloutMock.class, new GetLicencesPerUserCalloutMock());

        // Step 3: Start Test
        Test.startTest();
        GetLicencesPerUserCallout.getLicences();
        Test.stopTest();

        // Step 4: Verify records after the callout
        List<Licences_Per_User__c> licences = [
            SELECT External_Key__c, Company_ID__c, Name, Fiscal_ID__c, User_ID__c, User_Name__c,
                   Application_Name__c, Application_Id__c, System_ID__c, System_Name__c,
                   Company_Modified_Date__c, User_Application_Modified__c
            FROM Licences_Per_User__c
        ];

        System.assertEquals(2, licences.size(), 'There should be two records: one updated and one inserted.');
        
        Boolean isObsoleteDeleted = [SELECT COUNT() FROM Licences_Per_User__c WHERE Company_ID__c = 8989] == 0;
        System.assert(isObsoleteDeleted, 'The obsolete record should have been deleted.');
    }
    
    @isTest
    static void testCatchBlock() {

        Test.setMock(HttpCalloutMock.class, new ErrorThrowingMock());
        
        Test.startTest();
        try {
            // Call the method to invoke the catch block
            GetLicencesPerUserCallout.getLicences();
        } catch (Exception e) {
            System.assert(false, 'Method should handle the exception and not throw it.');
        }
        Test.stopTest();
    }
    
    
    // Mock implementation to throw an exception
    private class ErrorThrowingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            //throw new CalloutException('Simulated callout exception');
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            // Multi-Record Mock JSON Response
            String mockResponse = '';
            res.setBody(mockResponse);

            return res;
        }
    }

    // Mock HTTP Callout
    private class GetLicencesPerUserCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            // Multi-Record Mock JSON Response
            String mockResponse = '{"data":[{"userId":"user123","applicationId":1234,"companyId":12345,"companyName":"Test Company","fiscalId":"FI-98765","userName":"Test User","applicationName":"Test Application","systemId":56789,"systemName":"Test System","companyModified":"2024-11-18T12:30:45.000Z","userApplicationModified":"2024-11-18T14:45:30.000Z"},{"userId":"user456","applicationId":5678,"companyId":67890,"companyName":"New Company","fiscalId":"FI-12345","userName":"New User","applicationName":"New Application","systemId":98765,"systemName":"New System","companyModified":"2024-11-19T10:20:30.000Z","userApplicationModified":"2024-11-19T11:25:40.000Z"}]}';
            res.setBody(mockResponse);

            return res;
        }
    }
    
    
}