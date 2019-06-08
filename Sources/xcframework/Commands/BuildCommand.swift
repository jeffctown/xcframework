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
        let iOSScheme: String?
        let watchOSScheme: String?
        let tvOSScheme: String?
        let macOSScheme: String?
        let verbose: Bool
        let compilerArguments: [String]
        
        static func create(_ project: String?) -> (String?) -> (String) -> (String) -> (String?) -> (String?) -> (String?) -> (String?) -> (Bool) -> ([String]) -> Options {
            return { name in { outputDirectory in { buildDirectory in { iOSScheme in { watchOSScheme in { tvOSScheme in { macOSScheme in { verbose in { compilerArguments in Options(project: project, name: name, outputDirectory: outputDirectory, buildDirectory: buildDirectory, iOSScheme: iOSScheme, watchOSScheme: watchOSScheme, tvOSScheme: tvOSScheme, macOSScheme: macOSScheme, verbose: verbose, compilerArguments: compilerArguments) } } } } } } } } }
        }
        
        static func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<CommandantError<()>>> {
            let defaultBuildDirectory = "/tmp/xcframework/build/"
            return create
                <*> mode <| Option(key: "project", defaultValue: nil, usage: "REQUIRED: the path and project to build")
                <*> mode <| Option(key: "name", defaultValue: nil, usage: "REQUIRED: the framework name, Example: <name>.framework")
                <*> mode <| Option(key: "output", defaultValue: FileManager.default.currentDirectoryPath, usage: "the output directory (default: .)")
                <*> mode <| Option(key: "build", defaultValue: FileManager.default.currentDirectoryPath.appending(defaultBuildDirectory), usage: "build directory (default: \(defaultBuildDirectory)")
                <*> mode <| Option(key: "ios", defaultValue: nil, usage: "the scheme for your iOS target")
                <*> mode <| Option(key: "watchos", defaultValue: nil, usage: "the scheme for your watchOS target")
                <*> mode <| Option(key: "tvos", defaultValue: nil, usage: "the scheme for your tvOS target")
                <*> mode <| Option(key: "macos", defaultValue: nil, usage: "the scheme for your macOS target")
                <*> mode <| Switch(key: "verbose", usage: "enable verbose logs")
                <*> mode <| Argument(defaultValue: [], usage: "any extra xcodebuild arguments to be used in the framework archiving")
        }
    }
    
    func run(_ options: Options) -> Result<(), CommandantError<()>> {
        let builder = XCFrameworkBuilder() { builder in
            builder.name = options.name
            builder.project = options.project
            builder.outputDirectory = options.outputDirectory
            builder.buildDirectory = options.buildDirectory
            builder.iOSScheme = options.iOSScheme
            builder.watchOSScheme = options.watchOSScheme
            builder.tvOSScheme = options.tvOSScheme
            builder.macOSScheme = options.macOSScheme
            builder.verbose = options.verbose
            builder.compilerArguments = options.compilerArguments
        }
        let result = builder.build()
        switch result {
            case .success():
                return .success(())
            case .failure(let error):
                switch error {
                case .buildError:
                    return .failure(.usageError(description: error.description))
                default:
                    return .failure(.usageError(description: error.description + "\n Please run 'xcframework help build' to see the full list of parameters for this command."))
                }
        }
    }
}
