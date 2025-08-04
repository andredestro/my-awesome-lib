cd ..

rm -rf build

xcodebuild archive \
-scheme __PROJECT_NAME__ \
-configuration Release \
-destination 'generic/platform=iOS Simulator' \
-archivePath './scripts/build/__PROJECT_NAME__.framework-iphonesimulator.xcarchive' \
SKIP_INSTALL=NO \
BUILD_LIBRARIES_FOR_DISTRIBUTION=YES


xcodebuild archive \
-scheme __PROJECT_NAME__ \
-configuration Release \
-destination 'generic/platform=iOS' \
-archivePath './scripts/build/__PROJECT_NAME__.framework-iphoneos.xcarchive' \
SKIP_INSTALL=NO \
BUILD_LIBRARIES_FOR_DISTRIBUTION=YES


xcodebuild -create-xcframework \
-framework './scripts/build/__PROJECT_NAME__.framework-iphonesimulator.xcarchive/Products/Library/Frameworks/__PROJECT_NAME__.framework' \
-framework './scripts/build/__PROJECT_NAME__.framework-iphoneos.xcarchive/Products/Library/Frameworks/__PROJECT_NAME__.framework' \
-output './scripts/build/__PROJECT_NAME__.xcframework'
