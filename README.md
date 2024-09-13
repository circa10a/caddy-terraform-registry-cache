# caddy-terraform-registry-cache <img src="https://i.imgur.com/fAS7XqO.png" height="5%" width="5%" align="left"/>

A pull-through cache for Terraform providers using only Caddy. [Inspired by terrateam.io's blog post](https://terrateam.io/blog/terraform-registry-cache)

![Build Status](https://github.com/circa10a/caddy-terraform-registry-cache/workflows/deploy/badge.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/circa10a/caddy-terraform-registry-cache?style=plastic)

<img src="https://user-images.githubusercontent.com/1128849/36338535-05fb646a-136f-11e8-987b-e6901e717d5a.png" height="60%" width="60%"/>

## Background

> [!CAUTION]
> If you're thinking about using this in production to save yourself from Hashicorp's occasional CDN outages. You should know that this doesn't support caching providers from GitHub, only official hashicorp namespaced providers.

I was browsing reddit recently and came across this [post](https://www.reddit.com/r/Terraform/comments/u11m4u/terraform_provider_cache/?rdt=61441) that described a user reproducing a custom Go application that served as a Terraform provider proxy + cache, but reimplemented with Nginx. I thought it was a pretty cool idea and wanted to see if I could implement my own verison using my favorite web server [caddy](https://caddyserver.com/). Thus, the reason for this project.

## Requirements

You'll need two domains pointed at the address that hosts this web server. They'll be referred to as `REGISTRY_SITE_ADDRESS` and `RELEASES_SITE_ADDRESS` in this README. We need two because registry.terraform.io serves JSON that references a separate URL that points to `releases.hashicorp.com` and we need SNI rules in the reverse proxy configuration to support proxying both sites. TLDR; two sites, one server.

## Usage

To run `caddy-terraform-registry-cache`, you'll need two domains with DNS records for your host(s). This is required due to the use of the [ACME protocol implemented by Caddy](https://caddyserver.com/docs/automatic-https) for automatic TLS by using certificates issued by [Let's Encrypt](https://letsencrypt.org/) because Terraform/Opentofu require registries to use HTTPS. The configuration could of course be [modified to supply your own certificate and key](https://caddyserver.com/docs/caddyfile/directives/tls), but it isn't natively supported via environment variables.

```console
docker run --rm --name caddy-terraform-registry-cache  \
    -e REGISTRY_SITE_ADDRESS \
    -e RELEASES_SITE_ADDRESS \
    -v ./cache:/cache \
    -p 443:443 \
    -p 80:80 \
    circa10a/caddy-terraform-registry-cache
````

> [!IMPORTANT]
> If you made it past the red bulletin and still want to continue, you should _also_ know that if this server is restarted while Hashicorp's CDN is down, you'll receive 502's. Look it's not me, it's the implementation of caddy's [cache-handler](https://github.com/caddyserver/cache-handler)

### Terraform configuration

You'll need to modify your Terraform/Opentofu source to point to the caddy reverse proxy. Yes, this does indeed mean that we're installing entirely different providers from a Terraform perspective and it is much more ideal to implement [the network mirror protocol](https://developer.hashicorp.com/terraform/internals/provider-network-mirror-protocol). I understand why Hashicorp did this since the protocol does allow for some more flexiblility for download locations.

Here's how you use this proxy in Terraform:

```hcl
terraform {
  required_providers {
    aws = {
      source = "${REGISTRY_SITE_ADDRESS}/hashicorp/aws"
    }
  }
}
```
