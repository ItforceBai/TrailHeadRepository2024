import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export const showMessage = (that, message, type, messageData) => {
    const variant = (type ? type : 'success');
    let title;
    let mode;
    //sticky：クローズボタンを押すまで表示 pester：3秒間表示 dismissable：sticky+pester
    switch (variant) {
        case 'success': title = '成功'; mode = 'dismissable'; break;
        case 'error': title = 'エラー'; mode = 'dismissable'; break;
        case 'warning': title = '警告'; mode = 'sticky'; break;
        default: title = '情報'; mode = 'dismissable';
    }
    const evt = new ShowToastEvent({ title, message, variant, messageData, mode });
    that.dispatchEvent(evt);
}

export const showErrorMessage = (that, error) => {
    console.log(error);
    let message;
    if (typeof error === 'undefined') { 
        message = 'エラーが発生しました。システム管理者に連絡してください。'
    } else if (error instanceof Object) {
        // message = error.message || (error.body && (error.body.message + error.body.stackTrace));
        message = error.message || (error.body && error.body.message) || (error.body.pageErrors && error.body.pageErrors[0].message);
    } else {
        message = error;
    }

    const evt = new ShowToastEvent({
        title: 'エラー',
        message: message,
        variant: 'error',
        mode: 'sticky'
        //mode: 'pester' //sticky：クローズボタンを押すまで表示； pester：3秒間表示、クローズボタンなし； dismissable：sticky+pester
    });
    that.dispatchEvent(evt);
}
export const showToast = (that, title, message, type, mode) => {
    const modevalue = mode != null ? mode : "dismissable";
    const typevalue = type != null ? type : "success";
    let msg = "";
    if (typeof message === "object") {
        if (message?.body?.message) {
            msg = message.body.message;
        } else if (message?.body?.pageErrors && message?.body?.pageErrors.length > 0) {
            msg = message.body.pageErrors[0].message;
        } else if (message?.body?.fieldErrors) {
            for (var filedName in message.body.fieldErrors) {
                msg = message.body.fieldErrors[filedName][0].message;
                break;
            }
        } else {
            msg = message;
        }
    } else {
        msg = message;
    }
    if(type === "error") {
        console.error(msg);
    }
    const event = new ShowToastEvent({
        title: title,
        message: msg,
        variant: typevalue,
        mode: modevalue,
        duration: 20000
    });
    that.dispatchEvent(event);
};

export const dispatch = (that, methodName, detail) => {
    if (detail) {
        that.dispatchEvent(new CustomEvent(methodName, {detail}));
    } else {
        that.dispatchEvent(new CustomEvent(methodName));
    }
}


/**
 * @description 税抜金額と税抜金額(外貨)の計算
 * @paramter count                   数量
 * @paramter price                   単価/単価(外貨)
 * @paramter taxRate                 税率
 * @paramter taxType                 税区分
 * @paramter roundingMethod          端数処理方式
 **/
export const amountExcludeTax = (count, price, taxRate, taxType, roundingMethod) => {
    // 税抜金額 Or 税抜金額)(外貨)
    let amountExcludeTax = 0;

   //数量と税率と税区分が全記入の場合、自動計算する
    if (count && taxRate && taxType) {
       //内税の場合
        if (taxType == '内税') {
            let inTax = 1 + (parseFloat(taxRate.replace('%', '')) / 100);
            if (roundingMethod == '切り捨て') {
                amountExcludeTax = Math.floor((count * price) * 10 / (inTax * 10));
            } else if (roundingMethod == '切り上げ') {
                amountExcludeTax = Math.ceil((count * price) * 10 / (inTax * 10));
            } else if (roundingMethod == '四捨五入') {
                amountExcludeTax = Math.round((count * price) * 10 / (inTax * 10));
            } else {
                amountExcludeTax = Math.floor((count * price) * 10 / (inTax * 10));
            }
        //外税Or非課税の場合
        } else {
            amountExcludeTax = count * price;
        }
    }
    return amountExcludeTax;
}