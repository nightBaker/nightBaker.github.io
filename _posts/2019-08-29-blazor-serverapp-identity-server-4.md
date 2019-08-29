---
layout: post
title: Blazor server app + identity server 4
date:       2019-08-29
summary:    Adding openid connect to blazor app with identity server 4
categories: Blazor IdentityServer4 serverapp
---

## Blazor server app + Idendity Server 4

Blazor server app supports authentitication with external providers like identity server 4 using OpenId Connect.

First of all, install nuget package

```console
dotnet install IdentityServer4
```

Now, we need to configure services in `Startup.cs`

```csharp
services.AddAuthentication(options =>
{
    options.DefaultScheme = "Cookies";
    options.DefaultChallengeScheme = "oidc";
})
.AddCookie("Cookies")
.AddOpenIdConnect("oidc", options =>
{
    options.Authority = "identity server address";
    options.RequireHttpsMetadata = false;

    options.ClientId = "ClientId";
    options.SaveTokens = true;
});

services.AddMvcCore(options =>
{
    var policy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();
    options.Filters.Add(new AuthorizeFilter(policy));
});
```

This `.RequireAuthenticatedUser()` line tells aspnet always require authenticated user and challenge oidc scheme if user is not authenticated. It means all pages in your project are not shown for not authenticated user.

If you are in another situation and have pages for unauthorized user, you can remove last part of code and add mvc endpoint

```csharp
app.UseAuthentication();
app.UseRouting();

app.UseEndpoints(endpoints =>
{
    endpoints.MapControllerRoute("default", "{controller=Home}/{action=Index}/{id?}"); //adds mvc endpoint
    endpoints.MapBlazorHub<App>(selector: "app");
    endpoints.MapFallbackToPage("/_Host");
});
```

Then you need controller which will be responsible for challenging authentication scheme.

```csharp
public class AccountController : Controller
{
    public IActionResult SignIn([FromRoute] string scheme)
    {
        scheme = scheme ?? "oidc";
        var redirectUrl = Url.Content("~/");
        return Challenge(
            new AuthenticationProperties { RedirectUri = redirectUrl },
            scheme);
    }
}
```

You can use button like `<a href="/account/login">Login <a>` for logging in user.

For those pages which need to be protected, we can easily use `@attribute [Authorize]`, also it allows protect pages by roles or policy.
AuthenticationStateProvider gives us access to identity context, for example from microsoft index.razor page

```razor
@page "/"
@attribute [Authorize]
@inject AuthenticationStateProvider AuthenticationStateProvider

<h1>Hello, world!</h1>

Welcome to your new app.

<AuthorizeView  Roles="admin, superuser">
    <p>You can only see this if you're an admin or superuser.</p>
</AuthorizeView>

<button @onclick="@LogUsername">Write user info to console</button>

@code {

    private async Task LogUsername()
    {
        var authState = await AuthenticationStateProvider.GetAuthenticationStateAsync();
        var user = authState.User;

        if (user.Identity.IsAuthenticated)
        {
            name = user.Identity.Name;
            Console.WriteLine($"{user.Identity.Name} is authenticated.");
        }
        else
        {
            Console.WriteLine("The user is NOT authenticated.");
        }
    }
}
```

`<AuthorizeView>` component alike `@attribute [Authorize]` supports role-based and policy based authorization.

