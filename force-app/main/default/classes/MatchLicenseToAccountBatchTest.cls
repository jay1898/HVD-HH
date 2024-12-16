@isTest
public class MatchLicenseToAccountBatchTest {
    
    @isTest
    static void testBatchJob() {
        // Step 1: Create Test Data
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(
            Name = 'Abc',
            Organisation_Number__c = '12345',
            Active__c = true,
            BillingCountry = 'Norway'
        ));
        
        testAccounts.add(new Account(
            Name = 'XYZ',
            Organisation_Number__c = '12345678',
            Active__c = true,
            BillingCountry = 'Sweden'
        ));
        insert testAccounts;
        
        List<Portal_Admin_License__c> testLicenses = new List<Portal_Admin_License__c>();
       	 testLicenses.add(new Portal_Admin_License__c(
            Fiscal_ID__c = '12345MVA',
            Name = 'Abc',
            User_Name__c = 'avc@gmail.com',
            Application_Name__c = 'Entré Office'
        ));
        
         testLicenses.add(new Portal_Admin_License__c(
            Fiscal_ID__c = 'SE12345678',
            Name = 'XYZ',
            User_Name__c = 'XYZ@gmail.com',
            Application_Name__c = 'Entré Office'
        ));
        testLicenses.add(new Portal_Admin_License__c(
            Fiscal_ID__c = 'SE12345678',
            Name = 'XYZ',
            User_Name__c = 'XYZ1@gmail.com',
            Application_Name__c = 'Entré Office Demo'
        ));
        insert testLicenses;
        
        // Step 2: Execute the Batch
        Test.startTest();
        MatchLicenseToAccountBatch batch = new MatchLicenseToAccountBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Step 3: Verify Results
        // Verify Portal_Admin_License__c records were updated with matching Account__c
        Map<String, Id> fiscalIdToAccountIdMap = new Map<String, Id>();
        for (Account acc : testAccounts) {
            fiscalIdToAccountIdMap.put(acc.FiscalId__c, acc.Id);
        }
        
        for (Portal_Admin_License__c license : [SELECT Id, Fiscal_ID__c, Account__c, Matched__c FROM Portal_Admin_License__c]) {
            if (fiscalIdToAccountIdMap.containsKey(license.Fiscal_ID__c)) {
                System.assertEquals(fiscalIdToAccountIdMap.get(license.Fiscal_ID__c), license.Account__c, 'Account__c should match');
                System.assertEquals(true, license.Matched__c, 'Matched__c should be true');
            } 
        }
        
      
    }
}