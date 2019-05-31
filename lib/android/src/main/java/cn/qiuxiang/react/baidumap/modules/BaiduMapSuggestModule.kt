package cn.qiuxiang.react.baidumap.modules

import cn.qiuxiang.react.baidumap.toLatLng
import cn.qiuxiang.react.baidumap.toWritableMap
import com.baidu.mapapi.search.core.SearchResult
import com.baidu.mapapi.search.core.PoiDetailInfo
import com.baidu.mapapi.search.sug.*
import com.baidu.mapapi.search.poi.*
import com.facebook.react.bridge.*
import android.R.attr.scheme
import android.util.Log
import java.util.Queue
import java.util.ArrayDeque
import com.facebook.react.modules.core.DeviceEventManagerModule
import java.time.temporal.TemporalAdjusters.next






@Suppress("unused")
class BaiduMapSuggestModule(context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {
    private var queue: Queue<List<SuggestionResult.SuggestionInfo>> = ArrayDeque<List<SuggestionResult.SuggestionInfo>> ()
    private var emitter : DeviceEventManagerModule.RCTDeviceEventEmitter? = null

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
                    sendEventToReactNative(Arguments.createArray())
                } else {
                    val poiDetails = result.poiDetailInfoList
                    val promiseArray = Arguments.createArray()
                    val suggestResult =  queue.poll()

                    val it = suggestResult.listIterator()
                    while (it.hasNext()) {
                        val info = it.next()
                        val data = Arguments.createMap()
                        data.putString("key", info.key)
                        data.putString("city", info.city)
                        data.putString("district", info.district)
                        data.putString("tag", getTagFromPoi(poiDetails, info.uid))
                        if (info.pt != null) {
                            data.putDouble("latitude", info.pt.latitude)
                            data.putDouble("longitude", info.pt.longitude)
                        }
                        promiseArray.pushMap(data)
                    }
                    sendEventToReactNative(promiseArray)
                }
            }
        })
        mPoiSearch
    }

    private val mSuggestionSearch by lazy {
        val mSuggestionSearch = SuggestionSearch.newInstance()
        mSuggestionSearch.setOnGetSuggestionResultListener(object : OnGetSuggestionResultListener {
            override fun onGetSuggestionResult(result: SuggestionResult?) {
                if (result == null || result.error != SearchResult.ERRORNO.NO_ERROR) {
                    sendEventToReactNative(Arguments.createArray())
                } else {
                    if (result.allSuggestions.isEmpty()) {
                        sendEventToReactNative(Arguments.createArray())
                    } else {
                        Thread(Runnable {
                            val infos = result.allSuggestions
                            queue.add(infos)

                            val uids = infos.map { item -> item.uid }.joinToString(separator = ",")
                            requestForPoi(uids)
                        }).start()
                    }
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

    fun getTagFromPoi(detailResult: List<PoiDetailInfo>, uid: String): String? {
        var result : PoiDetailInfo? = null
        for (item in detailResult) {
           if (uid == item.uid) {
               result = item
               break
           }
        }
        if (result == null) {
            return null
        } else {
            return result.tag
        }
    }

    fun sendEventToReactNative(body: kotlin.Any) {
        if (emitter == null) {
            emitter = reactApplicationContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
        }
        emitter!!.emit("ResultEmitter", body)
    }

    @ReactMethod
    fun requestSuggestion(keyword: String, city: String) {
        mSuggestionSearch.requestSuggestion(SuggestionSearchOption().city(city).keyword(keyword))
    }
}

