Parse man source

Install
=======
    sudo gem install man_parser -s http://gemcutter.org

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

### available_commands
    ManParser.available_commands => array of commands that are available for parsing

### source
    ManParser.source('ls') => uncleaned source of man file

TODO
====
 - add to_html("\fBxx\fR") == "<b>xx</b>"

Author
======
[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...