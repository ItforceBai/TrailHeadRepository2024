/**
 * @description       : 請求書作成
 * @author            : ItForce-bai
 * @group             : ItForce
 * @last modified on  : 2024-12-18
 * @last modified by  : Itforce-Bai
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2024-11-01   ItForce-bai   Initial Version
**/
import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
// 売上請求検索
import searchHandler from '@salesforce/apex/CreateInvoicePdfCtrl.searchAction';

import * as com from 'c/commonMethod';

export default class CreateInvoicePdf extends NavigationMixin(LightningElement) {
    // ローディング
    isLoading = false;
    // 検索条件
    @track conditionInfo = {};
    // 検索結果
    @track resultList = [];
    // 検索結果件
    // title = '検索結果：0件';
    title = '検索結果';
    // 請求金額合計
    TotalRequestAmount = 0;
    // 全て選択FLG
    requestAllCheckFlg = false;
    // タブ表示フラグ
    tabShowFlg = false;
    // スクロール
    changeScroll = false;

    // 初期化
    async connectedCallback() {
        this.isLoading = true;
        this._setBillingDate('before');
        this.isLoading = false;
    }

    // 前月ボタン
    doGetBeforeMonth() {
        this._setBillingDate('before');
    }

    // 翌月ボタン
    doGetNextMonth() {
        this._setBillingDate('after');
    }

    // 検索条件変更
    doChange(event) {
        // 項目名
        let name = event.target.name;
        // 発行済含む変更
        if (name == 'issueStatus'){
            // 検索条件設定
            this.conditionInfo.issueStatus = event.target.checked ? true : false;
        }
        else {
            this.conditionInfo = {...this.conditionInfo, [name]: event.target.value};
        }
    }

