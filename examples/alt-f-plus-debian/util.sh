#!/bin/sh

log() {
    echo "---------------------------------------" 2>&1 >> /tmp/flossware.log
    echo `date`  $@ 2>&1 >> /tmp/flossware.log
    echo "---------------------------------------" 2>&1 >> /tmp/flossware.log
    echo 2>&1 >> /tmp/flossware.log
}
