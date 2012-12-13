Sometimes things go horribly wrong, and the only thing you can do is not to go
on. Then you throw an exception.

But of course the story doesn’t end there. The caller (or the caller’s caller)
must somehow deal with the exception. To do that in a sensible manner, the
caller needs to have as much information as possible.

In Perl 6, exceptions should inherit from the type `Exception`, and by
convention they go into the `X::` namespace.

So for example if you write a HTTP client library, and you decide that an
exception should be thrown when the server returns a status code starting with
4 or 5, you could declare your exception class as

    
     class X::HTTP is Exception {
            has $.request-method;
                 has $.url;
                      has $.status;
                           has $.error-string;
    
                                method message() {
                                            "Error during $.request-method request"
                                                     ~ " to $.url: $.status
                                                     $.error-string";
                                                          }
                                                           }

And throw an exception as

    
     die X::HTTP.new(
         request-method  => 'GET',
              url             => 'http://example.com/no-such-file',
                   status          => 404,
                        error-string    => 'Not found',
                         );

The error message then looks like this:

    
     Error during GET request to
        http://example.com/no-such-file: 404 Not found

(line wrapped for the benefit of small browser windows).

If the exception is not caught, the program aborts and prints the error
message, as well as a backtrace.

There are two ways to catch exceptions. The simple Pokemon style “gotta catch
‘em all” method catches exception of any type with `try`:

    
     my $result = try do-operation-that-might-die();
     if ($!) {
             note "There was an error: $!";
                  note "But I'm going to go on anyway";
                   }

Or you can selectively catch some exception types and handle only them, and
rethrow all other exceptions to the caller:

    
     my $result =  do-operation-that-might-die();
     CATCH {
             when X::HTTP {
                         note "Got an HTTP error for URL $_.url()";
                                  # do some proper error handling
                                       }
                                            # exceptions not of type X::HTTP are
                                            rethrown
                                             }

Note that the CATCH block is inside the same scope as the one where the error
might occur, so that by default you have access to all the interesting
varibles from that scope, which makes it easy to generate better error
messages.

Inside the CATCH block, the exception is available as `$_`, and is matched
against all `when` blocks.

Even if you don’t need to selectively catch your exceptions, it still makes
sense to declare specific classes, because that makes it very easy to write
tests that checks for proper error reporting. You can check the type and the
payload of the exceptions, without having to resort to checking the exact
error message (which is always brittle).

But Perl 6 being Perl, it doesn’t force you to write your own exception types.
If you pass a non-`Exception` objects to `die()`, it simply wraps them in an
object of type `X::AdHoc` (which in turn inherits from `Exception`), and makes
the argument available with the `payload` method:

    
        sub I-am-fatal() {
               die "Neat error message";
                   }
                       try I-am-fatal();
                           say $!;             # Neat error message;
                               say $!.perl;        # X::AdHoc.new(payload =>
                               "Neat error message")

To find out more about exception handling, you can read [the documentation of
class Exception](http://doc.perl6.org/type/Exception) and
[Backtrace](http://doc.perl6.org/type/Backtrace).

