---
layout: post
title: Asp.net core mvc routing
date:       2019-09-26
summary:    All ways to set up routings
categories: Asp net core Mvc routing
---

## Start point

In the previous [article] we added mvc support to asp.net core empty project.
 Now, I'm going to consider all ways of setting up routings.

## Conventional routing

Now, we have next configured route in our app. 

```csharp
app.UseMvc(routes =>
{
    routes.MapRoute(
        name: "default",
        template: "{controller=Hello}/{action=Index}/{id?}");
});
```

Let's map new route:

```csharp
app.UseMvc(routes =>
{
    routes.MapRoute(
        name: "messages",
        template: "say/{**message}",
        defaults: new { controller="Messages", action = "ShowMessage" });

    routes.MapRoute(
        name: "default",
        template: "{controller=Hello}/{action=Index}/{id?}");
});
```

As you can we need new controller (MessagesController) with action(ShowMessage) which get message as parameter.
Let's create needful controller and corresponding action and view.

```csharp
public class MessagesController : Controller
{
    public IActionResult ShowMessage(string message)
    {
        if (string.IsNullOrEmpty(message))
        {
            ViewData["Message"] = "Message is empty";
        }
        else
        {
            ViewData["Message"] = message;
        }

        return View();
    }
}
```

`ShowMessage.cshtml` view:

```html
@{
    ViewData["Title"] = "ShowMessage";
}

<h1 class="title is-1">@ViewData["Message"]</h1>
```

Now, let's run app and try to go to `/say/hello/world/from/conventional/route` url. You should see:

![conventional route example]({{ "/images/asp-routes/conventional_route.jpg" | absolute_url }})

As you noticed `{**message}` route parameter captures the remainder of URL path. It is also can match empty string (try goto `/say` url, you should get **"String is empty"** message).
The reason is double asterisk `**`, what means take everything after `/say`.

## Constraints

Let's suppose we wanna have action which get number and add ten to this number. First of all, let's add route and name it `calculator`

```csharp
app.UseMvc(routes =>
{
    routes.MapRoute(
        name: "calculator",
        template: "{controller=Calculator}/addTenToNumber/{number:int}",
        defaults: new { action = "plusTen" });

    routes.MapRoute(
        name: "messages",
        template: "say/{**message}",
        defaults: new { controller="Messages", action = "ShowMessage" });

    routes.MapRoute(
        name: "default",
        template: "{controller=Hello}/{action=Index}/{id?}");
});
```

**Note** route parameter `{number:int}` has constraint `:int` which states that number must be type of integer.
Create corresponding controller, action and view.

```csharp
public class CalculatorController : Controller
{
    public IActionResult PlusTen(int number)
    {
        ViewData["number"] = number;
        ViewData["result"] = number + 10;

        return View();
    }
}
```

View :

```html

@{
    ViewData["Title"] = "PlusTen";
}

<h2 class="subtitle is-2">@ViewData["number"] + 10 = @ViewData["result"]</h2>
```

if you go to `/calculator/addTenToNumber/10`, you will get following result

![conventional route_contraint example]({{ "/images/asp-routes/conventional_route.jpg" | absolute_url }})

Now, I want add more actions to calculator, for example devide ten by passed number. However, our previously configured route is not suitable for different actions. Let's change it bit.

## Link generator

Now let's change our navigation bar in `_Layout.cshtml` to following view.

```html
<!DOCTYPE html>

<html>
<head>
    <meta name="viewport" content="width=device-width" />
    <title>Hello from view</title>
    <link rel="stylesheet" href="~/css/bulma.min.css">
</head>
<body>
    <div class="container">
        <nav class="navbar" role="navigation" aria-label="main navigation">
            <div class="navbar-brand">
                <a class="navbar-item" href="/">
                    <strong class="title">My app</strong>
                </a>

                <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navbarBasicExample">
                    <span aria-hidden="true"></span>
                    <span aria-hidden="true"></span>
                    <span aria-hidden="true"></span>
                </a>
            </div>

            <div id="navbarBasicExample" class="navbar-menu">
                <div class="navbar-start">
                    @Html.ActionLink("10+5", "PlusTen", "Calculator", new { number = 5 }, new { @class = "navbar-item" })
                    @Html.ActionLink("10+23", "PlusTen", "Calculator", new { number = 23 }, new { @class = "navbar-item" })
                </div>

                <div class="navbar-end">
                    <div class="navbar-item">
                        <div class="buttons">                            
                        </div>
                    </div>
                </div>
            </div>
        </nav>
    </div>

    <div class="container">
        @RenderBody()
    </div>
</body>
</html>

```

As you noticed we did not use hard-coded links and used `Html` class to generate link with action and controller parameters

```html
<div class="navbar-start">
    @Html.ActionLink("10+5", "PlusTen", "Calculator", new { number = 5 }, new { @class = "navbar-item" })
    @Html.ActionLink("10+23", "PlusTen", "Calculator", new { number = 23 }, new { @class = "navbar-item" })
</div>
```

If you run your app you can discover that it generates next html code

```html
<div class="navbar-start">
    <a class="navbar-item" href="/Calculator/addTenToNumber/5">10+5</a>
    <a class="navbar-item" href="/Calculator/addTenToNumber/23">10+23</a>
</div>
```

Now, we can change our route in `Startup.cs`

