# Singularity Compose Simple

This is a simple, dummy example of creating a web application with Singularity
using just one container. Since Singularity network bridges get buggy given a user
(like myself) has Docker installed, this example oversteps that by not
requiring communiction between containers. The multiple container
example (that still has this issue) can be found at 
[singularityhub/singularity-compose-example](https://www.github.com/singularityhub/singularity-compose-example). Both are based on [django-nginx-upload](https://github.com/vsoch/django-nginx-upload).

## Setup

### singularity-compose.yml

For a singularity-compose project, it's expected to have a `singularity-compose.yml`
in the present working directory. You can look at the [example](singularity-compose.yml)
paired with the [specification](https://github.com/singularityhub/singularity-compose/tree/master/spec) 
to understand the fields provided. 

### Instance folders

Generally, each section in the yaml file corresponds with a container instance to be run, 
and each container instance is matched to a folder in the present working directory.
For example, if I give instruction to build an `nginx` instance from
a `nginx/Singularity.nginx` file, I should have the
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
in that folder.  While the context for starting containers with Singularity
compose is the directory location of the `singularity-compose.yml`,
the build context for this container is inside the nginx folder.
As another option, you can just define a container to pull,
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

It's less likely that you will be able to pull a container that is ready to
go, as typically you will want to customize the 
[startscript](https://sylabs.io/guides/3.2/user-guide/definition_files.html#startscript) 
for the instance.

## Quick Start

The quickest way to start is to build the one required container

```bash
$ singularity-compose build
```

and then bring it up!

```bash
$ singularity-compose up
```

Verify it's running:

```bash
$ singularity-compose ps
INSTANCES  NAME PID     IMAGE
1           app	20023	app.sif
```

And then look at logs, shell inside, or execute a command.

```bash
$ singularity-compose logs app
$ singularity-compose logs app --tail 30
$ singularity-compose shell app
$ singularity-compose exec app uname -a
```

When you open your browser to [http://127.0.0.1](http://127.0.0.1)
you should see the upload interface. 

![images/upload.png](images/upload.png)

If you drop a file in the box (or click
to select) we will use the nginx-upload module to send it directly to the
server. Cool!

![images/content.png](images/content.png)

This is just a simple Django application, the database is sqlite3, in the
app folder:

```bash
$ ls app/
app.sif  db.sqlite3  manage.py  nginx  requirements.txt  run_uwsgi.sh  Singularity  upload  uwsgi.ini
```

The images are stored in [images]():

```bash
$ ls images/
2018-02-20-172617.jpg  40-acos.png  _upload 
```

And static files are in [static](static).

```bash
$ ls static/
admin  css  js
```

If you look at the [singularity-compose.yml](singularity-compose.yml), we bind these
folders to locations in the container where the web server needs write. This is likely
a prime different between Singularity and Docker compose - Docker doesn't need
binds for write, but rather to reduce isolation. Continue below to 
read about networking, and see these commands in detail.

## Networking

When you bring the container up, you'll see generation of an `etc.hosts` file,
and if you guessed it, this is indeed bound to `/etc/hosts` in the container.
Let's take a look:

```bash
10.22.0.2	app
127.0.0.1	localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

This file will give each container that you create (in our case, just one)
a name on its local network. Singularity by default creates a bridge for
instance containers, which you can conceptually think of as a router,
This means that, if I were to reference the hostname "app" in a second container,
it would resolve to `10.22.0.2`. Singularity compose does this by generating
these addresses before creating the instances, and then assigning them to it.
If you would like to see the full commands that are generated, run the up
with `--debug` (binds and full paths have been removed to make this easier to read).

```bash
$ singularity instance start \
    --bind /home/vanessa/Documents/Dropbox/Code/singularity/singularity-compose-simple/etc.hosts:/etc/hosts \
    --net --network-args "portmap=80:80/tcp" --network-args "IP=10.22.0.2" \
    --hostname app \
    --writable-tmpfs app.sif app
```

## Commands

The following commands are currently supported. Remember, you must be in the 
present working directory of the compose file to reference the correct instances.

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
If the build requires sudo (if you've defined sections in the config that warrant
setting up networking with sudo) the build will instead give you an instruction
to run with sudo.

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

Up is typically the command that you want to use to bring containers up and down.

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

It's sometimes helpful to peek inside a running instance, either to look at permissions,
inspect binds, or manually test running something.
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
$ singularity-compose config
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
