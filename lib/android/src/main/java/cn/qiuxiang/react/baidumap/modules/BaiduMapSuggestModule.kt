package cn.qiuxiang.react.baidumap.modules

import cn.qiuxiang.react.baidumap.toLatLng
import cn.qiuxiang.react.baidumap.toWritableMap
import com.baidu.mapapi.search.core.SearchResult
import com.baidu.mapapi.search.sug.*
import com.facebook.react.bridge.*
import android.R.attr.scheme
import java.util.ArrayList



@Suppress("unused")
class BaiduMapSuggestModule(context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {
    private var promise: Promise? = null
    private val mSuggestionSearch by lazy {
        val mSuggestionSearch = SuggestionSearch.newInstance()
        mSuggestionSearch.setOnGetSuggestionResultListener(object : OnGetSuggestionResultListener {
            override fun onGetSuggestionResult(result: SuggestionResult?) {
                if (result == null || result.error != SearchResult.ERRORNO.NO_ERROR) {
                    // TODO: provide error message
                    promise?.reject("", "")
                } else {
                    val infos = result.allSuggestions
                    val promiseArray = Arguments.createArray()

                    for (info in infos) {
                        val data = Arguments.createMap()
                        data.putString("key", info.key)
                        data.putString("poi", info.poiChildrenInfoList.toString())
                        data.putString("address", info.address)
                        data.putDouble("latitude", info.pt.latitude)
                        data.putDouble("longitude", info.pt.longitude)
                        promiseArray.pushMap(data)
                    }

                    promise?.resolve(promiseArray)
                }
                promise = null
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
