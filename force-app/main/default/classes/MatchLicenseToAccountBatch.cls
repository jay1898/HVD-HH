public class MatchLicenseToAccountBatch implements Database.Batchable<SObject>, Database.Stateful {
    // Map to store account ID to count mapping
    private Map<Id, Integer> accountIdToLicenseCount = new Map<Id, Integer>();

    // Query to fetch Portal_Admin_License__c records in chunks
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            [SELECT Id, Fiscal_ID__c, Account__c FROM Portal_Admin_License__c WHERE Fiscal_ID__c != NULL]
        );
    }

    // Process each batch of records
    public void execute(Database.BatchableContext context, List<Portal_Admin_License__c> scope) {
        // Collect Fiscal IDs from the current batch
        Set<String> fiscalIds = new Set<String>();
        for (Portal_Admin_License__c license : scope) {
            if (license.Fiscal_ID__c != null) {
                fiscalIds.add(license.Fiscal_ID__c);
            }
        }

        // Query Account records with matching Fiscal_ID__c
        Map<String, Id> fiscalIdToAccountIdMap = new Map<String, Id>();
        for (Account acc : [SELECT Id, FiscalId__c FROM Account WHERE FiscalId__c IN :fiscalIds]) {
            fiscalIdToAccountIdMap.put(acc.FiscalId__c, acc.Id);
        }

        // Update the AccountId__c field and track counts
        for (Portal_Admin_License__c license : scope) {
            if (license.Fiscal_ID__c != null && fiscalIdToAccountIdMap.containsKey(license.Fiscal_ID__c)) {
                Id accountId = fiscalIdToAccountIdMap.get(license.Fiscal_ID__c);
                license.Account__c = accountId;
                license.Matched__c = true;

                // Increment the count for the matched account
                if (accountIdToLicenseCount.containsKey(accountId)) {
                    accountIdToLicenseCount.put(accountId, accountIdToLicenseCount.get(accountId) + 1);
                } else {
                    accountIdToLicenseCount.put(accountId, 1);
                }
            }
        }

        // Perform the DML update for the current batch
        if (!scope.isEmpty()) {
            update scope;
			System.debug('scope>>>>>' + scope);
        }
    }

    // Finalize the batch job
    public void finish(Database.BatchableContext context) {
        if (!accountIdToLicenseCount.isEmpty()) {
            List<Account> accountsToUpdate = new List<Account>();
            for (Id accountId : accountIdToLicenseCount.keySet()) {
                accountsToUpdate.add(new Account(
                    Id = accountId,
                    Active_License_Count__c = accountIdToLicenseCount.get(accountId) // Update License Count field
                ));
            }

            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
				System.debug('accountsToUpdate' + accountsToUpdate);
            }
        }
        
        System.debug('Batch job completed.');
        String hour = String.valueOf(Datetime.now().addHours(1).hour());
        //You can add any no of Minute you want to add to schedule it for next
        String min = String.valueOf(Datetime.now().minute());
        String ss = String.valueOf(Datetime.now().second());
        
        //parse to a cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        //Create an Instance of your Schedule Class
        MatchLicenseToAccountBatchScheduler s = new MatchLicenseToAccountBatchScheduler();
        System.schedule('Update the Account And  Active License', nextFireTime, s);

       
    }
}