/**
 * @description       : 見積受注
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-10-31
 * @last modified by  : ItForce-bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-10-31   ItForce-bai   Initial Version
**/
import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import * as com from 'c/commonMethod';
import createOrderInfoAction from '@salesforce/apex/EstimateOrderCtrl.createOrderInfoAction';

export default class EstimateOrder extends LightningElement {

    @api recordId;
    isLoading = false;

    // キャンセル
    doCancel() {
        // this.dispatchEvent(new CustomEvent("closenoreflesh"));
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // 確定
    async doCommit() {
        try {
            this.isLoading = true;
            let result = await createOrderInfoAction({ 'estimateId' : this.recordId });
            if (result) {
                // 成功のメッセージが表示
                com.showMessage(this, '受注成功されました。');
                this.dispatchEvent(new CloseActionScreenEvent());
                // 受注画面に遷移するためのURL
                let newUrl = '/' + result;
                setTimeout(() => {
                    window.location.href = newUrl;
                },500)
            }
        } catch (error) {
            com.showErrorMessage(this, error);
            this.dispatchEvent(new CloseActionScreenEvent());
        } finally {
            // this.dispatchEvent(new CustomEvent("modalclose"));
            this.dispatchEvent(new CloseActionScreenEvent());
            this.isLoading = false;
        }
    }
}