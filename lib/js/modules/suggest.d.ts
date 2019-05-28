import { LatLng } from "../types";
declare type SearchResult = {
    key: string;
    city: string;
    address: string;
} & LatLng;
declare const _default: {
    requestSuggestion(keyword: string, city?: string): Promise<SearchResult>;
};
export default _default;
