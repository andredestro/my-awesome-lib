Pod::Spec.new do |s|
  s.name             = "__PROJECT_NAME__"
  s.version          = "1.0.0"
  s.summary          = "A short description of __PROJECT_NAME__."
  s.description      = <<-DESC
    A longer description of __PROJECT_NAME__.
  DESC
  s.homepage         = "https://github.com/OutSystems/__PROJECT_NAME__"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "OutSystems Mobile Ecosystem" => "rd.mobileecosystem.team@outsystems.com" }
  s.source           = { :git => "https://github.com/OutSystems/__PROJECT_NAME__.git", :tag => s.version.to_s }

  s.ios.deployment_target = "15.0"
  s.source_files     = "__PROJECT_NAME__/**/*.{h,m,swift}"
  s.public_header_files = "__PROJECT_NAME__/**/*.h"
  s.swift_version    = "5.9"

  s.frameworks       = "UIKit", "Foundation"
end
