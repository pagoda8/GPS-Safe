## Idea behind the app

Text-based passwords are used everywhere nowadays, but what if we could use a real-world location as a password instead? 
This app simulates the experience of burying a treasure underground. 
Accessing the hidden data can only be done by knowing its location and having a special private key which is stored on the treasure owner's device 🌎🔑

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

## Screenshots

![1](https://github.com/pagoda8/GPS-Safe/assets/74459316/01e0c71e-2426-424a-8fc4-c40b799ee1f8)
![2](https://github.com/pagoda8/GPS-Safe/assets/74459316/4f44e81b-db86-48a8-b21b-8609b08f24a1)
![3](https://github.com/pagoda8/GPS-Safe/assets/74459316/2bc9c48e-0c8f-4564-86fb-a391ef59b568)
![4](https://github.com/pagoda8/GPS-Safe/assets/74459316/aad6e963-7922-45d4-a39c-98c88786719e)


