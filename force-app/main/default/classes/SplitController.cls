/**
 * @description       : 
 * @author            : Itforce-WangXize
 * @group             : 
 * @last modified on  : 2024-12-09
 * @last modified by  : Itforce-WangXize
**/
public with sharing class SplitController {
    public SplitController() {

    }

    @AuraEnabled
    public static List<RequestDetail__c> getRequestDetail(Id reqId) {
        List<RequestDetail__c> reqdList = [
            SELECT Name, RQD_ProductName__c, RQD_Quantity__c, RQD_Request__c, RQD_Request__r.RQ_InvoiceSendDate__c
            FROM RequestDetail__c
            WHERE RQD_Request__c = :reqId
        ];
        return reqdList;
    }
}