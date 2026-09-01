import asyncio
import os
from sqlalchemy.ext.asyncio import create_async_engine
from app.models.user import User
from app.models.profile import MasterProfile
from app.core.database import Base

DATABASE_URL = "postgresql+asyncpg://neondb_owner:npg_b4eGUD6jfKvV@ep-patient-haze-ayj6lw56-pooler.c-5.us-east-2.aws.neon.tech/neondb?sslmode=require"

engine = create_async_engine(DATABASE_URL, echo=True)

async def init_models():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("Tables created successfully!")

if __name__ == "__main__":
    asyncio.run(init_models())

