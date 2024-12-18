/**
 * @description       : 
 * @author            : Itforce-Bai
 * @group             : ItForce
 * @last modified on  : 2024-12-10
 * @last modified by  : Itforce-Bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-12-10   Itforce-Bai   Initial Version
**/
({
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
    }
})