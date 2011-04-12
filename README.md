# Nostos

Nostos simplifies library circulation systems by integrating transactions from disparate systems. 

Nostos was originally developed to integrate a library's interlibary loan system with its integrated library system. This lets libraries to manage circulation within a single system, allowing patrons to check a single account and simplifying their experience. It also improves administration in that circulation notifications, policies, reporting, and auditing originate from a single sytem, which is most likely the library's most powerful/mature circulation system.

## Configuration

Nostos does not ship with any particular source or target drivers. They must be installed individually and according to your needs.

### Source Drivers

* [Illiad](https://github.com/bricestacey/nostos-source-illiad)

### Target Drivers

* [Voyager](https://github.com/bricestacey/nostos-target-voyager)

Create a file `config/nostos.yml` as below. The below configuration is for the production environment. `sources` should be an Array of sources. `targets` should be an Array of targets. `mapping` should contain key:value pairs corresponding to source:targets respectively.

    production:
      sources: ['Source::Illiad']
      targets: ['Target::Voyager']
      mapping:
        'Source::Illiad': 'Target::Voyager'

Configure `config/database.yml` as appropriate and run `rake RAILS_ENV=production db:migrate`.

### Automating Nostos

Setup a cron job to run, fairly often. The following cronjob will run `rake nostos:cron` every 15 minutes and log the output to `log/production.log`.

    */15 *  *    *   *     /bin/bash -l -i -c 'cd /path/to/nostos && rake RAILS_ENV=production nostos:cron' >> /path/to/nostos/log/production.log 2>&1

## Rake Tasks

In general, you should use `nostos:cron` to automate your system. However, there are other rake tasks available.

* `nostos:poll_sources` - polls sources for new transactions.
* `nostos:send_to_targets` - sends transactions to their target system.
* `nostos:cron` - polls then sends.

## Writing Drivers

Nostos is designed to be a easily extended. The following sections describe how you might implement a source or target driver for a system.

### Source Interface

Source drivers must implement the following:

* Accessors: `id`, `title`, `due_date`, `charged?`
* `self.find(id)`: returns a Source object corresponding to `id`
* `self.poll`: returns an Array of Source objects that may be new. This method may return objects that are old.

### Target Interface

Target drivers must implement the following:

* Accessors: `id, `title`, `due_date`, `charged?`
* `self.find(id)`: returns a Target object corresponding to `id`
* `self.create(source_object)`: creates a transaction in the target system and returns the item. If the item already exists, do not create, but still return the item.

# Author

Nostos was written by [Brice Stacey](https://github.com/bricestacey)
