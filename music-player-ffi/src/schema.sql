PRAGMA journal_mode = wal2;

CREATE TABLE IF NOT EXISTS artist (artist_name TEXT PRIMARY KEY);

CREATE TABLE IF NOT EXISTS album (
  album_title TEXT,
  artist_name TEXT,
  FOREIGN KEY (artist_name) REFERENCES artist (artist_name) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (album_title, artist_name)
);

CREATE TABLE IF NOT EXISTS song (
  path TEXT NOT NULL,
  title TEXT NOT NULL,
  modified_stamp INTEGER NOT NULL,
  artist_name TEXT NOT NULL,
  disc_number INTEGER NOT NULL,
  track_number INTEGER NOT NULL,
  duration INTEGER NOT NULL,
  album_title TEXT NOT NULL,
  FOREIGN KEY (album_title, artist_name) REFERENCES album (album_title, artist_name) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (path)
);

CREATE VIRTUAL TABLE IF NOT EXISTS song_search USING FTS5 (
  title,
  artist_name,
  album_title,
  path UNINDEXED
);

CREATE TRIGGER IF NOT EXISTS delete_album_if_no_songs
AFTER DELETE ON song
FOR EACH ROW
BEGIN
  DELETE FROM album
  WHERE album_title = OLD.album_title
    AND artist_name = OLD.artist_name
    AND NOT EXISTS (
      SELECT 1 FROM song
      WHERE album_title = OLD.album_title
        AND artist_name = OLD.artist_name
    );
END;

CREATE TRIGGER IF NOT EXISTS delete_artist_if_no_songs
AFTER DELETE ON song
FOR EACH ROW
BEGIN
  DELETE FROM artist
  WHERE artist_name = OLD.artist_name
    AND NOT EXISTS (
      SELECT 1 FROM song
      WHERE artist_name = OLD.artist_name
    );
END;

CREATE TRIGGER IF NOT EXISTS delete_song_from_search
AFTER DELETE ON song
FOR EACH ROW
BEGIN
  DELETE FROM song_search
  WHERE path = OLD.path;
END;

CREATE TRIGGER IF NOT EXISTS update_song_in_search
AFTER UPDATE ON song
FOR EACH ROW
BEGIN
  UPDATE song_search
  SET path = NEW.path,
      title = NEW.title,
      artist_name = NEW.artist_name,
      album_title = NEW.album_title
  WHERE path = OLD.path;
END;