//
//  AssembleCommand.swift
//  
//
//  Created by Antonino Urbano on 2020-01-11.
//

import Commandant
import Foundation
import Shell
import XCFrameworkKit

struct AssembleCommand: CommandProtocol {
    
    static let frameworkSuffix = ".framework"
    
    // MARK: - CommandProtocol
    
    var verb = "assemble"
    var function = "Assembles an xcframework from pre-built frameworks. If the framework(s) passed in are fat  binaries containing multiple architecturees, they will first be split apart."

    // MARK: - OptionsProtocol
    
    struct Options: OptionsProtocol {
        let name: String?
        let outputDirectory: String
        let frameworks: String?
        
        static func create(_ name: String?) -> (String) -> (String?) -> Options {
            return { outputDirectory in { frameworks in Options(name: name, outputDirectory: outputDirectory, frameworks: frameworks ) } }
        }
        
        static func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<CommandantError<()>>> {
            return create
                <*> mode <| Option(key: "name", defaultValue: nil, usage: "REQUIRED: the framework name, Example: <name>.framework")
                <*> mode <| Option(key: "output", defaultValue: FileManager.default.currentDirectoryPath, usage: "the output directory (default: .)")
                <*> mode <| Option(key: "frameworks", defaultValue: nil, usage: "the pre-build frameworks to assemble into an xcframework")
        }
    }
    
    func run(_ options: Options) -> Result<(), CommandantError<()>> {
        
        var sanitizedFrameworks = options.frameworks?.components(separatedBy: "\(Self.frameworkSuffix) ")
        if sanitizedFrameworks?.count ?? 0 > 1 {
            sanitizedFrameworks = sanitizedFrameworks?.map { !$0.hasSuffix(Self.frameworkSuffix) ? $0+Self.frameworkSuffix : $0 }
        }
        
        var builder = XCFrameworkAssembler.init(name: options.name, outputDirectory: options.outputDirectory, frameworkPaths: sanitizedFrameworks)
        
        let result = builder.assemble()
        switch result {
            case .success():
                return .success(())
            case .failure(let error):
                switch error {
                case .other:
                    return .failure(.usageError(description: error.description))
                default:
                    return .failure(.usageError(description: error.description + "\n Please run 'xcframework help assemble' to see the full list of parameters for this command."))
                }
        }
    }
}
