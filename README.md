# xcframework

[![Swift Version](https://img.shields.io/badge/Swift-5.1-orange.svg?style=for-the-badge)](https://swift.org)
[![GitHub release](https://img.shields.io/github/release/jeffctown/xcframework.svg?style=for-the-badge)](https://github.com/jeffctown/xcframework/releases)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg?style=for-the-badge)](https://raw.githubusercontent.com/jeffctown/xcframework/master/LICENSE.md) 

xcframework is a tool to create XCFrameworks.

## Installation

### Using a pre-built package:

You can install xcframework by downloading `xcframework.pkg` from the
[latest GitHub release](https://github.com/jeffctown/xcframework/releases/latest) and
running it.

### Installing from source:

You can also install from source by cloning this project and running
`make install` (Xcode 11.0 beta 1 or later).  Note: Running `make install` requires sudo permission to install the final executable. 

### Compiling from source:

You can build from source and use the executable without installation if you prefer to.  Run `make installables` to output the final executable to `./.build/release/xcframework`.  Feel free to use or copy the executable how you like.

## Quick Start

* Create an XCFramework including a framework with iOS, tvOS, and watchOS:

```bash
xcframework build --project PMLog/PMLog.xcodeproj --name PMLog --ios PMLog_iOS --tvos PMLog_TvOS --watchos PMLog_WatchOS
```

## Usage


### Help

```
$ xcframework help
Available commands:

   build     Build an XCFramework
   help      Display general or command-specific help
   version   Display the current version of xcframework
```

### Build


#### Build with Verbose Logging Enabled

```bash
xcframework build --project PMLog/PMLog.xcodeproj --name PMLog --ios PMLog_iOS --tvos PMLog_TvOS --watchos PMLog_WatchOS --verbose
```

#### Build with Output Directory Specified

```bash
xcframework build --project PMLog/PMLog.xcodeproj --name PMLog --ios PMLog_iOS --tvos PMLog_TvOS --watchos PMLog_WatchOS --output ./output
```

#### Build with Build Directory Specified

```bash
xcframework build --project PMLog/PMLog.xcodeproj --name PMLog --ios PMLog_iOS --tvos PMLog_TvOS --watchos PMLog_WatchOS --build ./build
```

#### Build with Extra xcodebuild Arguments

Any arguments at the end of your command will be passed along to `xcodebuild` during archive.

```bash
xcframework build --project PMLog/PMLog.xcodeproj --name PMLog --ios PMLog_iOS DEBUG=1 PERFORM_MAGIC=0
```


## Known Issues

If you need to pass an xcodebuild argument that begins with a `-`, like `-configuration Release`, you will need to put a `--` before it.  `--` tells this program (or tells [Commandant](https://github.com/Carthage/Commandant/issues/59)) to stop looking for named arguments.

Without `--`:

```bash
$ xcframework build --project PMLog/PMLog.xcodeproj --name PMLog --ios PMLog_iOS -configuration Release
Unrecognized arguments: -configurat
```

With `--`:

```bash
xcframework build --project PMLog/PMLog.xcodeproj --name PMLog --ios PMLog_iOS -- -configuration Release
```

```bash
xcframework build --project PMLog/PMLog.xcodeproj --name PMLog --ios PMLog_iOS -- -enableAddressSanitizer YES
```


## License

xcframework is released under the [MIT license](LICENSE.md).
