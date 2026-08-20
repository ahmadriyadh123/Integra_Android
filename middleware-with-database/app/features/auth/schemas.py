# app/features/auth/schemas.py
from pydantic import BaseModel, EmailStr
from typing import Optional, List

class LoginRequest(BaseModel):
    username: str  # login / email / username
    password: str

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

class UserProfileData(BaseModel):
    user_id: int
    partner_id: Optional[int] = None
    student_id: Optional[int] = None
    nis: Optional[str] = None
    name: str
    username: str
    email: Optional[str] = None
    is_portal: bool = False

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserProfileData

class APIResponseLogin(BaseModel):
    success: bool
    message: str
    data: Optional[TokenResponse] = None