import asyncio
import logging
from datetime import datetime, timedelta, timezone
from sqlalchemy.future import select
from sqlalchemy import delete
from app.core.database import AsyncSessionLocal
from app.models.user import User

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def run_cleanup():
    """
    Standalone task to permanently delete accounts that have been soft-deleted for more than 30 days.
    """
    logger.info("Starting automated cleanup task for soft-deleted accounts.")
    
    threshold_date = datetime.now(timezone.utc) - timedelta(days=30)
    
    async with AsyncSessionLocal() as session:
        # Find all users where deleted_at is older than or equal to 30 days ago
        query = select(User).where(User.is_active == False, User.deleted_at <= threshold_date)
        result = await session.execute(query)
        users_to_delete = result.scalars().all()
        
        if not users_to_delete:
            logger.info("No accounts found for permanent deletion today.")
            return

        emails_to_delete = [user.email for user in users_to_delete]
        
        # Execute hard delete. (Assuming cascading deletes are configured on the DB side for related data)
        delete_stmt = delete(User).where(User.email.in_(emails_to_delete))
        await session.execute(delete_stmt)
        await session.commit()
        
        logger.info(f"Successfully permanently deleted {len(emails_to_delete)} account(s).")
        for email in emails_to_delete:
            logger.info(f" - Purged: {email}")

if __name__ == "__main__":
    asyncio.run(run_cleanup())

