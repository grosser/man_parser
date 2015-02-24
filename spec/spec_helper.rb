# ---- requirements

require_relative '../lib/man_parser'
require "rspec"
require "zlib"
class FakeFileSystem
  def initialize(files)
    @files = files
  end
  def exists?(name)
    b = File.basename(name)
    @files.has_key?(b)
  end
  def read(name)
    b = File.basename(name)
    @files[b]
  end
  def read_and_gzip_decompress(name)
    #`gzip -dc #{name}`
    raise "Not implemented"
  end
  def ls(dir)
    @files.keys
  end
end
$real_fs = RealFileSystem.new

def get_man_file(file)
  $real_fs.read_and_gzip_decompress(
    File.join(File.dirname(__FILE__),"test_data","#{file}.1.gz"))
end

$ls_man = get_man_file("ls")
$printf_man = get_man_file("printf")
$grep_man = get_man_file("grep")
$xargs_man = get_man_file("xargs")
#$acpi_man = get_man_file("acpi")
RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end