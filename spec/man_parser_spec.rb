require 'spec/spec_helper'

describe ManParser do
  describe :parse do
    it "finds the description" do
      d = ManParser.parse('ls')[:description]
      d.should =~ /^\.\\\" Add any additional description here\.PPList infor/
      d.should =~ /problems, 2 if serious trouble\.$/
      d.should_not include('\\-\\-all')
      d.should_not include('do not ignore entries starting with')
      d.should_not include("      ")
    end

    describe 'options in description' do
      def options
        ManParser.parse('ls')[:options]
      end

      it "finds all options" do
        options.size.should == 58
      end

      it "extracts the name" do
        options.first[:name].should == 'all'
      end

      it "extracts the alias" do
        options.first[:alias].should == 'a'
      end

      it "extracts the description" do
        options.first[:description].should == 'do not ignore entries starting with .'
      end

      it "understands format with only name (--author)" do
        options[2].should == {:name=>'author', :description=>'with -l, print the author of each file'}
      end
    end

    describe 'options in OPTIONS section' do
      def options
        ManParser.parse('acpi')[:options]
      end

      it "finds all options x" do
        options.size.should == 18
      end

      it "extracts the name" do
        options.first[:name].should == 'battery'
      end

      it "extracts the alias" do
        options.first[:alias].should == 'b'
      end

      it "extracts the description" do
        options.first[:description].should == 'show battery information'
      end
    end
  end

  describe :source do
    it "reads the source" do
      ManParser.source('printf').should =~ /^.\\\" DO NOT MODIFY THIS F(.*) access to the complete manual.\n$/m
    end
  end

  describe :available_commands do
    it "finds them" do
      ManParser.available_commands.should include('printf')
    end
  end

  describe :parse_option do
    def parse(x)
      ManParser.send(:parse_option, x)
    end

    it "parses single --" do
      x = parse('\fB\-\-help\fR display this help and exit .TP')
      x.should == {:name=>"help", :description=>"display this help and exit"}
    end

    it "parses single -- with =" do
      x = parse('\fB\-\-block\-size\fR=\fISIZE\fR xyz')
      x.should == {:name => 'block-size', :argument=>'SIZE', :description=>"xyz"}
    end

    it "parses single -" do
      x = parse('\fB\-1\fR list one file per line .TP')
      x.should == {:alias=>"1", :description=>"list one file per line"}
    end

    it "parses - and --" do
      x = parse('\fB\-Z\fR, \fB\-\-context\fR print any SELinux security context of each file .TP')
      x.should == {:alias=>"Z", :name => 'context', :description=>"print any SELinux security context of each file"}
    end

    it "parses - and -- with =" do
      x = parse('\fB\-T\fR, \fB\-\-tabsize\fR=\fICOLS\fR assume tab stops at each COLS instead of 8 .TP')
      x.should == {:alias=>"T", :name => 'tabsize', :argument=>'COLS', :description=>"assume tab stops at each COLS instead of 8"}
    end

    it "parses - and -- with <dir>" do
      x = parse('.IP "\fB-d | --directory <dir>\fP " 10 bla bla')
      x.should == {:alias=>'d', :name=>'directory', :argument=>'dir', :description=>'" 10 bla bla'}
    end

    it "does not parse random stuff" do
      ManParser.stub!(:puts)
      x = parse('as we say: \fB\-T\fR, \fB\-\-tabsize\fR=\fICOLS\fR assume tab stops at each COLS instead of 8')
      x.should == nil
    end
  end

  describe :is_option? do
    {
      '.IP "\fB-c | --cooling\fP " 10' => true,
      '\fB\-\-version\fR'=>true,
      '\fB\-1\fR'=>true,
      '\fB\-\-color\fR=\fIauto\fR'=>true,
      '\fB\-T\fR, \fB\-\-tabsize\fR=\fICOLS\fR'=>true,
      '\fB\-U\fR'=>true,
      '\-\-\-\-\-'=>false,
      '   asdadas'=>false
    }.each do |line, success|
      it "recognises #{line} -- #{success}" do
        ManParser.send(:is_option?, line).should == success
      end
    end
  end
end