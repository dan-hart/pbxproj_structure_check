#
#  missing_reference.rb
#  v0.0.1
#
# Dan Hart (04/27/2022)
#

require 'rubygems'
require 'json'

class PbxStructure

  attr_accessor :project_dir

  def initialize(pbx_tree)
    @pbx_tree = pbx_tree
    @pbx_objects = pbx_tree["objects"]
  end
  
  def getFilePathsFrom(object_id)
    files_in_object = []
    object = @pbx_objects[object_id]
    
    filename = object["path"]
    if not filename.nil?
      extension = File.extname(filename) # file extension ".swift" 
      if extension == ".swift"
        files_in_object.append(filename)
      end
    end   
    
    if not object["children"].nil?
      object["children"].each do |child_id|
        child_paths = getFilePathsFrom(child_id)
        child_paths.each do |child_path|
          files_in_object.append(child_path)
        end
      end 
    end

    return files_in_object
  end
  
  def check
    root_object = @pbx_objects[@pbx_tree["rootObject"]]
    main_group = @pbx_objects[root_object["mainGroup"]]
    if @project_dir.nil?
      abort "\nnil project_dir"
    end

    files_in_xcode_project = []
    main_group["children"].each do |child_id|
      child_paths = getFilePathsFrom(child_id)
      child_paths.each do |child_path|
        files_in_xcode_project.append(child_path)
      end
    end

    # file paths referenced by pbxproj
    # print files_in_xcode_project

    swiftFiles = Dir["#{project_dir}/**/*.swift"]
    swiftFiles.each do |swiftFile|
        swiftFilename = File.basename(swiftFile) # SomeSwiftFile.swift
        if files_in_xcode_project.include?(swiftFilename)
          # file is referenced in xcode project, no worries
        else 
          print "\nFile '#{swiftFilename}' is not referenced in the Xcode project"
        end
    end

    print "\n"
  end
end


if __FILE__ == $0
  def usage
    abort "ruby #{__FILE__} pbx_path [project_dir]"
  end

  pbx_path = ARGV[0]
  if pbx_path.nil?
    usage
  end
  pbx_data = `plutil -convert json -o - #{ARGV[0]}`
  if $? != 0
    abort "Could not read project file!"
  end
  
  pbx_tree = JSON.parse(pbx_data)

  pbx_structure = PbxStructure.new(pbx_tree)
  if not ARGV[1].nil?
    pbx_structure.project_dir = ARGV[1] # Path to project directory
    pbx_structure.check
  else
    abort "Missing project directory!"
   end
end
