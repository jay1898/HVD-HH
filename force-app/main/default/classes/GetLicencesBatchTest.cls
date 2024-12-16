@isTest
private class GetLicencesBatchTest {

    @isTest
    static void testGetLicencesBatch() {
        // Step 1: Create a User record
       /* User testUser = new User(
            Username = 'testuserHH@example.com',
            Email = 'testuserhh@example.com',
            Alias = 'hhvbn',
            FirstName = 'Test',
            LastName = 'User',
            ProfileId = UserInfo.getProfileId(), // Default profile
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;*/

        // Step 2: Mock the HTTP Callout
        Test.setMock(HttpCalloutMock.class, new GetLicencesPerUserCalloutMock());

        // Step 3: Run the Batch
        Test.startTest();
        GetLicencesBatch batch = new GetLicencesBatch();
        Database.executeBatch(batch, 1); // Batch size of 1 for simplicity
        Test.stopTest();

        // Step 4: Verify Batch Execution
        List<AsyncApexJob> jobs = [
            SELECT Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'GetLicencesBatch'
        ];

        // Assertions for Batch Execution
        System.assertEquals(3, jobs.size(), 'The batch job should have been executed.');
 

    
    }

    // Mock Callout Class
    private class GetLicencesPerUserCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            
            // Mock JSON Response
            String mockResponse = '{"data":[{"companyId":12345,"companyName":"Test Company","fiscalId":"FI-98765","userId":"user123","userName":"Test User","applicationName":"Test Application","systemId":56789,"systemName":"Test System","companyModified":"2024-11-18T12:30:45.000Z","userApplicationModified":"2024-11-18T14:45:30.000Z"}]}';
            res.setBody(mockResponse);

            return res;
        }
    }
}