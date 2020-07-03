---
layout: post
title: Generating gRPC client dynamicly in .net
date:       2019-10-30
summary:    Generating code for gRPC client by proto files dynamicly in .net
categories: net core gRPC
---

## gRPC

gRPC is framework for **Remote Procedure Call** (RPC) by google. gRPC is analog of well-known to enterprises SOAP(especially XML-RPC which is base of SOAP) protocol. 
Both protocols are based on http, however, gRPC works only on http version 2 (**http2**). Also gRPC uses **protocol buffers** (Protobuf), which is smaller, faster and simpler than xml.

### gRPC client

First step is creating new project. Right click on solution `Add->NewProject->Razor Class Library`

![creating razor class library]({{ "/images/razor-library/create.png" | absolute_url }})

You can see that library has following structure.

![razor class library structure]({{ "/images/razor-library/lib-structure.png" | absolute_url }})

* **wwwroot** contains static assets, which you can access from consuming app by prefix `_content/<LibraryName>`. For example,

```html
<script src="_content/MY.LIB/exampleJsInterop.js"></script>
```

* **_Imports.razor** contains shared `using` statements for all components
* **Component1.razor** is our custom component
* **ExampleJsInterop.cs** is just a example of using js interop

As you can see, `Component1.razor` has following content

```html
<div class="my-component">
    This Blazor component is defined in the <strong>MY.LIB</strong> package.
</div>
```

Let's rename our `Component1.razor` to `MyCompnent.razor`.

### Consuming app

Next step is creating blazor application and adding reference to our newly created razor class library.
 In `Pages/Index.razor` we can add using of our `MyComponent` as in following example

```html
 @page "/"

<h1>Hello, world!</h1>

Welcome to your new app.

<SurveyPrompt Title="How is Blazor working for you?" />

<MyComponent>

</MyComponent>
```

 Don't forget add `@using MY.LIB` to `_Imports.razor`.

 If we run blazor app, we can see result

![consume component]({{ "/images/razor-library/component.png" | absolute_url }})

### Consume static assets

As you noticed, our component uses `class="my-component"` which is defined in `wwwroot/styles.css` of our class library. Hovewer, in our blazor app we do not have 
access to this resources yet. To enclude static assests we should use prefix `_content/<LIBRARY NAME>/`. So let's change index.html to following form

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width" />
    <title>PRG.UI.MSB.WEB</title>
    <base href="/" />
    <link href="css/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <link href="css/site.css" rel="stylesheet" />
    <link href="_content/MY.LIB/styles.css" rel="stylesheet" />

</head>
<body>
    <app>Loading...</app>

    <script src="_framework/blazor.webassembly.js"></script>    
</body>
</html>
```

Run app and see we have styled message with background image

![consume component with static assets]({{ "/images/razor-library/result.png" | absolute_url }})

### Conclusion

We've learned how to create Razor Class Library and use it as shared library. If you want you can expose it as nuget package for example. 
Also we got to know that using static assets of library is pretty easy.