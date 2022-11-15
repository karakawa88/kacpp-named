#!/bin/bash

systemctl daemon-reload
systemctl enable named
systemctl start named

exit 0

