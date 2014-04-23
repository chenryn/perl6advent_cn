use HTML::WikiConverter;
use Mojo::UserAgent;
use Data::Dumper;
my $ua = Mojo::UserAgent->new();
my $html = $ua->get('http://perlgeek.de/en/article/5-to-6#post_00')->res->body;
my $wc = new HTML::WikiConverter( dialect => 'Markdown' );
print $wc->html2wiki( $html );
