/**
 * @description       : 商談トリガー
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-11-13
 * @last modified by  : ItForce-bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-11-13   ItForce-bai   Initial Version
**/
public with sharing class OpportunityTriggerHandler {
    // トリガーの有効化判定フラグ
    public static Boolean TriggerDisabled = false;

    /**
    * @description beforeInsert処理
    * @author ItForce-bai | 2024-11-13
    * @param List<Opportunity> newList
    **/
    public static void beforeInsert(List<Opportunity> newList) {

        // 商談名を更新
        oppNameReset(newList);
    }

    /**
    * @description 商談名を更新
    * @author ItForce-bai | 2024-11-13
    * @param List<Opportunity> newList
    **/
    @AuraEnabled
    public static void oppNameReset(List<Opportunity> newList) {
        Date today = Date.today();
        // 年
        String year = '' + today.year();
        year = year.substring(2);
        // 月
        String month = '' + today.month();
        if (month.length() == 1) {
            month = '0' + month;
        }
        // 日
        String day = '' + today.day();
        if (day.length() == 1) {
            day = '0' + day;
        }
        String num = year + month + day;

        // 毎日商談採番No
        DailyOpportunityNo__c oppNoObj = [
            SELECT Id,
                No__c
            FROM DailyOpportunityNo__c
            FOR UPDATE
        ];
        for (Opportunity newObj : newList) {
            // 商談名
            newObj.Name = num + '-' + String.valueOf(oppNoObj.No__c).leftPad(3, '0') + '-' + newObj.Name;
            oppNoObj.No__c++;
        }
        // 毎日商談採番Noを更新する
        update oppNoObj;
    }
}