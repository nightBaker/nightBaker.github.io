---
layout: post
title: Debugging blazor client side app
date:       2019-11-07
summary:    Learning how to debug blazor webassembly app
categories: blazor dotnet webassembly debug
---

## Debugging in blazor

Blazor supports full debugging in blazor server side. However, if you work with client side you still have opportunity to debug your code. At the writting moment, there is only early support of debugging blazor webassembly apps and there is some limitations.
* Only `int`, `string` and `bool` type varibales are observable
* Classes and their properties and fields are not obseravable
* Hover to observe is not working
* Execute code expressions in console is not working
* Step into async methods is not working

Anyway, debugging allows to set and remove breakpoins, observe local variables of `int`, `string` and `bool` types. Also you can see call stack including when js call .net and vise versa.

### Prerequisites

* You need chrome +70 version

### How to

1.**NOTE. Debugger works only for http.** Https in not working 
2. Run you app
3. Open you client app in chrome
4. Press `Shift+Alt+D`. You get following message
![debug blazor in browser]({{ "/images/debug-blazor/debuggable-browser.png" | absolute_url }})

5. Follow instructions
6. Open new instance of chrome as instruction says
7. Press `Shift+Alt+D` again
8. New page will be open 
![debug blazor in browser]({{ "/images/debug-blazor/debug-window.png" | absolute_url }})

9. Go to `Sources` tab. In the left side, goto `page` and find you code in `file://`
10. Set breakpoint


### Conclusion

You have ability to debug your code, observe variables and analyze call stack. It is not fully featured, however, it is more than nothing.

 
