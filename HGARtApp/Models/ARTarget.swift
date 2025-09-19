//
//  ARTarget.swift
//  HGARt
//  model
//  Created by Stanislav Grinshpun on 2025-04-07.
//
import Foundation

struct ARTarget: Decodable {
    let name: String
    let imageUrl: String
    let videoUrl: String
    let physicalWidth: Float
}

struct ARTargetsConfig: Decodable {
    let targets: [ARTarget]
}
