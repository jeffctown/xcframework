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
                return .failure(.usageError(description: error.localizedDescription))
        }
    }
}
