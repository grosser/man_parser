require 'spec/spec_helper'

describe ManParser do
  describe :parse do
    it "finds the description" do
      d = ManParser.parse('ls')[:description]
      d.should =~ /^\.PPList information about the FILEs \(the current/
      d.should =~ /problems, 2 if serious trouble\.$/
      d.should_not include('\\-\\-all')
      d.should_not include('do not ignore entries starting with')
      d.should_not include("      ")
    end

    describe 'options' do
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
        options.first[:description].should == 'do not ignore entries starting with . .TP'
      end

      it "understands format with only name (--author)" do
        options[2].should == {:name=>'author', :description=>'with \\fB\\-l\\fR, print the author of each file .TP'}
      end

      it "understands format with parameters --x=SIZE" do
        options[4].should == {:name=>"block\\-size\\fR=\\fISIZE", :description=>"use SIZE\\-byte blocks .TP"}
      end

      it "userstands single-line style" do
        options[7].should == {:name=>"C", :description=>"list entries by columns .TP"}
      end
    end
  end

  describe :start_of_option? do
    {
      '\fB\-\-version\fR'=>true,
      '\fB\-1\fR'=>true,
      '\fB\-\-color\fR=\fIauto\fR'=>true,
      '\fB\-T\fR, \fB\-\-tabsize\fR=\fICOLS\fR'=>true,
      '\fB\-U\fR'=>true,
      '\-\-\-\-\-'=>false,
      '   asdadas'=>false
    }.each do |line, success|
      it "recognises #{line} -- #{success}" do
        ManParser.send(:start_of_option?, line).should == success
      end
    end
  end
end