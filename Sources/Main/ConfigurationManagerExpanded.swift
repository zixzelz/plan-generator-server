//
//  ConfigurationManagerExpanded.swift
//  plan-generator-server
//
//  Created by Ruslan Maslouski on 3/19/17.
//
//

import Configuration

extension ConfigurationManager {

    public var isDev: Bool {

        if url.range(of: "-dev") != nil || url.range(of: "localhost") != nil {
            return true
        }

        return false
    }

}