```csharp
 app.UseMvc(routes =>
{
    routes.MapRoute(
        name: "calculator",
        template: "Calculator/{action}/{number:int}",
        defaults: new { Controller = "Calculator" });

    routes.MapRoute(
        name: "messages",
        template: "say/{**message}",
        defaults: new { controller="Messages", action = "ShowMessage" });

    routes.MapRoute(
        name: "default",
        template: "{controller=Hello}/{action=Index}/{id?}");
});
```

As you can see, route will be matched for all requests started on `Calculator`. However, we set up only default controller for given route and it will search for right action.

Rerun application and explore navigation bar. It should be changed to next form:

```html
<div class="navbar-start">
    <a class="navbar-item" href="/Calculator/PlusTen/5">10+5</a>
    <a class="navbar-item" href="/Calculator/PlusTen/23">10+23</a>
</div>
```

So, it is clear that using link generator allows you change routes mapping without pain.

**NOTE. Route names have no impact on URL matching or handling of requests; they're used only for URL generation**

# Attribute routing

Let's remove out last added routes and consider how we can achieve the same goals with attribute routing.

```cshtml
app.UseMvc(routes =>
{
    routes.MapRoute(
        name: "default",
        template: "{controller=Hello}/{action=Index}/{id?}");
});
```

First of all, `Route` attribute with specified template should be added to `MessagesController` as following

```csharp
[Route("Say")]
public class MessagesController : Controller
{
    [Route("{**message}")]
    public IActionResult ShowMessage(string message)
    {
        if (string.IsNullOrEmpty(message))
        {
            ViewData["Message"] = "Message is empty";
        }
        else
        {
            ViewData["Message"] = message;
        }
        
        return View();
    }
}
```

Check it out. It should be still working.

But what about Calculator controller. Let's changed it to real calculator.
First of all , I want add action `sum`, which should return sum of two numbers. 

```csharp
public class CalculatorController : Controller
{

    [Route("[controller]/{firstNumber:int}/{secondNumber:int}")]
    public IActionResult Sum(int firstNumber, int secondNumber)
    {
        ViewData["firstNumber"] = firstNumber;
        ViewData["secondNumber"] = secondNumber;
        ViewData["result"] = firstNumber + secondNumber;

        return View();
    }
}
```

Also View should be renamed from `PlusTen.cshtml` to `Sum.cshtml` and changed to :

```html

@{
    ViewData["Title"] = "Sum";
}

<h2 class="subtitle is-2">@ViewData["firstNumber"] + @ViewData["secondNumber"]  = @ViewData["result"]</h2>

```

And out navigation bar also has to be changed 

```html
<div id="navbarBasicExample" class="navbar-menu">
    <div class="navbar-start">
        @Html.ActionLink("10+5", "Sum", "Calculator", new { firstNumber = 10, secondNumber = 5 }, new { @class = "navbar-item" })
        @Html.ActionLink("10+23", "Sum", "Calculator", new { firstNumber = 10, secondNumber = 23 }, new { @class = "navbar-item" })
    </div>

    <div class="navbar-end">
        <div class="navbar-item">
            <div class="buttons">                            
            </div>
        </div>
    </div>
</div>
```

Check it out!

### Division action

Now, let's expand calculator functionality with division action

```csharp
[Route("[controller]/[action]")]
    public class CalculatorController : Controller
    {
        public CalculatorController()
        {
            ViewData["action"] = RouteData.Values["action"].ToString();
        }

        [Route("{firstNumber:int}/{secondNumber:int}")]
        public IActionResult Sum(int firstNumber, int secondNumber)
        {
            ViewData["mark"] = '+';
            ViewData["firstNumber"] = firstNumber;
            ViewData["secondNumber"] = secondNumber;
            ViewData["result"] = firstNumber + secondNumber;

            return View("Result");
        }

        [Route("{firstNumber:int}/{secondNumber:int}")]
        public IActionResult Divide(int firstNumber, int secondNumber)
        {
            ViewData["mark"] = '/';
            ViewData["firstNumber"] = firstNumber;
            ViewData["secondNumber"] = secondNumber;
            ViewData["result"] = firstNumber / secondNumber;

            return View("Result");
        }


    }
```

As you can noticed, there are two changes. Firstly , we added new `divide` action. Secondly, we extract `Route` attribute to controller, because it contains common part of both actions, so routes would be combined.

Also we have to rename view `Sum.cshtml` to `Result.cshtml`, now it will show results for both actions and has next content : 

```html

@{
    ViewData["Title"] = "Sum";
}

<h1 class="title is-1">@ViewData["action"]</h1>
<h2 class="subtitle is-2">@ViewData["firstNumber"] @ViewData["mark"] @ViewData["secondNumber"]  = @ViewData["result"]</h2>


```

Run application and go to `/Calculator/Divide/10/5`. Everything is good, however if you go to `/Calculator/Divide/10/0`, it will throw `DivideByZeroException`. 

To solve this problem, one more contraint can be added. For example.

```csharp
[Route("{firstNumber:int}/{secondNumber:int:min(1)}")]
public IActionResult Divide(int firstNumber, int secondNumber)
```

It states that second number must be more than zero.

### Conclusion

We can use conventional and attribute routing together or separately depending of situation and goals. There are contraints which helps us create rich routes with parameters. Asp.net core gives big abilities to expand mapping routes behaviour. However, for most basic applications and scenarious routes should be as simple as posible.
