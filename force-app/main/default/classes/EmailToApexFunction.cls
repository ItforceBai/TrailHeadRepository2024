/**
 * @description       : メールサービス用
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-11-13
 * @last modified by  : ItForce-bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-11-13   ItForce-bai   Initial Version
**/
global with sharing class EmailToApexFunction implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        // メール内容
        System.debug(email);
        // 確定コードを取得
        if (String.isNotBlank(email.plainTextBody) && email.plainTextBody.contains('にメールを自動転送するリクエストがありました。')) {

            // ケースを作成
            Case codeCase = new Case();
            // 状況
            codeCase.Status = 'New';
            // 発生源
            codeCase.Origin = 'Email';
            // 説明
            codeCase.Description = email.plainTextBody;
            // 件名
            codeCase.Subject = email.subject;
            insert codeCase;
        }

        // メールの件名には【白先生】が含まれています
        if (email.subject.contains('【白先生】')) {
            // 送信者の取引先
            Account oppAcc = null;
            // 送信者の取引先を取得する
            List<Account> accList = [
                SELECT
                    ID,
                    Name,
                    Email__c
                FROM Account
                WHERE Email__c = :email.fromAddress     // 送信者
            ];

            if (accList.size() == 0) {
                Account newAcc = new Account();
                // 取引先名
                newAcc.Name = email.fromName;
                // メール
                newAcc.Email__c = email.fromAddress;
                // 請求締日
                newAcc.RequestDay__c = '当月末日';
                insert newAcc;
                oppAcc = newAcc;
            } else {
                oppAcc = accList[0];
            }

            // ケースを作成
            Case codeCase = new Case();
            // Web メール
            codeCase.SuppliedEmail = email.fromName;
            // 状況
            codeCase.Status = 'New';
            // 発生源
            codeCase.Origin = 'Email';
            // 説明
            codeCase.Description = email.plainTextBody;
            // 件名
            codeCase.Subject = email.subject;
            insert codeCase;

            // 商談を新規
            Opportunity newOpp = new Opportunity();
            // 商談名
            newOpp.Name = email.fromName;
            // 取引先
            newOpp.AccountId = oppAcc.Id;
            // フェーズ
            newOpp.StageName = '商談開始';
            // 完了予定日
            newOpp.CloseDate = System.today().toStartOfMonth().addMonths(1).addDays(-1);
            // 説明
            newOpp.Description = email.plainTextBody;
            // 関連ケース
            newOpp.Case__c = codeCase.Id;
            insert newOpp;
        }

        return new Messaging.InboundEmailresult();
    }
}