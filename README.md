# [Vaultwarden](https://github.com/dani-garcia/vaultwarden) with Cloudflare Zero Trust

Selfhosted Vaultwarden with Nginx and Cloudflare Zero Trust as reverse proxy and security

## Zero Trust
To get Zero Trust tunnel token, you need to register here https://www.cloudflare.com/products/zero-trust/.
After that create a tunnel in Zero Trust dashboard, copy tunnel tokens and add to CLOUDFLARED_TOKEN in .env file

Add public hostname service as http://proxy:80
