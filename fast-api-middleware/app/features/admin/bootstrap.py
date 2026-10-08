import logging

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.models import SchoolAdminAccount
from app.features.admin.security import hash_password, normalize_username

logger = logging.getLogger(__name__)


def seed_initial_admin(db: Session) -> bool:
    username = settings.SCHOOL_ADMIN_USERNAME.strip()
    password = settings.SCHOOL_ADMIN_PASSWORD
    if not username and not password:
        logger.warning(
            "No school admin account is configured. Set "
            "SCHOOL_ADMIN_USERNAME and SCHOOL_ADMIN_PASSWORD to bootstrap one."
        )
        return False
    if not username or not password:
        raise ValueError(
            "SCHOOL_ADMIN_USERNAME dan SCHOOL_ADMIN_PASSWORD harus diatur bersama."
        )
    if len(username) > 120:
        raise ValueError("Username admin maksimal 120 karakter.")

    if db.query(SchoolAdminAccount).first():
        return False

    account = SchoolAdminAccount(
        username=normalize_username(username),
        password_hash=hash_password(password),
        is_active=True,
    )
    db.add(account)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        if db.query(SchoolAdminAccount).first():
            return False
        raise
    logger.info("Initial school admin account has been stored in the database.")
    return True
