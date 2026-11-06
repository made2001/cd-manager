from sqlalchemy import Column, Integer, String, Float, Text, DateTime, ForeignKey, Table
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

cd_tags = Table(
    "cd_tags", Base.metadata,
    Column("cd_id", Integer, ForeignKey("cds.id"), primary_key=True),
    Column("tag_id", Integer, ForeignKey("tags.id"), primary_key=True),
)

class CD(Base):
    __tablename__ = "cds"
    id = Column(Integer, primary_key=True, autoincrement=True)
    discogs_release_id = Column(Integer, nullable=True, index=True)
    title = Column(String, nullable=False)
    artist = Column(String, nullable=False, index=True)
    artist_sort = Column(String, nullable=True, index=True)
    title_sort = Column(String, nullable=True, index=True)
    label = Column(String, nullable=True)
    catalog_number = Column(String, nullable=True)
    year = Column(Integer, nullable=True, index=True)
    format = Column(String, nullable=True)
    genre = Column(String, nullable=True, index=True)
    style = Column(String, nullable=True)
    condition = Column(String, nullable=True)
    price_paid = Column(Float, nullable=True)
    currency = Column(String, default="EUR")
    notes = Column(Text, nullable=True)
    cover_image_path = Column(String, nullable=True)
    discogs_url = Column(String, nullable=True)
    ean = Column(String, nullable=True, index=True)
    in_wantlist = Column(Integer, default=0)
    date_added = Column(DateTime, default=datetime.utcnow)
    date_purchased = Column(DateTime, nullable=True)
    tracks = relationship("Track", back_populates="cd", cascade="all, delete-orphan")
    tags = relationship("Tag", secondary=cd_tags, back_populates="cds")

class Track(Base):
    __tablename__ = "tracks"
    id = Column(Integer, primary_key=True, autoincrement=True)
    cd_id = Column(Integer, ForeignKey("cds.id"), nullable=False)
    position = Column(String, nullable=True)
    title = Column(String, nullable=False)
    duration = Column(String, nullable=True)
    cd = relationship("CD", back_populates="tracks")

class Tag(Base):
    __tablename__ = "tags"
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, unique=True, nullable=False)
    cds = relationship("CD", secondary=cd_tags, back_populates="tags")

class Setting(Base):
    __tablename__ = "settings"
    key = Column(String, primary_key=True)
    value = Column(String, nullable=True)
