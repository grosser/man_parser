Parse man source

Install
=======
    sudo gem install grosser-man_parser -s http://gems.github.com/

Usage
=====
    ManParser.parse('ls')
    # all the sections
    :sections=>{
      "NAME"=>"printf \\- format and print data",
      "SYNOPSIS"=>".B printf\n\\f...",
      "AUTHOR"=>"Written by David MacKenzie.",
      ...
    },

    # options parsed into :name, :alias, :argument, :description
    :options=>[
      {:name=>"help", :description=>"display this help and exit"},
      {:name=>"version", :description=>"output version information and exit"},
      {:alias=>"Z", :name => 'context', :description=>"print any SELinux security context of each file"}
    ],

    # description without options
    :description=>".PPPrint ARGUMENT(s) according to FORMAT\n bla bla...."}

TODO
====
 - add to_html("\fBxx\fR") == "<b>xx</b>"

Author
======
[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...