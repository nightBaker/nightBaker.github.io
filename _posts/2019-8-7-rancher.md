---
layout: post
title: Namespace and service limits in Rancher
date:       2019-08-07
summary:    Rancher limits
categories: Rancher Docker Kubernates
---

## Problem

One day one of run services can consume all available resources of your Rancher cluster and kill all services.
It can happen because there are no limits for any service by default.

## Solution

Fortunately, there is easy way to set limits not only for one service, but also for namespace.

### Rancher namespace limits 

Goto edit page of namespace
![Namespace edit page]({{ "/images/rancher/namespace_edit.png" | absolute_url }})

As you can see there are no set limits by default. There are 4 limits which you can set.
1. CPU Limit - max amount of available CPU in milicores
2. CPU Reservation - amount of CPU which would be reserved for the namespace
3. Memory Limit - max amount of memory in MB
4. Memory Reservation - amount of memory which would be reserved for the namespace

Milicores (milicpus) means fraction of CPU core. For example, if you have 2 available CPU cores, but want your service use 1 core and only half of another core, you set limit equal to `1500 milli CPUs`. At the same time, you want your namespace always have half fraction of any CPU core, you set CPU Reservation equal to `500 milli CPUs`

### Rancher service limits

For setting up limit for service you have to go to edit page of service and then click `Show advanced options`, in the bottom of list you find `Security & Host config`

![service edit limits page]({{ "/images/rancher/Service_limits.png" | absolute_url }})
As you can see , there same settings for limits as for namespace.  

### Conclusion
It is good practise, always setting up limits for your services and namespace for exluding impact to another services in cluster. These easy steps help you to avoid problems in future.
