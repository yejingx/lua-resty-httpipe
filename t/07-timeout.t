# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => repeat_each() * (blocks() * 3);

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';

no_long_string();
#no_diff();

run_tests();

__DATA__
=== TEST 1: Read timeout.
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local httpipe = require "resty.httpipe"
            local hp = httpipe:new()

            hp:set_timeout(3 * 1000)

            local res, err = hp:request("127.0.0.1", ngx.var.server_port, {
                path = "/b",
                read_timeout = 2 * 1000
            })

            ngx.say(err)
        ';
    }
    location = /b {
        content_by_lua '
            ngx.sleep(2)
            return ngx.exit(ngx.HTTP_OK)
        ';
    }
--- request
GET /t
--- response_body
timeout
--- error_log
lua tcp socket read timed out
--- timeout: 4
