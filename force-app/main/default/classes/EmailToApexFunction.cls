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

        // // メールの件名には「支払番号:PY-」が含まれています
        // if (email.subject.contains('お支払内容について(PY-')) {
            
        // }
        return new Messaging.InboundEmailresult();
    }
}