class RealFileSystem
  def exists?(name)
    File.exists?(name)
  end
  def read(name)
    File.read(name)
  end
  def read_and_gzip_decompress(name)
    f = File.open(name,"r")
    gz = Zlib::GzipReader.new(f)
    gz.read
  end
  def ls(dir)
#    `ls #{dir}`.split("\n")
    Dir.entries(dir)
  end
end

class ManParser
  @@fs = RealFileSystem.new

  def self.use_filesystem(fs)
    @@fs = fs
  end

  def self.available_commands
    @@fs.ls(root).map{|c| c.sub(/.1(.gz)?$/,'')}
  end

  def self.source(cmd)
    name = File.join(root, cmd)
    if @@fs.exists?("#{name}.1.gz")
      return @@fs.read_and_gzip_decompress("#{name}.1.gz")
    elsif @@fs.exists?(name)
      return @@fs.read(name)
    else
      return ''
      #raise "Could not find #{cmd}"
    end
  end

  def self.parse(cmd)
    sections = sections(source(cmd))
    return {} if not sections['OPTIONS'] and not sections['DESCRIPTION']
    description, options = find_options(sections['OPTIONS']||sections['DESCRIPTION'])
    description = sections['DESCRIPTION'] if description.to_s.empty?
    options = parse_options(options)
    {:description => description.map{|l|l.strip}.join(''), :options=>options, :sections=>sections}
  end

  private

  # remove common prefix from options
  def self.parse_options(options)
    options = options.map{|option| parse_option(option*' ') }.reject{|o| o.empty?}
    common = common_prefix(options.map{|o| o[:description]})
    options.each{|o| o[:description] = o[:description].split(//)[common..-1].to_s}
    options
  end

  def self.root
    '/usr/share/man/man1'
  end

  def self.parse_option(option)
    option = without_markup(option)
    found = option_parts(option)
    if not found
      puts "#{option} <-> nothing found !"
      return {}
    end

    #remove ending .TP and any unnecessary whitespace
    found[:description] = found[:description].to_s.strip.sub(/\s*\.TP$/,'').gsub(/\s{2,}/,' ')
    found.delete(:argument) unless found[:argument]

    found
  end

  def self.common_prefix(texts)
    shortest = texts.map{|t| t.size}.min || 0
    shortest.downto(1) do |i|
      common = texts.map{|t| t[0...i]}.uniq
      next if common.size != 1
      next if common.first =~ /^\w+$/ # ['\d hello world','\d hell is hot'] -> '\d '
      return i
    end
    return 0
  end

  # description can be split like "description, options, descriptions"
  # so we remove the options part, and combine the 2 descriptions parts
  def self.find_options(text)
    in_option = false
    already_switched = false
    options = []
    known_names = []
    description = []

    text.split("\n").each do |line|

      if is_unknown_option?(line, known_names) and not already_switched
        in_option = true
        options << [] #new option
        known_names << parse_option(line)[:name]
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
    if text.nil?
      raise "Text is nil!"
    end
    lines = text.split("\n")+[".SH END"] 
    name = 'OUT_OF_SECTION'
    sections = {}
    temp = []

    lines.each do |line|
      if line =~ /^\.S[hH] (.*)$/
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
    text = text.gsub(/\\f[IB](.*?)\\f[RP]/,"\\1").gsub('\\','') # remove styles
    text = text.gsub(/-\^-(\w)/,"--\\1") # remove weird ^ in e.g. grep options
  end

  # duplicate prevention, e.g. many lines in grep start with --mmap
  def self.is_unknown_option?(line, known_names)
    return if not is_option?(line)
    name = parse_option(line)[:name]
    name == nil or not known_names.include?(name)
  end

  def self.is_option?(line)
    !! option_parts(line)
  end

  def self.option_parts(text)
    text = without_markup(text).sub(/\.[A-Z]+ (")?/,'') # remove any initial markup
    if text =~ /^-(\w+)[,"| ]+--(\w[-\w]*)(=(\w+)| <(\w+)>)?(.*)/
      {:alias=>$1, :name=>$2, :argument=>$4||$5, :description=>$6}
    elsif text =~ /^--(\w[-\w]*)(=(\w+))?(.*)/
      {:name=>$1, :argument=>$3, :description=>$4}
    elsif text =~ /^-(\w[-\w]*)(.*)/
      {:alias=>$1, :description=>$2}
    end
  end
end
