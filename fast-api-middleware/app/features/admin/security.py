import base64
import hashlib
import hmac
import secrets

PASSWORD_HASH_ITERATIONS = 600_000
PASSWORD_MIN_LENGTH = 5


def normalize_username(username: str) -> str:
    return username.strip().lower()


def hash_password(password: str) -> str:
    if len(password) < PASSWORD_MIN_LENGTH:
        raise ValueError(
            f"Password admin harus minimal {PASSWORD_MIN_LENGTH} karakter."
        )

    salt = secrets.token_bytes(16)
    derived_key = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        PASSWORD_HASH_ITERATIONS,
    )
    encoded_salt = base64.urlsafe_b64encode(salt).decode("ascii")
    encoded_key = base64.urlsafe_b64encode(derived_key).decode("ascii")
    return f"pbkdf2_sha256${PASSWORD_HASH_ITERATIONS}${encoded_salt}${encoded_key}"


def verify_password(password: str, encoded_hash: str) -> bool:
    try:
        algorithm, iterations, encoded_salt, encoded_key = encoded_hash.split("$")
        if algorithm != "pbkdf2_sha256":
            return False
        salt = base64.urlsafe_b64decode(encoded_salt.encode("ascii"))
        expected_key = base64.urlsafe_b64decode(encoded_key.encode("ascii"))
        actual_key = hashlib.pbkdf2_hmac(
            "sha256",
            password.encode("utf-8"),
            salt,
            int(iterations),
        )
    except (ValueError, TypeError):
        return False
    return hmac.compare_digest(actual_key, expected_key)
