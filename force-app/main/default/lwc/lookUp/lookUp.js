import { LightningElement, api } from 'lwc';
import showRecentViewed from '@salesforce/apex/LookUpCtrl.showRecentViewed';
import searchByCondition from '@salesforce/apex/LookUpCtrl.searchByCondition';
import updateLastReferencedDate from '@salesforce/apex/LookUpCtrl.updateLastReferencedDate';
import showAllData from '@salesforce/apex/LookUpCtrl.showAllData';

const SEARCH_DELAY = 300; // Wait 300 ms after user stops typing then, peform search

const KEY_ARROW_UP = 38;
const KEY_ARROW_DOWN = 40;
const KEY_ENTER = 13;

export default class LookUp extends LightningElement {
    // Public properties
    @api label;
    @api required;
    @api disabled;
    @api placeholder = '';
    @api errors = [];
    @api scrollAfterNItems = null;

    @api iconName;
    @api name;
    @api objectType;
    @api index;
    @api conditionField;
    @api conditionVal;
    @api conditionField2;
    @api conditionVal2;
    @api freeSqlCondition;
    @api orderby;
    @api showAllData;
    @api subColumn;
    @api mainColumn;
    @api noUseRedux = false;

    // Template properties
    loading = false;
    searchResultsLocalState = [];
    _searchResults = [];

    // Private properties
    _hasFocus = false;
    _searchTerm = '';
    _cancelBlur = false;
    _searchThrottlingTimeout;
    _curSelection = {};
    _focusedResultIndex = null;

    // PUBLIC FUNCTIONS AND GETTERS/SETTERS
    @api
    set value(initialSelection) {
        this._curSelection = initialSelection;
        this._searchTerm = '';
        this._hasFocus = false;
    }

    get value() {
        return this._curSelection;
    }

    // EVENT HANDLING
    handleFocus() {
        // Prevent action if selection is not allowed
        if (this.hasSelection()) {
            return;
        }
        this.focusSearch();
        this._hasFocus = true;
        this._focusedResultIndex = null;
    }

    handleInput(event) {
        // Prevent action if selection is not allowed
        if (this.hasSelection()) {
            return;
        }
        this.conditionSearch(event.target.value);
    }

    handleBlur() {
        // Prevent action if selection is either not allowed or cancelled
        if (this.hasSelection() || this._cancelBlur) {
            return;
        }
        this._hasFocus = false;
    }

    handleResultClick(event) {
        const recordId = event.currentTarget.dataset.recordid;
        // Save selection
        const selectedItem = this._searchResults.find((result) => result.Id === recordId);
        if (!selectedItem) {
            return;
        }
        this._curSelection = selectedItem;
        this._searchTerm = '';
        this.dispatchEvent(new CustomEvent('change', { detail: { name: this.name, value: this._curSelection, index: this.index } }));
        updateLastReferencedDate({ objectType: this.objectType, Id: this._curSelection.Id });
    }

    handleKeyDown(event) {
        if (this._focusedResultIndex === null) {
            this._focusedResultIndex = -1;
        }
        if (event.keyCode === KEY_ARROW_DOWN) {
            // If we hit 'down', select the next item, or cycle over.
            this._focusedResultIndex++;
            if (this._focusedResultIndex >= this._searchResults.length) {
                this._focusedResultIndex = 0;
                this.template.querySelector('.slds-listbox').scrollTop = 0;
            }
            if (this._focusedResultIndex > 2) {
                this.template.querySelector('.slds-listbox').scrollTop += 32;
            }
            event.preventDefault();
        } else if (event.keyCode === KEY_ARROW_UP) {
            // If we hit 'up', select the previous item, or cycle over.
            this._focusedResultIndex--;
            if (this._focusedResultIndex < 0) {
                this._focusedResultIndex = this._searchResults.length - 1;
                this.template.querySelector('.slds-listbox').scrollTop = 32 * (this._searchResults.length + 1);
            }
            if (this._focusedResultIndex < this._searchResults.length - 3) {
                this.template.querySelector('.slds-listbox').scrollTop -= 32;
            }
            event.preventDefault();
        } else if (event.keyCode === KEY_ENTER && this._hasFocus && this._focusedResultIndex >= 0) {
            // If the user presses enter, and the box is open, and we have used arrows,
            // treat this just like a click on the listbox item
            const selectedId = this._searchResults[this._focusedResultIndex].Id;
            this.template.querySelector(`[data-recordid="${selectedId}"]`).click();
            event.preventDefault();
        }
    }

