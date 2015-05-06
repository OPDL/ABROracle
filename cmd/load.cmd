#!/bin/bash
date
w | head -n 1 |sed -e s/^/`hostname`/

