# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
use_frameworks!

def shared_pods
	pod 'Alamofire'
	pod 'Strongbox'
end

target 'Neurio Home Automation' do
	platform :ios, '10.0'
	shared_pods
	#pod '1PasswordExtension'
	#pod 'SwiftyJSON'

	target 'WatchApp Extension' do
		platform :watchos, '3.0'
		inherit! :search_paths
		shared_pods
	end
end