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
	
	//Generate and return public and private key
	//Throws error when unsuccessful
	public static func generateKeys(username: String) throws -> Dictionary<String, SecKey> {
		let tag = ("com.pagoda8.GPS-Safe." + username).data(using: .utf8)
		
		let attributes: [String: Any] = [
			kSecAttrType as String: kSecAttrKeyTypeRSA,
			kSecAttrKeySizeInBits as String: 2048,
			kSecPrivateKeyAttrs as String: [
				kSecAttrIsPermanent as String: true,
				kSecAttrApplicationTag as String: tag!
			]
		]
		
		var error: Unmanaged<CFError>?
		
		guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
			throw error!.takeRetainedValue() as Error
		}
		guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
			throw error!.takeRetainedValue() as Error
		}
		
		let keys = ["public": publicKey, "private": privateKey]
		
		return keys
	}
}
