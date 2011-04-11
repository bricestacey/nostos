# Nostos

Nostos simplifies library circulation systems by integrating transactions from disparate systems. 

Nostos was originally developed to integrate a library's interlibary loan system with its integrated library system. This lets libraries to manage circulation within a single system, allowing patrons to check a single account and simplifying their experience. It also improves administration in that circulation notifications, policies, reporting, and auditing originate from a single sytem, which is most likely the library's most powerful/mature circulation system.

## Configuration

Nostos currently ships with an Illiad source driver and a Voyager target driver. These must be configured or replaced with alternate drivers.

### Configure Illiad source driver

Install and configure FreeTDS for your system.

Create a file `config/source_illiad.yml` as below. Replace `environment` with the appropriate environment: test, development, or production. Then fill in the other attributes. `dataserver` is the name for your server as defined in freetds.conf. `number_of_days_old_transactions` is how many days you want to poll into the past. This number must be greater than how often you run Nostos in order to stay synchronized. I recommend 2-3 days at most.

    environment:
      number_of_days_old_transactions: 2
      db:
        adapter:  "sqlserver"
        dataserver:
        host:     
        dsn:      
        username: 
        password:
        database:

### Configure Voyager target driver

Create a file `config/target_voyager.yml` as below. Replace `environment` with the appropriate environment: test, development, or production. Then fill in the other attributes. Note that `username` and `location` is the operator id and location code used to sign into the SIP server (or Circulation module). `operator` is the operator id used for creating items. Theoretically they should be identical, however it is not required.

    environment:
      sip:
        host: 
        port:
        username:
        password:
        operator:
        location:

For more information on how to configure your Voyager system for SIP see the manual _Voyager 7.2 Interface to Self Check Modules Using 3M SIP User's Guide, November 2009_

### Configure Nostos

Create a file `config/nostos.yml` as below. Currently, Nostos ships with an Illiad source driver and a Voyager target driver and is configured for that. The below configuration is for the production environment. `sources` should be an Array of sources. `targets` should be an Array of targets. `mapping` should contain key:value pairs corresponding to source:targets respectively.

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

# See Also

These are some other gems I've developed that are used for the Illiad and Voyager drivers.

* [activerecord-illiad-adapter](https://github.com/bricestacey/activerecord-illiad-adapter) - For connecting with Illiad SQLServer database.
* [voyager-sip](https://github.com/bricestacey/voyager-sip) - For connecting with Voyager via SIP.

# Author

Nostos was written by [Brice Stacey](https://github.com/bricestacey)
