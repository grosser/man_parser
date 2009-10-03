class ManParser
  def self.available_commands
    `ls #{root}`.split("\n").map{|c| c.sub('.1.gz','')}
  end

  def self.source(cmd)
    `gzip -dc #{root}/#{cmd}.1.gz`
  end

  def self.parse(cmd)
    sections = sections(source(cmd))
    if sections['OPTIONS']
      options = find_options(sections['OPTIONS'])
      description = sections['DESCRIPTION']
    else
      description, options = find_options_in_description(sections['DESCRIPTION'])
    end
    options = options.map{|option| parse_option(option*' ') }
    {:description => description.map{|l|l.strip}.join(''), :options=>options, :sections=>sections}
  end

  private

  def self.root
    '/usr/share/man/man1'
  end

  def self.parse_option(option)
    option = option.gsub(/\\f[IB](.*?)\\fR/,"\\1").gsub('\\','')

    found =  if option =~ /^-(\w+), --([-\w]+)(=(\w+))?(.*)/
      {:alias=>$1, :name=>$2, :argument=>$4, :description=>$5}
    elsif option =~ /^--([-\w]+)(=(\w+))?(.*)/
      {:name=>$1, :argument=>$3, :description=>$4}
    elsif option =~ /^-([-\w]+)(.*)/
      {:alias=>$1, :description=>$2}
    end

    if not found
      puts "#{option} <-> nil !"
      return
    end

    found[:description] = found[:description].to_s.strip.sub(/\s*\.TP$/,'')
    found.delete(:argument) unless found[:argument]

    found
  end

  # find all options in a given section of text
  def self.find_options(text)
    []
  end

  # description can be split like "description, options, descriptions"
  # so we remove the options part, and combine the 2 descriptions parts
  def self.find_options_in_description(text)
    in_option = false
    already_switched = false
    options = []
    description = []

    text.split("\n")[1..-1].each do |line|

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

    [description * "\n", options]
  end

  # split into sections according to "SectionHead" aka .SH
  def self.sections(text)
    lines = text.split("\n")+[".SH END"] 
    name = 'OUT_OF_SECTION'
    sections = {}
    temp = []

    lines.each do |line|
      if line =~ /^\.SH (.*)$/
        sections[name] = temp * "\n"
        temp = []
        name = $1.gsub('"','').strip
      else
        temp << line
      end
    end

    sections
  end

  def self.start_of_option?(line)
    !!( line =~ /^\\fB\\-/)
  end
end