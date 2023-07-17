//
//  StartupTask.swift
//  Ulry
//
//  Created by Matt on 03/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import os
import Foundation

public protocol StartupTask {
    var runOnce: Bool { get }
    var key: String { get }

    func execTask() throws
}

extension StartupTask {
    func run() {
        guard shouldRun() else { return }
        os_log(.info, "running task: \(key)")

        do {
            try execTask()
        } catch {
            fatalError("[TASK][ERROR] -> [\(key)] failed because: \(error)")
        }

        setRun()
    }

    func shouldRun() -> Bool {
        // If not runOnce then always run
        !runOnce ||
        // If runOnce, run only if it hasn't been run before
        (runOnce && !UserDefaults(suiteName: "com.mattrighetti.Ulry.startup-tasks")!.bool(forKey: key))
    }

    func setRun() {
        if runOnce {
            UserDefaults(suiteName: "com.mattrighetti.Ulry.startup-tasks")!.set(true, forKey: key)
        }
    }
}

