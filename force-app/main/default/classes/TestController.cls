/**
 * @description       : 
 * @author            : Itforce-Bai
 * @group             : ItForce
 * @last modified on  : 2024-12-19
 * @last modified by  : Itforce-Bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-12-10   Itforce-Bai   Initial Version
**/
public with sharing class TestController {

    /**
    * @description 見積明細データを取得する
    * @author Itforce-Bai | 2024-12-10
    * @param Id recordId 見積Id
    * @return List<EstimateDetail__c> 見積明細リスト
    **/
    @AuraEnabled
    public static List<EstimateDetail__c> getEstimateDetail(Id recordId) {
        List<EstimateDetail__c> esdList = [
            SELECT
                Id,
                Name,
                ESD_Amount__c,
                ESD_UnitPrice__c,
                ESD_TotalPrice__c,
                ESD_Memo__c

            FROM EstimateDetail__c
            WHERE ESD_Estimate__c = :recordId
        ];
        return esdList;
    }
}