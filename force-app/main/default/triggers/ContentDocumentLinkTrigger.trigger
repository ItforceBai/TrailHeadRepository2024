/**
 * @description       : コンテンツドキュメントリンクトリガー
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-11-11
 * @last modified by  : ItForce-bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-11-11   ItForce-bai   Initial Version
**/
trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert, after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ContentDocumentLinkTriggerHandler.afterInsert(Trigger.new);
    }
}