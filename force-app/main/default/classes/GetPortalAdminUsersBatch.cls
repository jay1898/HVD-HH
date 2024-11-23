global class GetPortalAdminUsersBatch implements Database.Batchable<Object>, Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1]);
    }

    global void execute(Database.BatchableContext BC, List<Object> scope) {
		GetPortalAdminUsersCallout.getUsers();
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch job completed.');
        String hour = String.valueOf(Datetime.now().addHours(1).hour());
        //You can add any no of Minute you want to add to schedule it for next
        String min = String.valueOf(Datetime.now().minute());
        String ss = String.valueOf(Datetime.now().second());
        
        //parse to a cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        //Create an Instance of your Schedule Class
        GetPortalAdminUsersBatchScheduler s = new GetPortalAdminUsersBatchScheduler();
        System.schedule('Get Portal Admin Users', nextFireTime, s);
    }    
}