    handleComboboxMouseDown(event) {
        const mainButton = 0;
        if (event.button === mainButton) {
            this._cancelBlur = true;
        }
    }

    handleComboboxMouseUp() {
        this._cancelBlur = false;
        // Re-focus to text input for the next blur event
        this.template.querySelector('input').focus();
    }

    handleClearSelection() {
        this._curSelection = undefined;
        this._hasFocus = false;
        this._searchTerm = '';
        this.dispatchEvent(new CustomEvent('change', { detail: { name: this.name, value: {}, index: this.index } }));
    }

    // INTERNAL FUNCTIONS
    async focusSearch() {
        if (this.getDropdownClass.includes('slds-is-open') || this._searchTerm != "") {
            return;
        }
        this.loading = true;
        this._searchResults = [];
        const param = {
            objectType: this.objectType,
            conditionField: this.conditionField,
            conditionVal: this.editCondition(this.conditionVal),
            conditionField2: this.conditionField2,
            conditionVal2: this.editCondition(this.conditionVal2),
            freeSqlCondition: this.freeSqlCondition,
            orderby: this.orderby
        }
        try {
            let results;
            if (this.showAllData === 'true') {
                results = await showAllData(param);
            } else {
                results = await showRecentViewed(param);
            }
            this.setSearchResults(results);
        } catch (error) {
            this.errors = [{ message: 'データ取得失敗しました。システム管理者に連絡してください。' }];
        } finally {
            // Reset the spinner
            this.loading = false;
            this._focusedResultIndex = null;
            this.template.querySelector('.slds-listbox').scrollTop = 0;
        }
    }

    conditionSearch(newSearchTerm) {
        // Apply search throttling (prevents search if user is still typing)
        if (this._searchThrottlingTimeout) {
            clearTimeout(this._searchThrottlingTimeout);
        }

        if (newSearchTerm == "") {
            this._searchTerm = "";
            this.focusSearch();
            return;
        }
        this._searchTerm = newSearchTerm;

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._searchThrottlingTimeout = setTimeout(() => {
            // Send search event if search term is long enougth
            this.loading = true;
            const param = {
                searchKeyWord: this._searchTerm,
                objectType: this.objectType,
                conditionField: this.conditionField,
                conditionVal: this.editCondition(this.conditionVal),
                conditionField2: this.conditionField2,
                conditionVal2: this.editCondition(this.conditionVal2),
                freeSqlCondition: this.freeSqlCondition,
                orderby: this.orderby
            };
            this.search(param);
            this._searchThrottlingTimeout = null;
        }, SEARCH_DELAY);
    }

    /**
     * Handles the lookup search event.
     * Calls the server to perform the search and returns the resuls to the lookup.
     */
    async search(detailInfo) {
        try {
            const results = await searchByCondition(detailInfo);
            this.setSearchResults(results);
        } catch (error) {
            this.errors = [{ message: 'データ取得失敗しました。システム管理者に連絡してください。' }];
        } finally {
            this.loading = false;
            this._focusedResultIndex = null;
            this.template.querySelector('.slds-listbox').scrollTop = 0;
        }
    }

