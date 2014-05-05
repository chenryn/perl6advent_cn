use HTML::WikiConverter;
use Mojo::UserAgent;
use Data::Dumper;
my $ua = Mojo::UserAgent->new();
my $url = 'http://perlcabal.org/syn/Differences.html';
my $html = $ua->get($url)->res->body;
my $wc = new HTML::WikiConverter( dialect => 'Markdown' );
print $wc->html2wiki( $html );
