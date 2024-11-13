/**
 * @description       : 見積受注
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-11-12
 * @last modified by  : ItForce-bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-10-31   ItForce-bai   Initial Version
**/
public with sharing class EstimateOrderCtrl{

    @AuraEnabled
    public static String createOrderInfoAction(String estimateId) {

        // 見積
        Estimate__c estimate = [
            SELECT
                Id                                          // Id
                ,ES_OrderDay__c                             // 受注日
                ,ES_Status__c                               // ステータス
                ,ES_OrderAmount__c                          // 受注合計額
                ,ES_TotalProductAmount__c                   // 定価合計額
                ,ES_Profits__c                              // 期待収益
                ,ES_Opportunity__r.AccountId                // 取引先名
                ,ES_Opportunity__r.Account.RequestDay__c    // 取引先.請求締日
                ,ES_Opportunity__c                          // 商談名
                ,(
                    SELECT
                        Id                                  // Id
                        ,ESD_Amount__c                      // 数量
                        ,ESD_UnitPrice__c                   // 単価
                        ,ESD_Color__c                       // カラーマスタ
                        ,ESD_Estimate__c                    // 見積
                        ,ESD_TotalPrice__c                  // 小計額
                        ,ESD_ProductName__c                 // 商品名
                        ,ESD_ProductPrice__c                // 商品定価
                        ,ESD_ProductTotalPrice__c           // 定価合計額
                    FROM estimateDetail__r
                )
            FROM Estimate__c
            WHERE Id = :estimateId
        ];

        // 受注以外の見積を取得する
        List<Estimate__c> otherEstimateList = [
            SELECT
                Id,                                 // Id
                ES_Status__c                        // ステータス
            FROM Estimate__c
            WHERE Id != :estimateId
            AND ES_Opportunity__c = :estimate.ES_Opportunity__c
        ];

        if (otherEstimateList.size() > 0) {
            for (Estimate__c otherEsObj : otherEstimateList) {
                otherEsObj.ES_Status__c = '無効';
            }
            update otherEstimateList;
        }

        // 商談更新
        Opportunity oppObj = new Opportunity();
        // Id
        oppObj.Id = estimate.ES_Opportunity__c;
        // 金額
        oppObj.Amount = estimate.ES_OrderAmount__c;
        // フェーズ
        oppObj.StageName = '受注';
        update oppObj;

        // 見積更新
        // ステータス
        estimate.ES_Status__c = '受注';
        // 受注日
        estimate.ES_OrderDay__c = System.today();
        update estimate;

        // 請求作成
        Request__c requestObj = new Request__c();
        // 見積
        requestObj.RQ_Estimate__c = estimate.Id;
        // 請求先
        requestObj.RQ_Account__c = estimate.ES_Opportunity__r.AccountId;
        // 商談
        requestObj.RQ_Opportunity__c = estimate.ES_Opportunity__c;
        // 請求期日
        String requestEndDay = estimate.ES_Opportunity__r.Account.RequestDay__c;
        if (requestEndDay == '当月末日') {
            requestObj.RQ_InvoiceSendDate__c = System.today().toStartOfMonth().addMonths(1).addDays(-1);
        } else if (requestEndDay == '次月1日') {
            requestObj.RQ_InvoiceSendDate__c = System.today().toStartOfMonth().addMonths(1);
        } else if (requestEndDay == '次月末日') {
            requestObj.RQ_InvoiceSendDate__c = System.today().toStartOfMonth().addMonths(2).addDays(-1);
        } else if (requestEndDay == '10日') {
            requestObj.RQ_InvoiceSendDate__c =
                System.today().day() > 10
                ? System.today().toStartOfMonth().addMonths(1).addDays(9)
                : System.today().toStartOfMonth().addDays(9);
        } else if (requestEndDay == '20日') {
            requestObj.RQ_InvoiceSendDate__c =
                System.today().day() > 20
                ? System.today().toStartOfMonth().addMonths(1).addDays(19)
                : System.today().toStartOfMonth().addDays(19);

        }
        insert requestObj;

        // 請求明細作成
        List<RequestDetail__c> requestDetailList = new List<RequestDetail__c>();
        for (EstimateDetail__c estimateDetail : estimate.estimateDetail__r) {
            RequestDetail__c rqDetail = new RequestDetail__c();
            // 請求
            rqDetail.RQD_Request__c = requestObj.Id;
            // 商品名
            rqDetail.RQD_ProductName__c = estimateDetail.ESD_ProductName__c;
            // 数量
            rqDetail.RQD_Quantity__c = estimateDetail.ESD_Amount__c;
            // 単価
            rqDetail.RQD_UnitPrice__c = estimateDetail.ESD_UnitPrice__c;
            // 見積明細
            rqDetail.RQD_EstimateDetail__c = estimateDetail.Id;
            requestDetailList.add(rqDetail);
        }
        if (!requestDetailList.isEmpty()) {
            insert requestDetailList;
        }

        return requestObj.Id;
    }


    private class MyException extends Exception{
    }

}