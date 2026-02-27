-- CREATE SCHEMA ai;
--DROP TABLE dbo.netflix_titles;
DROP TABLE ai.netflix_titles;

--SELECT * FROM dbo.netflix_titles2;

CREATE TABLE ai.netflix_titles (
    show_id VARCHAR(10) UNIQUE NOT NULL,
    show_type VARCHAR(20) NOT NULL,
    title VARCHAR(1000) NOT NULL,
    director VARCHAR(250) NULL,
    show_cast TEXT  NULL,
    country VARCHAR(1000) NULL,
    date_added VARCHAR(100) NULL,
    release_year INT  NOT NULL,
    rating VARCHAR(10) NULL,
    duration VARCHAR(100)  NULL,
    listed_in VARCHAR(100) NOT NULL,
    [description] NVARCHAR(MAX)  NOT NULL
);


INSERT INTO ai.netflix_titles 
SELECT * FROM dbo.netflix_titles2

ALTER TABLE ai.netflix_titles
ADD document_vector VECTOR(1536) NULL;

-- LOOP thru records to generate embedding
DECLARE @id VARCHAR(10);
DECLARE @input NVARCHAR(MAX);
DECLARE @embedding VECTOR(1536);

DECLARE doc_cursor CURSOR FOR

SELECT TOP 10000 NT.show_id AS ID, NT.title + ' ' + NT.[description] AS inputText
FROM ai.netflix_titles AS NT
WHERE document_vector IS NULL;

OPEN doc_cursor;
FETCH NEXT FROM doc_cursor INTO @id, @input;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Call your embedding generation procedure
	EXEC dbo.generate_embedding @input, @embedding OUTPUT;
	   
    -- Update the table with the returned embedding
    UPDATE ai.netflix_titles 
    SET document_vector = @embedding
    WHERE show_id = @id;

    FETCH NEXT FROM doc_cursor INTO @id, @input;
END

CLOSE doc_cursor;
DEALLOCATE doc_cursor;
GO

-- Embeddings generated...
SELECT *
FROM ai.netflix_titles AS NT
WHERE document_vector IS NOT NULL;

-- Vector Search
DECLARE @e vector(1536);
EXEC dbo.generate_embedding 'Best romantic comedy movies to watch in family with kids coming to tenage years', @e OUTPUT;
--EXEC dbo.generate_embedding 'Action movie with zombies and a lot of blood', @e OUTPUT;
--EXEC dbo.generate_embedding 'Sports movie that shows the struggle of a team to win the championship', @e OUTPUT;

SELECT TOP 3 *, vector_distance('cosine', NT.document_vector, @e)
FROM ai.netflix_titles AS NT
ORDER BY vector_distance('cosine', NT.document_vector, @e)


-- 2nd query
DECLARE @e vector(1536);
--EXEC dbo.generate_embedding 'Best romantic comedy movies to watch in family with kids coming to tenage years', @e OUTPUT;
--EXEC dbo.generate_embedding 'Action movie with zombies and a lot of blood', @e OUTPUT;
EXEC dbo.generate_embedding 'Sports movie that shows the struggle of a team to win the championship', @e OUTPUT;

SELECT TOP 3 *, vector_distance('cosine', NT.document_vector, @e)
FROM ai.netflix_titles AS NT
WHERE NT.release_year = 2011 --2011
ORDER BY vector_distance('cosine', NT.document_vector, @e)