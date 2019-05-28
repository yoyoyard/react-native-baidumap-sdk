#import <React/RCTBridgeModule.h>
#import <BaiduMapAPI_Search/BMKSuggestionSearch.h>
#import <MapKit/MKGeometry.h>

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

- (void)onGetSuggestionResult:(BMKSuggestionSearch *)searcher result:(BMKSuggestionResult *)result errorCode:(BMKSearchErrorCode)error {
    if (error == BMK_SEARCH_NO_ERROR) {
        NSArray *keyList = result.keyList;
        NSArray *ptList = result.ptList;
        NSArray *districtList = result.districtList
        NSArray *poiIdList = result.poiIdList

        NSMutableArray *_resultList = [[NSMutableArray alloc] init];

        int i;
        for (i = 0; i < [keyList count]; i++) {
            id keyItem = [keyList objectAtIndex:i];
            id ptItem = [ptList objectAtIndex:i];
            id districtItem = [districtList objectAtIndex:i];
            id poiIdItem = [poiIdList objectAtIndex:i];

            NSString *keyString = keyItem;
            NSString *districtString = districtItem;
            NSString *poiIdString = poiIdItem;

            NSValue *ptValue = ptItem;
            CLLocationCoordinate2D ptCoordinate = ptValue.MKCoordinateValue;

            [_resultList addObject: @{
                @"key": keyString,
                @"address": @"",
                @"district": districtString,
                @"poi": poiIdString,
                @"latitude": @(ptCoordinate.latitude),
                @"longitude": @(ptCoordinate.longitude)
            }];
        }

        NSArray *resultList = [_resultList copy];
        _resultList = nil;

        _resolve(resultList);
    } else {
        // TODO: provide error message
        _reject(@"", @"", nil);
    }
}

@end
