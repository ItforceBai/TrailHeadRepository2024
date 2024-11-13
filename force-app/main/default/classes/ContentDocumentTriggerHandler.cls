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
public with sharing class ContentDocumentTriggerHandler {
    // トリガーの有効化判定フラグ
    public static Boolean TriggerDisabled = false;

    /**
    * @description beforeDelete
    * @author ItForce-bai | 2024-11-11
    * @param Map<Id, ContentDocument> oldMap
    **/
    public static void beforeDelete(List<ContentDocument> oldList) {
        if (EstimateDetailTriggerHandler.TriggerDisabled) {
            return;
        }
        // ファイルID
        Set<Id> docIdSet = new Set<Id>();
        for (ContentDocument contentDocument : oldList) {
            docIdSet.add(contentDocument.Id);
        }
        // ContentDocumentLinkデータを取得する
        List<ContentDocumentLink> contentDocumentLinkList = [
            SELECT
                Id,
                LinkedEntityId,
                ContentDocumentId
            FROM
                ContentDocumentLink
            WHERE
                ContentDocumentId  =: docIdSet
        ];

        Set<Id> estimateId = new Set<Id>();
        Set<Id> requestId = new Set<Id>();
        for (ContentDocumentLink link : contentDocumentLinkList) {
            // 見積のファイル
            if (link.LinkedEntityId.getSObjectType() == Estimate__c.getSObjectType()) {
                estimateId.add(link.LinkedEntityId);
            }
            // 請求ファイル
            if (link.LinkedEntityId.getSObjectType() == Request__c.getSObjectType()) {
                requestId.add(link.LinkedEntityId);
            }
        }

        // 見積処理
        if (estimateId.size() > 0) {
            // 削除後、その以外の添付ファイルが有の見積
            List<ContentDocumentLink> otherFileList = [
                SELECT
                    Id,
                    LinkedEntityId,
                    ContentDocumentId
                FROM
                    ContentDocumentLink
                WHERE LinkedEntityId  = :estimateId
                AND ContentDocumentId != :docIdSet
            ];
            for (ContentDocumentLink otherFile : otherFileList) {
                // 添付ファイルが有の見積
                estimateId.remove(otherFile.LinkedEntityId);
            }

            // 見積.見積書添付済フラグを更新する
            if (estimateId.size() > 0) {
                List<Estimate__c> estimateList = [
                    SELECT
                        Id,
                        ES_AddFileFlg__c
                    FROM
                        Estimate__c
                    WHERE
                        Id =: estimateId
                ];

                for (Estimate__c estimate : estimateList) {
                    // 見積書添付済フラグ
                    estimate.ES_AddFileFlg__c = false;
                }
                update estimateList;
            }
        }

        // 請求処理
        if (requestId.size() > 0) {
            // 削除後、その以外の添付ファイルが有の請求
            List<ContentDocumentLink> otherFileList = [
                SELECT
                    Id,
                    LinkedEntityId,
                    ContentDocumentId
                FROM
                    ContentDocumentLink
                WHERE LinkedEntityId  = :requestId
                AND ContentDocumentId != :docIdSet
            ];
            for (ContentDocumentLink otherFile : otherFileList) {
                // 添付ファイルが有の請求
                requestId.remove(otherFile.LinkedEntityId);
            }

            // 請求.請求書作成済みを更新する
            if (requestId.size() > 0) {
                List<Request__c> requestList = [
                    SELECT
                        Id,
                        RQ_InvoicedFlg__c
                    FROM
                        Request__c
                    WHERE
                        Id =: requestId
                ];

                for (Request__c request : requestList) {
                    // 請求書作成済み
                    request.RQ_InvoicedFlg__c = false;
                }
                update requestList;
            }
        }
    }
}