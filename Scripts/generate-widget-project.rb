#!/usr/bin/env ruby

require "fileutils"
require "xcodeproj"

project_root = File.expand_path("..", __dir__)
project_path = File.join(project_root, "SoramoyoWidgets.xcodeproj")
FileUtils.rm_rf(project_path)

project = Xcodeproj::Project.new(project_path)
project.root_object.attributes["LastSwiftUpdateCheck"] = "2630"
project.root_object.attributes["LastUpgradeCheck"] = "2630"

widget_group = project.main_group.new_group("Widget", "Widget")
source = widget_group.new_file("SoramoyoWidget.swift")
widget_group.new_file("Info.plist")
widget_group.new_file("SoramoyoWidgets.entitlements")

target = project.new_target(:app_extension, "SoramoyoWidgets", :osx, "14.0")
target.source_build_phase.add_file_reference(source)
["WidgetGlowCloud.png", "WidgetGlowRain.png", "WidgetGlowSun.png", "WidgetGlowIce.png"].each do |asset_name|
  asset = widget_group.new_file(asset_name)
  target.resources_build_phase.add_file_reference(asset)
end

target.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings["APPLICATION_EXTENSION_API_ONLY"] = "YES"
  settings["CODE_SIGN_ENTITLEMENTS"] = "Widget/SoramoyoWidgets.entitlements"
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["CURRENT_PROJECT_VERSION"] = "1"
  settings["DEVELOPMENT_TEAM"] = "FVGT53TKRS"
  settings["ENABLE_HARDENED_RUNTIME"] = "YES"
  settings["GENERATE_INFOPLIST_FILE"] = "NO"
  settings["INFOPLIST_FILE"] = "Widget/Info.plist"
  settings["MARKETING_VERSION"] = "1.0"
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "local.soramoyo.weather.widget"
  settings["PRODUCT_NAME"] = "SoramoyoWidgets"
  settings["SDKROOT"] = "macosx"
  settings["SKIP_INSTALL"] = "YES"
  settings["SWIFT_VERSION"] = "5.0"
end

project.save
puts "Generated #{project_path}"
