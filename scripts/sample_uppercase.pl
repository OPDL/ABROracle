#!/usr/bin/perl
my @a = 
(
    "THIS IS TESTING",
    "JOE MARCONES",
    "RESIDENTIAL MAINTENANCE COMPANY",
);

s/(?<=\w)(.)/\l$1/g for @a;

print join "\n", @a;
