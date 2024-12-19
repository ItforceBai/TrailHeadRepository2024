/**
 * @description       : 請求書
 * @author            : Itforce-bai
 * @group             : ITF
 * @last modified on  : 2024-12-19
 * @last modified by  : Itforce-Bai
**/
public with sharing class InvoicePdfPageCtrl {

    // 画面用
    public List<Request__c> requestList { get; set; }

    public InvoicePdfPageCtrl() {
        // 請求ID
        String requestIds = ApexPages.currentPage().getParameters().get('id');
        // 請求IDセット
        List<Id> requestIdsList = new List<Id>();
        requestIdsList.addAll(requestIds.split(','));
        // 請求情報取得
        List<Request__c> requestList = [
            SELECT
                Id,
                Name,
                RQ_Account__c,
                RQ_BillingSplitFlg__c,
                RQ_Estimate__c,
                RQ_InvoicedFlg__c,
                RQ_InvoiceSendDate__c,
                RQ_Opportunity__c,
                RQ_RequestAmount__c,
                // 請求明細情報取得
                (
                    SELECT
                        Id,
                        Name,
                        RQD_EstimateDetail__c,
                        RQD_ProductName__r.Name,
                        RQD_Quantity__c,
                        RQD_Request__c,
                        RQD_RequestAmount__c,
                        RQD_UnitPrice__c
                    FROM RequestDetail__r
                )
            FROM Request__c
            WHERE Id = :requestIdsList];
        // 請求情報セット
        this.requestList = requestList;
    }
}