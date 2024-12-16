global class GetLicencesBatchScheduler implements Schedulable {
    //global String cronExp = '0 02 * * * ?';
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new GetLicencesBatch());
        
        System.abortJob(sc.getTriggerId());
    }
}