---
layout: post
title: Store array of numbers with ef core and fluent api
date:       2019-02-12
summary:    Using value converter of entity framework core and fluent api
categories: ef core, fluent api, .net core
---

## Problem

Sometimes we have data which we are mapping to table, however there is array of info related to our entity and we don't want to create separate table for such information and to use one to many relationships. 
For example, we have entity loteryTicket where user can choose 10 any numbers from 0 to 100. Now loteryTicker has array of numbers. There are two way to store data into table. First, we could create new table with only number column and loteryTicket id column. Second, we could use the same table and add new column which can contain converted array of numbers.  

## Solution
Let's consider second way and how entity framework core can ease our life.

Consume we have such entity
```c#
public class LoteryTicket
{
    public long Id { get; set; }

    public long UserId { get; set; }

    public int[] ChoosenNumbers { get; set; }
}
```

EF has ValueConverter generic class, which can be used to say ef to convert value before insert it into table and after receiving convert it to property.

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

That's all. Now our property is saved in our custom format like "10;5;34", hovewer at application layer we abstract of persistence and work with array.