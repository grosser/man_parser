require 'spec/spec_helper'

describe ManParser do
  describe :parse do
    it "finds the description" do
      d = ManParser.parse('ls')[:description]
      d.should =~ /^List  information  about  the FILEs /
      d.should be_end_with('problems, 2 if serious trouble.')
      d.should_not include('-a, --all')
      d.should_not include('do not ignore entries starting with')
      d.should_not include("      ")
    end

    describe 'options' do
      def options
        ManParser.parse('ls')[:options]
      end

      it "finds all options" do
        options.size.should == 60
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

      it "understands format with parameters --x=SIZE" do
        options[4].should == {:name=>"block-size", :description=>"=SIZE use SIZE-byte blocks"}
      end

      it "userstands single-line style" do
        options[7].should == {:name=>"C", :description=>"list entries by columns"}
      end
    end
  end

  describe :start_of_option? do
    {
      '   -1'=>true,
      '   -a'=>true,
      '   -X'=>true,
      '   -a, --all'=>true,
      '   '=>false,
      'asdas a -asd, --asd'=>false,
      '---------'=>false,
      '  --------- '=>false,
      '   asdadas'=>false
    }.each do |line, success|
      it "recognises #{line} -- #{success}" do
        ManParser.send(:start_of_option?, line).should == success
      end
    end
  end
end