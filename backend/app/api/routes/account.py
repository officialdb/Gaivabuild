from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from app.api.dependencies import get_current_user, get_db, oauth2_scheme
from app.schemas.account import ChangePasswordRequest, TwoFactorToggleResponse
from app.services.account_service import AccountService

router = APIRouter()

@router.post("/change-password")
async def change_password(data: ChangePasswordRequest, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    await AccountService.change_password(db, current_user, data.current_password, data.new_password)
    return {"msg": "Password updated"}

@router.post("/2fa/toggle", response_model=TwoFactorToggleResponse)
async def toggle_2fa(current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await AccountService.toggle_2fa(db, current_user)

@router.get("/export-json")
async def export_json(current_user: str = Depends(get_current_user), db = Depends(get_db)):
    data = await AccountService.export_json(db, current_user)
    return JSONResponse(content=data, headers={"Content-Disposition": 'attachment; filename="master_profile.json"'})

@router.delete("/clear-cache")
async def clear_cache(current_user: str = Depends(get_current_user), db = Depends(get_db)):
    await AccountService.clear_cache(db, current_user)
    return {"msg": "Cache cleared"}

@router.post("/logout")
async def logout(token: str = Depends(oauth2_scheme), current_user: str = Depends(get_current_user), db = Depends(get_db)):
    await AccountService.logout(db, current_user, token)
    return {"msg": "Logged out"}

@router.delete("/", status_code=status.HTTP_200_OK)
async def delete_account(current_user: str = Depends(get_current_user), db = Depends(get_db)):
    from sqlalchemy.future import select
    from app.models.user import User as UserModel
    from datetime import datetime, timezone

    result = await db.execute(select(UserModel).where(UserModel.email == current_user))
    user = result.scalars().first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.is_active = False
    user.deleted_at = datetime.now(timezone.utc)
    
    await db.commit()
    
    return {"message": "Account deleted successfully. Your data will be permanently removed in 30 days."}
