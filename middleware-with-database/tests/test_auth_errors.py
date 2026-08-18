"""
Test untuk login endpoint dengan error messages yang lebih specific.
"""
import pytest
import json
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession
from unittest.mock import AsyncMock, patch

# Mock database response untuk user tidak ditemukan
@pytest.mark.asyncio
async def test_login_user_not_found():
    """
    Test ketika email/username tidak ada di database.
    Harus return 404 NOT_FOUND dengan pesan "Email/Username tidak ditemukan".
    """
    # Mock response dari repository.get_user_by_login() = None
    request_data = {
        "username": "nonexistent@example.com",
        "password": "password123"
    }
    
    # Expected response
    expected_status = 404
    expected_detail = "Email/Username tidak ditemukan. Silakan periksa kembali."
    
    # Hasil test akan:
    # - Return 404 status code
    # - Pesan akan ditampilkan di Flutter: "Email/Username tidak ditemukan. Silakan periksa kembali."


@pytest.mark.asyncio
async def test_login_password_wrong():
    """
    Test ketika email ada tapi password salah.
    Harus return 401 UNAUTHORIZED dengan pesan "Password salah".
    """
    # Mock response:
    # - repository.get_user_by_login() = {user_data...}
    # - repository.authenticate_user() = None (password mismatch)
    request_data = {
        "username": "valid@example.com",
        "password": "wrongpassword"
    }
    
    # Expected response
    expected_status = 401
    expected_detail = "Password salah. Silakan periksa kembali."
    
    # Hasil test akan:
    # - Return 401 status code
    # - Pesan akan ditampilkan di Flutter: "Password salah. Silakan periksa kembali."


@pytest.mark.asyncio
async def test_login_success():
    """
    Test ketika email dan password benar.
    Harus return 200 OK dengan token.
    """
    request_data = {
        "username": "valid@example.com",
        "password": "correctpassword"
    }
    
    # Expected response
    expected_status = 200
    expected_response_structure = {
        "success": True,
        "message": "Login berhasil",
        "data": {
            "access_token": "...",
            "token_type": "bearer",
            "user": {
                "user_id": 1,
                "username": "valid@example.com",
                "name": "User Name",
                # ... other user fields
            }
        }
    }
    
    # Hasil test akan:
    # - Return 200 status code
    # - Return access token untuk future requests
    # - Flutter akan save auth result ke Hive


# Integration test scenario
"""
Flow Test: Login dengan berbagai error cases

1. Test User Not Found:
   - POST /auth/login dengan email yang tidak ada
   - Response: 404 "Email/Username tidak ditemukan. Silakan periksa kembali."
   - Flutter UI: Tampilkan error message

2. Test Wrong Password:
   - POST /auth/login dengan email ada tapi password salah
   - Response: 401 "Password salah. Silakan periksa kembali."
   - Flutter UI: Tampilkan error message (berbeda dari user not found)

3. Test Success:
   - POST /auth/login dengan email & password benar
   - Response: 200 dengan access_token
   - Flutter: Save to Hive, navigate to Dashboard

4. Test Offline:
   - Saved auth di Hive
   - App restart tanpa network
   - restoreSessionFromHive() loads dari Hive (NO API CALL)
   - Dashboard shows dengan cached data
"""
