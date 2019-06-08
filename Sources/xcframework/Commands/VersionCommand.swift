//
//  VersionCommand.swift
//  xcframework
//
//  Created by Jeff Lett on 6/7/19.
//

import Commandant
import Foundation
import XCFrameworkKit

struct VersionCommand: CommandProtocol {
    // MARK: - CommandProtocol
    
    let verb = "version"
    let function = "Display the current version of xcframework"
    
    func run(_ options: NoOptions<CommandantError<()>>) -> Result<(), CommandantError<()>> {
        print(Version.current.value)
        return .success(())
    }
}
