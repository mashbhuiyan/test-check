const crypto = require("crypto");

module.exports = class AESCipher {
    constructor() {
    }

    encrypt(plain_text, key) {
        const cipher = crypto.createCipheriv('aes-128-ecb', key, null);
        let encrypted = cipher.update(plain_text, 'utf8', 'base64');
        encrypted += cipher.final('base64');
        return encrypted;
    }

    decrypt(encrypted_data, key) {
        const decipher = crypto.createDecipheriv('aes-128-ecb', key, null);
        let decrypted = decipher.update(encrypted_data, 'base64', 'utf8');
        decrypted += decipher.final('utf8');
        return decrypted;
    }
}
