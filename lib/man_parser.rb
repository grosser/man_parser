class ManParser
  def self.parse(cmd)
    text = `gzip -dc /usr/share/man/man1/#{cmd}.1.gz`
    sections = sections(text)
    description, options = parse_description(sections['DESCRIPTION'])
    options = options.map{|option| parse_option(option*' ') }
    {:description => description.map{|l|l.strip}.join(''), :options=>options, :sections=>sections}
  end

  private

  def self.parse_option(option)
#    option_rex = '([-\w\\]|[-\w\\]+\\fR=\\fI\w+)'
    found = if option =~ /^\\fB\\-([-\w\\]+\\fR=\\fI\w+|[-\w\\]+)\\fR, \\fB\\-\\-([-\w\\]+\\fR=\\fI\w+|[-\w\\]+)\\fR(.*)/
      {:alias=>$1, :name=>$2, :description=>$3}
    elsif option =~ /^\\fB(\\-){1,2}([-\w\\]+\\fR=\\fI\w+|[-\w\\]+)\\fR(.*)/
      {:name=>$2, :description=>$3}
    end
    return unless found
    found[:description] = found[:description].to_s.strip.gsub(/\s{2,}/, ' ')
    found
  end

  def self.parse_description(text)
    in_option = false
    already_switched = false
    options = []
    description = []

    text[1..-1].each do |line|

      if start_of_option?(line) and not already_switched
        in_option = true
        options << [] #new option
      elsif line =~ /^\.PP/ and in_option
        already_switched = true
        in_option = false
      end

      next if line.strip.empty?

      if in_option
        options.last << line
      else
        description << line
      end
    end

    [description, options]
  end

  def self.sections(text)
    name = 'OUT_OF_SECTION'
    sections = Hash.new([])

    text.split("\n").each do |line|
      if line =~ /^\.SH (.*)$/
        name = $1
      else
        sections[name] += [line]
      end
    end

    sections
  end

  def self.start_of_option?(line)
    !!( line =~ /^\\fB\\-/)
  end
end