    // 検索ボタンを押下
    async doSearch() {
        try {
            this.isLoading = true;
            if (this.conditionInfo.billingFromDate != null &&
                this.conditionInfo.billingToDate != null &&
                this.conditionInfo.billingFromDate > this.conditionInfo.billingToDate) {
                    com.showMessage(this, '請求日について、請求日(TO)を請求日(FROM)より、未来日で設定ください。', 'error', 'sticky');
                    return;
            }
            // 検索結果
            let data =  await searchHandler({ conditionInfo: this.conditionInfo });
            let result = JSON.parse(data);

            // 0件
            if (result.count == 0) {
                this.resultList = [];
                this.title = '検索結果：' + result.count + '件';
                this.tabShowFlg = false;
                com.showMessage(this, 'データが1件も見つかりませんでした。', 'warning', 'sticky');
            } else {
                if (result.count > 200) {
                    this.title = '検索結果：200件';
                    com.showMessage(this, result.count + '件見つかりましたが、200件以上は多すぎるため表示できません。', 'warning', 'sticky');
                } else {
                    this.title = '検索結果：' + result.count + '件';
                }
                this.tabShowFlg = true;
                //　検索結果表示内容
                this.resultList = result.Data;
                // ヘルプテキスト
                this.resultList.forEach(item => {
                    item.selectFlg = false;
                    // 商談リンク
                    item.OppLink = '/' + item.RQ_Opportunity__c;
                    // 見積リンク
                    item.EstimateLink = '/' + item.RQ_Estimate__c;
                    // 請求リンク
                    item.RequestLink = '/' + item.Id;
                })
                this.requestAllCheckFlg = false;
                // 金額クリア
                this.TotalRequestAmount = 0;
                // スクロールの調整
                if (navigator.platform.indexOf("Win") == 0) {
                    this.changeScroll = result.Data.length > 13;
                }
            }
        } catch (error) {
            com.showErrorMessage(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    // クリアボタンを押下
    doClear() {
        // 検索条件をクリア
        this.conditionInfo = {};
    }

    // 請求書プレビュー
    doPreviewPdf() {
        try{
            // 請求Id
            let requestIdList = [];
            let selectedRows = this.template.querySelectorAll('lightning-input[data-name=resultCheckBox]');
            for (let i = 0; i < selectedRows.length; i++) {
                // チェック済み
                if (selectedRows[i].checked) {
                    requestIdList.push(this.resultList[i].Id);
                }
            }
            // チェック処理
            if (requestIdList.length == 0) {
                com.showErrorMessage(this, '請求書プレビュー対象がありませんなので、請求データを選択してください。');
                return;
            }
            this.isLoading = true;
            // 請求書
            window.open('/apex/InvoicePdfPage?id=' + requestIdList);
        } catch (error) {
            com.showErrorMessage(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    // 請求書作成
    doDownloadPdf() {
        try{
            // 請求Id
            let requestIdList = [];
            let selectedRows = this.template.querySelectorAll('lightning-input[data-name=resultCheckBox]');
            for (let i = 0; i < selectedRows.length; i++) {
                // チェック済み
                if (selectedRows[i].checked) {
                    requestIdList.push(this.resultList[i].Id);
                }
            }
            // チェック処理
            if (requestIdList.length == 0) {
                com.showErrorMessage(this, '請求書作成対象がありませんなので、請求データを選択してください。');
                return;
            }
            this.isLoading = true;
            // 請求書
            // this[NavigationMixin.Navigate]({
            //     type: 'standard__webPage',
            //     attributes: {
            //         url: '/apex/InvoicePdfPage?id=' + requestIdList
            //     }
            // })
        } catch (error) {
            com.showErrorMessage(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    // 右クリック
    doSelectedRequest(event) {
        event.preventDefault();
        event.stopPropagation();
        // index
        let index = event.target.parentNode.querySelector('lightning-formatted-text[data-name=resultId]').value;
        // 印刷チェックボックス
        this.resultList[index].selectFlg = !this.resultList[index].selectFlg;
        // 請求金額
        var requestAmount = this.resultList[index].RQ_RequestAmount__c;
        if (this.resultList[index].selectFlg) {
            this.TotalRequestAmount += requestAmount;
        } else {
            this.TotalRequestAmount -= requestAmount;
        }
        // 全て選択FLGチェック
        this._requestAllCheckFlg();
    }

    // 全て選択FLGチェック
    _requestAllCheckFlg() {
        this.requestAllCheckFlg = true;
        this.resultList.forEach(item => {
            if (!item.selectFlg) {
                this.requestAllCheckFlg = false;
            }
        });
    }

    // 全チェック
    doAllSelected(event) {
        this.requestAllCheckFlg = event.target.checked;
        this.resultList.forEach(item => {
            item.selectFlg = event.target.checked;
        });
        if (event.target.checked) {
            // 金額クリア
            this.TotalRequestAmount = 0;
            // 金額合計
            this.resultList.forEach(item => {
                this.TotalRequestAmount += item.RQ_RequestAmount__c;
            })
        } else {
            // 金額クリア
            this.TotalRequestAmount = 0;
        }
    }

    // 請求日(FROM)、請求日(TO)の設定
    _setBillingDate(type) {
        var fromDate = this.conditionInfo.billingFromDate;
        var toDate = this.conditionInfo.billingToDate;
        const dateFormatter = Intl.DateTimeFormat('sv-SE');
        // 請求日(FROM)、かつ、請求日(TO) nullの場合
        if (fromDate == null && toDate == null) {
            var date = new Date();
            // 当月初日
            this.conditionInfo.billingFromDate = dateFormatter.format(new Date(date.getFullYear(), date.getMonth(), 1));
            // 当月末日
            this.conditionInfo.billingToDate = dateFormatter.format(new Date(date.getFullYear(), date.getMonth() + 1, 0));
        } else {
            var dateFrom;
            var dateTo;
            if (fromDate != null) {
                dateFrom = new Date(fromDate);
            } else {
                dateFrom = new Date(toDate);
            }
            if (toDate != null) {
                dateTo = new Date(toDate);
            } else {
                dateTo = new Date(fromDate);
            }
            if (type == 'before') {
                // 請求日(FROM)
                this.conditionInfo.billingFromDate = dateFormatter.format(new Date(dateFrom.getFullYear(), dateFrom.getMonth() - 1, 1));
                // 請求日(TO)
                this.conditionInfo.billingToDate = dateFormatter.format(new Date(dateTo.getFullYear(), dateTo.getMonth(), 0));
            } else if (type == 'after') {
                // 請求日(FROM)
                this.conditionInfo.billingFromDate = dateFormatter.format(new Date(dateFrom.getFullYear(), dateFrom.getMonth() + 1, 1));
                // 請求日(TO)
                this.conditionInfo.billingToDate = dateFormatter.format(new Date(dateTo.getFullYear(), dateTo.getMonth() + 2, 0));
            }
        }
    }
}