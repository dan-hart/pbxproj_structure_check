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
  
  def check_object(object_id, object_location)
    if (not @ignored_ids.nil?) and (@ignored_ids.include?(object_id))
      return
    end
    object = @pbx_objects[object_id]
    
    if object_location.empty?
      object_description = "Object '#{object_id}' named '#{object["name"]}' at '/'"
    else 
      object_description = "Object '#{object_id}' named '#{object["name"]}' at '#{object_location}'"
    end
    
    if not object["sourceTree"].eql?("<group>")
      print "\n#{object_description} is not relative to <group> but to #{object["sourceTree"]}"
    end
    if object["path"].nil?
      print "\n#{object_description} has no physical path"
    end
    if (not object["name"].nil?) and (not object["name"].eql?(object["path"]))
      print "\n#{object_description} has name '#{object["name"]}' different from its real path '#{object["path"]}'"
    end
  
    children_location = "#{object_location}/#{object["path"]}"
    if not object["children"].nil?
      object["children"].each do |child_id|
        check_object(child_id, children_location)
      end 
    end
  end
  
  def check
    root_object = @pbx_objects[@pbx_tree["rootObject"]]
    main_group = @pbx_objects[root_object["mainGroup"]]
    if @project_dir.nil?
      abort "\nnil project_dir"
    end

    files_in_xcode_project = [""]
    main_group["children"].each do |child_id|
      object = @pbx_objects[child_id]
      filename = object["path"]
      if not filename.nil?
        files_in_xcode_project.append(filename)
      end    
    end

    print files_in_xcode_project.length

    swiftFiles = Dir["#{project_dir}/**/*.swift"]
    swiftFiles.each do |swiftFile|
        swiftFilename = File.basename(swiftFile) # SomeSwiftFile.swift
        if files_in_xcode_project.include?(swiftFilename)
          # file is referenced in xcode project, no worries
        else 
          # print "\nFile '#{swiftFilename}' is not referenced in the Xcode project"
        end
    end
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
