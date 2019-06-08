//
//  BuildCommand.swift
//  xcframework
//
//  Created by Jeff Lett on 6/7/19.
//

import Commandant
import Foundation
import Shell
import XCFrameworkKit

struct BuildCommand: CommandProtocol {
    
    // MARK: - CommandProtocol
    
    let verb = "build"
    let function = "Build an XCFramework"
    
    // MARK: - OptionsProtocol
    
    struct Options: OptionsProtocol {
        let project: String?
        let name: String?
        let outputDirectory: String
        let buildDirectory: String
        let verbose: Bool
        let schemes: [String]
        
        static func create(_ project: String?) -> (String?) -> (String) -> (String) -> (Bool) -> ([String]) -> Options {
            return { name in { outputDirectory in { buildDirectory in  { verbose in { schemes in Options(project: project, name: name, outputDirectory: outputDirectory, buildDirectory: buildDirectory, verbose: verbose, schemes: schemes) } } } } }
        }
        
        static func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<CommandantError<()>>> {
            
            return create
                <*> mode <| Option(key: "project", defaultValue: nil, usage: "project to build")
                <*> mode <| Option(key: "name", defaultValue: nil, usage: "framework name, Example: <name>.framework")
                <*> mode <| Option(key: "output", defaultValue: FileManager.default.currentDirectoryPath, usage: "output directory")
                <*> mode <| Option(key: "build", defaultValue: FileManager.default.currentDirectoryPath.appending(".xcframework/build/"), usage: "build directory")
                <*> mode <| Switch(key: "verbose", usage: "enable verbose logs")
                <*> mode <| Option(key: "schemes", defaultValue: [], usage: "schemes to build")
        }
    }
    
    func run(_ options: Options) -> Result<(), CommandantError<()>> {
        guard let name = options.name else {
            return .failure(.usageError(description: "No Framework name Found!! Please use the --name or -n option to pass in the framework's name."))
        }
        
        guard let project = options.project else {
            return .failure(.usageError(description: "No Project Found! Please use the --project or -p option to pass in the project's name."))
        }
        
        guard options.schemes.count > 0 else {
            return .failure(.usageError(description: "No schemes Found! Please use the --schemes or -s option to pass in the schemes to build in your project."))
        }
        
        print("Creating \(name)...")
        
        //final xcframework location
        let finalOutput = options.outputDirectory + "/" + name + ".xcframework"
        
        shell.usr.rm(finalOutput)
        //array of arguments for the final xcframework construction
        var frameworksArguments = ["-create-xcframework"]
        
        for scheme in options.schemes {
            print("Building scheme \(scheme)...")
            //path for each scheme's archive
            let archivePath = options.buildDirectory + "\(scheme).xcarchive"
            //array of arguments for the archive of each framework
            //weird interpolation errors are forcing me to use this "" + syntax.  not sure if this is a compiler bug or not.
            let archiveArguments = ["-project", "" + project, "-scheme", "" + scheme, "archive", "SKIP_INSTALL=NO", "BUILD_LIBRARY_FOR_DISTRIBUTION=YES", "-archivePath", archivePath]
            if options.verbose {
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
        if options.verbose {
            print("xcodebuild \(frameworksArguments.joined(separator: " "))")
        }
        shell.usr.bin.xcodebuild.dynamicallyCall(withArguments: frameworksArguments)
        print("Success. \(finalOutput)")
        return .success(())
    }
}
