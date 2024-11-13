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
public with sharing class EstimateDetailTriggerHandler {

    // トリガーの有効化判定フラグ
    public static Boolean TriggerDisabled = false;

    /**
    * @description afterInsert
    * @author ItForce-bai | 2024-10-29
    * @param List<EstimateDetail__c> newList
    **/
    public static void afterInsert(List<EstimateDetail__c> newList) {
        if (EstimateDetailTriggerHandler.TriggerDisabled) {
            return;
        }
        // 見積明細の商品定価の設定
        setFieldValue(newList, null);
    }

    /**
    * @description afterUpdate
    * @author ItForce-bai | 2024-10-29
    * @param List<EstimateDetail__c> newList
    **/
    public static void afterUpdate(List<EstimateDetail__c> newList, Map<Id,EstimateDetail__c> oldMap) {
        if (EstimateDetailTriggerHandler.TriggerDisabled) {
            return;
        }
        // 見積明細の商品定価の設定
        setFieldValue(newList, oldMap);
    }

    /**
    * @description 見積明細の商品定価の設定
    * @author ItForce-bai | 2024-10-29
    * @param List<EstimateDetail__c> newList
    * @param Map<Id EstimateDetail__c> oldMap
    **/
    @AuraEnabled
    public static void setFieldValue(List<EstimateDetail__c> newList, Map<Id, EstimateDetail__c> oldMap) {
        // 商品ID
        Set<Id> productIdSet = new Set<Id>();
        // 見積明細Id、商品IdのMap
        Map<Id, Id> detailProductMap = new Map<Id, Id>();
        for (EstimateDetail__c newObj : newList) {
            productIdSet.add(newObj.ESD_ProductName__c);
            detailProductMap.put(newObj.Id, newObj.ESD_ProductName__c);
        }
        // 商品リスト
        List<ProductMaster__c> productList = [
            SELECT
                Id,
                Name,
                PM_Price__c,
                PM_ProductDescription__c,
                PM_SalesFlg__c,
                PM_ProductType__c
            FROM ProductMaster__c
            WHERE Id IN :productIdSet
        ];
        Map<Id,ProductMaster__c> productMap = new Map<Id,ProductMaster__c>(productList);

        // 見積明細更新リスト
        List<EstimateDetail__c> updateList = new List<EstimateDetail__c>();
        for (EstimateDetail__c newObj : newList) {
            EstimateDetail__c updateNew = new EstimateDetail__c();
            // 見積明細Id
            updateNew.Id = newObj.Id;
            // 商品定価
            updateNew.ESD_ProductPrice__c = productMap?.get(detailProductMap?.get(newObj.Id))?.PM_Price__c;
            updateList.add(updateNew);
        }

        if (updateList.size() > 0) {
            EstimateDetailTriggerHandler.TriggerDisabled = true;
            update updateList;
            EstimateDetailTriggerHandler.TriggerDisabled = false;
        }
    }
}