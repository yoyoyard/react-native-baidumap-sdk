"use strict";
exports.__esModule = true;
var react_native_1 = require("react-native");
var BaiduMapSuggest = react_native_1.NativeModules.BaiduMapSuggest;
exports["default"] = {
    search: function (keyword, city) {
        if (city === void 0) { city = ""; }
        return BaiduMapSuggest.requestSuggestion(keyword, city);
    }
};
