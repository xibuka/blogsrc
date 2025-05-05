---
title: "Moving From Hexo to Hugo"
date: 2020-03-30T14:07:21+09:00
draft: false
---

## Moving from Hexo to Hugo

I used to write my blog with Hexo, but switched to Hugo while learning Golang.
There are several reasons, but the main points are:

1. Hexo relies on multiple modules, which sometimes causes installation failures.
2. In contrast, Hugo works with just a single binary.
3. The speed of generating HTML files is much faster with Hugo than with Hexo.

I'll skip the details of how to install and use Hugo, but here I'll summarize the issues I encountered during the migration.

### How to Add Tags

With Hexo, the following tag format was fine, but it doesn't work with Hugo:

```conf
tag: Python
```

For Hugo, unify the format as below and there will be no problem:

```conf
tags:
- Python
```

### Where to Save Blog md Files

This depends on the theme. In my case, using the Even theme, it's under the `post` directory.

### Publishing Generated Blog Pages and Integrating with Github Action

With Hexo, you could push to Github using the `deploy` subcommand, but with Hugo, that's not possible.
The `Hugo deploy` command does exist, but it's mainly for AWS, GCE, or Azure:
[https://gohugo.io/hosting-and-deployment/hugo-deploy/](https://gohugo.io/hosting-and-deployment/hugo-deploy/)

Therefore, you need to manually push the generated files to your Github Pages repository.
The generated blog pages are in the `public` directory.
If you use Github Action, you can automate the process: after writing and pushing a new article, the above steps can be fully automated.
I'll summarize how to do that in the next post.

### Enabling https

This isn't directly related to Hugo, but I also used CloudFlare to enable https.
