/**
 * @description       : 毎日商談の採番Noをリセットのバッチ
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-11-13
 * @last modified by  : ItForce-bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-11-13   ItForce-bai   Initial Version
**/
global without sharing class DailyUpdateOppNoBatch implements Schedulable {

    global void execute(SchedulableContext sc) {

        //毎日商談名採番をリセット
        DailyOpportunityNo__c wpn = null;
        try {
            wpn = [SELECT Id,No__c FROM DailyOpportunityNo__c FOR UPDATE];
        } catch(QueryException e) {
            wpn = new DailyOpportunityNo__c();
        }
        wpn.No__c = 1;
        upsert wpn;
    }

}