@isTest
public class GetPortalAdminUsersCalloutTest {

    @isTest
    static void testGetUsers() {

        Portal_Admin_User__c existingUser = new Portal_Admin_User__c(
            User_DB_Id__c = 27,
            Company_Id__c = 99, 
            User_Id__c = 'old.email@example.com', 
            User_Name__c = 'Old Name', 
            Name = 'Old Company Name'        
        );
        insert existingUser;

        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PortalAdminUsersCalloutMock());

       
        GetPortalAdminUsersCallout.getUsers();
        Test.stopTest();

      
        List<Portal_Admin_User__c> updatedRecords = [
            SELECT User_DB_Id__c, Company_Id__c, User_Id__c, User_Name__c, Name 
            FROM Portal_Admin_User__c
            WHERE User_DB_Id__c = 27
        ];
        System.assert(!updatedRecords.isEmpty(), 'Record should have been updated.');
        System.assertEquals(1, updatedRecords.size(), 'One record should exist.');

        
        Portal_Admin_User__c updatedUser = updatedRecords[0];
        System.assertEquals(27, updatedUser.User_DB_Id__c);
        System.assertEquals(1, updatedUser.Company_Id__c); 
        System.assertEquals('peter.qvennerstedt@hantverksdata.se', updatedUser.User_Id__c);
        System.assertEquals('Peter Qvennerstedt', updatedUser.User_Name__c);
        System.assertEquals('Hantverksdata', updatedUser.Name); 
    }

    
    public class PortalAdminUsersCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            String mockResponse = '{"count":2,"data":[{"userDbId":27,"companyId":1,"userId":"peter.qvennerstedt@hantverksdata.se","userName":"Peter Qvennerstedt","companyName":"Hantverksdata"},{"userDbId":28,"companyId":2,"userId":"new.user@hantverksdata.se","userName":"New User","companyName":"New Hantverksdata"}]}';
            res.setBody(mockResponse);
            return res;
        }
    }
}