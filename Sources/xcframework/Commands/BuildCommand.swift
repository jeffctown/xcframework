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
        let schemes: [String]
        let outputDirectory: String
        let buildDirectory: String
        let verbose: Bool
        
        static func create(_ project: String?) -> (String?)  -> ([String]) -> (String) -> (String) -> (Bool) -> Options {
            return { name in { schemes in { outputDirectory in { buildDirectory in  { verbose in Options(project: project, name: name, schemes: schemes, outputDirectory: outputDirectory, buildDirectory: buildDirectory, verbose: verbose) } } } } }
        }
        
        static func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<CommandantError<()>>> {
            let defaultBuildDirectory = ".xcframework/build/"
            return create
                <*> mode <| Option(key: "project", defaultValue: nil, usage: "REQUIRED: the path and project to build")
                <*> mode <| Option(key: "name", defaultValue: nil, usage: "REQUIRED: the framework name, Example: <name>.framework")
                <*> mode <| Option(key: "schemes", defaultValue: [], usage: "REQUIRED: a comma separated list of the schemes to build")
                <*> mode <| Option(key: "output", defaultValue: FileManager.default.currentDirectoryPath, usage: "the output directory (default: .)")
                <*> mode <| Option(key: "build", defaultValue: FileManager.default.currentDirectoryPath.appending(defaultBuildDirectory), usage: "build directory (default: \(defaultBuildDirectory)")
                <*> mode <| Switch(key: "verbose", usage: "enable verbose logs")
            
        }
    }
    
    func run(_ options: Options) -> Result<(), CommandantError<()>> {
        let builder = XCFrameworkBuilder() { builder in
            builder.name = options.name
            builder.project = options.project
            builder.schemes = options.schemes
            builder.outputDirectory = options.outputDirectory
            builder.buildDirectory = options.buildDirectory
            builder.verbose = options.verbose
        }
        let result = builder.build()
        switch result {
            case .success():
                return .success(())
            case .failure(let error):
                return .failure(.usageError(description: error.localizedDescription + "\n Please run 'xcframework help build' to see the full list of parameters for this command."))
        }
    }
}
