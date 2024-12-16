global class MatchLicenseToAccountBatchScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new MatchLicenseToAccountBatch());
        
        System.abortJob(sc.getTriggerId());
    }

}