    setSearchResults(results) {
        this._searchResults = JSON.parse(JSON.stringify(results));
        // Add local state and dynamic class to search results
        const self = this;
        this.searchResultsLocalState = this._searchResults.map((result, i) => {
            let subColumnValue = this.subColumn ? (result[this.subColumn] ? result[this.subColumn] + ' ' : '') : '';
            let mainColumnValue = this.mainColumn ? (result[this.mainColumn] ? result[this.mainColumn] : '') : result.Name;
            result = { ...result, Name: subColumnValue + mainColumnValue };
            return {
                result,
                state: {},
                get classes() {
                    let cls =
                        'slds-media slds-listbox__option slds-listbox__option_entity slds-media_center';
                    if (self._focusedResultIndex === i) {
                        cls += ' slds-has-focus';
                    }
                    return cls;
                }
            };
        });
    }

    editCondition(conditionVal) {
        return conditionVal instanceof Object ? (conditionVal.Id !== undefined ? conditionVal.Id : "") : conditionVal;
    }

    hasSelection() {
        return this._curSelection === undefined || this._curSelection.Id === undefined ? false : true;
    }

    get hasResults() {
        return this._searchResults.length > 0;
    }

    get getContainerClass() {
        let css = 'slds-combobox_container slds-has-inline-listbox ';
        if (this._hasFocus && this.hasResults) {
            css += 'slds-has-input-focus ';
        }
        if (this.errors.length > 0 || this.isShowErrorMsg) {
            css += 'has-custom-error';
        }
        return css;
    }

    get getDropdownClass() {
        let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ';
        if (this._hasFocus && !this.hasSelection()) {
            css += 'slds-is-open';
        }
        return css;
    }

    get getInputClass() {
        let css = 'slds-input slds-combobox__input has-custom-height ';
        if (this.errors.length > 0 || this.isShowErrorMsg) {
            css += ' has-custom-error ';
        }
        css += 'slds-combobox__input-value ' + (this.hasSelection() ? 'has-custom-border' : '');
        return css;
    }

    get getComboboxClass() {
        let css = 'slds-combobox__form-element slds-input-has-icon ';
        css += this.hasSelection() ? 'slds-input-has-icon_left-right' : 'slds-input-has-icon_right';
        return css;
    }

    get getSearchIconClass() {
        let css = 'slds-input__icon slds-input__icon_right ';
        css += this.hasSelection() ? 'slds-hide' : '';
        return css;
    }

    get getClearSelectionButtonClass() {
        return (
            'slds-button slds-button_icon slds-input__icon slds-input__icon_right ' +
            (this.hasSelection() ? '' : 'slds-hide')
        );
    }

    get getSelectIconClass() {
        return 'slds-combobox__input-entity-icon ' + (this.hasSelection() ? '' : 'slds-hide');
    }

    get getInputValue() {
        let val = this._searchTerm;
        if (this.hasSelection()) {
            let subColumnValue = this.subColumn ? (this._curSelection[this.subColumn] ? this._curSelection[this.subColumn] + ' ' : '') : '';
            let mainColumnValue = this.mainColumn ? (this._curSelection[this.mainColumn] ? this._curSelection[this.mainColumn] : '') : this._curSelection.Name;
            val = subColumnValue + mainColumnValue;
        }
        return val;
    }

    get getInputTitle() {
        return this.hasSelection() ? this._curSelection.Name : '';
    }

    get getListboxClass() {
        return (
            'slds-listbox slds-listbox_vertical slds-dropdown slds-dropdown_fluid slds-dropdown_left ' +
            (this.scrollAfterNItems ? 'slds-dropdown_length-with-icon-' + this.scrollAfterNItems : '')
        );
    }

    get isInputReadonly() {
        return this.hasSelection();
    }

    get isShowErrorMsg() {
        return !this._hasFocus && this._searchTerm != "" && (this._curSelection === undefined || this._curSelection.Id === undefined)
    }

    get getPaddingStyle() {
        return this.label ? '' : 'padding-left: 0%;';
    }
}