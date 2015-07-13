Pod::Spec.new do |s|
    s.name = 'RDHCollectionViewTableLayout'
    s.version = '1.0.1'
    s.license = 'MIT'
    
    s.summary = 'Table layout for UICollectionView.'
    s.homepage = 'https://github.com/rhodgkins/RDHCollectionViewTableLayout'
    s.author = 'Rich Hodgkins'
    s.source = { :git => 'https://github.com/rhodgkins/RDHCollectionViewTableLayout.git', :tag => s.version.to_s }
    s.social_media_url = 'https://twitter.com/rhodgkins'

    s.frameworks = 'Foundation', 'UIKit', 'CoreGraphics'
    s.requires_arc = true
    
    s.ios.deployment_target = '8.0'
    s.source_files = 'RDHCollectionViewTableLayout/'
end
