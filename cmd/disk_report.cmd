# list disk space on machine
# Author: Adam Richards
date
df -Ph | perl -ne 'chomp; printf "\n%-50s %8s %8s %8s %8s %-20s", split / +/, $_, 6 ; ';echo ""
