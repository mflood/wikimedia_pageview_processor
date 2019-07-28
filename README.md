# Datadog Take Home Project


# Running the app

> requires python3, virtualenv, pip

```
cd app
./setup.sh
./run_test coverage
./run.sh
./run_range.sh
```


# How to Test

> Document a sanity check that can be performed on a single date/hour
for example:

## Sanity Check 1
    1. Look at the output report
    2. pick a domain at random
    3. ZCat the actual pageview file and manually compare the top 25 pages with the report output

## Sanity Check 2
    1. Alter the downloaded file to make some other pageview the top view
    2. re-run the report and ensure that the new page is the winning view
    3. repeat this with pages that have non-ascii chars
    
## Regression/Unit tests

    1. Unit tests
    2. Use a small sample file and run regression tests against that file.

## Report Validation
    - Code up a module for report file validation, things like:
        - "en" domain should have the largest numbers
        - "en" views should be more than 5000, etc...
        - file should contain at least N domains
        - no domain should have more than 25 entries
        - entries are sorted
        - etc...


# Production considerations

## metrics collection / monitoring

- send metrics for date/hour, pageview file num lines, output report size to datadog
- put monitoring around those ^ metrics

## deployment

- run app inside docker container
- use airflow for job control
- put some thought into how localtime affects the run. Files for the current day are only available after a certain
period of time so local machine time is important

## hourly job run

- make the script process the last N hours by default
- since it would skip files already processed, this would essentially
allow it to catch back up if it failed to run for some time and it would
normally just process a single hour

## cache directory for downloaded pageview files

- Implement purging of downloaded pageview files to avoid running out of disk space.
- Use a more scalable directory structure year/month/files.gz
- need to add a flag to re-download files for a more robust solution to corrupted/incomplete files

## Report output

- Reports should be output to s3 so independent instances can be run
- Consider storing report in a datamart along the lines of:

```{sql}
    -- rough draft just to illustrate basic design.
    -- This DDL has not been tested and syntax may be off.
    create table pageview_fact(
        pageview_fact_id int unsigned not null auto_increment primary key
      , datehour int unsigned not null
      , domain_dim_id int unsigned not null
      , page_dim_id int unsigned not null
      , num_views int unsigned not null
      , num_views_rank tinyint unsigned not null
      , create_time timestamp not null default current_timestamp
      , update_time timestamp not null default current_timestamp on update current_timestamp

      , unique (datehour, domain_id, page_id)
      , index(domain_id, page_id)
      , index(page_id)
    ) charset=utf8mb4;

    create table domain_dim (
        domain_dim_id int unsigned not null auto_increment primary key
      , domain_name varchar(255) not null unique
      , create_time timestamp not null default current_timestamp
      , update_time timestamp not null default current_timestamp on update current_timestamp
    ) charset=utf8mb4;

    create table page_dim (
        page_dim_id int unsigned not null auto_increment primary key
      , page_name varchar(255) not null unique
      , create_time timestamp not null default current_timestamp
      , update_time timestamp not null default current_timestamp on update current_timestamp
    ) charset=utf8mb4;

```

# Application Design Improvements

    - Harden the app against network failure
    - Harden the app against missing files or invalid URLs
    - Auto re-download when gzip file is corrupt
    - Make the app long-running and scalable, where it pulls year/month/day/hour off of a queue
    - See testing section for ideas about validation
    - add --refresh-blacklist flag to re-download the blacklist
