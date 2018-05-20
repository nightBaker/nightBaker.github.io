---
layout: post
title: Cache the future with service worker
date:       2017-05-14
summary:    Cache the future with service worker.
categories: js serviceWorker
---

## Brief intro.

1. Reqister service worker
2. Cache initial resources 
3. Fetch network requests
3. Send message to service worker
4. Add dynamic resource to cache
5. Debug


## Reqister	service worker in our main.js
Firstly, we have to try to install our serviceWorker. sw.js will contain our source code of serviceWorker and should be in a root of website.
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
In sw.js we can add listeners for events which servicWorker listent to.
Firstly, let's add event 'install', which is occured when browser try in register serviceWorker first time.
When we install our service worker we can add resources to cache. Here we add only 2 main files.
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
Now, we cached some resources, but if we look on network reguest we can see that responces come from our server not cache.
The reaseon is our service worker in not listenning to network requests. For this functionality we have to add following lines of code.
```javascript
//sw.js

this.addEventListener('fetch', function (event) {
    event.respondWith(
        
        //Here we can check if we have response in cache for this request
        //If not, browser makes response and we can save this response for future requests in offline
        //However in this example we do not need to do that for all requests
        caches.match(event.request).then(function (resp) {
            return resp || fetch(event.request).then(function (response) {
                return caches.open('v1').then(function (cache) {
                    //cache.put(event.request, response.clone()); adding response clone to cache because we can read only once from response
                    return response;
                });
            });
        })
            //.catch(function () {
            //if we don't have response in cache and do not have network connection
            // we can response with custom image or page
            //return caches.match('/sw-test/gallery/myLittleVader.jpg');
        //})
    );
});
```  

For this time we have ability to cache static resources. Also, our service worker works as proxy and response with cached resources.
But it is not enough, if we want to cache not only static resources. Let's imagine that we have blog and list of posts. We could want to cache posts pages for client for future oflline works. I have good news for you, because it is pretty easy to code.

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
