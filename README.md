# [Vaultwarden](https://github.com/dani-garcia/vaultwarden) with Cloudflare Zero Trust

Selfhosted Vaultwarden with Nginx and Cloudflare Zero Trust as reverse proxy and security

## Step 1: Set up Google Cloud `e2-micro` Compute Engine Instance

Google Cloud offers an '[always free](https://cloud.google.com/free/)' tier of their Compute Engine with one virtual core and ~600 MB of RAM (about 150 MB free depending on which OS you installed).

Go to [Google Compute Engine](https://cloud.google.com/compute) and open a Cloud Shell. You may also create the instance manually following [the constraints of the free tier](https://cloud.google.com/free/docs/gcp-free-tier). In the Cloud Shell enter the following command to build the properly spec'd machine: 

```bash
$ gcloud compute instances create vaultwarden \
    --machine-type e2-micro \
    --zone us-central1-a \
    --image-project cos-cloud \
    --image-family cos-stable \
    --boot-disk-size=30GB \
    --scopes compute-rw
```

## Step 2: Clone and Configure Docker-compose alias

Enter a shell on the new instance and clone this repo:

```bash
$ git clone https://github.com/abdulaziz-git/vaultwarden-cloudflare-zero-trust.git
$ cd vaultwarden-cloudflare-zero-trust
```

Set up the docker-compose alias by using the included script:

```bash
$ sh utilities/install-alias.sh
$ source ~/.bashrc
$ docker-compose version
docker-compose version 1.26.2, build eefe0d3
docker-py version: 4.2.2
CPython version: 3.7.7
OpenSSL version: OpenSSL 1.1.1g  21 Apr 2020
```

### Configure Environmental Variables with `.env`

I provide `.env.template` which should be copied to `.env` and filled out; filling it out is self-explanitory and requires certain values such as a domain name, Cloudflare tokens, etc. 

Add domain name to `.env`, please make sure that your domain is already added to Cloudflare.

### Configure Zero Trust
To get Zero Trust tunnel token, you need to register here https://www.cloudflare.com/products/zero-trust/.
After that create a tunnel in Zero Trust dashboard, copy tunnel tokens and add to `CLOUDFLARED_TOKEN` in `.env` file

## Step 3: Start Services

To start up, use `docker-compose`:

```bash
$ docker-compose up -d
```

After that go back to Cloudflare Zero Trust tunnel page.

- Go to `Public Hostname` and click `Add a public hostname` button
- Select domain you configure in `.env` file
- Set Service Type to `HTTP`
- Set URL to `proxy:80`
- Click `Save hostname`