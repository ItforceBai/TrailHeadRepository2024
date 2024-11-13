/**
 * @description       : 請求書作成
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-11-07
 * @last modified by  : ItForce-bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-11-01   ItForce-bai   Initial Version
**/
public with sharing class CreateInvoicePdfCtrl {
    /**
    * @description 請求データを取得する
    * @author ItForce-bai | 2024-11-01
    * @param ConditionInfo conditionInfo
    * @return String
    **/
    @AuraEnabled
    public static String searchAction(ConditionInfo conditionInfo) {
        String result = '';
        Map<String, Object> resultMap = new Map<String, Object>();
        resultMap.put('ErrMsg' ,'');
        // 検索結果数量sql
        String countSql = '';
        countSql +=' SELECT COUNT()';
        countSql += getSearchSql(conditionInfo);

        Integer count = Database.countQuery(countSql);
        resultMap.put('count', count);
        // 0件
        if (count == 0) {
            result = JSON.serialize(resultMap);
            return result;
        }
        // 検索結果sql
        String sql = '';
            sql +=' SELECT Id, ';                           // Id
            sql +=' Name, ';                                // 売上請求No.
            sql +=' RQ_Account__c, ';                       // 請求先
            sql +=' RQ_Opportunity__c, ';                   // 商談
            sql +=' RQ_Opportunity__r.Name, ';              // 商談名
            sql +=' RQ_Estimate__c, ';                      // 見積
            sql +=' RQ_Estimate__r.Name, ';                 // 見積.見積名
            sql +=' RQ_InvoiceSendDate__c, ';               // 請求期日
            sql +=' RQ_RequestAmount__c, ';                 // 請求金額
            sql +=' RQ_InvoicedFlg__c ';                    // 請求書作成済み
        sql += getSearchSql(conditionInfo);
        sql += ' ORDER BY ';
        // 請求期日 昇順
        sql += ' RQ_InvoiceSendDate__c, ';
        // 見積NO. 昇順
        sql += ' RQ_Estimate__r.Name ';
        sql += ' LIMIT 200 ';

        resultMap.put('Data', Database.query(sql));

        result = JSON.serialize(resultMap);
        return result;
    }

    /**
    * @description 検索条件
    * @param ConditionInfo conditionInfo
    * @return String
    **/
    @AuraEnabled
    public static String getSearchSql(ConditionInfo conditionInfo) {
        String sql = '';
        sql += ' FROM ';
            sql += ' Request__c ';
        // 発行済含む
        if (conditionInfo.issueStatus == 'true') {
            sql += ' WHERE ';
            sql += ' (RQ_InvoicedFlg__c = true' ;
            sql += ' OR ';
            sql += ' RQ_InvoicedFlg__c = false)';
        } else {
            sql += ' WHERE ';
            sql += ' RQ_InvoicedFlg__c = false';
        }
        // 請求日(FROM) != null の場合
        if (conditionInfo.billingFromDate != null) {
            sql += ' AND ';
            sql += ' RQ_InvoiceSendDate__c >= ' + conditionInfo.billingFromDate;
        }
        // 請求日(TO) != null の場合
        if (conditionInfo.billingToDate != null) {
            sql += ' AND ';
            sql += ' RQ_InvoiceSendDate__c <= ' + conditionInfo.billingToDate;
        }
        // 請求先 != null の場合
        if (conditionInfo.billingAcc != null) {
            sql += ' AND ';
            sql += ' RQ_Account__c =' + ' \'' + conditionInfo.billingAcc.id + '\' ';
        }
        // 営業担当者
        sql += ' AND ';
        sql += ' OwnerId =' + ' \'' + UserInfo.getUserId() + '\' ';
        System.debug(sql);
        return sql;
    }

    /**
    * @description 発行状態更新
    * @param List<Id> requestIdList
    **/
    @AuraEnabled
    public static void updateRequestAction(List<Id> requestIdList) {
        List<Request__c> requestList = [
            SELECT
                ID,
                RQ_InvoicedFlg__c   // 請求書発行済（非表示）
            FROM
                Request__c
            WHERE
                ID IN: requestIdList
        ];

        for (Request__c req : requestList) {
            // 請求書発行済（非表示）
            req.RQ_InvoicedFlg__c = true;
        }
        update requestList;

    }

    /**
     * 検索条件対象
     */
    public class ConditionInfo {
        // 請求日(FROM)
        @AuraEnabled
        public String billingFromDate {get;set;}
        // 請求日(TO)
        @AuraEnabled
        public String billingToDate {get;set;}
        // 発行済含む
        @AuraEnabled
        public String issueStatus {get;set;}
        // 請求先
        @AuraEnabled
        public ObjectNameId billingAcc {get;set;}
    }

    public class ObjectNameId {
        // 名
        @AuraEnabled
        public String name {get;set;}
        // ID
        @AuraEnabled
        public String id {get;set;}
    }
}