/**
 * @description       : 
 * @author            : Itforce-Bai
 * @group             : ItForce
 * @last modified on  : 2024-12-18
 * @last modified by  : Itforce-Bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-12-18   Itforce-Bai   Initial Version
**/
({
    /**
     * 初期化
     * @param {*} component 
     * @param {*} event 
     * @param {*} helper 
     */
    doInit : function(component, event, helper) {
        const action = component.get("c.getRequestDetail");
        action.setParams({
            'reqId' : component.get("v.recordId")
        });
        // 現在の請求に関連するの請求明細を取得し、requestDetailListに格納する
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                const requestDetailList = response.getReturnValue();
                component.set("v.requestDetailList", requestDetailList);
                let num = 0;
                for (let i=0; i<requestDetailList.length; i++) {
                    // 請求明細の数量＝１の場合、割引回数入力不可
                    if (requestDetailList[i].RQD_Quantity__c === 1) {
                        let inpComponent = component.find("requestDetail_" + i);
                        inpComponent.set("v.disabled", true);
                        num++;
                    }
                }
                //　請求明細の数量＝1のデータのみの場合、実行ボタンを非活性化する
                if(num === requestDetailList.length-1) {
                    let saveButton = component.find("saveButton");
                    saveButton.set("v.disabled", true);
                }
            }
        });

        $A.enqueueAction(action);
    },

    /**
     * 分割回数入力後処理
     * @param {*} component 
     * @param {*} event 
     * @param {*} helper 
     * @returns 
     */
    discountsNumberBlur : function(component, event, helper) {
        let inputComponent = event.getSource();
        let oldDiscountsNumberList = component.get("v.oldDiscountsNumberList");
        // 割引回数が変更されていない場合、処理を行う必要はない
        if (inputComponent.get("v.value") === oldDiscountsNumberList[inputComponent.get("v.name")]) {
            return ;
        }
        oldDiscountsNumberList[inputComponent.get("v.name")] = inputComponent.get("v.value");
        const requestDetailList = component.get("v.requestDetailList");
        // 割引回数は、その請求の数量を超えてことはできません
        if (inputComponent.get("v.value") > requestDetailList[inputComponent.get("v.name")].RQD_Quantity__c) {
            helper.showMessage('割引回数は数量を超えてはいけません');
            inputComponent.set("v.value", '');
            return;
        }
        let newRequestComponent = component.get("v.newRequestDetailList");
        // 請求の割引回数がクリアまたは変更された場合、作成された対応の請求明細データを削除する
        if ($A.util.isEmpty(inputComponent.get("v.value")) || !$A.util.isEmpty(oldDiscountsNumberList[inputComponent.get("v.name")])) {
            for (let i = 0; i < newRequestComponent.length; i++) {
                if (newRequestComponent[i].startsWith(requestDetailList[inputComponent.get("v.name")].Name)) {
                    newRequestComponent.splice(i, 1);
                    i--;
                }
            }
            component.set("v.newRequestDetailList", newRequestComponent);
            if ($A.util.isEmpty(inputComponent.get("v.value"))) {
                component.find("saveButton").set("v.disabled", false);
                return;
            }
        }
        let num = Number(inputComponent.get("v.value")) + Number(newRequestComponent.length);
        let j = 1;
        // 対応の請求明細データを作成する
        for (let i = newRequestComponent.length; i < num; i++) {
            newRequestComponent[i] = requestDetailList[inputComponent.get("v.name")].Name + '-' + j;
            j++;
            console.log(newRequestComponent[i]);
        }
        component.set("v.newRequestDetailList", newRequestComponent);
        // 新作成の請求明細の最後の数量は入力できません
        console.log(`[name="num_${num-1}"]`);
        let numName = num-1;
        setTimeout(function() {
            console.log(component.getElement().querySelectorAll(`[name="num_${numName}"]`));
        
            component.getElement().querySelectorAll(`[name="num_${numName}"]`).forEach(function(element) {
                console.log('koko');
                console.log(element.disabled);
                element.disabled = true;
                console.log(element.disabled);
            })
        }, 1000);
        // 実行ボタンを活性化する
        let value;
        num = 0;
        for (let i = 0; i < requestDetailList.length; i++) {
            component.getElement().querySelectorAll(`[name="${i}"]`).forEach(function(element) {
                value = element.value;
            })
            console.log(value);
            if (requestDetailList[i].RQD_Quantity__c === 1) {
                num++;
                continue;
            } else if (value !== undefined && !$A.util.isEmpty(value)) {
                continue;
            } else {
                return;
            }
        }
        console.log(num);
        if (num === requestDetailList.length) {
            return;
        }
        component.find("saveButton").set("v.disabled", false);
    },

    quantitychange : function(component, event, helper) {
        console.log(event.getSource().get("v.name"));
    },

    /**
     * 実行処理
     * @param {*} component 
     * @param {*} event 
     * @param {*} helper 
     */
    save: function(component, event, helper) {
        console.log('koko');
        let newRequestDetailList = component.get("v.newRequestDetailList");
        // 数量と請求期日は入力必須です
        for (let i = 0; i < newRequestDetailList.length; i++) {
            let numInput;
            console.log(component.getElement().querySelectorAll(`[name="num_${i}"]`));
            component.getElement().querySelectorAll(`[name="num_${i}"]`).forEach(function(element) {
                console.log(11111);
                numInput = element.value;
            })
            let dateInput;
            component.getElement().querySelectorAll(`[name="date_${i}"]`).forEach(function(element) {
                dateInput = element.value;
            })
            if (numInput === undefined || $A.util.isEmpty(numInput)) {
                helper.showMessage("数量を入力してください");
                return;
            }
            if (dateInput === undefined || $A.util.isEmpty(dateInput)) {
                helper.showMessage("請求期日を入力してください");
                return;
            }
        }
    }
})