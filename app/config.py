from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    discogs_token: str
    discogs_user_agent: str = "CDManager/1.0"
    secret_key: str
    admin_password: str
    musicbrainz_user_agent: str = "CDManager/1.0"
    db_path: str = "data/cd_manager.db"
    covers_path: str = "data/covers"

    class Config:
        env_file = ".env"

settings = Settings()
