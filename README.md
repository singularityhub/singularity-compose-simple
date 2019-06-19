# Singularity Compose Simple

This is a simple, dummy example of creating a web application with Singularity
using just one container. Since Singularity network bridges get buggy given a user
(like myself) has Docker installed, this example oversteps that by not
requiring communiction between containers. It is still based on 
[django-nginx-upload](https://github.com/vsoch/django-nginx-upload).

## Setup

### singularity-compose.yml

For a singularity-compose project, it's expected to have a `singularity-compose.yml`
in the present working directory. You can look at the [example](singularity-compose.yml)
paired with the [specification](https://github.com/singularityhub/singularity-compose/tree/master/spec) 
to understand the fields provided. 

### Instance folders

Generally, each section in the yaml file corresponds with a container instance to be run, 
and each container instance is matched to a folder in the present working directory.
For example, if I give instruction to build an [nginx](nginx) instance from
a [Singularity.nginx](nginx/Singularity.nginx) file, I should have the
following in my singularity-compose:

```
  nginx:
    build:
      context: ./nginx
      recipe: Singularity.nginx
...
```

paired with the following directory structure:

```bash
singularity-compose-example
├── nginx
...
│   ├── Singularity.nginx
│   └── uwsgi_params.par
└── singularity-compose.yml

```

Notice how I also have other dependency files for the nginx container
in that folder.  As another option, you can just define a container to pull,
and it will be pulled to the same folder that is created if it doesn't exist.

```
  nginx:
    image: docker://nginx
...
```

```bash
singularity-compose-example
├── nginx                    (- created if it doesn't exist
│   └── nginx.sif            (- named according to the instance
└── singularity-compose.yml

```

## Commands

The following commands are currently supported.

### Build

Build will either build a container recipe, or pull a container to the
instance folder. In both cases, it's named after the instance so we can
easily tell if we've already built or pulled it. This is typically
the first step that you are required to do in order to build or pull your
recipes. It ensures reproducibility because we ensure the container binary
exists first.

```bash
$ singularity-compose build
```

The working directory is the parent folder of the singularity-compose.yml file.

### Create

Given that you have built your containers with `singularity-compose build`,
you can create your instances as follows:

```bash
$ singularity-compose create
```

### Up

If you want to both build and bring them up, you can use "up." Note that for
builds that require sudo, this will still stop and ask you to build with sudo.

```bash
$ singularity-compose up
```

### ps

You can list running instances with "ps":

```bash
$ singularity-compose ps
INSTANCES  NAME PID     IMAGE
1           app	6659	app.sif
2            db	6788	db.sif
3         nginx	6543	nginx.sif
```

### Shell

You can easily shell inside of a running instance:

```bash
$ singularity-compose shell app
Singularity app.sif:~/Documents/Dropbox/Code/singularity/singularity-compose-example> 
```

### Exec

You can easily execute a command to a running instance:

```bash
$ singularity-compose exec app ls /
bin
boot
code
dev
environment
etc
home
lib
lib64
media
mnt
opt
proc
root
run
sbin
singularity
srv
sys
tmp
usr
var
```

### Down

You can bring one or more instances down (meaning, stopping them) by doing:

```bash
$ singularity-compose down
Stopping (instance:nginx)
Stopping (instance:db)
Stopping (instance:app)
```

To stop a custom set, just specify them:


```bash
$ singularity-compose down nginx
```

### Logs

You can of course view logs for all instances, or just specific named ones:

```bash
$ singularity-compose logs --tail 10
nginx ERR
nginx: [emerg] host not found in upstream "uwsgi" in /etc/nginx/conf.d/default.conf:22
2019/06/18 15:41:35 [emerg] 15#15: host not found in upstream "uwsgi" in /etc/nginx/conf.d/default.conf:22
nginx: [emerg] host not found in upstream "uwsgi" in /etc/nginx/conf.d/default.conf:22
2019/06/18 16:04:42 [emerg] 15#15: host not found in upstream "uwsgi" in /etc/nginx/conf.d/default.conf:22
nginx: [emerg] host not found in upstream "uwsgi" in /etc/nginx/conf.d/default.conf:22
2019/06/18 16:50:03 [emerg] 15#15: host not found in upstream "uwsgi" in /etc/nginx/conf.d/default.conf:22
nginx: [emerg] host not found in upstream "uwsgi" in /etc/nginx/conf.d/default.conf:22
2019/06/18 16:51:32 [emerg] 15#15: host not found in upstream "uwsgi" in /etc/nginx/conf.d/default.conf:22
nginx: [emerg] host not found in upstream "uwsgi" in /etc/nginx/conf.d/default.conf:22
``

### Config

You can load and validate the configuration file (singularity-compose.yml) and
print it to the screen as follows:

```bash
$ singularity-compose config .
{
    "version": "1.0",
    "instances": {
        "nginx": {
            "build": {
                "context": "./nginx",
                "recipe": "Singularity.nginx"
            },
            "volumes": [
                "./nginx.conf:/etc/nginx/conf.d/default.conf:ro",
                "./uwsgi_params.par:/etc/nginx/uwsgi_params.par:ro",
                ".:/code",
                "./static:/var/www/static",
                "./images:/var/www/images"
            ],
            "volumes_from": [
                "app"
            ],
            "ports": [
                "80"
            ]
        },
        "db": {
            "image": "docker://postgres:9.4",
            "volumes": [
                "db-data:/var/lib/postgresql/data"
            ]
        },
        "app": {
            "build": {
                "context": "./app"
            },
            "volumes": [
                ".:/code",
                "./static:/var/www/static",
                "./images:/var/www/images"
            ],
            "ports": [
                "5000:80"
            ],
            "depends_on": [
                "nginx"
            ]
        }
    }
}
```
