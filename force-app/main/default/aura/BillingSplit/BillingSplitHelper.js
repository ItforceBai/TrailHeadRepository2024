({
    /**
     * エラーメッセージを表示する
     * @param {*} message 
     */
    showMessage: function(message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "tilte": "Error!",
            "message": message,
            "type": "error"
        });
        toastEvent.fire();
    }
})