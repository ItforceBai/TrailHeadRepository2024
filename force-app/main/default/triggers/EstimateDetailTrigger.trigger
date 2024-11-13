/**
 * @description       : 見積明細トリガー
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-10-29
 * @last modified by  : ItForce-bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-10-29   ItForce-bai   Initial Version
**/
trigger EstimateDetailTrigger on EstimateDetail__c (after insert, after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        EstimateDetailTriggerHandler.afterInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate){
        EstimateDetailTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}