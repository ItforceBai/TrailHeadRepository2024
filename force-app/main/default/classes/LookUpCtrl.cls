/**
 * LookUpコンポーネント
 */
public with sharing class LookUpCtrl {
	@AuraEnabled (Cacheable = true)
	public static List<SObject> showRecentViewed(String objectType
	                                             , String conditionField
	                                             , String conditionVal
	                                             , String conditionField2
	                                             , String conditionVal2
	                                             , String freeSqlCondition) {
		List<SObject> recentRecordsList = new List<Account>();

		String query = generateQuery(objectType
		                             , ''
		                             , true
		                             , conditionField
		                             , conditionVal
		                             , conditionField2
		                             , conditionVal2
		                             , freeSqlCondition
		                             , '');

		if (query != '') recentRecordsList = DataBase.query(query);

		return recentRecordsList;
	}

	@AuraEnabled (Cacheable = true)
	public static List<SObject> showAllData(String objectType
	                                        , String conditionField
	                                        , String conditionVal
	                                        , String conditionField2
	                                        , String conditionVal2
	                                        , String freeSqlCondition
	                                        , String orderby) {
		List<SObject> obtainList = new List < SObject > ();

		String query = generateQuery(objectType
		                             , ''
		                             , false
		                             , conditionField
		                             , conditionVal
		                             , conditionField2
		                             , conditionVal2
		                             , freeSqlCondition
		                             , orderby);
		if (query != '') obtainList = DataBase.query(query);

		return obtainList;
	}

	@AuraEnabled (Cacheable = true)
	public static List<SObject> searchByCondition(String searchKeyWord
	                                              , String objectType
	                                              , String conditionField
	                                              , String conditionVal
	                                              , String conditionField2
	                                              , String conditionVal2
	                                              , String freeSqlCondition
	                                              , String orderby) {
		List<SObject> obtainList = new List < SObject > ();

		String query = generateQuery(objectType
		                             , searchKeyWord
		                             , false
		                             , conditionField
		                             , conditionVal
		                             , conditionField2
		                             , conditionVal2
		                             , freeSqlCondition
		                             , orderby);

		if (query != '') obtainList = DataBase.query(query);

		return obtainList;
	}

	@AuraEnabled
	public static void updateLastReferencedDate (String objectType, String Id){
		String query = ' SELECT Id FROM ' + objectType + ' WHERE Id = \'' + Id + '\' FOR REFERENCE ';
		Database.query(query);
	}

	public static String generateQuery(String objectType
	                                   , String searchKeyWord
	                                   , Boolean isLastViewed
	                                   , String conditionField
	                                   , String conditionVal
	                                   , String conditionField2
	                                   , String conditionVal2
	                                   , String freeSqlCondition
	                                   , String orderby) {
		String query = '';
		List<String> fieldList = obtainFieldList(objectType);
		String clause = obtaineClause(objectType, searchKeyWord);
		SObjectType schemaType = Schema.getGlobalDescribe().get(objectType);

		if (!fieldList.isEmpty() && schemaType.getDescribe().isAccessible()) {
			query = 'SELECT ' + String.join(fieldList, ',');
			query += ' FROM ' + objectType;
			query += ' ' + clause;

			if (isLastViewed) {  //歴史
				query += ' WHERE Id != null ';
				if (String.isNotBlank(conditionField) && String.isNotBlank(conditionVal)) {
					query += ConditionEdit(conditionField, conditionVal);
				}
				if (String.isNotBlank(conditionField2) && String.isNotBlank(conditionVal2)) {
					query += ConditionEdit(conditionField2, conditionVal2);
				}
				if (String.isNotBlank(freeSqlCondition)) {
					query += ' AND ' + freeSqlCondition;
				}
				query += ' ORDER BY LastReferencedDate DESC NULLS LAST LIMIT 5 ';

			} else {  //検索条件より
				if (searchKeyWord == '') {
					query += ' WHERE Id != null ';
				}
				if (String.isNotBlank(conditionField) && String.isNotBlank(conditionVal)) {
					query += ConditionEdit(conditionField, conditionVal);
				}
				if (String.isNotBlank(conditionField2) && String.isNotBlank(conditionVal2)) {
					query += ConditionEdit(conditionField2, conditionVal2);
				}
				if (String.isNotBlank(freeSqlCondition)) {
					query += ' AND ' + freeSqlCondition;
				}
				if (String.isNotBlank(orderby)) {
					query += ' ORDER BY ' + orderby + ' ASC NULLS LAST ';
				}
			}
		}
		return query;
	}

	private static List<String> obtainFieldList(String sObjectType) {
		SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectType);
		Map<String, SObjectField> fieldMap = schemaType.getDescribe().fields.getMap();
		SObjectType schemaTypeAccount = Schema.getGlobalDescribe().get('Account');
		Map<String, SObjectField> accountFieldMap = schemaTypeAccount.getDescribe().fields.getMap();

		List<String> fieldList = new List<String>();
		Set<String> fieldSet = new Set<String>();
		fieldSet = obtainFieldSet(sObjectType);

		if (!fieldSet.isEmpty() && schemaType.getDescribe().isAccessible()) {
			for (String field_i : fieldSet) {
				if (field_i != 'Account.Name'
				    && fieldMap.get(field_i).getDescribe().isAccessible()) {
					fieldList.add(field_i.trim());
				} else if (schemaTypeAccount.getDescribe().isAccessible()
				           && fieldMap.get('AccountId').getDescribe().isAccessible()
				           && field_i.contains('Account')
				           && fieldMap.get('AccountId').getDescribe().isAccessible()
				           && accountFieldMap.get('Name').getDescribe().isAccessible()) {
					fieldList.add(field_i.trim());
				}
			}
		}
		return fieldList;
	}

	private static Set<String> obtainFieldSet(String sObjectType) {
		Set<String> fieldSet = new Set<String>();

		sObjectType = sObjectType.toLowerCase();
		if (sObjectType == 'case') {
			fieldSet.addAll(new Set<String> {'Id', 'CaseNumber', 'Subject'});
		} else if (sObjectType == 'contract') {
			fieldSet.addAll(new Set<String> {'Id', 'ContractNumber'});
		} else if (sObjectType == 'order') {
			fieldSet.addAll(new Set<String> {'Id', 'OrderNumber'});
		} else if (sObjectType == 'orderitem') {
			fieldSet.addAll(new Set<String> {'Id', 'OrderItemNumber'});
		} else {
			fieldSet.addAll(new Set<String> {'Id', 'Name'});
		}

		if (sObjectType == 'contact' || sObjectType == 'user' ) {
			fieldSet.addAll(new Set<String> {'FirstName', 'LastName'});
		} else if (sObjectType == 'contact' || sObjectType == 'order' || sObjectType == 'contract') {
			fieldSet.add('Account.Name');
		} else if (sObjectType == 'lead') {
			fieldSet.addAll(new Set<String> {'FirstName', 'LastName', 'Title'});
		} else if (sObjectType == 'product2') {
			fieldSet.add('ProductCode');
		} else if (sObjectType == 'Account') {
			fieldSet.add('Id');
			fieldSet.add('Name');
		}

		return fieldSet;
	}

	private static String obtaineClause (String sObjectType, String searchKeyWord) {
		String clause = '', searchKey = '';

		if (searchKeyWord != null && searchKeyWord != '') {
			searchKey = '%' + searchKeyWord + '%';
			if (sObjectType.toLowerCase() == 'case') {
				clause += ' WHERE CaseNumber Like \'' + searchKey + '\' OR Subject Like \'' + searchKey + '\'';
			} else if (sObjectType.toLowerCase() == 'user') {
				clause += ' WHERE Name Like \'' + searchKey + '\' OR FirstName Like \'' + searchKey + '\' OR LastName Like \'' + searchKey + '\'';
			} else if (sObjectType.toLowerCase() == 'lead') {
				clause += ' WHERE Name Like \'' + searchKey + '\' OR Title Like \'' + searchKey + '\' OR FirstName Like\'' + searchKey + '\' OR LastName Like\'' + searchKey + '\'';
			} else if (sObjectType.toLowerCase() == 'product2') {
				clause += ' WHERE Name Like \'' + searchKey + '\' OR ProductCode Like \'' + searchKey + '\'';
			} else if (sObjectType.toLowerCase() == 'contract') {
				clause += ' WHERE ContractNumber Like \'' + searchKey + '\' OR Account.Name Like \'' + searchKey + '\'';
			} else {
				clause += ' WHERE Name Like \'' + searchKey + '\'';
			}
		}
		return clause;
	}

	private static String ConditionEdit(String field, String condition) {
		String result ='';
		if (condition.toLowerCase() == 'true' || condition.toLowerCase() == 'false') {
			result = ' AND ' + field +' = ' + condition + ' ';
		} else {
			result = ' AND ' + field +' = \'' + condition + '\' ';
		}
		return result;
	}
}