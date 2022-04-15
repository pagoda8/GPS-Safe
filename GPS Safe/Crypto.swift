//
//  Crypto.swift
//  GPS Safe
//
//  Class for all cryptographic operations
//

import UIKit
import CryptoKit

public class Crypto {
	
	//Returns a SHA256 hash of a string
	public static func hash(input: String) -> String {
		let data = Data(input.utf8)
		let hash = SHA256.hash(data: data)
		let string = hash.compactMap { String(format: "%02x", $0) }.joined()
		return string
	}
}
