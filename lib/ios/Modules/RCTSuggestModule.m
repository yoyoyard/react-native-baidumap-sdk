#import <React/RCTBridgeModule.h>
#import <BaiduMapAPI_Search/BMKSuggestionSearch.h>

@interface RCTSuggestModule : NSObject <RCTBridgeModule, BMKSuggestionSearchDelegate>
@end

@implementation RCTSuggestModule {
    BMKSuggestionSearch *_search;
    RCTPromiseResolveBlock _resolve;
    RCTPromiseRejectBlock _reject;
}

RCT_EXPORT_MODULE(BaiduMapSuggest)

RCT_EXPORT_METHOD(requestSuggestion:(NSString *)keyword
                    city:(NSString *)city
      searchWithResolver:(RCTPromiseResolveBlock)resolve
                rejecter:(RCTPromiseRejectBlock)reject) {
    BMKSuggestionSearchOption *option = [BMKSuggestionSearchOption new];
    option.cityname = city;
    option.keyword = keyword;
    _resolve = resolve;
    _reject = reject;
    if (!_search) {
        _search = [BMKSuggestionSearch new];
        _search.delegate = self;
    }
    [_search suggestionSearch:option];
}

- (void)onGetSuggestionResult:(BMKSuggestionSearch *)searcher result:(BMKSuggestionSearchResult *)result errorCode:(BMKSearchErrorCode)error {
    if (error == BMK_SEARCH_NO_ERROR) {
        NSArray *list = result.suggestionList;
        NSMutableArray *_resultList;

        int i;
        for (i = 0; i < [list count]; i++) {
            id result = [list objectAtIndex:i];

            [resultList add: @{
                @"key": result.key,
                @"address": result.address,
                @"latitude": @(result.location.latitude),
                @"longitude": @(result.location.longitude)
            }]
        }

        NSArray *resultList = [_resultList copy];

        _resolve(resultList);
    } else {
        // TODO: provide error message
        _reject(@"", @"", nil);
    }
}

@end
