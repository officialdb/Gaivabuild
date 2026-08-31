class AccountService:
    @staticmethod
    async def change_password(db, user_id: str, current_password: str, new_password: str):
        pass

    @staticmethod
    async def toggle_2fa(db, user_id: str):
        return {"enabled": True, "secret": "mock", "qr_code_url": "mock_url"}

    @staticmethod
    async def export_json(db, user_id: str):
        return {}

    @staticmethod
    async def clear_cache(db, user_id: str):
        pass

    @staticmethod
    async def logout(db, user_id: str, token: str):
        pass

    @staticmethod
    async def delete_account(db, user_id: str):
        pass
