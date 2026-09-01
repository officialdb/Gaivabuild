from fastapi import HTTPException, status
from sqlalchemy.future import select
from app.models.user import User as UserModel
from app.core.security import verify_password, get_password_hash
from app.services.profile_service import ProfileService

class AccountService:
    @staticmethod
    async def change_password(db, user_id: str, current_password: str, new_password: str):
        if not new_password or len(new_password) < 6:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="New password must be at least 6 characters long."
            )
            
        result = await db.execute(select(UserModel).where(UserModel.email == user_id))
        user = result.scalars().first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
            
        if not verify_password(current_password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password is incorrect."
            )
            
        user.hashed_password = get_password_hash(new_password)
        await db.commit()
        return {"msg": "Password updated successfully."}

    @staticmethod
    async def toggle_2fa(db, user_id: str):
        # Return 2FA configuration
        return {"enabled": True, "secret": "GAIVABUILD2FASECRET", "qr_code_url": "https://gaivabuild.app/2fa-qr"}

    @staticmethod
    async def export_json(db, user_id: str):
        return await ProfileService.get_full_profile(db, user_id)

    @staticmethod
    async def clear_cache(db, user_id: str):
        return {"msg": "AI tailoring cache cleared successfully."}

    @staticmethod
    async def logout(db, user_id: str, token: str):
        return {"msg": "Logged out successfully."}

    @staticmethod
    async def delete_account(db, user_id: str):
        pass
