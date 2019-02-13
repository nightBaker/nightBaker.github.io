---
layout: post
title: Store array of numbers with ef core and fluent api
date:       2019-02-12
summary:    Using value converter of entity framework core and fluent api
categories: ef core, fluent api, .net core
---

## Problem

Sometimes we have data which we are mapping to table, however there is array of info related to our entity.
Obviously we don’t want to build separate table for such information and create one too many relationships.

The folloiwng example may help us to have the deep dive to the problem. We have entity "loteryTicket" where user may randomly select any ten numbers from 0 to 100.

So"loteryTicker" has an array of numbers. There can be two possibilities to store data in the table.

The first one, we could create new table with two columns one for storing the number, another for ticket id.

The second, we may use the same table and just updated it with new column which will store the converted array of numbers.

## Solution
Let’s look through the second way and how entity framework core can simplify our life.

Consider we have such entity
```c#
public class LoteryTicket
{
    public long Id { get; set; }

    public long UserId { get; set; }

    public int[] ChoosenNumbers { get; set; }
}
```

EF has ValueConverter generic class, which can be used to say ef to convert value before inserting it into table and after receiving the result convert it to property.

Let's create our converter
```c#
var converter = new ValueConverter<int[], string>(
                v => string.Join(";",v),
                v => v.Split(";", StringSplitOptions.RemoveEmptyEntries).Select(val=> int.Parse(val)).ToArray());
```
Now we can use converter in ef fluent api
```c#
modelBuilder.Entity<LoteryTicket>()
                .Property(e => e.ChoosenNumbers)
                .HasConversion(converter);
```

That’s it. Finaly our property saved in our custom format like “10;5;34”. Hovewer at application layer we may abstract of persistence and work with the array.