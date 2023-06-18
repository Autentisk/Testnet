from Crypto.Hash import keccak
from rlp import encode

def get_contract_address(address: str, nonce: int) -> str:
    """Get the contract address given an address and nonce."""
    address_bytes = bytes.fromhex(address[2:])  # Remove the 0x prefix

    # RLP encoding for the address and the nonce
    rlp_encoded = encode([address_bytes,nonce])

    # Get the Keccak-256 hash of the RLP encoded
    keccak_hash = keccak.new(digest_bits=256)
    keccak_hash.update(rlp_encoded)
    hashed = keccak_hash.digest()

    # The address without checksum
    contract_address_lower = hashed[-20:].hex()

    # Calculate the Keccak-256 hash of the lowercase address
    keccak_hash_address = keccak.new(digest_bits=256)
    keccak_hash_address.update(contract_address_lower.encode())
    keccak_hash_address_digest = keccak_hash_address.hexdigest()

    checksum_address = '0x'
    for i in range(len(contract_address_lower)):
        if int(keccak_hash_address_digest[i], 16) >= 8:
            checksum_address += contract_address_lower[i].upper()
        else:
            checksum_address += contract_address_lower[i]
    return checksum_address

if __name__ == '__main__':
    address = input("Enter the wallet address: ")
    nonce = int(input("Enter the nonce: "))
    contract_address = get_contract_address(address, nonce)
    print(f'The future contract address will be: {contract_address}')
