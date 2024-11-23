@isTest
private class GetPortalAdminUsersBatchTest {
    
    @isTest
    static void testBatchJob() {
        // Step 1: Setup - Create a User record to be processed by the batch
        User testUser = new User(
            Username = 'testuserHH@example.com',
            Email = 'testuserhh@example.com',
            Alias = 'hhvbn',
            FirstName = 'Test', // Add First Name
            LastName = 'User',  // Add Last Name
            ProfileId = UserInfo.getProfileId(), // Default profile
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        // Step 2: Mock the HTTP Callout
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PortalAdminUsersCalloutMock());
        
        // Step 3: Execute the Batch
        GetPortalAdminUsersBatch batch = new GetPortalAdminUsersBatch();
        Database.executeBatch(batch, 1); // Batch size of 1 for testing
        Test.stopTest();
        
        // Step 4: Verify that the batch ran and processed correctly
        List<AsyncApexJob> jobs = [
            SELECT Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'GetPortalAdminUsersBatch'
        ];
        
        // Assert the batch job status
        System.assertEquals(3, jobs.size(), 'The batch job should have run.');
       // System.assertEquals('Completed', jobs[0].Status, 'The batch job should be completed.');
        
        
    }
    
    
    // Mock the HttpCallout class used in the batch
    public class PortalAdminUsersCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Simulate a successful HTTP response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            String mockResponse = '{"count":1,"data":[{"userDbId":27,"companyId":1,"userId":"peter.qvennerstedt@hantverksdata.se","userName":"Peter Qvennerstedt","companyName":"Hantverksdata"}]}';
            res.setBody(mockResponse);
            return res;
        }
    }
}