class ManParser
  def self.available_commands
    `ls #{root}`.split("\n").map{|c| c.sub('.1.gz','')}
  end

  def self.source(cmd)
    `gzip -dc #{root}/#{cmd}.1.gz`
  end

  def self.parse(cmd)
    sections = sections(source(cmd))
    description, options = find_options(sections['OPTIONS']||sections['DESCRIPTION'])
    description ||= sections['DESCRIPTION']
    options = options.map{|option| parse_option(option*' ') }
    {:description => description.map{|l|l.strip}.join(''), :options=>options, :sections=>sections}
  end

  private

  def self.root
    '/usr/share/man/man1'
  end

  def self.parse_option(option)
    option = without_markup(option)
    found = option_parts(option)
    if not found
      puts "#{option} <-> nil !"
      return
    end

    found[:description] = found[:description].to_s.strip.sub(/\s*\.TP$/,'')
    found.delete(:argument) unless found[:argument]

    found
  end

  # description can be split like "description, options, descriptions"
  # so we remove the options part, and combine the 2 descriptions parts
  def self.find_options(text)
    in_option = false
    already_switched = false
    options = []
    description = []

    text.split("\n").each do |line|

      if is_option?(line) and not already_switched
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

  def self.without_markup(text)
    text.gsub(/\\f[IB](.*?)\\f[RP]/,"\\1").gsub('\\','')
  end

  def self.is_option?(text)
    !! option_parts(text)
  end

  def self.option_parts(text)
    text = without_markup(text).sub(/.IP "/,'')
    if text =~ /^-(\w+)[,| ]+--(\w[-\w]*)(=(\w+))?(.*)/
      {:alias=>$1, :name=>$2, :argument=>$4, :description=>$5}
    elsif text =~ /^--(\w[-\w]*)(=(\w+))?(.*)/
      {:name=>$1, :argument=>$3, :description=>$4}
    elsif text =~ /^-(\w[-\w]*)(.*)/
      {:alias=>$1, :description=>$2}
    end
  end
end