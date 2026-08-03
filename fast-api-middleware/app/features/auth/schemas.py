from pydantic import BaseModel
from typing import Optional

class LoginRequest(BaseModel):
    username: str  # Email / Username akun Odoo
    password: str  # Password akun Odoo

class UserProfileData(BaseModel):
    user_id: int
    partner_id: Optional[int] = None
    name: str
    username: str
    email: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserProfileData

class APIResponseLogin(BaseModel):
    success: bool
    message: str
    data: Optional[TokenResponse] = None