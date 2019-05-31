#import <React/RCTBridgeModule.h>
#import <BaiduMapAPI_Search/BMKSuggestionSearch.h>
#import <BaiduMapAPI_Search/BMKPoiSearch.h>
#import <MapKit/MKGeometry.h>
#import <React/RCTLog.h>
#import <Foundation/Foundation.h>
#import <React/RCTEventEmitter.h>

@interface RCTSuggestModule : RCTEventEmitter <RCTBridgeModule, BMKSuggestionSearchDelegate, BMKPoiSearchDelegate>
@end

@implementation RCTSuggestModule {
    BMKSuggestionSearch *_search;
    BMKPoiSearch *_poiSearch;
    BMKSuggestionResult *_suggestResult;
}

RCT_EXPORT_MODULE(BaiduMapSuggest)

RCT_EXPORT_METHOD(requestSuggestion:(NSString *)keyword
                    city:(NSString *)city) {
    BMKSuggestionSearchOption *option = [BMKSuggestionSearchOption new];
    option.cityname = city;
    option.keyword = keyword;

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

- (NSArray<NSString *> *)supportedEvents {
  return @[@"ResultEmitter"];
}

- (void)requestForPoiDetail:(NSArray *)uids {
    BMKPOIDetailSearchOption *option = [BMKPOIDetailSearchOption new];
    NSMutableArray *mutableArray = [uids mutableCopy];
    [mutableArray removeObject:@""];

    option.poiUIDs = [mutableArray copy];
    option.scope = 2;
    mutableArray = nil;
    [_poiSearch poiDetailSearch:option];
}

- (void)onGetSuggestionResult:(BMKSuggestionSearch *)searcher result:(BMKSuggestionResult *)result errorCode:(BMKSearchErrorCode)error {
    if (error == BMK_SEARCH_NO_ERROR) {
        NSArray *uidList = result.poiIdList;
        if ([uidList count] == 0) {
          [self sendEventWithName:@"ResultEmitter" body:uidList];
        }
        else {
          _suggestResult = result;
          [self requestForPoiDetail:uidList];
        }
    } else {
        [self sendEventWithName:@"ResultEmitter" body:@[]];
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
      NSArray *uidList = _suggestResult.poiIdList;
      NSArray *cityList = _suggestResult.cityList;

      NSMutableArray *_resultList = [[NSMutableArray alloc] init];

      int i;
      for (i = 0; i < [keyList count]; i++) {
          id keyItem = [keyList objectAtIndex:i];
          id ptItem = [ptList objectAtIndex:i];
          id districtItem = [districtList objectAtIndex:i];
          id cityItem = [cityList objectAtIndex:i];
          id uidItem = [uidList objectAtIndex:i];

          NSString *tag;
          NSString *uidItemString= uidItem;
          if ([uidItemString isEqualToString:@""]) {
              tag = @"";
          } else {
              BMKPoiInfo *searhResult;
              for (int i = 0; i < [poiInfoList count]; i++) {
                  BMKPoiInfo *poiInfoItem = poiInfoList[i];
                  if ([poiInfoItem.UID isEqualToString:uidItem]) {
                      searhResult = poiInfoItem;
                      break;
                  }
              }
              if (searhResult) {
                  tag = searhResult.detailInfo.tag;
                  if (!tag) tag = @"";
              } else {
                  tag = @"";
              }
          }

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

      [self sendEventWithName:@"ResultEmitter" body:resultList];
    } else {
        // TODO: provide error message
        [self sendEventWithName:@"ResultEmitter" body:@[]];
    }
}
@end
