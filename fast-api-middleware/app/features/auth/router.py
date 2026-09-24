from fastapi import APIRouter, Depends, HTTPException, status
from app.core.dependencies import get_current_user_credentials, get_odoo_client
from app.core.odoo_client import OdooRPCClient
from app.features.auth.schemas import LoginRequest, ChangePasswordRequest, APIResponseLogin, TokenResponse, UserProfileData
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
    
    # Verifikasi login ke Odoo sebelum token aplikasi dibuat.
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

    # Simpan identitas dan konteks siswa, tanpa password mentah.
    jwt_payload = {
        "uid": user_info["uid"],
        "username": user_info["username"],
        "odoo_password": AuthService.encrypt_odoo_password(payload.password),
        "partner_id": user_info["partner_id"],
        "student_id": user_info["student_id"],
        "jenjang": user_info["jenjang"],
        "course_id": user_info["course_id"],
        "course_name": user_info["course_name"],
    }

    access_token = AuthService.create_access_token(data=jwt_payload)

    response_data = TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserProfileData(
            user_id=user_info["uid"],
            partner_id=user_info["partner_id"],
            name=user_info["name"],
            username=user_info["username"],
            email=user_info["email"],
            class_name=user_info["course_name"],
            jenjang=user_info["jenjang"],
        )
    )

    return APIResponseLogin(
        success=True,
        message="Login berhasil",
        data=response_data
    )

@router.post("/validate")
def validate_token(creds: dict = Depends(get_current_user_credentials)):
    """Validate the JWT locally for background session checks in the mobile app."""
    return {
        "success": True,
        "message": "Token valid",
        "data": {
            "user_id": creds.get("uid"),
            "username": creds.get("username"),
        },
    }

@router.post("/change-password")
def change_password(
    payload: ChangePasswordRequest,
    creds: dict = Depends(get_current_user_credentials),
    odoo_client: OdooRPCClient = Depends(get_odoo_client),
):
    if len(payload.new_password) < 6:
        raise HTTPException(status_code=400, detail="Password baru minimal 6 karakter.")
    if payload.current_password == payload.new_password:
        raise HTTPException(status_code=400, detail="Password baru harus berbeda dari password lama.")

    try:
        # Re-authenticate against Odoo instead of trusting the JWT password claim.
        authenticated_uid = odoo_client.common.authenticate(
            odoo_client.db,
            creds.get("username"),
            payload.current_password,
            {},
        )
        if authenticated_uid != creds["uid"]:
            raise HTTPException(status_code=401, detail="Password lama tidak sesuai.")

        updated = odoo_client.write(
            uid=creds["uid"],
            password=payload.current_password,
            model="res.users",
            ids=[creds["uid"]],
            values={"password": payload.new_password},
        )
        if not updated:
            raise HTTPException(status_code=400, detail="Password gagal diperbarui.")
        return {"success": True, "message": "Password berhasil diperbarui."}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Gagal memperbarui password: {str(e)}")