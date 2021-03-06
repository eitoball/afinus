#!/usr/bin/env ruby
# frozen_string_literal: true

require 'colorize'

class AFI
  MAX_RANDOM_NUMBER = 99_999_999_999_999_999
  # Start counters
  def initialize
    @c_file = 0
    @c_dir  = 0
    @c_err  = 0
    @c_byte = 0
    @dirs   = []
  end

  def execute!(directory, opts = {})
    recursive   = opts[:recursive].is_a?(TrueClass)
    @start_time = Time.now
    enter(directory)
    fill_empty_space!(512_000) # Fill empty space before recursive clean!
    clean!(recursive: recursive)
    remove_directories!(recursive: recursive)

    @end_time = Time.now

    print_info
    print_thank_you
  end

  # Enter start directory or exit
  def enter(dir)
    Dir.chdir(dir)
    print_working_dir
  rescue
    puts "\n >> FOLDER DO NOT EXIST OR PERMISSION DENIED <<\n".red.bold
    exit(1)
  end

  # end of enter(dir)

  # Fill empty space on partition
  def fill_empty_space!(bytes)
    @start_time = Time.now
    create_random_files(bytes)
  rescue
    @end_time = Time.now
    puts "\n[#{@c_byte}] files created in [#{(@end_time - @start_time).round(3)}] seconds".white
    print_delimiter
  end

  # end of fill_empty_space!

  # Clean all files!
  def clean!(recursive: false)
    collect(recursive && :recursive).each do |file|
      if File.directory?(file)
        @c_dir += 1
        printer(@c_dir.to_s.yellow.bold, file, 'Directory Found!'.white)
        Dir.rmdir(file) if Dir.empty?(file)
        @dirs << file
      else
        begin
          rewrite(file) if File.writable?(file)
        rescue
          puts '>> FOLDER DO NOT EXIST OR PERMISSION DENIED <<'.red.bold
        end
      end

      puts "\n[#{@c_dir}] directories counted".white
    end
  end

  # end of clean!

  # Remove Directories
  def remove_directories!(recursive: false)
    collect(recursive && :recursive).select { |file| File.directory?(file) }
      .each { |dir| Dir.rmdir(dir) }
  end

  # Overwrite and Null file
  def rewrite(file)
    truncate_file(file)
    File.delete(file)
    @c_file += 1
    printer(@c_file.to_s.yellow, file.white, 'Overwritten, Nulled, Removed!'.yellow)
  rescue
    @c_err += 1
    printer(@c_err.to_s.red, file.white.bold, 'NOT PROCESSED => PERMISSION PROBLEM?'.red.bold)
  end

  # end of rewrite

  def truncate_file(file, bytes_array = [50, 100, 50])
    bytes_array = Array(bytes_array)
    bytes_array.each do |bytes|
      File.write(file, Random.new.bytes(bytes).to_s)
      File.truncate(file, 0)
    end
  end

  private

  # Print file counter and time info
  def print_info
    puts "[#{@c_file}] files cleaned in [#{(@end_time - @start_time).round(3)}] seconds".white
    print_delimiter
  end

  # Print "thank you" note
  def print_thank_you
    puts "Thank's for using AFI Null Script! Stay with TAILS to protect your privacy!".yellow.bold
  end

  # Print working directory
  def print_working_dir
    print_delimiter
    puts 'You are in'.green, " #{Dir.pwd}\n".white.bold
    print_delimiter
  end

  def print_delimiter
    puts '='.yellow * 60, ''
  end

  # Define printer for processed files
  def printer(counter, name, note)
    puts "[#{counter}] - #{name} - #{note}"
  end

  # Create random-byte file
  def create_random_files(bytes)
    loop do
      a_rand  = "#{rand(MAX_RANDOM_NUMBER)}.fillfile"
      @c_byte += 1
      File.write(a_rand.to_s, Random.new.bytes(bytes).to_s)
      printer(@c_byte.to_s.yellow.bold, "Created #{a_rand}".white, "#{bytes} bytes\n".white)
    end
  end

  # end of create_random_bytes

  # Collect files to clean
  def collect(mode = nil)
    # binding.pry
    case mode.to_sym
    when :recursive
      Dir.glob(File.join('**', '*'))
    when :fill_empty
      Dir.glob('*.fillfile')
    else
      Dir.glob('*').select { |file| File.file?(file) }
    end
  end
  # end of collect
end
