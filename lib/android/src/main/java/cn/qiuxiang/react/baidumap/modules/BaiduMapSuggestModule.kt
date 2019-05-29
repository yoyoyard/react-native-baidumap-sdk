package cn.qiuxiang.react.baidumap.modules

import cn.qiuxiang.react.baidumap.toLatLng
import cn.qiuxiang.react.baidumap.toWritableMap
import com.baidu.mapapi.search.core.SearchResult
import com.baidu.mapapi.search.sug.*
import com.baidu.mapapi.search.poi.*
import com.facebook.react.bridge.*
import android.R.attr.scheme
import android.util.Log
import java.util.ArrayList


@Suppress("unused")
class BaiduMapSuggestModule(context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {
    private var promise: Promise? = null
    private var suggestResult: List<SuggestionResult.SuggestionInfo>? = null

    private val mPoiSearch by lazy {
        val mPoiSearch = PoiSearch.newInstance()
        mPoiSearch.setOnGetPoiSearchResultListener(object : OnGetPoiSearchResultListener {
            override fun onGetPoiIndoorResult(p0: PoiIndoorResult?) {
            }

            override fun onGetPoiResult(p0: PoiResult?) {
            }

            override fun onGetPoiDetailResult(p0: PoiDetailResult?) {
            }

            override fun onGetPoiDetailResult(result: PoiDetailSearchResult?) {
                if (result == null || result.error != SearchResult.ERRORNO.NO_ERROR) {
                    // TODO: provide error message
                    promise?.reject("", "")
                } else {
                    val poiDetails = result.poiDetailInfoList
                    val promiseArray = Arguments.createArray()

                    for ((index, info) in suggestResult!!.withIndex()) {
                        val data = Arguments.createMap()
                        data.putString("key", info.key)
                        data.putString("city", info.city)
                        data.putString("district", info.district)
                        data.putString("tag", poiDetails[index].tag)
                        data.putDouble("latitude", info.pt.latitude)
                        data.putDouble("longitude", info.pt.longitude)
                        promiseArray.pushMap(data)
                    }

                    promise?.resolve(promiseArray)
                }
                promise = null
            }
        })
        mPoiSearch
    }

    private val mSuggestionSearch by lazy {
        val mSuggestionSearch = SuggestionSearch.newInstance()
        mSuggestionSearch.setOnGetSuggestionResultListener(object : OnGetSuggestionResultListener {
            override fun onGetSuggestionResult(result: SuggestionResult?) {
                if (result == null || result.error != SearchResult.ERRORNO.NO_ERROR) {
                    // TODO: provide error message
                    promise?.reject("", "")
                } else {
                    val infos = result.allSuggestions
                    suggestResult = infos

                    val uids = infos.map { item -> item.uid }.joinToString(separator = ",")
                    requestForPoi(uids)
                }
            }
        })
        mSuggestionSearch
    }

    override fun getName(): String {
        return "BaiduMapSuggest"
    }

    override fun canOverrideExistingModule(): Boolean {
        return true
    }

    fun requestForPoi(uids: String) {
        mPoiSearch.searchPoiDetail(PoiDetailSearchOption().poiUids(uids))
    }

    @ReactMethod
    fun requestSuggestion(keyword: String, city: String, promise: Promise) {
        if (this.promise == null) {
            this.promise = promise
            mSuggestionSearch.requestSuggestion(SuggestionSearchOption().city(city).keyword(keyword))
        } else {
            promise.reject("", "This callback type only permits a single invocation from native code")
        }
    }
}

