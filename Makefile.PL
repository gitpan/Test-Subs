use ExtUtils::MakeMaker;

WriteMakefile(
		NAME => 'Test::Subs',
		AUTHOR => 'Mathias Kende <mathias@cpan.org>',
		VERSION_FROM => 'lib/Test/Subs.pm',
		ABSTRACT_FROM => 'lib/Test/Subs.pm',
		#README_FROM => 'lib/Test/Subs.pm',
		LICENSE => 'perl',
		MIN_PERL_VERSION => '5.8.0',
		CONFIGURE_REQUIRES => {
				'ExtUtils::MakeMaker' => 6.3002,
			},
		BUILD_REQUIRES => {},
		PREREQ_PM => {
				'Exporter' => 0,
				'Filter::Simple' => 0,
				'Carp' => 0
    		},
	);

