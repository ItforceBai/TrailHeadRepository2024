/**
 * @description       : コンテンツドキュメントトリガー
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-11-13
 * @last modified by  : ItForce-bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-11-11   ItForce-bai   Initial Version
**/
trigger ContentDocumentTrigger on ContentDocument (before delete, after delete) {
    if (Trigger.isBefore && Trigger.isDelete) {
        ContentDocumentTriggerHandler.beforeDelete(Trigger.old);
    }
}