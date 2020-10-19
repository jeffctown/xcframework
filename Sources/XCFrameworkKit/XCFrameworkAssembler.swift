//
//  XCFrameworkAssembler.swift
//  
//
//  Created by Antonino Urbano on 2020-01-11.
//

import Foundation
import Shell

public struct XCFrameworkAssembler {

    public var name: String?
    public var outputDirectory: String?
    public var frameworkPaths: [String]?

    private struct Framework {
        
        let path: String
        let name: String
        let archs: [String]
        let temporary: Bool
        
        var binaryPath: String {
            path+"/"+name
        }
    }
    
    private func frameworks(from paths: [String]) -> Result<[Framework], XCFrameworkAssemblerError> {
        
        var frameworks = [Framework]()
        for path in paths {
            guard path.hasSuffix(".framework") else {
                print(paths)
                return .failure(.invalidFrameworks)
            }
            if let binaryName = path.split(separator: "/").last?.split(separator: ".").first {
                let binaryPath = path + "/" + binaryName
                let archsResult = shell.usr.bin.xcrun.dynamicallyCall(withArguments: ["lipo", binaryPath, "-archs"])
                if !archsResult.isSuccess {
                    return .failure(.other("Couldn't parse the framework paths: \(archsResult.stderr)"))
                }
                if let archs = archsResult.stdout
                    .split(separator: "\n")
                    .first?
                    .split(separator: " ")
                    .compactMap({ String.init($0) }) {
                    frameworks.append(XCFrameworkAssembler.Framework(path: path, name: String(binaryName), archs: archs, temporary: false))
                }
            }
        }
        return .success(frameworks)
    }
    
    public enum XCFrameworkAssemblerError: Error {
        case nameNotFound
        case frameworksNotFound
        case invalidFrameworks
        case outputDirectoryNotFound
        case other(String)
        
        public var description: String {
            switch self {
            case .nameNotFound:
                return "No name parameter found."
            case .frameworksNotFound:
                return "No frameworks specified."
            case .invalidFrameworks:
                return "One or more of the passed in frameworks is not a valid .framework file, or the specified path was wrong."
            case .outputDirectoryNotFound:
                return "No output directory found."
            case .other(let stderr):
                return stderr
            }
        }
    }
    
    public init(name: String?, outputDirectory: String?, frameworkPaths: [String]?) {
        
        self.name = name
        self.outputDirectory = outputDirectory
        self.frameworkPaths = frameworkPaths
    }
    
    public mutating func assemble() -> Result<(),XCFrameworkAssemblerError> {
        
        guard let name = name else {
            return .failure(.nameNotFound)
        }
        
        guard let outputDirectory = outputDirectory else {
            return .failure(.outputDirectoryNotFound)
        }
        
        guard let frameworkPaths = frameworkPaths, frameworkPaths.count > 0 else {
            return .failure(.frameworksNotFound)
        }
        
        var frameworks = [Framework]()
        switch self.frameworks(from: frameworkPaths) {
        case .success(let result):
            frameworks = result
        case .failure(let error):
            return .failure(error)
        }
        
        guard frameworks.count > 0 else {
            print("count is 0")
            return .failure(.invalidFrameworks)
        }
                
        let finalOutputDirectory = outputDirectory.hasSuffix("/") ? outputDirectory : outputDirectory + "/"
        let finalOutput = finalOutputDirectory + name + ".xcframework"
        shell.bin.rm("-r",finalOutput)
        
        //duplicate the frameworks per-architecture and then create an xcframework from them
        var thinnedFrameworks = [Framework]()
        for framework in frameworks {
            print("Thinning framework \(framework.name) with archs: \(framework.archs)")
            if framework.archs.count <= 1 {
                thinnedFrameworks.append(framework)
            } else {
                for arch in framework.archs {
                    let thinnedFrameworkPath = "\(framework.path)/../\(framework.name)_\(arch).framework"
                    let thinnedFramework = Framework(path: thinnedFrameworkPath, name: framework.name, archs: [arch], temporary: true)
                    shell.bin.rm("-r",thinnedFramework.path)
                    let copyResult = shell.bin.cp("-R", framework.path, thinnedFramework.path)
                    if !copyResult.isSuccess {
                        return Result.failure(.other(copyResult.stderr))
                    }
                    let thinnedResult = shell.usr.bin.xcrun.dynamicallyCall(withArguments: ["lipo", thinnedFramework.binaryPath, "-thin", arch, "-output", thinnedFramework.binaryPath])
                    if !thinnedResult.isSuccess {
                        return Result.failure(.other(thinnedResult.stderr))
                    }
                    thinnedFrameworks.append(thinnedFramework)
                }
            }
        }
        
        print("All thinned variants created, creating xcframework...")
        
        var arguments = [
            "-create-xcframework",
            "-output",
            finalOutput,
        ]
        
        for thinnedFramework in thinnedFrameworks {
            arguments.append("-framework")
            arguments.append(thinnedFramework.path)
        }
        
        let xcframeworkResult = shell.usr.bin.xcodebuild.dynamicallyCall(withArguments: arguments)
        
        print("Cleaning up...")
        for thinnedFramework in thinnedFrameworks {
            if thinnedFramework.temporary {
                shell.bin.rm("-r",thinnedFramework.path)
            }
        }

        if !xcframeworkResult.isSuccess || !xcframeworkResult.stderr.isEmpty {
            return Result.failure(.other("xcframework creation failed. \nArguments: \(arguments.joined(separator: " "))\nError: \(xcframeworkResult.stderr)"))
        }
        
        print("Successfully created \(name).xcframework")
        
        return .success(())
    }
}
