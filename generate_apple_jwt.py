#!/usr/bin/env python3
"""
Script pour générer le JWT Apple Sign-In pour Supabase
"""
import jwt
import time

# Vos informations Apple
team_id = "7M288BM6Q3"
client_id = "com.BadisG.ryzeApp.auth"  # Services ID
key_id = "8KB56YY7H8"

# Votre clé privée .p8
private_key = """-----BEGIN PRIVATE KEY-----
YOUR_PRIVATE_KEY_HERE
-----END PRIVATE KEY-----"""

# Timestamps (valide 6 mois)
now = int(time.time())
expiration = now + (6 * 30 * 24 * 60 * 60)  # 6 mois

# Headers
headers = {
    "alg": "ES256",
    "kid": key_id
}

# Payload
payload = {
    "iss": team_id,
    "iat": now,
    "exp": expiration,
    "aud": "https://appleid.apple.com",
    "sub": client_id
}

# Générer le JWT
token = jwt.encode(
    payload,
    private_key,
    algorithm="ES256",
    headers=headers
)

print("=" * 80)
print("JWT Apple Sign-In généré avec succès!")
print("=" * 80)
print("\nCopiez ce token dans le champ 'Secret Key' de Supabase:\n")
print(token)
print("\n" + "=" * 80)
print("Ce token expire dans 6 mois")
print("=" * 80)
