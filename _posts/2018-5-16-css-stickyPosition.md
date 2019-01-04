---
layout:     post
title:      CSS tricks
date:       2017-05-16 11:21:29
summary:    CSS position sticky and smooth scroll
categories: css sticky scroll
---

![My helpful screenshot]({{ "/images/sticky.gif" | absolute_url }})
```css
.element {
  position: sticky;
  top: 50px;
}
```

![My helpful screenshot]({{ "/images/smoothScroll1.gif" | absolute_url }})
![My helpful screenshot]({{ "/images/smoothScroll2.gif" | absolute_url }})
```css
html {
  scroll-behavior: smooth;
}
```
