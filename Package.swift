// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "react-native-nfc",
    platforms: [
        .iOS(.v8),
        .tvOS(.v9),
        .watchOS(.v2),
        .macOS(.v10_10)
    ],
    products: [
        .library(
            name: "react-native-nfc",
            targets: ["react-native-nfc"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.7.1"))
    ],
    
)
