global class GetPortalAdminUsersBatchScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new GetPortalAdminUsersBatch());
        
        System.abortJob(sc.getTriggerId());
    }
}