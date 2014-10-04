use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Disk::SMART',
    AUTHOR              => q{Paul Trost <paul.trost@trostfamily.org>},
    VERSION_FROM        => 'lib/Disk/SMART.pm',
    ABSTRACT_FROM       => 'lib/Disk/SMART.pm',
    ($ExtUtils::MakeMaker::VERSION ge 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Disk-SMART-*' },
);
