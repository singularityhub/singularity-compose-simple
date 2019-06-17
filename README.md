# Singularity Compose Example

**under development**

This is an example of simple container orchestration with singularity-compose,
It is based on [django-nginx-upload](https://github.com/vsoch/django-nginx-upload).

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
easily tell if we've already built or pulled it.

```bash
$ singularity-compose build .
```

The "." at the end indicates we are building in the present working directory,
which is the most common use case.
