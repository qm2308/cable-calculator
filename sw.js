/**
 * Service Worker for Cable Calculator PWA
 * 提供离线支持和缓存功能
 */

const CACHE_NAME = 'cable-calculator-v1.0.0';
const STATIC_CACHE = 'static-v1';
const DYNAMIC_CACHE = 'dynamic-v1';

// 需要缓存的静态资源
const STATIC_ASSETS = [
    '/',
    '/index.html',
    '/styles/main.css',
    '/scripts/app.js',
    '/manifest.json',
    '/icons/icon-192.png',
    '/icons/icon-512.png'
];

// 安装事件
self.addEventListener('install', event => {
    console.log('Service Worker: Install Event');
    
    event.waitUntil(
        caches.open(STATIC_CACHE)
            .then(cache => {
                console.log('Service Worker: Caching Static Assets');
                return cache.addAll(STATIC_ASSETS);
            })
            .then(() => {
                // 强制激活新的Service Worker
                return self.skipWaiting();
            })
    );
});

// 激活事件
self.addEventListener('activate', event => {
    console.log('Service Worker: Activate Event');
    
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cacheName => {
                    if (cacheName !== STATIC_CACHE && cacheName !== DYNAMIC_CACHE) {
                        console.log('Service Worker: Clearing Old Cache', cacheName);
                        return caches.delete(cacheName);
                    }
                })
            );
        }).then(() => {
            // 立即控制所有页面
            return self.clients.claim();
        })
    );
});

// 获取事件
self.addEventListener('fetch', event => {
    const { request } = event;
    const url = new URL(request.url);
    
    // 只处理同源请求
    if (url.origin !== location.origin) {
        return;
    }
    
    // 优先使用缓存策略
    event.respondWith(
        caches.match(request)
            .then(cachedResponse => {
                // 如果缓存中有，直接返回
                if (cachedResponse) {
                    console.log('Service Worker: Serving from cache', request.url);
                    return cachedResponse;
                }
                
                // 否则从网络获取，并缓存
                return fetch(request)
                    .then(response => {
                        // 检查响应是否有效
                        if (!response || response.status !== 200 || response.type !== 'basic') {
                            return response;
                        }
                        
                        // 克隆响应以供缓存
                        const responseToCache = response.clone();
                        
                        caches.open(DYNAMIC_CACHE)
                            .then(cache => {
                                cache.put(request, responseToCache);
                            });
                        
                        return response;
                    })
                    .catch(error => {
                        console.log('Service Worker: Fetch failed, serving offline page', error);
                        
                        // 如果是导航请求，返回离线页面
                        if (request.mode === 'navigate') {
                            return caches.match('/index.html');
                        }
                        
                        // 其他请求返回错误
                        throw error;
                    });
            })
    );
});

// 后台同步
self.addEventListener('sync', event => {
    if (event.tag === 'background-sync') {
        console.log('Service Worker: Background sync');
        event.waitUntil(doBackgroundSync());
    }
});

// 推送通知
self.addEventListener('push', event => {
    const options = {
        body: event.data ? event.data.text() : '电缆计算器有新功能更新！',
        icon: '/icons/icon-192.png',
        badge: '/icons/icon-72.png',
        vibrate: [200, 100, 200],
        data: {
            dateOfArrival: Date.now(),
            primaryKey: 1
        },
        actions: [
            {
                action: 'explore',
                title: '查看详情',
                icon: '/icons/icon-192.png'
            },
            {
                action: 'close',
                title: '关闭',
                icon: '/icons/icon-192.png'
            }
        ]
    };
    
    event.waitUntil(
        self.registration.showNotification('电缆计算器', options)
    );
});

// 通知点击
self.addEventListener('notificationclick', event => {
    event.notification.close();
    
    if (event.action === 'explore') {
        // 打开应用
        event.waitUntil(
            clients.openWindow('/')
        );
    } else if (event.action === 'close') {
        // 关闭通知
        event.notification.close();
    } else {
        // 默认行为：打开应用
        event.waitUntil(
            clients.openWindow('/')
        );
    }
});

// 消息处理
self.addEventListener('message', event => {
    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
    
    if (event.data && event.data.type === 'GET_VERSION') {
        event.ports[0].postMessage({ version: CACHE_NAME });
    }
});

// 后台同步功能
async function doBackgroundSync() {
    try {
        // 这里可以添加需要在后台同步的功能
        console.log('Service Worker: Performing background sync');
        
        // 例如：同步用户数据、清理缓存等
        
        return Promise.resolve();
    } catch (error) {
        console.error('Service Worker: Background sync failed', error);
        throw error;
    }
}

// 缓存清理函数
async function cleanupOldCaches() {
    const cacheWhitelist = [STATIC_CACHE, DYNAMIC_CACHE];
    const cacheNames = await caches.keys();
    
    return Promise.all(
        cacheNames.map(cacheName => {
            if (!cacheWhitelist.includes(cacheName)) {
                return caches.delete(cacheName);
            }
        })
    );
}

// 缓存策略
const CacheStrategy = {
    CACHE_FIRST: 'cache-first',
    NETWORK_FIRST: 'network-first',
    STALE_WHILE_REVALIDATE: 'stale-while-revalidate'
};

function matchStrategy(request, strategy = CacheStrategy.CACHE_FIRST) {
    switch (strategy) {
        case CacheStrategy.CACHE_FIRST:
            return caches.match(request)
                .then(cachedResponse => {
                    return cachedResponse || fetch(request);
                });
        
        case CacheStrategy.NETWORK_FIRST:
            return fetch(request)
                .then(response => {
                    const responseClone = response.clone();
                    caches.open(DYNAMIC_CACHE).then(cache => {
                        cache.put(request, responseClone);
                    });
                    return response;
                })
                .catch(() => {
                    return caches.match(request);
                });
        
        case CacheStrategy.STALE_WHILE_REVALIDATE:
            return caches.match(request)
                .then(cachedResponse => {
                    const fetchPromise = fetch(request).then(response => {
                        const responseClone = response.clone();
                        caches.open(DYNAMIC_CACHE).then(cache => {
                            cache.put(request, responseClone);
                        });
                        return response;
                    });
                    
                    return cachedResponse || fetchPromise;
                });
        
        default:
            return caches.match(request);
    }
}

console.log('Service Worker: Loaded successfully');