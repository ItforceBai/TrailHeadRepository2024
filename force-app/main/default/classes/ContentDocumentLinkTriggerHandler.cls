/**
 * @description       : コンテンツドキュメントリンクトリガー
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-11-12
 * @last modified by  : ItForce-bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-11-11   ItForce-bai   Initial Version
**/
public with sharing class ContentDocumentLinkTriggerHandler {
    // トリガーの有効化判定フラグ
    public static Boolean TriggerDisabled = false;

    /**
    * @description afterInsert
    * @author ItForce-bai | 2024-11-11
    * @param List<ContentDocumentLink> newList
    **/
    public static void afterInsert(List<ContentDocumentLink> newList) {
        if (EstimateDetailTriggerHandler.TriggerDisabled) {
            return;
        }

        // ファイルのステータスを更新する
        updateStatus(newList);
    }

    /**
    * @description ファイルのステータスを更新する
    * @author ItForce-bai | 2024-11-11
    * @param List<ContentDocumentLink> newList
    **/
    @AuraEnabled
    public static void updateStatus(List<ContentDocumentLink> newList) {
        // 請求IDSet
        Set<Id> requestIdSet = new Set<Id>();
        // 見積IDSet
        Set<Id> estimateIdSet = new Set<Id>();
        for (ContentDocumentLink newObj : newList) {
            // 請求オブジェクト
            if (newObj.LinkedEntityId.getSObjectType() == Request__c.getSObjectType()) {
                requestIdSet.add(newObj.LinkedEntityId);
            }
            // 見積オブジェクト
            if (newObj.LinkedEntityId.getSObjectType() == Estimate__c.getSObjectType()) {
                estimateIdSet.add(newObj.LinkedEntityId);
            }
        }

        if (requestIdSet.size() == 0 && estimateIdSet.size() == 0) {
            return;
        }

        // 請求データを更新する
        List<Request__c> requestList = [
            SELECT
                Id,
                RQ_InvoicedFlg__c
            FROM Request__c
            WHERE Id in :requestIdSet
        ];

        for (Request__c udpateObj : requestList) {
            // 請求書作成済み
            udpateObj.RQ_InvoicedFlg__c = true;
        }
        update requestList;

        // 見積データを更新する
        List<Estimate__c> estimateList = [
            SELECT
                Id,
                ES_AddFileFlg__c
            FROM Estimate__c
            WHERE Id in :estimateIdSet
        ];

        for (Estimate__c udpateObj : estimateList) {
            // 見積書添付済フラグ
            udpateObj.ES_AddFileFlg__c = true;
        }
        update estimateList;
    }
}