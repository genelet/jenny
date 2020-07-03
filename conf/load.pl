#!/usr/bin/perl

use strict;
use DBI;
use Text::CSV;

my $dbh = DBI->connect("dbi:mysql:database=jenny;host=localhost;port=3306", "root", "sntmnc") or die $!;
my $ins = $dbh->prepare(qq~INSERT INTO Book3_csv (RECALL_NUMBER_NUM,YEAR,MANUFACTURER_RECALL_NO_TXT,CATEGORY_ETXT,CATEGORY_FTXT,MAKE_NAME_NM,MODEL_NAME_NM,UNIT_AFFECTED_NBR,SYSTEM_TYPE_ETXT,SYSTEM_TYPE_FTXT,NOTIFICATION_TYPE_ETXT,NOTIFICATION_TYPE_FTXT,COMMENT_ETXT,COMMENT_FTXT,RECALL_DATE_DTE,updated) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,CURDATE())~) or die $!;
my $sth = $dbh->prepare(qq~SELECT tabilet_id FROM Book3_csv WHERE RECALL_NUMBER_NUM=?~) or die $!;

my $csv = Text::CSV->new ({ binary => 1, auto_diag => 1 });
my $fh;
open $fh, "<:encoding(utf8)", "vrdb_full_monthly.csv" or return $!;
my $k=0;
my $num = 0;
while (my $row = $csv->getline ($fh)) {
	if ($k==0) {
		$k++;
		next;
	}
	$k++;
	$row->[1] =~ s/,//;
	$row->[7] =~ s/,//;
warn $k if (($k % 1000) ==0);
=pod
	$sth->execute($row->[0]) or return $dbh->errstr();
	my $e = 0;
	while (my $data = $sth->fetchrow_arrayref) {
		$e++;
	}
	$sth->finish;
	if ($e==0) {
=cut
		$ins->execute(@$row) or return $dbh->errstr();
#	}
}
close($fh);
$ins->finish;

$dbh->disconnect;

exit(0);
