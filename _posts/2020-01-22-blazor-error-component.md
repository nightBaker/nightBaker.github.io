---
layout: post
title:  Blazor common error component 
date:   2020-01-22
summary:  Single component for showing erros on any page and component
categories: gitflow azure piplines 
---

### Problem

Actually, on every page and in every component exception can be thrown and client should have ability to understand that's something goes wrong. 
Unfortunately, there still is no global error handling mechanism in blazor to catch exceptions. So developers have to wrap all methods with `try catch` and show error information to user in every page and component. However, last part can be optimized and we can create single component which will show error information and can be accessed from any layer of components in our applicaiton tree.

### Solution

Firstly, let's create blazor webassembly application. Then create folder `Components` in the root of project. Finnaly, add new class with name `IErrorComponet`.

This components has following content :

```csharp
public interface IErrorComponent
{
    void ShowError(string title, string message);
}
```

So as we can see, it just has one method for showing error message with title and information message;

Next step is modifying `MainLayout` as implementation of our `IErrorComponent` interface. 

```csharp
@using Components

@inherits LayoutComponentBase
@implements IErrorComponent

<div class="sidebar">
    <NavMenu />
</div>

<div class="main">
    <div class="top-row px-4">
        <a href="http://blazor.net" target="_blank" class="ml-md-auto">About</a>
    </div>

    <div class="content px-4">
        @if (isErrorActive)
        {        
        <div class="alert alert-danger" role="alert">
            <button type="button" class="close" data-dismiss="alert" aria-label="Close" @onclick="HideError">
                <span aria-hidden="true">&times;</span>
            </button>
            <h3>@title</h3>
            <p>@message</p>
        </div>
        }



    <CascadingValue Value="this" Name="ErrorComponent">
        @Body
    </CascadingValue>

    </div>
</div>

@code {

    bool isErrorActive;
    string title;
    string message;

    public void ShowError(string title, string message)
    {
        this.isErrorActive = true;
        this.title = title;
        this.message = message;
        StateHasChanged();
    }

    private void HideError()
    {
        isErrorActive = false;
    }
}

```

Firstly, we added next line of code

```csharp
@implements IErrorComponent
```

It says that our layout implement our `IErrorComponent` interface, so it should have `ShowError` method. Which you can see in `@code` section.
We also added alert part :
```csharp
@if (isErrorActive)
{        
<div class="alert alert-danger" role="alert">
    <button type="button" class="close" data-dismiss="alert" aria-label="Close" @onclick="HideError">
        <span aria-hidden="true">&times;</span>
    </button>
    <h3>@title</h3>
    <p>@message</p>
</div>
}
```
which will show alert message if `isErrorActive` field is true.

And last one, but the important one part is wrapping body with `CascadingValue` component

```csharp
<CascadingValue Value="this" Name="ErrorComponent">
    @Body
</CascadingValue>
```

With cascading parameters we can pass the paramter to any of components in a subtree.

So for example, we can easily use our component on `FetchData` page. Let's modify into next form :

```csharp

@page "/fetchdata"
@inject HttpClient Http
@using Components

<h1>Weather forecast</h1>

<p>This component demonstrates fetching data from the server.</p>

@if (forecasts == null)
{
    <p><em>Loading...</em></p>
}
else
{
    <table class="table">
        <thead>
            <tr>
                <th>Date</th>
                <th>Temp. (C)</th>
                <th>Temp. (F)</th>
                <th>Summary</th>
            </tr>
        </thead>
        <tbody>
            @foreach (var forecast in forecasts)
            {
                <tr>
                    <td>@forecast.Date.ToShortDateString()</td>
                    <td>@forecast.TemperatureC</td>
                    <td>@forecast.TemperatureF</td>
                    <td>@forecast.Summary</td>
                </tr>
            }
        </tbody>
    </table>
}

@code {
    private WeatherForecast[] forecasts;

    [CascadingParameter(Name = "ErrorComponent")]
    protected IErrorComponent ErrorComponent { get; set; }

    protected override async Task OnInitializedAsync()
    {
        try
        {
            forecasts = await Http.GetJsonAsync<WeatherForecast[]>("sample-data/notfound.json");
        }
        catch(Exception e)
        {
            ErrorComponent.ShowError(e.Message, e.StackTrace);
        }
    }

    public class WeatherForecast
    {
        public DateTime Date { get; set; }

        public int TemperatureC { get; set; }

        public string Summary { get; set; }

        public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
    }
}

```

Here we suppose that `GetJsonAsync` method can throw any exception, so if it does we catch it and show information to our user. *NOTE: it is just example, don't do it on production.* As you can see, we get CascadingParameter as ErrorComponet so we can use it in our code and show error. This method call our layout and show common error alert.

### Conclusion

Though, we don't have ability to create global error handling yet, we can create one component for error rendering and use it anywhere in subtree of components.