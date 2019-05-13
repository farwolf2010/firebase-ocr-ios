

Pod::Spec.new do |s|

 
  s.platform  = :ios, "9.0"
  s.name         = "firebaseOcr"
  s.version      = "0.0.1"
  s.summary      = "Handle some data."
  s.description  = <<-DESC
                    Handle the data.
                   DESC

  s.homepage     = "http://csdn.net/veryitman"
  s.license      = "MIT"
  s.author             = { "veryitman" => "veryitman@126.com" }
  s.source =  { :path => '.' }
  s.source_files  = "Source", "**/**/*.{h,m,mm,c}"
  s.resources = '*.bundle',"*.plist"
  s.ios.vendored_libraries = '*.a'
  s.ios.vendored_frameworks = '*.framework'

  s.exclude_files = "Source/Exclude"
  s.dependency 'farwolf.weex' 
  s.dependency 'Firebase', '~> 5.20.2'
  s.dependency 'Firebase/CoreOnly', '~> 5.20.2'
  s.dependency 'Firebase/MLVision', '~> 5.20.2'
  s.dependency  'Firebase/MLVisionTextModel', '~> 5.20.2'
 


 
  
  s.frameworks =  'UIKit'
  #s.libraries = "z", "c++"
  #s.requires_arc  = true
    

end
