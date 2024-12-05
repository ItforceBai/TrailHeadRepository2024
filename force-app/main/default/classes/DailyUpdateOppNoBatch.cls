/**
 * @description       : 毎日商談の採番Noをリセットのバッチ
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-11-28
 * @last modified by  : Itforce-Bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-11-13   ItForce-bai   Initial Version
**/
global without sharing class DailyUpdateOppNoBatch implements Schedulable {

    global void execute(SchedulableContext sc) {

        try {
            //毎日商談名採番をリセット
            DailyOpportunityNo__c wpn = null;
            try {
                wpn = [SELECT Id,No__c FROM DailyOpportunityNo__c FOR UPDATE];
            } catch(QueryException e) {
                wpn = new DailyOpportunityNo__c();
            }
            wpn.No__c = 1;
            upsert wpn;

            // 更新成功
            ToolsClass.sendSingleMail(
                'バッチ成功：白先生組織',
                '毎日商談の採番Noをリセットのバッチが実行完了しました。',
                new List<String>{'bai.yushuai@itforce.co.jp'},
                new List<Id>{ UserInfo.getUserId()},
                'bai.yushuai@itforce.co.jp'
            );

        } catch (Exception e) {
            // エラーが発生
            ToolsClass.sendSingleMail(
                'バッチ失敗：白先生組織',
                '毎日商談の採番Noをリセットのバッチが実行失敗しました。',
                new List<String>{'bai.yushuai@itforce.co.jp'},
                new List<Id>{ UserInfo.getUserId()},
                'bai.yushuai@itforce.co.jp'
            );
        }
    }

}