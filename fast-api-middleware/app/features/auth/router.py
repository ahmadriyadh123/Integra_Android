from fastapi import APIRouter, Depends, HTTPException, status
from app.core.dependencies import get_odoo_client
from app.core.odoo_client import OdooRPCClient
from app.features.auth.schemas import LoginRequest, APIResponseLogin, TokenResponse, UserProfileData
from app.features.auth.repository import AuthRepository
from app.features.auth.service import AuthService

router = APIRouter(
    prefix="/auth",
    tags=["Autentikasi & Login"]
)

@router.post("/login", response_model=APIResponseLogin)
def login(
    payload: LoginRequest,
    odoo_client: OdooRPCClient = Depends(get_odoo_client)
):
    repo = AuthRepository(odoo_client)
    
    # 1. Verifikasi Kredensial ke Odoo
    user_info = repo.authenticate_odoo_user(
        username=payload.username, 
        password=payload.password
    )
    
    if not user_info:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Username/Email atau Password salah. Silakan periksa kembali kredensial Anda.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 2. Buat Payload JWT yang menyimpan uid & password Odoo
    jwt_payload = {
        "uid": user_info["uid"],
        "username": user_info["username"],
        "password": payload.password,  # Disimpan terenkripsi dalam JWT untuk dipasok ke Odoo RPC
        "partner_id": user_info["partner_id"],  # Disimpan untuk referensi profil
        "student_id": user_info["student_id"]   # Disimpan untuk filter attendance tanpa query op.student
    }
    
    access_token = AuthService.create_access_token(data=jwt_payload)

    # 3. Kembalikan Response Token dan Data Profil User
    response_data = TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserProfileData(
            user_id=user_info["uid"],
            partner_id=user_info["partner_id"],
            name=user_info["name"],
            username=user_info["username"],
            email=user_info["email"]
        )
    )

    return APIResponseLogin(
        success=True,
        message="Login berhasil",
        data=response_data
    )