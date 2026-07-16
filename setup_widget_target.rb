require 'xcodeproj'
require 'fileutils'

project_path = 'brew_sixty.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 1. Find main app target
main_target = project.targets.find { |t| t.name == 'brew_sixty' }
if main_target.nil?
  puts "Error: Main target 'brew_sixty' not found!"
  exit 1
end

# Find active development team from main target before clearing it
dev_team = nil
main_target.build_configurations.each do |config|
  if config.build_settings['DEVELOPMENT_TEAM']
    dev_team = config.build_settings['DEVELOPMENT_TEAM']
    break
  end
end
dev_team ||= 'WNR38C2P6Z' # Fallback to known team ID

# 2. Set DEVELOPMENT_TEAM at the Project Level so all targets inherit it automatically
project.build_configurations.each do |config|
  config.build_settings['DEVELOPMENT_TEAM'] = dev_team
end
puts "Set DEVELOPMENT_TEAM = #{dev_team} at the Project Level"

# 3. Clean target-level signing overrides on main target to inherit from project
main_target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_KEY_NSSupportsLiveActivities'] = 'YES'
  config.build_settings.delete('DEVELOPMENT_TEAM')
end
puts "Cleaned target-level signing on main target"

# 4. Create or find the Widget Extension target
widget_target = project.targets.find { |t| t.name == 'BrewSixtyWidgets' }
if widget_target.nil?
  widget_target = project.new_target(:app_extension, 'BrewSixtyWidgets', :ios, '26.4')
  puts "Created target BrewSixtyWidgets"
else
  puts "Target BrewSixtyWidgets already exists"
end

# 5. Set Widget target build settings (Inherit signing from project)
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = 'BrewSixtyWidgets'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'practice.brew-sixty.BrewSixtyWidgets'
  config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'BrewSixtyWidgets'
  config.build_settings['INFOPLIST_KEY_NSExtensionPointIdentifier'] = 'com.apple.widgetkit-extension'
  config.build_settings['INFOPLIST_FILE'] = 'BrewSixtyWidgets-Info.plist'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '26.4'
  
  # Crucial: Specify Version strings so dynamically generated Info.plist is valid
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  
  # Configure signing to inherit from project level automatically
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings.delete('DEVELOPMENT_TEAM')
  config.build_settings.delete('CODE_SIGNING_ALLOWED')
end
puts "Configured build settings for BrewSixtyWidgets to inherit project-level signing"

# 6. Create dynamic folder structure on disk
FileUtils.mkdir_p('BrewSixtyWidgets')
FileUtils.mkdir_p('brew_sixty/Support/LiveActivity')

# Write placeholder files so compile doesn't fail
File.write('BrewSixtyWidgets/BrewSixtyWidgets.swift', "// Placeholder\n") unless File.exist?('BrewSixtyWidgets/BrewSixtyWidgets.swift')
File.write('BrewSixtyWidgets/BrewActivityWidgetView.swift', "// Placeholder\n") unless File.exist?('BrewSixtyWidgets/BrewActivityWidgetView.swift')
File.write('brew_sixty/Support/LiveActivity/BrewActivityAttributes.swift', "// Placeholder\n") unless File.exist?('brew_sixty/Support/LiveActivity/BrewActivityAttributes.swift')
File.write('brew_sixty/Support/LiveActivityManager.swift', "// Placeholder\n") unless File.exist?('brew_sixty/Support/LiveActivityManager.swift')

# 7. Configure PBXFileSystemSynchronizedRootGroup for widgets
widgets_sync_group = project.main_group.children.find do |child|
  child.is_a?(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup) && child.path == 'BrewSixtyWidgets'
end

if widgets_sync_group.nil?
  widgets_sync_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
  widgets_sync_group.path = 'BrewSixtyWidgets'
  widgets_sync_group.source_tree = '<group>'
  project.main_group.children << widgets_sync_group
  puts "Created file-system synchronized group for BrewSixtyWidgets"
end

unless widget_target.file_system_synchronized_groups.include?(widgets_sync_group)
  widget_target.file_system_synchronized_groups << widgets_sync_group
  puts "Linked BrewSixtyWidgets synchronized group to widget target"
end

live_activity_sync_group = project.objects.select { |o| o.is_a?(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup) }.find do |g|
  g.path == 'brew_sixty/Support/LiveActivity'
end

if live_activity_sync_group.nil?
  live_activity_sync_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
  live_activity_sync_group.path = 'brew_sixty/Support/LiveActivity'
  live_activity_sync_group.source_tree = '<group>'
  puts "Created file-system synchronized group for brew_sixty/Support/LiveActivity"
end

unless widget_target.file_system_synchronized_groups.include?(live_activity_sync_group)
  widget_target.file_system_synchronized_groups << live_activity_sync_group
  puts "Linked brew_sixty/Support/LiveActivity synchronized group to widget target"
end

old_support_sync_group = project.objects.select { |o| o.is_a?(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup) }.find do |g|
  g.path == 'brew_sixty/Support'
end
if old_support_sync_group && widget_target.file_system_synchronized_groups.include?(old_support_sync_group)
  widget_target.file_system_synchronized_groups.delete(old_support_sync_group)
  puts "Removed old brew_sixty/Support synchronized group from widget target"
end

# 8. Add target dependency & Copy Files build phase
unless main_target.dependencies.any? { |d| d.target == widget_target }
  main_target.add_dependency(widget_target)
  puts "Added dependency: main target -> BrewSixtyWidgets"
end

embed_phase = main_target.copy_files_build_phases.find { |p| p.name == 'Embed App Extensions' || p.symbol_dst_subfolder_spec == :plug_ins }
if embed_phase.nil?
  embed_phase = main_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
end

widget_product = widget_target.product_reference
unless embed_phase.files.any? { |f| f.file_ref == widget_product }
  embed_phase.add_file_reference(widget_product)
  puts "Embedded BrewSixtyWidgets.appex in Copy Files phase"
end

project.save
puts "Successfully configured brew_sixty.xcodeproj!"
