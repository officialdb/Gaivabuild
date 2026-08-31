class ProfileService:
    @staticmethod
    async def get_full_profile(db, user_id: str):
        pass

    @staticmethod
    async def update_details(db, user_id: str, data):
        pass

    @staticmethod
    async def update_links(db, user_id: str, data):
        pass

    @staticmethod
    async def create_experience(db, user_id: str, data):
        pass

    @staticmethod
    async def update_experience(db, user_id: str, exp_id: str, data):
        pass

    @staticmethod
    async def delete_experience(db, user_id: str, exp_id: str):
        pass

    @staticmethod
    async def update_skills(db, user_id: str, data):
        pass

    @staticmethod
    async def create_education(db, user_id: str, data):
        pass

    @staticmethod
    async def update_education(db, user_id: str, edu_id: str, data):
        pass

    @staticmethod
    async def delete_education(db, user_id: str, edu_id: str):
        pass

    @staticmethod
    async def parse_cv(file_bytes: bytes) -> dict:
        return {}
