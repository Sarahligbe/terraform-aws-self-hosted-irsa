import json
import base64
import hashlib
import boto3
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

def handler(event, context):
    try:
        pem_data = event['public_key_pem']
        discovery_bucket = event['discovery_bucket_name']
        cluster_name = event['cluster_name']
        region = event['region']
        
        s3 = boto3.client('s3', region_name=region)
        
        public_key = serialization.load_pem_public_key(pem_data.encode())
        
        if not isinstance(public_key, rsa.RSAPublicKey):
            raise Exception("Public key was not RSA")
        
        public_key_der_bytes = public_key.public_bytes(
            encoding=serialization.Encoding.DER,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        
        hasher = hashlib.sha256()
        hasher.update(public_key_der_bytes)
        public_key_der_hash = hasher.digest()
        
        key_id = base64.urlsafe_b64encode(public_key_der_hash).decode().rstrip('=')
        
        public_numbers = public_key.public_numbers()
        
        def int_to_base64url(val):
            """Convert integer to base64url without padding (go-jose format)"""
            byte_length = (val.bit_length() + 7) // 8
            val_bytes = val.to_bytes(byte_length, 'big')
            return base64.urlsafe_b64encode(val_bytes).decode().rstrip('=')
        
        jwks = {
            "keys": [
                {
                    "kty": "RSA",                                    
                    "use": "sig",                                   
                    "alg": "RS256",                                  
                    "kid": key_id,                                  
                    "n": int_to_base64url(public_numbers.n),        
                    "e": int_to_base64url(public_numbers.e)        
                }
            ]
        }
        
        s3.put_object(
            Bucket=discovery_bucket,
            Key='keys.json',
            Body=json.dumps(jwks, indent=4),
            ContentType='application/json',
            CacheControl='no-cache',
            Metadata={
                'key-id': key_id,
                'generated-by': 'terraform-irsa-lambda',
                'algorithm': 'RS256'
            }
        )
        
        return {
            'jwks_uploaded': True,
            'mode': 'production',
            'algorithm': 'RS256',
            'key_type': 'RSA'
        }
        
    except Exception as e:
        return {
            'error': str(e),
            'jwks_uploaded': False,
            'mode': 'production'
        }