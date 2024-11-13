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
trigger OpportunityTrigger on Opportunity (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        OpportunityTriggerHandler.beforeInsert(Trigger.new);
    }
}