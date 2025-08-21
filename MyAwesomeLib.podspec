Pod::Spec.new do |s|
  s.name             = "MyAwesomeLib"
  s.version          = "1.0.1"
  s.summary          = "A short description of MyAwesomeLib."
  s.description      = <<-DESC
    A longer description of MyAwesomeLib.
  DESC
  s.homepage         = "https://github.com/andredestro/my-awesome-lib"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "OutSystems Mobile Ecosystem" => "rd.mobileecosystem.team@outsystems.com" }
  # s.source           = { :git => "https://github.com/andredestro/my-awesome-lib.git", :tag => s.version.to_s }
  s.source           = { :http => "https://github.com/andredestro/my-awesome-lib/releases/download/v#{spec.version}/MyAwesomeLib.zip", :type => "zip" }

  s.ios.deployment_target = "15.0"
  # s.source_files     = "MyAwesomeLib/**/*.{h,m,swift}"
  # s.public_header_files = "MyAwesomeLib/**/*.h"
  s.swift_version    = "5.9"

  s.frameworks       = "UIKit", "Foundation"
end
