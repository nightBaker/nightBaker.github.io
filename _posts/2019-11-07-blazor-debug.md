---
layout: post
title: Debugging blazor client side app
date:       2019-11-07
summary:    Learning how to debug blazor webassembly app
categories: blazor dotnet webassembly debug
---

## Debugging in blazor

Blazor supports full debugging in blazor server side. But, if you work with client-side you still have the opportunity to debug your code. At the writing moment, there is only early support of debugging blazor webassembly apps and there are some limitations.

* Only `int`, `string` and `bool` type variables  are observable
* Classes and their properties and fields are not observable
* Hover to observe is not working
* Execute code expressions in the console is not working
* Step into async methods is not working

Anyway, debugging allows to set and remove breakpoins, observe local variables of `int`, `string` and `bool` types. Also you can see call stack including when js call .net and vise versa.

### Prerequisites

* You need chrome +70 version

### How to

1.**NOTE.  The debugger works only for Http.** Https in not working 
2. Run your app
3. Open your client app in chrome
4. Press `Shift+Alt+D`. You get the following message
![debug blazor in browser]({{ "/images/debug-blazor/debuggable-browser.png" | absolute_url }})

5. Follow instructions
6. Open a new instance of chrome as the instruction says
7. Press `Shift+Alt+D` again
8. New page will be open 
![debug blazor in browser]({{ "/images/debug-blazor/debug-window.png" | absolute_url }})

9. Go to the `Sources` tab. In the left side, goto `page` and find your code in `file://`
10. Set breakpoint


### Conclusion

You have ability to debug your code, observe variables and analyze call stack. It is not fully featured, however, it is more than nothing.

 
