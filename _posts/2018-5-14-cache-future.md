---
layout: post
title: Cache the sfuture with service worker
date:       2017-05-14
summary:    Cache the future with service worker.
categories: jekyll pixyll
---

## Brief intro.

1. Reqister service worker
2. Cache initial resources 
3. Fetch network requests
3. Send message to service worker
4. Add dynamic resource to cache
5. Debug


## Reqister	service worker in our main.js
```javascript
//if browser supports serviceWorker
if ('serviceWorker' in navigator) {
	navigator.serviceWorker.register('/sw.js').then(function (reg) {
		// success
		console.log('Registration succeeded. Scope is ' + reg.scope);
	}).catch(function (error) {
		// failed
		console.log('Registration failed with ' + error);
	});
};
```

## Cache initial resource
```javascript
//sw.js should be in root of our website

//event is triggered when serviceWorker installing first time
this.addEventListener('install', function (event) {
    event.waitUntil(        
		//try to open out 'v1' cache
        caches.open('v1').then(function (cache) {
			//here we can add our static resources to cache
            return cache.addAll([
                '/js/main.js',
				'/css/main.css'
            ]);
        })
    );
});
```

## Fetch network requests
```javascript
this.addEventListener('fetch', function (event) {
    event.respondWith(

        //Если же мы были достаточно умны, то мы не стали бы просто возвращать сетевой запрос, а сохранили бы его результат в кеше, чтобы иметь возможность получить его в offline-режиме
        caches.match(event.request).then(function (resp) {
            return resp || fetch(event.request).then(function (response) {
                return caches.open('v1').then(function (cache) {
                    //cache.put(event.request, response.clone()); ложит ответ в кэш 
                    return response;
                });
            });
        })
            //.catch(function () {
            //если на какой-либо запрос в кеше не будет найдено соответствие, и в этот момент сеть не доступна, то наш запрос завершится неудачно. Давайте реализуем запасной вариант по умолчанию, при котором пользователь, в описанном случае, будет получать хоть что-нибудь:
            //return caches.match('/sw-test/gallery/myLittleVader.jpg');
        //})
    );
});
```

## Send message to service worker
Now we can send messages from out javascript to serviceWorker, however serviceWorker should know how process our messages.
Let's add code for receiving messages firstly
```javascript
//sw.js

//event is triggered when message is received
this.addEventListener('message', function (event) {
    console.log("SW Received Message: " + event.data);    
});
```

Now our serviceWorker can receive messages
Let's send some from website javascript
```javascript
//main.js

//check if serviceWorker is supported
// navigator.serviceWorker.controller can be null and this is normal behaviuor
// because serviceWorker can be not installed yet 
if('serviceWorker' in navigator && navigator.serviceWorker.controller){                        
	navigator.serviceWorker.controller.postMessage('Hello from main.js');
}
```

Run our sample and see messages
//TODO

## Add dynamic resource to cache
Now we can receive messages from our main.js, so such messages can contain urls which we should cache
Let's edit our message event listener and assume that each message is url
```javascript
this.addEventListener('message', function (event) {
    //console.log("SW Received Message: " + event.data);
    caches.open('v1').then(function (cache) {
        cache.add(event.data); //adding response to cache        
    });
});
```

Now we have ability to cache future requests. For example if you have a blog and list of posts in main page you can cache posts pages for client and when he goes to post, it will be opened in a tick.
