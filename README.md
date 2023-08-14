## Idea behind the app

Text-based passwords are used everywhere nowadays, but what if we could use a real-world location as a password instead? 
This app simulates the experience of burying a treasure underground. 
Accessing the hidden data can only be done by knowing its location and having a special private key which is stored on the treasure owner's device.

## App's description

- Each user is assigned a public and private key upon account creation
- The private key is stored on the user's Keychain and is synced via iCloud
- User's account credentials are hashed with SHA
- A user can encrypt a piece of text
- The text is encrypted with AES and the AES key is encrypted with RSA (user's public key)
- The user's current location is saved along with the encrypted data and encrypted AES key
- To retrieve the text, the user must be in the same location and use the same device (or be logged into the same iCloud account) as when the encryption happened
- Encrypted data can be shared with others
- Sharing allows another user to access the data (only if they know the location)

## Tools used

- Swift & UIKit
- CocoaPods
- Firebase RT database
- CoreLocation
- CryptoKit
- Apple Keychain
- RSA, AES & SHA algorithms
