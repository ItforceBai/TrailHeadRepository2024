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
({
    // 初期化処理
    doInit : function(component, event, helper) {
        component.set("v.isLoadSpinner", true);

        const action = component.get("c.getEstimateDetail");
        action.setParams({
            'recordId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                const estimateDetailList = response.getReturnValue();
                component.set("v.estimateDetailList", estimateDetailList);
                component.set("v.isLoadSpinner", false);
            } else {
                component.set("v.isLoadSpinner", false);
            }
        });

        $A.enqueueAction(action);
    },

    // キャンセル処理
    doCancel : function(component, event, helper) {
        const urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/lightning/r/Estimate__c/" + component.get("v.recordId") + "/view"
        });
        urlEvent.fire();
    },
    // 保存処理
    doSave : function(component, event, helper) {
        component.set("v.isLoadSpinner", true);

        const action = component.get("c.saveEstimateDetail");
        action.setParams({
            'estimateDetailList' : component.get("v.estimateDetailList")
        });
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                const result = response.getReturnValue();
                if (result === 'SUCCESS') {
                    const urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/lightning/r/Estimate__c/" + component.get("v.recordId") + "/view"
                    });
                    urlEvent.fire();
                } else {
                    component.set("v.isLoadSpinner", false);
                    const toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "エラー",
                        "message": result,
                        "type": "error"
                    });
                    toastEvent.fire();
                }
            } else {
                component.set("v.isLoadSpinner", false);
                const toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "エラー",
                    "message": "保存に失敗しました。",
                    "type": "error"
                });
                toastEvent.fire();
            }
        });

        $A.enqueueAction(action);
    }
})