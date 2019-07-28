#!/bin/sh 
#
# runs the report using the defaults
# which runs for the current date and hour (localtime)
#
date
source venv/bin/activate
python3 datadog/driver.py --date=2019-04-01 --hour=12
date
