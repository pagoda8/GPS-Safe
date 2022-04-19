//
//  Crypto.swift
//  GPS Safe
//
//  Class for all cryptographic operations
//

import UIKit
import CryptoKit

public class Crypto {
	
	//Used for identifying keys in keychain
	private static let appTag = "com.pagoda8.GPS-Safe."
	
	
	//Returns a SHA256 hash of a string
	public static func hash(input: String) -> String {
		let data = Data(input.utf8)
		let hash = SHA256.hash(data: data)
		let string = hash.compactMap { String(format: "%02x", $0) }.joined()
		return string
	}
	
	//Encrypts a string using a symmetric key and returns encrypted string
	//Throws error when unsuccessful
	public static func encryptTextAES(plaintext: String, key: SymmetricKey) throws -> String {
		guard let textData = plaintext.data(using: .utf8) else {
			throw CryptoError.dataConversionError
		}
		
		let sealedData = try AES.GCM.seal(textData, using: key)
		let combined = sealedData.combined!
		
		return combined.base64EncodedString()
	}
	
	//Decrypts an encrypted string using a symmetric key and returns decrypted string
	//Throws error when unsuccessful
	public static func decryptTextAES(ciphertext: String, key: SymmetricKey) throws -> String {
		guard let textDataCombined = Data(base64Encoded: ciphertext) else {
			throw CryptoError.dataConversionError
		}
		
		let sealedData = try AES.GCM.SealedBox(combined: textDataCombined)
		let decryptedData = try AES.GCM.open(sealedData, using: key)
		
		if let decryptedString = String(data: decryptedData, encoding: .utf8) {
			return decryptedString
		} else {
			throw CryptoError.dataConversionError
		}
	}
	
	//Encrypts a string with a public key and returns encrypted string
	//Throws error when unsuccessful
	public static func encryptRSA(string: String, publicKey: SecKey) throws -> String {
		guard let stringData = string.data(using: .utf8) else {
			throw CryptoError.dataConversionError
		}
		
		var error: Unmanaged<CFError>?
		guard let encryptedCFData = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionPKCS1, stringData as CFData, &error) else {
			throw error!.takeRetainedValue() as Error
		}
		
		let encryptedData = encryptedCFData as Data
		
		return encryptedData.base64EncodedString()
	}
	
	//Decrypts an encrypted string with a private key and returns decrypted string
	//Throws error when unsuccessful
	public static func decryptRSA(string: String, privateKey: SecKey) throws -> String {
		guard let stringData = Data(base64Encoded: string) else {
			throw CryptoError.dataConversionError
		}
		
		var error: Unmanaged<CFError>?
		guard let decryptedCFData = SecKeyCreateDecryptedData(privateKey, .rsaEncryptionPKCS1, stringData as CFData, &error) else {
			throw error!.takeRetainedValue() as Error
		}
		
		let decryptedData = decryptedCFData as Data
		
		if let decryptedString = String(data: decryptedData, encoding: .utf8) {
			return decryptedString
		} else {
			throw CryptoError.dataConversionError
		}
	}
	
	//Generates and returns a symmetric key
	public static func generateAESKey() -> SymmetricKey {
		return SymmetricKey(size: .bits128)
	}
	
	//Generates and returns public and private key
	//Throws error when unsuccessful
	public static func generateRSAKeys(username: String) throws -> Dictionary<String, SecKey> {
		//Key identifier in Keychain
		guard let tag = (appTag + username).data(using: .utf8) else {
			throw CryptoError.dataConversionError
		}
		
		let attributes: [String: Any] = [
			kSecAttrType as String: kSecAttrKeyTypeRSA,
			kSecAttrKeySizeInBits as String: 2048,
			kSecPrivateKeyAttrs as String: [
				kSecAttrIsPermanent as String: true,
				kSecAttrCanDecrypt as String: true,
				kSecAttrApplicationTag as String: tag
			]
		]
		
		var error: Unmanaged<CFError>?
		
		//Generate and save in Keychain
		guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
			throw error!.takeRetainedValue() as Error
		}
		guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
			throw error!.takeRetainedValue() as Error
		}
		
		let keys = ["public": publicKey, "private": privateKey]
		
		return keys
	}
	
	//Returns private key from user's Keychain
	//Throws error when unsuccessful
	public static func getPrivateKey(username: String) throws -> SecKey {
		//Key identifier in Keychain
		guard let tag = (appTag + username).data(using: .utf8) else {
			throw CryptoError.dataConversionError
		}
		
		let query: [String: Any] = [
			kSecClass as String: kSecClassKey,
			kSecAttrApplicationTag as String: tag,
			kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
			kSecReturnPersistentRef as String: kCFBooleanTrue!
		]
		
		var item: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &item)
		
		if (status == errSecSuccess) {
			let privateKey = item as! SecKey
			return privateKey
		} else {
			throw CryptoError.keyReadingError
		}
	}
	
	//Returns a string representation of a SymmetricKey
	//Throws error when unsuccessful
	public static func getStringFromAESKey(key: SymmetricKey) throws -> String {
		return key.withUnsafeBytes { body in
			Data(body).base64EncodedString()
		}
	}
	
	//Returns a SymmetricKey given a string representation of a symmetric key
	//Throws error when unsuccessful
	public static func getAESKeyFromString(keyString: String) throws -> SymmetricKey {
		guard let keyData = Data(base64Encoded: keyString) else {
			throw CryptoError.dataConversionError
		}
		
		let key = SymmetricKey(data: keyData)
		
		return key
	}
	
	//Returns a string representation of a SecKey
	//Throws error when unsuccessful
	public static func getStringFromRSAKey(key: SecKey) throws -> String {
		var error: Unmanaged<CFError>?
		if let cfdata = SecKeyCopyExternalRepresentation(key, &error) {
			let data = cfdata as Data
			let keyString = data.base64EncodedString()
			return keyString
		} else {
			throw error!.takeRetainedValue() as Error
		}
	}
	
	//Returns a SecKey given a string representation of a public key
	//Throws error when unsuccessful
	public static func getPublicKeyFromString(keyString: String) throws -> SecKey {
		if let data = Data(base64Encoded: keyString) {
			let attributes: [String: Any] = [
				kSecAttrType as String: kSecAttrKeyTypeRSA,
				kSecAttrKeySizeInBits as String: 2048,
				kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
				kSecReturnPersistentRef as String: kCFBooleanTrue!
			]
			
			var error: Unmanaged<CFError>?
			if let secKey = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) {
				return secKey
			} else {
				throw error!.takeRetainedValue() as Error
			}
		} else {
			throw CryptoError.keyReadingError
		}
	}
	
	//Enum for throwing errors
	public enum CryptoError: Error {
		case keyReadingError
		case dataConversionError
	}
}
