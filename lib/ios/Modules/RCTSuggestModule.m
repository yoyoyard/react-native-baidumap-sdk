#import <React/RCTBridgeModule.h>
#import <BaiduMapAPI_Search/BMKSuggestionSearch.h>
#import <BaiduMapAPI_Search/BMKPoiSearch.h>
#import <MapKit/MKGeometry.h>

@interface RCTSuggestModule : NSObject <RCTBridgeModule, BMKSuggestionSearchDelegate, BMKPoiSearchDelegate>
@end

@implementation RCTSuggestModule {
    BMKSuggestionSearch *_search;
    BMKPoiSearch *_poiSearch;
    RCTPromiseResolveBlock _resolve;
    RCTPromiseRejectBlock _reject;
    BMKSuggestionResult *_suggestResult;
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

    if (!_poiSearch) {
      _poiSearch = [BMKPoiSearch new];
      _poiSearch.delegate = self;
    }
    if (!_search) {
        _search = [BMKSuggestionSearch new];
        _search.delegate = self;
    }
    [_search suggestionSearch:option];
}

- (void)requestForPoiDetail:(NSArray *)uids {
    BMKPOIDetailSearchOption *option = [BMKPOIDetailSearchOption new];
    option.poiUIDs = uids;
    option.scope = 2;
    [_poiSearch poiDetailSearch:option];
}

- (void)onGetSuggestionResult:(BMKSuggestionSearch *)searcher result:(BMKSuggestionResult *)result errorCode:(BMKSearchErrorCode)error {
    if (error == BMK_SEARCH_NO_ERROR) {
        NSArray *uidList = result.poiIdList;
        if ([uidList count] == 0) {
          _resolve(uidList);
        }
        else {
          _suggestResult = result;
          [self requestForPoiDetail:uidList];
        }
    } else {
        // TODO: provide error message
        _reject(@"", @"", nil);
    }
}


- (void) onGetPoiDetailResult:(BMKPoiSearch *)searcher
                       result:(BMKPOIDetailSearchResult *)result
                    errorCode:(BMKSearchErrorCode)error {
    if (error == BMK_SEARCH_NO_ERROR) {
      NSArray *poiInfoList = result.poiInfoList;

      NSArray *keyList = _suggestResult.keyList;
      NSArray *ptList = _suggestResult.ptList;
      NSArray *districtList = _suggestResult.districtList;
      NSArray *cityList = _suggestResult.cityList;

      NSMutableArray *_resultList = [[NSMutableArray alloc] init];

      int i;
      for (i = 0; i < [keyList count]; i++) {
          id keyItem = [keyList objectAtIndex:i];
          id ptItem = [ptList objectAtIndex:i];
          id districtItem = [districtList objectAtIndex:i];
          id poiInfoItem = [poiInfoList objectAtIndex:i];
          id cityItem = [cityList objectAtIndex:i];

          BMKPoiInfo *poiInfo = poiInfoItem;
          NSString *tag = poiInfo.detailInfo.tag;
          if (!tag) tag = @"";

          NSValue *ptValue = ptItem;
          CLLocationCoordinate2D ptCoordinate = ptValue.MKCoordinateValue;

          [_resultList addObject: @{
              @"key": keyItem,
              @"city": cityItem,
              @"tag": tag,
              @"district": districtItem,
              @"latitude": @(ptCoordinate.latitude),
              @"longitude": @(ptCoordinate.longitude)
          }];
      }

      NSArray *resultList = [_resultList copy];
      _resultList = nil;
      _suggestResult = nil;

      _resolve(resultList);
    } else {
        // TODO: provide error message
        _reject(@"", @"", nil);
    }
}
@end
