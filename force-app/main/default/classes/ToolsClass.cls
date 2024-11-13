/**
 * @description       :
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-10-29
 * @last modified by  : ItForce-bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-10-29   ItForce-bai   Initial Version
**/
public class ToolsClass {

    /*Sobject リストによって IdListを取る*/
    public static List<Id> getSObjectIdList(List<SObject> sobjectList){
        if(sobjectList == null){
            return null;
        }
        List<Id> IdList = new List<Id>();
        for (SObject sobj: sobjectList) {
            if(sobj.Id == null) continue;
            IdList.add(sobj.Id);
        }
        return IdList;
    }


    // 日付Format
    public static String DateFormat(Date myDate){
        if(myDate == null){
            myDate = Date.today();
        }
        String year = ''+myDate.year();
        String month = '' + myDate.month();
        String day = '' + myDate.day();

        if(month.length() == 1){
            month = '0' +month;
        }
        if(day.length() == 1){
            day = '0' + day;
        }
        String str = year + month + day;
        return str;
    }

    public static String DateFormat(Date myDate,String splitStr){
        if(myDate == null){
            myDate = Date.today();
        }
        String year = ''+myDate.year();
        String month = '' + myDate.month();
        String day = '' + myDate.day();

        if(month.length() == 1){
            month = '0' +month;
        }
        if(day.length() == 1){
            day = '0' + day;
        }
        String str = year + splitStr + month  + splitStr + day;
        return str;
    }

    // 日付Format
    public static String DayFormat(Date myDate){
        if(myDate == null){
            myDate = Date.today();
        }

        String month = '' + myDate.month();
        String day = '' + myDate.day();

        if(month.length() == 1){
            month = '0' +month;
        }
        if(day.length() == 1){
            day = '0' + day;
        }
        String str =  month + day;
        return str;
    }

    @AuraEnabled
    public static RecordType getRecordTypeIdByDeveloperName(String developerName){
        return [SELECT Id,Name FROM RecordType WHERE DeveloperName =: developerName];
    }

    // システム項目
    private static Set<String> SystemFields = new Set<String> { 'createddate','createdbyid','lastmodifieddate',
            'lastmodifiedbyid','systemmodstamp','isdeleted','lastactivitydate','lastvieweddate','lastreferenceddate' };
    // SOQL自動生成
    public static String getSelectAllQuery(Schema.SObjectType objType) {
        return getSelectAllQuery(objType, null);
    }
    // SOQL自動生成
    public static String getSelectAllQuery(Schema.SObjectType objType, Set<String> extraFieldName) {
        String fieldNames = getCustomFieldNames(objType);
        if(extraFieldName != null && extraFieldName.size() > 0) {
            for(String fName : extraFieldName) fieldNames += ',' + fName ;
            //fieldNames = fieldNames.substring(0, fieldNames.length() - 1);
        } return ' SELECT ' + fieldNames + ' FROM ' + objType.getDescribe().getName() + ' ';
    }
    // 引数に渡されたオブジェクトタイプのカスタムフィールド名をカンマ区切りで返す
    public static String getCustomFieldNames(Schema.SObjectType objType) {
        String fieldNames = '';
        Map<string,Sobjectfield> fieldMap = objType.getDescribe().fields.getmap();
        for (String fieldName : fieldMap.keySet()) {
            if (!SystemFields.contains(fieldName.toLowerCase())) {
                fieldNames += fieldName + ',';
            }
        } return fieldNames.substring(0, fieldNames.length() - 1);
    }

    /**
    * @description 簡単メールを送信する
    * @author ItForce-bai | 2024-10-29
    * @param String subjectName
    * @param String mailBody
    * @param String[] addressList
    * @param List<Id> userId
    * @param String sender
    **/
    public static void sendSingleMail(String subjectName,String mailBody,String[] addressList,List<Id> userId,String sender){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //件名
        mail.setSubject(subjectName);
        //内容
        mail.setPlainTextBody(mailBody);
        //送信先
        mail.setToAddresses(addressList);
        //送信元を設定する
        if(String.isNotBlank(sender)){
            mail.setReplyTo(sender);
        }
        //ユーザID への送信
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    /**
     * 全角チェック
     * @param str 文字列
     * @return true: 全角あり／false: 全角なし
     */
    public static Boolean isFullwidthExsisted(String str) {
        boolean rtn = false;
        Integer intLen = str.length();
        for (Integer i = 0; i < intLen; i++) {
            String subTmp = str.mid(i, 1);
            if (Pattern.matches('[^ -~｡-ﾟ]+', subTmp)) {
                rtn = true;
                break;
            }
        }
        return rtn;
    }

    /**
    * @description 選択リスト項目の値を取得する
    * @author ItForce-bai | 2024-10-29
    * @param String sobjectName
    * @param String fieldName
    * @return List<SelectOption>
    **/
    @AuraEnabled
    public static List<SelectOption> getPickListOptions(String sobjectName, String fieldName) {
        List<SelectOption> resultList = new List<SelectOption>();
        List<Schema.PicklistEntry> pickList = getPicklist(sobjectName, fieldName);
        if (!pickList.isEmpty()) {
            for (Schema.PicklistEntry pickObj : pickList) {
                SelectOption selectObj = new SelectOption();
                // 表示ラベル
                selectObj.label = pickObj.getLabel();
                // 値
                selectObj.value = pickObj.getValue();
                resultList.add(selectObj);
            }
        }
        return resultList;
    }

    /**
    * @description 選択肢を取得する
    * @author ItForce-bai | 2024-10-29
    * @param String sObjName
    * @param String fieldName
    * @return List<Schema.PicklistEntry>
    **/
    public static List<Schema.PicklistEntry> getPicklist(String sObjName, String fieldName) {
        List<Schema.PicklistEntry> pickList = new List<Schema.PicklistEntry>();
        Schema.SObjectType sObjType = (Schema.SObjectType) Schema.getGlobalDescribe().get(sObjName);
        if (sObjType != null) {
            Map<String, Schema.SObjectField> fieldmap = sObjType.getDescribe().fields.getMap();
            Schema.SObjectField f = (Schema.SObjectField) fieldmap.get(fieldName);
            if (f != null) {
                Schema.DescribeFieldResult r = f.getDescribe();
                if (r.getType() == Schema.DisplayType.Picklist || r.getType() == Schema.DisplayType.MultiPicklist) {
                    pickList = r.getPicklistValues();
                }
            }
        }
        return pickList;
    }

    /**
     * 画面の選択リスト対象
     */
    public class SelectOption {
        // 表示ラベル
        @AuraEnabled
        public String label { get; set; }
        // 対応の値
        @AuraEnabled
        public String value { get; set; }
    }
}