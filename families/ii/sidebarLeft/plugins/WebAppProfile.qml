import QtWebEngine

// One web app's own storage, made before its view so storageName is set from the start.
WebEngineProfilePrototype {
    httpCacheType: WebEngineProfile.DiskHttpCache
    persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
}
