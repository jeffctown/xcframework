//
//  XCFrameworkBuilder.swift
//  XCFrameworkKit
//
//  Created by Jeff Lett on 6/8/19.
//

import Foundation
import Shell

public class XCFrameworkBuilder {
    public var name: String?
    public var project: String?
    public var schemes: [String]?
    public var outputDirectory: String?
    public var buildDirectory: String?
    public var verbose: Bool = false
    
    public enum XCFrameworkError: Error {
        case nameNotFound
        case projectNotFound
        case schemesNotFound
        case buildDirectoryNotFound
        case outputDirectoryNotFound
        
        public var localizedDescription: String {
            switch self {
            case .nameNotFound:
                return "No name parameter found."
            case .projectNotFound:
                return "No project parameter found."
            case .schemesNotFound:
                return "No schemes found."
            case .buildDirectoryNotFound:
                return "No build directory found."
            case .outputDirectoryNotFound:
                return "No output directory found."
            }
        }
    }
    
    public init(configure: (XCFrameworkBuilder) -> ()) {
        configure(self)
    }
    
    public func build() -> Result<(),XCFrameworkError> {
        
        guard let name = name else {
            return .failure(XCFrameworkError.nameNotFound)
        }
        
        guard let project = project else {
            return .failure(XCFrameworkError.projectNotFound)
        }
        
        guard let schemes = schemes,
            schemes.count > 0 else {
            return .failure(XCFrameworkError.schemesNotFound)
        }
        
        guard let outputDirectory = outputDirectory else {
            return .failure(XCFrameworkError.outputDirectoryNotFound)
        }
        
        guard let buildDirectory = buildDirectory else {
            return .failure(XCFrameworkError.buildDirectoryNotFound)
        }
        
        print("Creating \(name)...")
        
        //final xcframework location
        let finalOutput = outputDirectory + "/" + name + ".xcframework"
        
        shell.usr.rm(finalOutput)
        //array of arguments for the final xcframework construction
        var frameworksArguments = ["-create-xcframework"]
        
        for scheme in schemes {
            print("Building scheme \(scheme)...")
            //path for each scheme's archive
            let archivePath = buildDirectory + "\(scheme).xcarchive"
            //array of arguments for the archive of each framework
            //weird interpolation errors are forcing me to use this "" + syntax.  not sure if this is a compiler bug or not.
            let archiveArguments = ["-project", "" + project, "-scheme", "" + scheme, "archive", "SKIP_INSTALL=NO", "BUILD_LIBRARY_FOR_DISTRIBUTION=YES", "-archivePath", archivePath]
            if verbose {
                print("   xcodebuild \(archiveArguments.joined(separator: " "))")
            }
            shell.usr.bin.xcodebuild.dynamicallyCall(withArguments: archiveArguments)
            //add this framework to the list for the final output command
            frameworksArguments.append("-framework")
            frameworksArguments.append(archivePath + "/Products/Library/Frameworks/\(name).framework")
        }
        
        print("Combining...")
        //add output to final command
        frameworksArguments.append("-output")
        frameworksArguments.append(finalOutput)
        if verbose {
            print("xcodebuild \(frameworksArguments.joined(separator: " "))")
        }
        shell.usr.bin.xcodebuild.dynamicallyCall(withArguments: frameworksArguments)
        print("Success. \(finalOutput)")
        return .success(())
    }
    
}
